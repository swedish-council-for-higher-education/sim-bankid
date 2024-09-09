package se.uhr.sim.bankid.boundary;

import java.io.IOException;
import java.nio.file.Files;
import java.util.List;
import jakarta.inject.Inject;
import jakarta.json.Json;
import jakarta.json.JsonReader;
import jakarta.json.JsonString;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.resteasy.reactive.multipart.FileUpload;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import se.uhr.sim.bankid.control.PersonalNumberRepository;

@Path("/admin/pnr")
public class PersonalNumberResource {

	private final PersonalNumberRepository repository;

	private static final Logger LOG = LoggerFactory.getLogger(PersonalNumberResource.class);

	@Inject
	public PersonalNumberResource(PersonalNumberRepository repository) {
		this.repository = repository;
	}

	@POST
	@Consumes(MediaType.MULTIPART_FORM_DATA)
	public Response addPersonalNumbers(FileUploadInput input) {
		input.file.forEach(f -> {
			try (var reader = Files.newBufferedReader(f.uploadedFile())) {
				try (JsonReader jsonReader = Json.createReader(reader)) {
					List<String> numbers = jsonReader.readArray()
							.stream()
							.filter(JsonString.class::isInstance)
							.map(JsonString.class::cast)
							.map(JsonString::getString)
							.toList();
					repository.addAll(numbers);

					LOG.info("Added {} pnr, total size is {}", numbers.size(), repository.size());
				}
			} catch (IOException e) {
				throw new WebApplicationException(Response.Status.BAD_REQUEST);
			}
		});
		return Response.ok().build();
	}

	@GET
	@Produces(MediaType.TEXT_PLAIN)
	public Response nextPersonalNumber() {
		String number = repository.nextPerson();
		return Response.ok(number).build();
	}

	@DELETE
	public Response clear() {
		repository.clear();
		LOG.info("clear pnr list");
		return Response.ok().build();
	}

	public static class FileUploadInput {

		@FormParam("file")
		public List<FileUpload> file;
	}
}
