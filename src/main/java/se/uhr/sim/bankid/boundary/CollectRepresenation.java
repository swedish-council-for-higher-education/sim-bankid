package se.uhr.sim.bankid.boundary;

import java.util.UUID;

public record CollectRepresenation(UUID orderRef, String status, String hintCode, CompletionDataRepresenation completionData) {

}
