package se.uhr.sim.bankid.boundary;

import java.util.concurrent.atomic.AtomicInteger;

public record State(Status status, AtomicInteger initCount) {

	public State() {
		this(Status.INITIAL, new AtomicInteger(1));
	}

	public State(Status status) {
		this(status, new AtomicInteger(1));
	}

	public enum Status {
		INITIAL,
		OUTSTANDING_TRANSACTION,
		STARTED,
		USER_SIGN
	}
}
