library(readr)
library(dplyr)

ROOT_DIR <- dirname(dirname(dirname(getwd())))

barchart_folder <- file.path(ROOT_DIR, "data/raw/barchart")
toWrite_folder <- file.path(ROOT_DIR, "data/interim/01_cleaned/barchart")

fileList <- list.files(barchart_folder)
ZQ_names <- substr(fileList, 1, 5)


# data cleaning
for (i in seq_along(fileList)) {
  filePath <- file.path(barchart_folder, fileList[i])
  writePath <- file.path(toWrite_folder, fileList[i])

  uncleaned_data <- read_csv(
    filePath,
    col_types = cols(
      `Date Time` = col_character()
    )
  ) |>
    mutate(
      time = as.numeric(as.POSIXct(`Date Time`, tz = "America/Chicago"))
    ) |>
    select(
      time,
      open = Open,
      high = High,
      low = Low,
      close = Close,
      Volume
    )

  uncleaned_data |>
    write_csv(
      file = writePath
    )
}

rm(
  barchart_folder,
  i,
  filePath,
  writePath,
  uncleaned_data
)

# data joining
clean_data_path <- toWrite_folder
toWrite_folder <- file.path(ROOT_DIR, "data/interim/02_renamed/barchart")

for (ZQ_name in unique(ZQ_names)) {
  is_relevant_ZQ <- startsWith(fileList, ZQ_name)
  filePaths <- file.path(clean_data_path, fileList)[is_relevant_ZQ]
  writePath <- file.path(toWrite_folder, paste0(ZQ_name, ".csv"))

  relevant_ZQs <- lapply(filePaths, FUN = read_csv)

  combined <- do.call(bind_rows, relevant_ZQs)
  deduplicated <- combined |>
    distinct() |>
    arrange(time)

  write_csv(deduplicated, writePath)
}
