package se.uhr.sim.bankid.control;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class PersonalNumberRepository {

	private final CopyOnWriteArrayList<String> persons = new CopyOnWriteArrayList<>();

	private int currentIndex = 0;

	public String nextPerson() {
		if(persons.isEmpty()) {
			throw new IndexOutOfBoundsException("No personal numbers available");
		}
		currentIndex = currentIndex < Integer.MAX_VALUE ? currentIndex + 1 : 0;
		return persons.get(currentIndex % persons.size());
	}

	public void addAll(List<String> numbers) {
		persons.addAll(numbers);
	}

	public int size() {
		return persons.size();
	}

	public boolean isEmpty() {
		return persons.isEmpty();
	}

	public void clear() {
		persons.clear();
	}
}
