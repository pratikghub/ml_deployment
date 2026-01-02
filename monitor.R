library(tidyverse)

cat("Starting monitoring pipeline...\n")

# -----------------------------
# 1️⃣ Load baseline statistics
# -----------------------------
baseline <- read.csv("model/baseline_stats.csv")

# -----------------------------
# 2️⃣ Load latest prediction file
# -----------------------------
pred_files <- list.files(
  "predictions",
  pattern = "^pred_.*\\.csv$",
  full.names = TRUE
)

if (length(pred_files) == 0) {
  cat("No prediction files found. Exiting monitoring.\n")
  quit(save = "no")
}

latest_pred <- pred_files[which.max(file.info(pred_files)$mtime)]
data <- read.csv(latest_pred)

dataset_name <- basename(latest_pred)

cat("Monitoring file:", dataset_name, "\n")

# -----------------------------
# 3️⃣ Data Drift Detection
# -----------------------------
drift_results <- data.frame()

features <- baseline$feature

for (f in features) {
  
  if (!f %in% colnames(data)) next
  
  current_mean <- mean(data[[f]], na.rm = TRUE)
  current_sd   <- sd(data[[f]], na.rm = TRUE)
  
  base_mean <- baseline$mean[baseline$feature == f]
  base_sd   <- baseline$sd[baseline$feature == f]
  
  mean_shift <- abs(current_mean - base_mean)
  sd_shift   <- abs(current_sd - base_sd)
  
  ks_pvalue <- tryCatch(
    ks.test(data[[f]], rnorm(1000, base_mean, base_sd))$p.value,
    error = function(e) NA
  )
  
  drift_results <- rbind(
    drift_results,
    data.frame(
      feature = f,
      mean_shift = mean_shift,
      sd_shift = sd_shift,
      ks_pvalue = ks_pvalue
    )
  )
}

data_drift_flag <- any(drift_results$ks_pvalue < 0.05, na.rm = TRUE)

# -----------------------------
# 4️⃣ Concept Drift Detection
# -----------------------------
metric_files <- list.files(
  "predictions",
  pattern = "^metrics_.*\\.csv$",
  full.names = TRUE
)

concept_drift_flag <- FALSE

if (length(metric_files) >= 2) {
  
  metrics <- metric_files %>%
    lapply(read.csv) %>%
    bind_rows() %>%
    arrange(timestamp)
  
  baseline_rmse <- metrics$rmse[1]
  latest_rmse   <- tail(metrics$rmse, 1)
  
  if ((latest_rmse - baseline_rmse) / baseline_rmse > 0.2) {
    concept_drift_flag <- TRUE
  }
}

# -----------------------------
# 5️⃣ Save monitoring report
# -----------------------------

new_report <- data.frame(
  timestamp = as.character(Sys.time()),
  dataset = dataset_name,
  data_drift = data_drift_flag,
  concept_drift = concept_drift_flag,
  stringsAsFactors = FALSE
)

report_path <- "predictions/monitoring_report.csv"

if (file.exists(report_path)) {
  old_report <- read.csv(report_path, stringsAsFactors = FALSE)
  final_report <- bind_rows(old_report, new_report)
} else {
  final_report <- new_report
}

write.csv(
  final_report,
  report_path,
  row.names = FALSE
)


# -----------------------------
# 6️⃣ Alerting
# -----------------------------
if (data_drift_flag || concept_drift_flag) {
  
  alert <- paste(
    Sys.time(),
    "ALERT:",
    ifelse(data_drift_flag, "Data drift detected.", ""),
    ifelse(concept_drift_flag, "Concept drift detected.", "")
  )
  
  cat(alert, "\n")
  
  write(
    alert,
    file = "predictions/drift_alerts.log",
    append = TRUE
  )
} else {
  cat("No drift detected.\n")
}

cat("Monitoring completed.\n")

