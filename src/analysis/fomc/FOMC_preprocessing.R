# TODO: Move this into data_processing

if (!require(dplyr)) install.packages("dplyr")
if (!require(ggplot2)) install.packages("ggplot2")
if (!require(readr)) install.packages("readr")
if (!require(tibble)) install.packages("tibble")
if (!require(tidyr)) install.packages("tidyr")
if (!require(viridis)) install.packages("viridis")
if (!require(lubridate)) install.packages("lubridate")

library(dplyr)
library(ggplot2)
library(readr)
library(tibble)
library(tidyr)
library(viridis)
library(lubridate)


# Set wd to the dir containing this file before running
ROOT_DIR <- dirname(dirname(dirname(getwd()))) 

ZQ_name_month_table <- tibble(
  name = c(
    "ZQF2023", # January
    "ZQG2023", # February
    "ZQH2023", # March
    "ZQJ2023", # April
    "ZQK2023", # May
    "ZQM2023", # June
    "ZQN2023", # July
    "ZQQ2023", # August
    "ZQU2023", # September
    "ZQV2023", # October
    "ZQX2023", # November
    "ZQZ2023", # December
    "ZQF2024", # January
    "ZQG2024", # February
    "ZQH2024", # March
    "ZQJ2024", # April
    "ZQK2024", # May
    "ZQM2024", # June
    "ZQN2024", # July
    "ZQQ2024", # August
    "ZQU2024", # September
    "ZQV2024", # October
    "ZQX2024", # November
    "ZQZ2024", # December
    "ZQF2025", # January
    "ZQG2025", # February
    "ZQH2025", # March
    "ZQJ2025", # April
    "ZQK2025", # May
    "ZQM2025", # June
    "ZQN2025", # July
    "ZQQ2025", # August
    "ZQU2025"  # September
  ),
  month = c(
    "2023-01",
    "2023-02",
    "2023-03",
    "2023-04",
    "2023-05",
    "2023-06",
    "2023-07",
    "2023-08",
    "2023-09",
    "2023-10",
    "2023-11",
    "2023-12",
    "2024-01",
    "2024-02",
    "2024-03",
    "2024-04",
    "2024-05",
    "2024-06",
    "2024-07",
    "2024-08",
    "2024-09",
    "2024-10",
    "2024-11",
    "2024-12",
    "2025-01",
    "2025-02",
    "2025-03",
    "2025-04",
    "2025-05",
    "2025-06",
    "2025-07",
    "2025-08",
    "2025-09"
  )
)

# Data frame with fileName, event_slug, meeting time
meetings_noTimeRange <- tibble(
  fileName = c(
    "Fed_Interest_Rates_2023_02_February.csv",
    "Fed_Interest_Rates_2023_03_March.csv",
    "Fed_Interest_Rates_2023_05_May.csv",
    "Fed_Interest_Rates_2023_06_June.csv",
    "Fed_Interest_Rates_2023_07_July.csv",
    "Fed_Interest_Rates_2023_09_September.csv",
    "Fed_Interest_Rates_2023_11_November.csv",
    "Fed_Interest_Rates_2023_12_December.csv",
    "Fed_Interest_Rates_2024_01_January.csv",
    "Fed_Interest_Rates_2024_03_March.csv",
    "Fed_Interest_Rates_2024_05_May.csv",
    "Fed_Interest_Rates_2024_06_June.csv",
    "Fed_Interest_Rates_2024_07_July.csv",
    "Fed_Interest_Rates_2024_09_September.csv",
    "Fed_Interest_Rates_2024_11_November.csv",
    "Fed_Interest_Rates_2024_12_December.csv",
    "Fed_Interest_Rates_2025_01_January.csv",
    "Fed_Interest_Rates_2025_03_March.csv",
    "Fed_Interest_Rates_2025_05_May.csv",
    "Fed_Interest_Rates_2025_06_June.csv",
    "Fed_Interest_Rates_2025_07_July.csv"
  ),
  event_slug = c(
    "fed-interest-rates-february-2023",
    "fed-interest-rates-march-2023",
    "fed-interest-rates-may-2023",
    "fed-interest-rates-june-2023",
    "fed-interest-rates-july-2023",
    "fed-interest-rates-september-2023",
    "fed-interest-rates-november-2023",
    "fed-interest-rates-december-2023",
    "fed-interest-rates-january-2024",
    "fed-interest-rates-march-2024",
    "fed-interest-rates-may-2024",
    "fed-interest-rates-june-2024",
    "fed-interest-rates-july-2024",
    "fed-interest-rates-september-2024",
    "fed-interest-rates-november-2024",
    "fed-interest-rates-december-2024",
    "fed-interest-rates-january-2025",
    "fed-decision-in-march",
    "fed-decision-in-may-2025",
    "fed-decision-in-june",
    "fed-decision-in-july"
  ),
  meetingTime = c(
    as.POSIXct("2023-02-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-03-22 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-05-03 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-06-14 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-07-26 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-09-20 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-11-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2023-12-13 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-01-31 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-03-20 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-05-01 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-06-12 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-07-31 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-09-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-11-07 14:00:00", tz = "America/New_York"),
    as.POSIXct("2024-12-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-01-29 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-03-19 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-05-07 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-06-18 14:00:00", tz = "America/New_York"),
    as.POSIXct("2025-07-30 14:00:00", tz = "America/New_York")
  )
) |>
  mutate(
    meetingMonth = format(meetingTime, "%Y-%m"),
    previousMonthIsAnchor = 
    (floor_date(meetingTime, unit = "month") - months(1)) !=
      na.omit(c(
        as.POSIXct(1671044400, tz = "America/New_York"), # September meeting
        lag(floor_date(meetingTime, unit = "month")) 
      )),
    nextMonthIsAnchor = 
    (floor_date(meetingTime, unit = "month") + months(1)) !=
      na.omit(c(
        lead(floor_date(meetingTime, unit = "month")), 
        as.POSIXct(1758132000, tz = "America/New_York") # September meeting
      )),
    # technically redundant because no 4 consecutive meetings months
    nextNextMonthIsAnchor = 
    (floor_date(meetingTime, unit = "month") + months(2)) !=
      na.omit(c(
        lead(floor_date(meetingTime, unit = "month"), n = 2),
        as.POSIXct(1758132000, tz = "America/New_York"), # September meeting
        as.POSIXct(1761764400, tz = "America/New_York") # October meeting
      )),
  )


