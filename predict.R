# predict.R
# -------------------------------
# Safe package loading
# -------------------------------
if (!require("tidyverse", quietly = TRUE)) {
  install.packages("tidyverse", repos = "https://cloud.r-project.org")
  library(tidyverse)
}

# 1️⃣ Load trained model
model <- readRDS("model/linear_model.rds")

# 2️⃣ List all CSV files in new_data folder
all_files <- list.files("new_data", pattern = "*.csv", full.names = TRUE)

# 3️⃣ Create predictions folder if it doesn't exist
dir.create("predictions", showWarnings = FALSE)

# 4️⃣ Track already processed files
processed_log <- "predictions/processed_files.txt"
if(file.exists(processed_log)) {
  processed_files <- readLines(processed_log)
} else {
  processed_files <- character(0)
}

# 5️⃣ Find only new datasets
new_files <- setdiff(all_files, processed_files)

if(length(new_files) == 0){
  cat("No new datasets to process.\n")
} else {
  for(file in new_files){
    # Load dataset
    ds <- read.csv(file)
    
    # Make predictions
    ds$predicted_height <- predict(model, ds)
    
    # Evaluate if 'height' exists
    if("height" %in% colnames(ds)){
      rmse <- sqrt(mean((ds$height - ds$predicted_height)^2))
      mae <- mean(abs(ds$height - ds$predicted_height))
      cat("Dataset:", basename(file), "→ RMSE:", round(rmse,2), "MAE:", round(mae,2), "\n")
    } else {
      cat("Dataset:", basename(file), "→ No true labels found, skipping evaluation.\n")
    }
    
    # Save predictions
    out_file <- paste0("predictions/pred_", basename(file))
    write.csv(ds, out_file, row.names = FALSE)
    
    cat("Processed:", basename(file), "\n\n")
    
    # Update processed files log
    processed_files <- c(processed_files, file)
  }
  
  # Save updated processed log
  writeLines(processed_files, processed_log)
}



