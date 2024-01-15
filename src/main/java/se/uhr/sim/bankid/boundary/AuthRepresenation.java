package se.uhr.sim.bankid.boundary;

import java.util.UUID;

public record AuthRepresenation(UUID orderRef, UUID autoStartToken, UUID qrStartToken, UUID qrStartSecret) {

}
