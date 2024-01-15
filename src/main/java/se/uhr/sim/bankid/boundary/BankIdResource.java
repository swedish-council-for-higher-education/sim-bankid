package se.uhr.sim.bankid.boundary;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicInteger;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.micrometer.core.annotation.Counted;
import io.smallrye.common.annotation.RunOnVirtualThread;
import se.uhr.sim.bankid.boundary.State.Status;
import se.uhr.sim.bankid.control.Config;
import se.uhr.sim.bankid.control.PersonalNumbers;

@Path("/rp/v6.0")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class BankIdResource {

	private static final Logger LOG = LoggerFactory.getLogger(BankIdResource.class);

	private static final String PENDING = "pending";

	private static final ConcurrentMap<UUID, State> STATUS_MAP = new ConcurrentHashMap<>();

	private final Config config;

	@Inject
	BankIdResource(Config config) {
		this.config = config;
	}

	@Counted(value = "bankid.auth.calls")
	@POST
	@Path("/auth")
	public AuthRepresenation auth() throws InterruptedException {
		var orderRef = UUID.randomUUID();
		STATUS_MAP.put(orderRef, new State());

		Thread.sleep(config.delay());

		return new AuthRepresenation(orderRef, UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID());
	}

	@Counted(value = "bankid.collect.calls")
	@RunOnVirtualThread
	@POST
	@Path("/collect")
	public CollectRequestRepresentation collect(CollectRequestRepresentation collectRequest) throws InterruptedException {
		State state = STATUS_MAP.get(collectRequest.orderRef());

		if (state != null) {
			LOG.info("Collecting orderRef: {} status: {}", collectRequest.orderRef(), state.status());
		} else {
			throw new WebApplicationException(400);
		}

		Thread.sleep(config.delay());

		return switch (state.status()) {
			case INITIAL -> {
				STATUS_MAP.computeIfPresent(collectRequest.orderRef(),
						(k, v) -> v.initCount().intValue() < config.iterations()
								? new State(Status.INITIAL, new AtomicInteger(v.initCount().incrementAndGet()))
								: new State(Status.OUTSTANDING_TRANSACTION));

				yield new CollectRequestRepresentation(collectRequest.orderRef(), PENDING, "outstandingTransaction", null);
			}
			case OUTSTANDING_TRANSACTION -> {
				STATUS_MAP.computeIfPresent(collectRequest.orderRef(), (k, v) -> new State(Status.STARTED));
				yield new CollectRequestRepresentation(collectRequest.orderRef(), PENDING, "started", null);
			}
			case STARTED -> {
				STATUS_MAP.computeIfPresent(collectRequest.orderRef(), (k, v) -> new State(Status.USER_SIGN));
				yield new CollectRequestRepresentation(collectRequest.orderRef(), PENDING, "userSign", null);
			}
			case USER_SIGN -> {
				STATUS_MAP.remove(collectRequest.orderRef());
				yield new CollectRequestRepresentation(collectRequest.orderRef(), "complete", null, new CompletionDataRepresenation(
						new User(PersonalNumbers.randomPerson(), "John Doe", "John", "Doe"), new Device("192.168.0.1"), "2020-02-01"));
			}
		};
	}

	@PUT
	@Path("/clear")
	public void clear() {
		STATUS_MAP.clear();
	}

}