if (!require(dplyr)) install.packages("dplyr")
if (!require(readr)) install.packages("readr")

library(dplyr)
library(readr)


ROOT_DIR <- dirname(dirname(dirname(getwd()))) 


# WARNING: Unfinished
# Rewrite for processing election data


tokens_data <- read_csv(
  file.path(ROOT_DIR, "data/processed/tokens/FOMC Tokens.csv"),
  col_types = cols(
    Yes = col_character(),
    No = col_character()
  ))


tokens_outcomes <- tokens_data |>
  select(
    tokenId = Yes,
    tokenOutcome = outcomeYes
  )  |>
  bind_rows(
    tokens_data |> 
      select(
        tokenId = No,
        tokenOutcome = outcomeNo
      )
  )


perform_analysis <- function(event_tibble, event_name) {
  scaled_PnL <- event_tibble |>
    select(-id) |>
    mutate(
      amount = amount / 10^6,
      avgPrice = avgPrice / 10^6,
      realizedPnl = realizedPnl / 10^6,
      totalBought = totalBought / 10^6,
    ) |>
    left_join(
      tokens_outcomes,
      by = "tokenId"
    ) |>
    mutate(
      unrealizedPnl = amount * tokenOutcome
    )  |>
    mutate(
      payoff = realizedPnl + unrealizedPnl,
      investmentSize = avgPrice * totalBought
    )

  userReturns <- scaled_PnL |>
    select(user, tokenId, investmentSize, payoff) |>
    filter(
      investmentSize != 0
    ) |>
    group_by(user) |>
    summarise(
      eventReturn = sum(payoff) / sum(investmentSize)
    ) |>
    arrange(user)

  realUsers <- unique(userReturns$user)
  save(
    scaled_PnL,
    userReturns,
    realUsers,
    file = file.path(ROOT_DIR, sprintf("data/processed/UserPnLs/%s.RData", event_name))
  )
}

dirs <- list.dirs(
  path = file.path(
    ROOT_DIR,
    "data/raw/polymarket/userPnL/fomc_PnL"
  ),
  recursive = FALSE
)

# Write users to users.txt for each event
# For each event perform analysis
for (dir in dirs) {
  event_name <- last(strsplit(dir, "/")[[1]])
  csv_files <- file.path(dir, list.files(path = dir, pattern = "\\.csv$"))

  all_PnLs_for_event <- bind_rows(
    sapply(csv_files,
      function(x) {
        read_csv(x,
          col_types = cols(
            user = col_character(),
            tokenId = col_character()
          )
        ) |>
          as_tibble()
      },
      simplify = FALSE))

  perform_analysis(all_PnLs_for_event, event_name)
}
