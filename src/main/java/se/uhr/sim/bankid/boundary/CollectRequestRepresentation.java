package se.uhr.sim.bankid.boundary;

import java.util.UUID;

public record CollectRequestRepresentation(UUID orderRef, String status, String hintCode, CompletionDataRepresenation completionData) {

}
