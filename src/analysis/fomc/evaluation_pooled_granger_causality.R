if (!require(knitr)) install.packages("knitr")
if (!require(kableExtra)) install.packages("kableExtra")
if (!require(modelsummary)) install.packages("modelsummary")

library(knitr)
library(kableExtra)
library(modelsummary)

# load("./pooled_granger_causality_results.RData")
# load("pooled_gc_5_mins.RData")
load("pooled_gc_no_monday_1_min.RData")

options(scipen = 9999)


get_significance_stars <- function(p_value) {
  if (p_value == "None") "None"
  else {
    p_value <- as.numeric(p_value)

    stars <- ifelse(
      0.1 < p_value,
      " ",
      ifelse(
        0.05 < p_value,
        ".",
        ifelse(
          0.01 < p_value,
          "*",
          ifelse(
            0.001 < p_value,
            "**",
            "***"
          )
        )
      )
    )

    stars
  }
}

# --- Blockwise ---
PM_cause_ZQ_blockwise
ZQ_cause_PM_blockwise

# ------ Evaluate granger causality test ------
# Initialise empty tables
blockwise_PM_cause_ZQ_table_trace <- data.frame(
  F_stat = NA,
  df1 = NA,
  df2 = NA,
  p_value = NA,
  significance = NA
)

blockwise_PM_cause_ZQ_table_eigen <- data.frame(
  F_stat = NA,
  df1 = NA,
  df2 = NA,
  p_value = NA,
  significance = NA
)

blockwise_ZQ_cause_PM_table_trace <- data.frame(
  F_stat = NA,
  df1 = NA,
  df2 = NA,
  p_value = NA,
  significance = NA
)

blockwise_ZQ_cause_PM_table_eigen <- data.frame(
  F_stat = NA,
  df1 = NA,
  df2 = NA,
  p_value = NA,
  significance = NA
)


