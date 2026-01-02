library(tidyverse)

# 1️⃣ Load trained model
model <- readRDS("model/linear_model.rds")

# 2️⃣ List all CSV files in new_data folder
all_files <- list.files("new_data", pattern = "*.csv", full.names = TRUE)

# 3️⃣ Create predictions folder if it doesn't exist
dir.create("predictions", showWarnings = FALSE)

# 4️⃣ Track already processed files
processed_log <- "predictions/processed_files.txt"
if (file.exists(processed_log)) {
  processed_files <- readLines(processed_log)
} else {
  processed_files <- character(0)
}

# 5️⃣ Find only new datasets
new_files <- setdiff(all_files, processed_files)

if (length(new_files) == 0) {
  cat("No new datasets to process.\n")
} else {
  
  for (file in new_files) {
    
    ds <- read.csv(file)
    
    # 6️⃣ Predictions
    ds$predicted_height <- predict(model, ds)
    
    # 7️⃣ Evaluation (only if ground truth exists)
    if ("height" %in% colnames(ds)) {
      
      rmse <- sqrt(mean((ds$height - ds$predicted_height)^2))
      mae  <- mean(abs(ds$height - ds$predicted_height))
      r2   <- cor(ds$height, ds$predicted_height)^2
      
      cat(
        "Dataset:", basename(file),
        "→ RMSE:", round(rmse, 3),
        "MAE:", round(mae, 3),
        "R2:", round(r2, 3), "\n"
      )
      
      # 🔜 This will later be consumed by monitor.R
      metrics <- data.frame(
        dataset = basename(file),
        rmse = rmse,
        mae = mae,
        r2 = r2,
        timestamp = Sys.time()
      )
      
      write.csv(
        metrics,
        paste0("predictions/metrics_", basename(file)),
        row.names = FALSE
      )
      
    } else {
      cat(
        "Dataset:", basename(file),
        "→ No true labels found, skipping evaluation.\n"
      )
    }
    
    # 8️⃣ Save predictions
    out_file <- paste0("predictions/pred_", basename(file))
    write.csv(ds, out_file, row.names = FALSE)
    
    # 9️⃣ Update processed log
    processed_files <- c(processed_files, file)
    
    cat("Processed:", basename(file), "\n\n")
  }
  
  writeLines(processed_files, processed_log)
}
