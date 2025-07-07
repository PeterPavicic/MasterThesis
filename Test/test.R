library(dplyr)
library(purrr)


asd <- read.csv("/home/peter/WU_OneDrive/QFin/MT Master Thesis/Analysis/FOMC analysis/TimeSeries/Fed_Interest_Rates_2024_09_September.csv")

sum(asd$tokenVolume) / 2

# Assuming 'scaled_events' is your dataframe of orderFilledEvents
# and it includes transactionHash, maker, taker, and tokenVolume.


# First, group by transactionHash and identify the true end-users of the trade
net_volume_per_transaction <- scaled_eventsList[[2]] %>%
  group_by(transactionHash) %>%
  # nest() creates a mini-dataframe for each transaction
  nest() %>%
  # Now, operate on each transaction's dataframe
  mutate(net_volume = map_dbl(data, ~{
    # Identify all makers and takers within this single transaction
    makers_in_tx <- unique(.x$maker)
    takers_in_tx <- unique(.x$taker)
    
    # Intermediaries are those who are both makers and takers
    intermediaries <- intersect(makers_in_tx, takers_in_tx)
    
    # The true buyers are takers who are NOT intermediaries
    true_buyers <- setdiff(takers_in_tx, intermediaries)
    
    # If there are no true buyers, this might be a complex trade between bots.
    # We only want volume from trades that reach a final destination.
    if (length(true_buyers) == 0) {
      print("This is a complex transaction")
      return(0)
    }
    
    # Calculate volume by summing the amounts received by the true buyers
    net_trade_volume <- .x %>%
      filter(taker %in% true_buyers) %>%
      summarise(total_vol = sum(tokenVolume)) %>%
      pull(total_vol)
      
    return(net_trade_volume)
  }))

# The total accurate volume is the sum of the net volumes of each transaction
total_accurate_volume <- sum(net_volume_per_transaction$net_volume)

print(paste("Total Accurate Token Volume:", total_accurate_volume))
