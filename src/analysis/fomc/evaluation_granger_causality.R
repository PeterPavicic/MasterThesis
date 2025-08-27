load("FOMC_granger_results_1_min.RData")
# load("FOMC_granger_results_5_min.RData")


# ------ Evaluate granger causality test ------
# --- Blockwise ---
# --- PM --> ZQ ---
for (meetingName in meetingMonths) {
  eigen_results <- PM_cause_ZQ_blockwise[[meetingName]]$eigen$Granger
  trace_results <- PM_cause_ZQ_blockwise[[meetingName]]$trace$Granger

  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")
  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")

  cat(
    "\n\nMeeting", meetingName,
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}

# TODO: Check if these run fine, add more print statements in running code beginning-to-end
# TODO: Try addig garbage collection to see if code can run at 1 minute fidelity

# --- ZQ --> PM ---
for (meetingName in meetingMonths) {
  eigen_results <- ZQ_cause_PM_blockwise[[meetingName]]$eigen$Granger
  trace_results <- ZQ_cause_PM_blockwise[[meetingName]]$trace$Granger

  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")
  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")

  cat(
    "\n\nMeeting", meetingName,
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}


# --- Bivariate ---
# --- PM --> ZQ ---
for (meetingName in meetingMonths) {
  assetNames <- names(PM_cause_ZQ_bivariate)

  cat("\n\nMeeting:", meetingName)

  for (unique_asset in assetNames) {
    eigen_results <- PM_cause_ZQ_bivariate[[meetingName]][[unique_asset]]$eigen$Granger
    trace_results <- PM_cause_ZQ_bivariate[[meetingName]][[unique_asset]]$trace$Granger
    eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")
    trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")
    cat(
      "\nasset:", unique_asset,
      "\nEigen result:", eigen_rejects,
      "\nwith p-value:", eigen_results$p.value,
      "\nTrace result:", trace_rejects,
      "\nwith p-value:", trace_results$p.value,
      "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
      "\n\n"
    )
  }
}

# --- ZQ --> PM ---
for (meetingName in meetingMonths) {
  assetNames <- names(PM_cause_ZQ_bivariate)

  cat("\n\nMeeting:", meetingName)

  for (unique_asset in assetNames) {
    eigen_results <- ZQ_cause_PM_bivariate[[meetingName]]$eigen$Granger
    trace_results <- ZQ_cause_PM_bivariate[[meetingName]]$trace$Granger
    eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")
    trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")

    cat(
      "\nasset:", unique_asset,
      "\nEigen result:", eigen_rejects,
      "\nwith p-value:", eigen_results$p.value,
      "\nTrace result:", trace_rejects,
      "\nwith p-value:", trace_results$p.value,
      "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
      "\n\n"
    )
  }
}
