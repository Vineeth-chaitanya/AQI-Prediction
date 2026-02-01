library(keras)
library(tensorflow)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tibble)
library(readr)
library(scales)
library(tidyr)

df <- Air_data %>%
  select(Date.Local, Latitude, Longitude, temperature, O3, PM2.5, AQI)%>%
  rename(Date = Date.Local)

# taking the average of pollutant readings onthe same day and same location
df <- df %>%
  group_by(Date, Latitude, Longitude) %>%
  summarize(
    temperature = mean(temperature, na.rm = TRUE),
    O3 = mean(O3, na.rm = TRUE),
    PM2.5 = mean(PM2.5, na.rm = TRUE),
    AQI = mean(AQI, na.rm = TRUE)
  ) %>%
  ungroup()
str(df)
# Ensure Date is in Date format
df$Date <- as.Date(df$Date, format= "%d-%m-%Y")
# sorting the date column
df <- df %>% arrange(Date, Latitude, Longitude)

# checking for the last dates for each loc
last_dates <- df %>%
  group_by(Latitude, Longitude) %>%
  summarize(Last_date = as.Date(max(Date, na.rm = TRUE)), .groups = 'drop') %>%
  ungroup()

last_dates <- last_dates %>%
  mutate(Last_date = as.Date(Last_date, format= "%Y-%m-%d"))

# Noramlizing the data
normalize <- function(x) {
  return ((x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE)- min(x, na.rm = TRUE)))
}

df <- df %>% mutate(
  temperature = normalize(temperature),
  O3 = normalize(O3),
  PM2.5 = normalize(PM2.5)
)

# creating Lag features (past 5 days)
create_lags <- function(df1,column, lags) {
  for (i in 1:lags) {
    df1 <- df1 %>% mutate(!!paste0(column, "_lag", i) := dplyr::lag(.data[[column]], i))
  }
  return(df1)
}

lags <- 5
df <- create_lags(df, "temperature", lags)
df <- create_lags(df, "O3", lags)
df <- create_lags(df, "PM2.5", lags)

#drop NA rows created by lags
df <- df %>% drop_na()

# Generate training sequences
create_sequences <- function(df2, target_column, timesteps){
  X <- list()
  Y <- list()
  
  target_index <- which(colnames(df2) == target_column)
  
  for (i in 1:(nrow(df2)-timesteps)){
    X[[i]] <- as.matrix(df2[i:(i+timesteps -1), -c(1,2,3, target_index)])
    Y[[i]] <- df2[i + timesteps, target_index]
  }
  
  return (list(X = array(unlist(X), dim = c(length(X), timesteps, ncol(df2) - 4)),
               Y = unlist(Y)))
}

# LSTM model
lstm <- function(input_shape){
  model <- keras_model_sequential() %>%
    layer_lstm(units = 50, return_sequences = TRUE, input_shape = input_shape) %>%
    layer_lstm(units = 50) %>%
    layer_dense(units = 1)
  
  model %>% compile(
    loss = "mean_squared_error",
    optimizer = optimizer_adam(learning_rate = 0.001)
  )
  
  return(model)
}

# Train model
train_lstm <- function(model, X_train, Y_train) {
  early_stop <- callback_early_stopping(monitor = "val_loss", patience =5)
  
  model %>% fit(
    X_train, Y_train,
    epochs = 50, batch_size =32, validation_split = 0.2,
    callbacks = list(early_stop), verbose = 1
  )
  return(model)
}

predict_future <- function(model, last_seq, forecast_days, feature_name) {
  future_preds <- c()
  
  # Get the index of the feature to update
  feature_index <- which(colnames(last_seq) == feature_name)
  if (length(feature_index) == 0) {
    stop(paste("Feature", feature_name, "not found in last_seq"))
  }
  
  for (i in 1:forecast_days) {
    # Reshape last_seq into a 3D array with shape (1, timesteps, features)
    input_seq <- array(as.numeric(last_seq), dim = c(1, nrow(last_seq), ncol(last_seq)))
    
    # Predict the next value and extract the numeric result
    next_value <- as.numeric(model %>% predict(input_seq))
    
    # Store the predicted value
    future_preds <- c(future_preds, next_value)
    
    # Create a new row where only the predicted feature is updated
    next_row <- as.numeric(last_seq[nrow(last_seq), ])  # Ensure it's numeric
    next_row[feature_index] <- next_value   # Replace predicted feature
    
    # Update last_seq by removing the oldest row and adding the new row
    last_seq <- rbind(last_seq[-1, , drop = FALSE], next_row)
  }
  
  return(future_preds)
}