# --- PM --> ZQ ---
{
  eigen_results <- PM_cause_ZQ_blockwise$eigen$Granger
  trace_results <- PM_cause_ZQ_blockwise$trace$Granger
  
  if (is.null(eigen_results)) eigen_results <- list(
    statistic = "None",
    parameter = c("None", "None"),
    p.value = "None"
  )

  if (is.null(trace_results)) trace_results <- list(
    statistic = "None",
    parameter = c("None", "None"),
    p.value = "None"
  )

  trace_F_stat <- drop(trace_results$statistic)
  trace_df1 <- drop(trace_results$parameter[1])
  trace_df2 <- drop(trace_results$parameter[2])
  trace_p_value <- drop(trace_results$p.value)
  trace_significance <- get_significance_stars(trace_p_value)

  eigen_F_stat <- drop(eigen_results$statistic)
  eigen_df1 <- drop(eigen_results$parameter[1])
  eigen_df2 <- drop(eigen_results$parameter[2])
  eigen_p_value <- drop(eigen_results$p.value)
  eigen_significance <- get_significance_stars(eigen_p_value)

  if (trace_F_stat != "None") trace_F_stat <- sprintf("%.4f", as.numeric(trace_F_stat))
  if (trace_df1 != "None") trace_df1 <- sprintf("%.4f", as.numeric(trace_df1))
  if (trace_df2 != "None") trace_df2 <- sprintf("%.4f", as.numeric(trace_df2))
  if (trace_p_value != "None") trace_p_value <- sprintf("%.4f", as.numeric(trace_p_value))
  if (trace_significance != "None") trace_significance <- get_significance_stars(trace_p_value)

  if (eigen_F_stat != "None") eigen_F_stat <- sprintf("%.4f", as.numeric(eigen_F_stat))
  if (eigen_df1 != "None") eigen_df1 <- sprintf("%.4f", as.numeric(eigen_df1))
  if (eigen_df2 != "None") eigen_df2 <- sprintf("%.4f", as.numeric(eigen_df2))
  if (eigen_p_value != "None") eigen_p_value <- sprintf("%.4f", as.numeric(eigen_p_value))
  if (eigen_significance != "None") eigen_significance <- get_significance_stars(eigen_p_value)

  blockwise_PM_cause_ZQ_table_trace["F_stat"] <- trace_F_stat
  blockwise_PM_cause_ZQ_table_trace["df1"] <- trace_df1
  blockwise_PM_cause_ZQ_table_trace["df2"] <- trace_df2
  blockwise_PM_cause_ZQ_table_trace["p_value"] <- trace_p_value
  blockwise_PM_cause_ZQ_table_trace["significance"] <- trace_significance

  blockwise_PM_cause_ZQ_table_eigen["F_stat"] <- eigen_F_stat
  blockwise_PM_cause_ZQ_table_eigen["df1"] <- eigen_df1
  blockwise_PM_cause_ZQ_table_eigen["df2"] <- eigen_df2
  blockwise_PM_cause_ZQ_table_eigen["p_value"] <- eigen_p_value
  blockwise_PM_cause_ZQ_table_eigen["significance"] <- eigen_significance

  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")
  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")


  cat(
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}


# --- ZQ --> PM ---
{
  eigen_results <- ZQ_cause_PM_blockwise$eigen$Granger
  trace_results <- ZQ_cause_PM_blockwise$trace$Granger

  
  if (is.null(eigen_results)) eigen_results <- list(
    statistic = "None",
    parameter = c("None", "None"),
    p.value = "None"
  )

  if (is.null(trace_results)) trace_results <- list(
    statistic = "None",
    parameter = c("None", "None"),
    p.value = "None"
  )

  trace_F_stat <- drop(trace_results$statistic)
  trace_df1 <- drop(trace_results$parameter[1])
  trace_df2 <- drop(trace_results$parameter[2])
  trace_p_value <- drop(trace_results$p.value)
  trace_significance <- get_significance_stars(trace_p_value)


  eigen_F_stat <- drop(eigen_results$statistic)
  eigen_df1 <- drop(eigen_results$parameter[1])
  eigen_df2 <- drop(eigen_results$parameter[2])
  eigen_p_value <- drop(eigen_results$p.value)
  eigen_significance <- get_significance_stars(eigen_p_value)

  if (trace_F_stat != "None") trace_F_stat <- sprintf("%.4f", as.numeric(trace_F_stat))
  if (trace_df1 != "None") trace_df1 <- sprintf("%.4f", as.numeric(trace_df1))
  if (trace_df2 != "None") trace_df2 <- sprintf("%.4f", as.numeric(trace_df2))
  if (trace_p_value != "None") trace_p_value <- sprintf("%.4f", as.numeric(trace_p_value))
  if (trace_significance != "None") trace_significance <- get_significance_stars(trace_p_value)

  if (eigen_F_stat != "None") eigen_F_stat <- sprintf("%.4f", as.numeric(eigen_F_stat))
  if (eigen_df1 != "None") eigen_df1 <- sprintf("%.4f", as.numeric(eigen_df1))
  if (eigen_df2 != "None") eigen_df2 <- sprintf("%.4f", as.numeric(eigen_df2))
  if (eigen_p_value != "None") eigen_p_value <- sprintf("%.4f", as.numeric(eigen_p_value))
  if (eigen_significance != "None") eigen_significance <- get_significance_stars(eigen_p_value)

  blockwise_ZQ_cause_PM_table_trace["F_stat"] <- trace_F_stat
  blockwise_ZQ_cause_PM_table_trace["df1"] <- trace_df1
  blockwise_ZQ_cause_PM_table_trace["df2"] <- trace_df2
  blockwise_ZQ_cause_PM_table_trace["p_value"] <- trace_p_value
  blockwise_ZQ_cause_PM_table_trace["significance"] <- trace_significance
                                   
  blockwise_ZQ_cause_PM_table_eigen["F_stat"] <- eigen_F_stat
  blockwise_ZQ_cause_PM_table_eigen["df1"] <- trace_df1
  blockwise_ZQ_cause_PM_table_eigen["df2"] <- trace_df2
  blockwise_ZQ_cause_PM_table_eigen["p_value"] <- eigen_p_value
  blockwise_ZQ_cause_PM_table_eigen["significance"] <- eigen_significance

  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")
  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")

  cat(
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}


blockwise_PM_cause_ZQ_table_trace
blockwise_PM_cause_ZQ_table_eigen
blockwise_ZQ_cause_PM_table_trace
blockwise_ZQ_cause_PM_table_eigen


PM_ZQ_eigen <- datasummary_df(
  blockwise_PM_cause_ZQ_table_eigen,
  output = "latex",
  align = "lllll",
  title = "blockwise_PM_cause_ZQ_table_eigen"
)
ZQ_PM_eigen <- datasummary_df(
  blockwise_ZQ_cause_PM_table_eigen,
  output = "latex",
  align = "lllll",
  title = "blockwise_ZQ_cause_PM_table_eigen"
)
PM_ZQ_trace <- datasummary_df(
  blockwise_PM_cause_ZQ_table_trace,
  output = "latex",
  align = "lllll",
  title = "blockwise_PM_cause_ZQ_table_trace"
)
ZQ_PM_trace <- datasummary_df(
  blockwise_ZQ_cause_PM_table_trace,
  output = "latex",
  align = "lllll",
  title = "blockwise_ZQ_cause_PM_table_trace"
)

toCopy <- paste0(
  "\n\n% PM_ZQ_eigen\n",
  as.character(PM_ZQ_eigen),
  "\n\n% ZQ_PM_eigen\n",
  as.character(ZQ_PM_eigen),
  "\n\n% PM_ZQ_trace\n",
  as.character(PM_ZQ_trace),
  "\n\n% ZQ_PM_trace\n",
  as.character(ZQ_PM_trace)
)

system2(
  "wl-copy",
  input = toCopy
)



rm(
  blockwise_PM_cause_ZQ_table_eigen,
  blockwise_PM_cause_ZQ_table_trace,
  blockwise_ZQ_cause_PM_table_eigen,
  blockwise_ZQ_cause_PM_table_trace,
  eigen_rejects,
  eigen_results,
  eigen_stars,
  trace_rejects,
  trace_results,
  trace_stars
)



# ------ Evaluate instaneous causality test ------
# --- Blockwise ---
# Initialise empty tables
blockwise_PM_cause_ZQ_table_trace <- data.frame(
  chisq = NA,
  df1 = NA,
  p_value = NA,
  significance = NA
)

blockwise_PM_cause_ZQ_table_eigen <- data.frame(
  chisq = NA,
  df1 = NA,
  p_value = NA,
  significance = NA
)

blockwise_ZQ_cause_PM_table_trace <- data.frame(
  chisq = NA,
  df1 = NA,
  p_value = NA,
  significance = NA
)

blockwise_ZQ_cause_PM_table_eigen <- data.frame(
  chisq = NA,
  df1 = NA,
  p_value = NA,
  significance = NA
)



# --- PM --> ZQ ---
{
  eigen_results <- PM_cause_ZQ_blockwise$eigen$Instant
  trace_results <- PM_cause_ZQ_blockwise$trace$Instant

  if (is.null(eigen_results)) eigen_results <- list(
    statistic = "None",
    parameter = "None",
    p.value = "None"
  )

  if (is.null(trace_results)) trace_results <- list(
    statistic = "None",
    parameter = "None",
    p.value = "None"
  )

  trace_chisq <- drop(trace_results$statistic)
  trace_df1 <- drop(trace_results$parameter)
  trace_p_value <- drop(trace_results$p.value)
  trace_significance <- get_significance_stars(trace_p_value)

  eigen_chisq <- drop(eigen_results$statistic)
  eigen_df1 <- drop(eigen_results$parameter)
  eigen_p_value <- drop(eigen_results$p.value)
  eigen_significance <- get_significance_stars(eigen_p_value)

  if (trace_chisq != "None") trace_chisq <- sprintf("%.4f", as.numeric(trace_chisq))
  if (trace_df1 != "None") trace_df1 <- sprintf("%.4f", as.numeric(trace_df1))
  if (trace_p_value != "None") trace_p_value <- sprintf("%.4f", as.numeric(trace_p_value))
  if (trace_significance != "None") trace_significance <- get_significance_stars(trace_p_value)

  if (eigen_chisq != "None") eigen_chisq <- sprintf("%.4f", as.numeric(eigen_chisq))
  if (eigen_df1 != "None") eigen_df1 <- sprintf("%.4f", as.numeric(eigen_df1))
  if (eigen_p_value != "None") eigen_p_value <- sprintf("%.4f", as.numeric(eigen_p_value))
  if (eigen_significance != "None") eigen_significance <- get_significance_stars(eigen_p_value)

  blockwise_PM_cause_ZQ_table_trace["chisq"] <- trace_chisq
  blockwise_PM_cause_ZQ_table_trace["df1"] <- trace_df1
  blockwise_PM_cause_ZQ_table_trace["p_value"] <- trace_p_value
  blockwise_PM_cause_ZQ_table_trace["significance"] <- trace_significance

  blockwise_PM_cause_ZQ_table_eigen["chisq"] <- eigen_chisq
  blockwise_PM_cause_ZQ_table_eigen["df1"] <- eigen_df1
  blockwise_PM_cause_ZQ_table_eigen["p_value"] <- eigen_p_value
  blockwise_PM_cause_ZQ_table_eigen["significance"] <- eigen_significance

  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")
  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")


  cat(
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}


# --- ZQ --> PM ---
{
  eigen_results <- ZQ_cause_PM_blockwise$eigen$Instant
  trace_results <- ZQ_cause_PM_blockwise$trace$Instant

  if (is.null(eigen_results)) eigen_results <- list(
    statistic = "None",
    parameter = "None",
    p.value = "None"
  )

  if (is.null(trace_results)) trace_results <- list(
    statistic = "None",
    parameter = "None",
    p.value = "None"
  )

  trace_chisq <- drop(trace_results$statistic)
  trace_df1 <- drop(trace_results$parameter)
  trace_p_value <- drop(trace_results$p.value)
  trace_significance <- get_significance_stars(trace_p_value)

  eigen_chisq <- drop(eigen_results$statistic)
  eigen_df1 <- drop(eigen_results$parameter)
  eigen_p_value <- drop(eigen_results$p.value)
  eigen_significance <- get_significance_stars(eigen_p_value)

  if (trace_chisq != "None") trace_chisq <- sprintf("%.4f", as.numeric(trace_chisq))
  if (trace_df1 != "None") trace_df1 <- sprintf("%.4f", as.numeric(trace_df1))
  if (trace_p_value != "None") trace_p_value <- sprintf("%.4f", as.numeric(trace_p_value))
  if (trace_significance != "None") trace_significance <- get_significance_stars(trace_p_value)

  if (eigen_chisq != "None") eigen_chisq <- sprintf("%.4f", as.numeric(eigen_chisq))
  if (eigen_df1 != "None") eigen_df1 <- sprintf("%.4f", as.numeric(eigen_df1))
  if (eigen_p_value != "None") eigen_p_value <- sprintf("%.4f", as.numeric(eigen_p_value))
  if (eigen_significance != "None") eigen_significance <- get_significance_stars(eigen_p_value)

  blockwise_ZQ_cause_PM_table_trace["chisq"] <- trace_chisq
  blockwise_ZQ_cause_PM_table_trace["df1"] <- trace_df1
  blockwise_ZQ_cause_PM_table_trace["p_value"] <- trace_p_value
  blockwise_ZQ_cause_PM_table_trace["significance"] <- trace_significance
                                   
  blockwise_ZQ_cause_PM_table_eigen["chisq"] <- eigen_chisq
  blockwise_ZQ_cause_PM_table_eigen["df1"] <- eigen_df1
  blockwise_ZQ_cause_PM_table_eigen["p_value"] <- eigen_p_value
  blockwise_ZQ_cause_PM_table_eigen["significance"] <- eigen_significance

  trace_rejects <- ifelse(trace_results$p.value < 0.05, "rejects", "does not reject")
  eigen_rejects <- ifelse(eigen_results$p.value < 0.05, "rejects", "does not reject")

  cat(
    "\nEigen result:", eigen_rejects,
    "\nwith p-value:", eigen_results$p.value,
    "\nTrace result:", trace_rejects,
    "\nwith p-value:", trace_results$p.value,
    "\nThe two methods:", ifelse(eigen_rejects == trace_rejects, "AGREE", "DISAGREE"),
    "\n"
  )
}


blockwise_PM_cause_ZQ_table_trace
blockwise_PM_cause_ZQ_table_eigen
blockwise_ZQ_cause_PM_table_trace
blockwise_ZQ_cause_PM_table_eigen


blockwise_PM_cause_ZQ_table_trace <- data.frame(
  blockwise_PM_cause_ZQ_table_trace
)
blockwise_PM_cause_ZQ_table_eigen <- data.frame(
  blockwise_PM_cause_ZQ_table_eigen
)
blockwise_ZQ_cause_PM_table_trace <- data.frame(
  blockwise_ZQ_cause_PM_table_trace
)
blockwise_ZQ_cause_PM_table_eigen <- data.frame(
  blockwise_ZQ_cause_PM_table_eigen
)


PM_ZQ_eigen <- datasummary_df(
  blockwise_PM_cause_ZQ_table_eigen,
  output = "latex",
  align = "llll",
  title = "blockwise_PM_cause_ZQ_table_eigen"
)
ZQ_PM_eigen <- datasummary_df(
  blockwise_ZQ_cause_PM_table_eigen,
  output = "latex",
  align = "llll",
  title = "blockwise_ZQ_cause_PM_table_eigen"
)
PM_ZQ_trace <- datasummary_df(
  blockwise_PM_cause_ZQ_table_trace,
  output = "latex",
  align = "llll",
  title = "blockwise_PM_cause_ZQ_table_trace"
)
ZQ_PM_trace <- datasummary_df(
  blockwise_ZQ_cause_PM_table_trace,
  output = "latex",
  align = "llll",
  title = "blockwise_ZQ_cause_PM_table_trace"
)

toCopy <- paste0(
  "\n\n% PM_ZQ_eigen\n",
  as.character(PM_ZQ_eigen),
  "\n\n% ZQ_PM_eigen\n",
  as.character(ZQ_PM_eigen),
  "\n\n% PM_ZQ_trace\n",
  as.character(PM_ZQ_trace),
  "\n\n% ZQ_PM_trace\n",
  as.character(ZQ_PM_trace)
)

system2(
  "wl-copy",
  input = toCopy
)
