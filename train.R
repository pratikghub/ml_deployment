# train.R
library(tidyverse)

# 1️⃣ Load initial dataset
df <- read.csv("data/dataset0.csv")

# 2️⃣ Train linear model
model <- lm(height ~ weight, data = df)

# 3️⃣ Evaluate model on training data
pred <- predict(model, df)
rmse <- sqrt(mean((df$height - pred)^2))
mae <- mean(abs(df$height - pred))

cat("Training RMSE:", rmse, "\n")
cat("Training MAE :", mae, "\n")

# 4️⃣ Save the trained model as .rds
dir.create("model", showWarnings = FALSE)
saveRDS(model, "model/linear_model.rds")

cat("Model training completed and saved in 'model/linear_model.rds'\n")
