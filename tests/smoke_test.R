required_files <- c(
  "dashboard.Rmd",
  "data/pine_beetle_1993.xlsx",
  "README.md",
  "NOTICE.md"
)

missing_files <- required_files[!file.exists(required_files)]
stopifnot("Required repository files are present" = length(missing_files) == 0)

stopifnot("readxl is installed" = requireNamespace("readxl", quietly = TRUE))
data <- readxl::read_excel("data/pine_beetle_1993.xlsx")

required_columns <- c(
  "TreeNum", "Response", "Easting", "Northing", "TreeDiam",
  "Infest_Serv1", "Ind_DeadDist", "DeadDist", "SDI_20th", "BA_20th"
)

stopifnot("Dataset has expected dimensions" = nrow(data) == 9687L && ncol(data) == 26L)
stopifnot("Dataset has expected columns" = all(required_columns %in% names(data)))
stopifnot("Outcome is non-negative" = all(data$DeadDist >= 0, na.rm = TRUE))

source_text <- paste(readLines("dashboard.Rmd", warn = FALSE), collapse = "\n")
stopifnot("Dashboard uses a relative data path" = grepl("data/pine_beetle_1993.xlsx", source_text, fixed = TRUE))
stopifnot("Dashboard has no absolute home path" = !grepl("/Users/", source_text, fixed = TRUE))
stopifnot("Square-root outcome is not transformed twice" = !grepl("step_sqrt(all_outcomes())", source_text, fixed = TRUE))
stopifnot("Log transform keeps zero-valued observations" = grepl("log(BA_Inf_20th + 0.001)", source_text, fixed = TRUE))
stopifnot("Train/test split is reproducible" = grepl("set.seed(612)", source_text, fixed = TRUE))

message("Pine beetle dashboard smoke test passed.")