tokens <- read_csv(
  file.path(ROOT_DIR, "data/processed/tokens/FOMC Tokens.csv"),
  col_types = cols(
    Yes = col_character(),
    No = col_character()
  )) |>
  select(
    event_slug,
    assetName = marketTitle,
    Yes,
    No
  )


# ------ Loading PM and ZQ data ------ 
{
  PM_files <- file.path(ROOT_DIR, "data/processed/TimeSeries",
    list.files(
      path = file.path(ROOT_DIR, "data/processed/TimeSeries"),
      pattern = "\\.csv$")
  )


  ZQ_files <- file.path(ROOT_DIR, "data/processed/ZQ", 
    list.files(
      path = file.path(ROOT_DIR, "data/processed/ZQ"),
      pattern = "\\.csv$")
  )

  PM_data <- list()
  ZQ_data <- list()

  # Loading Polymarket data
  for (i in seq_along(PM_files)) {
    csv_fileName <- PM_files[i]

    PM_df <- read_csv(
      csv_fileName,
      col_types = cols(
        asset = col_character() 
      )
    ) |> 
      filter(asset %in% tokens$Yes) |>
      mutate(
        time = as.POSIXct(timestamp, tz = "America/New_York")
      ) |>
      left_join(
        tokens |>
          select(assetName, Yes),
        by = join_by(asset == Yes)
      ) |>
      select(
        time,
        asset = assetName,
        price
      ) 

    PM_name <- meetings_noTimeRange |>
      filter(
        fileName == basename(csv_fileName)
      ) |>
      pull(meetingMonth)
    


    PM_df_long <- PM_df[!duplicated(PM_df[, 1:2]), ]

    assetNames <- unique(PM_df_long$asset)

    # This is the best way I could use replace_na
    replaceWith <- list()
    replaceWith[assetNames] <- 0

    # assert that PM_df_long sorted in time
    # without this, fill ends up wrong
    if (any(PM_df_long$time != sort(PM_df_long$time))) stop("PM_df_long unsorted by time")
    # If price data missing fill down, otherwise replace with 0
    PM_df_wide <- PM_df_long |> 
      pivot_wider(
        names_from = asset,
        values_from = price,
        ) |>
      fill(!time, .direction = "down") |>
      replace_na(replace = replaceWith)

    PM_data[[PM_name]] <- PM_df_wide
  }

  for (i in seq_along(ZQ_files)) {
    csv_fileName <- ZQ_files[i]

    ZQ_df <- read_csv(
      csv_fileName,
      col_types = cols(
        open = col_double(),
        high = col_double(),
        low = col_double(),
        close = col_double()
      )
    ) |>
      mutate(
        time = as.POSIXct(time, tz = "America/New_York"),
        rateBps = (100 - close) * 100
      ) |>
      select(time, rateBps)

    ZQ_name <- substr(
      basename(csv_fileName), 1, nchar(basename(csv_fileName)) - 4
    )

    ZQ_name_converted <- ZQ_name_month_table |>
      filter(name == ZQ_name) |>
      pull(month)

    ZQ_data[[ZQ_name_converted]] <- ZQ_df
  }

}


meetings <- meetings_noTimeRange |>
  rowwise() |>
  mutate(
    data_start = min(PM_data[[meetingMonth]]$time),
    data_end = max(PM_data[[meetingMonth]]$time)
  ) |> 
  ungroup()

rm(
  meetings_noTimeRange, 
  ZQ_name_month_table,
  i,
  PM_df,
  ZQ_df,
  PM_files,
  ZQ_files,
  PM_name,
  ZQ_name,
  ZQ_name_converted,
  csv_fileName,
  ROOT_DIR
)


save(
  meetings,
  PM_data,
  tokens,
  ZQ_data,
  file = "./FOMC_preprocesed.RData"
)

print("Finished preprocessing")
