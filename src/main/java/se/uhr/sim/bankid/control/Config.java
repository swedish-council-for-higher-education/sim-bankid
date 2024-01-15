package se.uhr.sim.bankid.control;

import java.time.Duration;

import jakarta.enterprise.context.Dependent;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.quarkus.runtime.Startup;

@Dependent
public class Config {

	private static final Logger LOG = LoggerFactory.getLogger(Config.class);

	@ConfigProperty(name = "bankid.call.delay.duration", defaultValue = "PT0S")
	Duration delay;

	@ConfigProperty(name = "bankid.iterations", defaultValue = "1")
	Integer iterations;

	@Startup
	void init() {
		LOG.info("configuration delay: {} iterations: {}", delay, iterations);
	}

	public Duration delay() {
		return delay;
	}

	public int iterations() {
		return iterations;
	}

}
