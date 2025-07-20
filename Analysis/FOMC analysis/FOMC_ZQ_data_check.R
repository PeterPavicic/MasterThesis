library(dplyr)
library(readr)
library(tibble)
library(tidyr)


# --------- Checking ZQ data from BC against TW ---------
as.POSIXct("2024-09-01 17:00:00", tz = "America/Chicago")

BC_data <- read_csv(
  "./ZQ/test/BC_ZQN2025.csv",
  col_types = cols(
    `Date Time`     = col_character(),
    `Open`          = col_double(),
    `High`          = col_double(),
    `Low`           = col_double(),
    `Close`         = col_double(),
    `Change`        = col_double(),
    `Volume`        = col_double(),
    `Open Interest` = col_double()
  )
) |> 
  select(
    ChicagoTime = `Date Time`,
    close = Close,
    volume = Volume
  ) |> 
  mutate(
    POSIXTime = as.POSIXct(ChicagoTime, tz = "America/Chicago"),
    rateBps = (100 - close) * 100
  ) |>
  mutate(
    time = as.POSIXct(POSIXTime, tz = "America/New_York")
  ) |>
  select(
    time,
    rateBps,
    volume
  )


TW_data <- read_csv(
  "./ZQ/test/TW_ZQN2025.csv",
  col_types = cols(
    open = col_double(),
    high = col_double(),
    low = col_double(),
    close = col_double(),
    Volume = col_double()
  )
) |> 
  select(
    time,
    close,
    volume = Volume
  ) |> 
  mutate(
    time = as.POSIXct(time, tz = "America/New_York"),
    rateBps = (100 - close) * 100
  ) |>
  select(
    time,
    rateBps,
    volume
  )



plot(BC_data[, c("time", "rateBps")], type = 'l', col = "black")
lines(TW_data[, c("time", "rateBps")], type = 'l', col="red")


# NOTE: Test for ZQG
BC_data <- read_csv(
  "./ZQ/test/BC_ZQG2025.csv",
  col_types = cols(
    `Date Time`     = col_character(),
    `Open`          = col_double(),
    `High`          = col_double(),
    `Low`           = col_double(),
    `Close`         = col_double(),
    `Change`        = col_double(),
    `Volume`        = col_double(),
    `Open Interest` = col_double()
  )
) |> 
  select(
    ChicagoTime = `Date Time`,
    close = Close,
    volume = Volume
  ) |> 
  mutate(
    POSIXTime = as.POSIXct(ChicagoTime, tz = "America/Chicago"),
    rateBps = (100 - close) * 100
  ) |>
  mutate(
    time = as.POSIXct(POSIXTime, tz = "America/New_York")
  ) |>
  select(
    time,
    rateBps,
    volume
  )


TW_data <- read_csv(
  "./ZQ/test/TW_ZQG2025.csv",
  col_types = cols(
    open = col_double(),
    high = col_double(),
    low = col_double(),
    close = col_double(),
    Volume = col_double()
  )
) |> 
  select(
    time,
    close,
    volume = Volume
  ) |> 
  mutate(
    time = as.POSIXct(time, tz = "America/New_York"),
    rateBps = (100 - close) * 100
  ) |>
  select(
    time,
    rateBps,
    volume
  )


plot(BC_data[, c("time", "rateBps")], type = 'l', col = "black")
lines(TW_data[, c("time", "rateBps")], type = 'l', col = "red")



# --------- Processing ZQ data from BC into format of TW ---------
BC_files <- file.path("./ZQ/BC", 
  list.files(path = "./ZQ/BC/", pattern = "\\.csv$")
)

for (BC_file in BC_files) {
  fileName <- substr(BC_file, 9, nchar(BC_file))
  BC_data <- read_csv(
    BC_file,
    col_types = cols(
      `Date Time`     = col_character(),
      `Open`          = col_double(),
      `High`          = col_double(),
      `Low`           = col_double(),
      `Close`         = col_double(),
      `Change`        = col_double(),
      `Volume`        = col_double(),
      `Open Interest` = col_double()
    )
  ) |> 
    mutate(
      time = as.numeric(
        as.POSIXct(`Date Time`, tz = "America/Chicago")
      )
    ) |>
    select(
      time,
      open = Open,
      high = High,
      low = Low,
      close = Close,
      Volume
    ) |> 
    write_csv(
      file.path("./ZQ/BC", "processed", fileName)
    )
}


# ---------- Checking starting time of ZQ files
firstStarts <- numeric(length(ZQ_files))

# TODO: Put this into for loop just like PM_data above
for (i in seq_along(ZQ_files)) {
  ZQ_fileName <- ZQ_files[i]
  ZQ_data <- read_csv(
    ZQ_fileName,
    col_types = cols(
      open = col_double(),
      high = col_double(),
      low = col_double(),
      close = col_double()
    )
  ) |>
    select(time, close) |>
    mutate(
      time = as.POSIXct(time, tz = "America/New_York"),
      rateBps = (100 - close) * 100,
      # TODO: Here only load data, perform change calculation elsewhere
      changeBps = rateBps - 525
    )

  # # Print time range for data in each of the files:
  firstStarts[i] <- min(ZQ_data$time)
  # cat("\n\n", ZQ_fileName, "\n")
  # print("ZQ range:")
  # print(range(ZQ_data$time))
}


rm(i)

df <- data.frame(fileName = ZQ_files, firstStart = as.POSIXct(firstStarts))
View(df)
