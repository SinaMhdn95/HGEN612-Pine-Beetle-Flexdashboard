required <- c(
  "broom", "broom.mixed", "car", "corrr", "dotwhisker", "dplyr",
  "DT", "flexdashboard", "GGally", "ggfortify", "ggplot2", "glmnet",
  "gt", "knitr", "patchwork", "performance", "plotly", "readxl",
  "rmarkdown", "see", "skimr", "tidymodels", "tidyverse", "vip"
)

missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

message("All dashboard dependencies are installed.")

