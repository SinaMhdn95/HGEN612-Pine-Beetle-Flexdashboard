# Download the complete repository before running this file. The dashboard
# depends on the accompanying data directory.

`%||%` <- function(x, y) if (is.null(x)) y else x
script_args <- commandArgs(trailingOnly = FALSE)
script_file_arg <- grep("^--file=", script_args, value = TRUE)
script_path <- if (length(script_file_arg)) {
  sub("^--file=", "", script_file_arg[[1]])
} else {
  tryCatch(sys.frame(1)$ofile, error = function(...) NULL) %||%
    "render_dashboard.R"
}

project_dir <- dirname(normalizePath(script_path, mustWork = TRUE))
original_dir <- setwd(project_dir)
on.exit(setwd(original_dir), add = TRUE)

required_files <- c("dashboard.Rmd", "data/pine_beetle_1993.xlsx")
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop(
    "The complete repository is required. In GitHub, choose Code > Download ZIP, ",
    "extract it, open HGEN612-Pine-Beetle-Flexdashboard.Rproj, and run ",
    "render_dashboard.R. Missing: ", paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

source("scripts/install_packages.R")
rmarkdown::render("dashboard.Rmd")

message("Dashboard created: ", normalizePath("dashboard.html"))