# Define AQI calculation function
calculate_aqi <- function(C_p, breakpoints, aqi_values) {
  if (C_p < min(breakpoints) || C_p > max(breakpoints)) {
    return(NA)
  }
  index <- which(C_p >= breakpoints)
  index <- tail(index, 1)
  if (index >= length(breakpoints)) {
    return(NA)
  }
  BP_Lo <- breakpoints[index]
  BP_Hi <- breakpoints[index + 1]
  I_Lo <- aqi_values[index]
  I_Hi <- aqi_values[index + 1]
  AQI_calculated <- ((I_Hi - I_Lo) / (BP_Hi - BP_Lo)) * (C_p - BP_Lo) + I_Lo
  return(AQI_calculated)
}

# Define AQI breakpoints
o3_breakpoints <- c(0.000, 0.054, 0.070, 0.085, 0.105, 0.200)
o3_aqi_values <- c(0, 50, 100, 150, 200, 300)

pm25_breakpoints <- c(0.0, 9.0, 35.4, 55.4, 125.4, 225.4)
pm25_aqi_values <- c(0, 50, 100, 150, 200, 300)

# Create training sequences
seq_temp <- create_sequences(df, "temperature", 10)
seq_O3 <- create_sequences(df, "O3", 10)
seq_PM2.5 <- create_sequences(df, "PM2.5", 10)

# Train models
model_temp <- train_lstm(lstm(dim(seq_temp$X)[2:3]), seq_temp$X, seq_temp$Y)
model_O3 <- train_lstm(lstm(dim(seq_O3$X)[2:3]), seq_O3$X, seq_O3$Y)
model_PM2.5 <- train_lstm(lstm(dim(seq_PM2.5$X)[2:3]), seq_PM2.5$X, seq_PM2.5$Y)

#Denormalize the values
denormalize <- function(x, min_val, max_val) {
  return (x * (max_val - min_val) + min_val)
}

# Get original min and max values from df
min_temp <- min(Air_data$temperature, na.rm = TRUE)
max_temp <- max(Air_data$temperature, na.rm = TRUE)

min_O3 <- min(Air_data$O3, na.rm = TRUE)
max_O3 <- max(Air_data$O3, na.rm = TRUE)

min_PM2.5 <- min(Air_data$`PM2.5`, na.rm = TRUE)
max_PM2.5 <- max(Air_data$`PM2.5`, na.rm = TRUE)

# Get all feature names used during training
feature_cols <- setdiff(colnames(df), c("Date", "Latitude", "Longitude", "AQI"))

forecast_results <- tibble()

for (i in 1:nrow(last_dates)) {
  location_data <- df %>% filter(Latitude == last_dates$Latitude[i], Longitude == last_dates$Longitude[i])
  
  # Ensure last_seq has at least 10 rows (repeat last row if needed)
  if (nrow(location_data) < 10) {
    last_seq <- location_data[, feature_cols]
    last_seq <- rbind(matrix(rep(last_seq[nrow(last_seq), ], 10 - nrow(last_seq)), ncol = ncol(last_seq), byrow = TRUE), last_seq)
  } else {
    last_seq <- tail(location_data[, feature_cols], 10)
  }
  
  # convert last_seq to numeric matrix
  last_seq <- as.matrix(sapply(last_seq, as.numeric))
  # Predict future values
  future_temp <- predict_future(model_temp, last_seq, 10, "temperature")
  future_O3 <- predict_future(model_O3, last_seq, 10, "O3")
  future_PM2.5 <- predict_future(model_PM2.5, last_seq, 10, "PM2.5")
  
  
  
  #Denormalize predictions
  future_temp <- denormalize(future_temp, min_temp, max_temp)
  future_O3 <- denormalize(future_O3, min_O3, max_O3)
  future_PM2.5 <- denormalize(future_PM2.5, min_PM2.5, max_PM2.5)
  
  # Calculate AQI
  aqi_O3 <- sapply(future_O3, calculate_aqi, o3_breakpoints, o3_aqi_values)
  aqi_PM2.5 <- sapply(future_PM2.5, calculate_aqi, pm25_breakpoints, pm25_aqi_values)
  final_aqi <- pmax(aqi_O3, aqi_PM2.5, na.rm = TRUE)
  
  # store results in a tibble
  location_forecast <- tibble(
    Last_Date = last_dates$Last_date[i],
    Latitude = last_dates$Latitude[i],
    Longitude = last_dates$Longitude[i],
    Date = seq.Date(from = last_dates$Last_date[i] +1, by = "day", length.out = length(future_temp)),
    Predicted_Temperature = future_temp,
    Predicted_O3 = future_O3,
    Predicted_PM2.5 = future_PM2.5,
    AQI_O3 = aqi_O3,
    AQI_PM2.5 = aqi_PM2.5,
    Final_AQI = final_aqi
  )
  
  # Append results
  forecast_results <- bind_rows(forecast_results, location_forecast)
}

