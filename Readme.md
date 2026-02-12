# 🌍 Air Quality Forecasting System

![R](https://img.shields.io/badge/Language-R-blue.svg)
![TensorFlow](https://img.shields.io/badge/Backend-TensorFlow_Keras-orange.svg)
![Shiny](https://img.shields.io/badge/Dashboard-Shiny-blueviolet.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📌 Overview
The **Air Quality Forecasting System** is a data-driven project designed to predict the **Air Quality Index (AQI)** for various locations across the United States. By leveraging historical environmental data and Deep Learning (**Long Short-Term Memory (LSTM)** networks), the system forecasts key pollutants—**Ozone ($O_3$)** and **Particulate Matter (PM2.5)**—along with **Temperature** to compute the overall AQI for the next **10 days**.

This project provides actionable insights through an **interactive Shiny dashboard**, allowing users to visualize AQI trends and geographical distributions on a dynamic map.

## 🚀 Key Features
- **Multi-Pollutant Forecasting**: Independently models and predicts Temperature, $O_3$, and PM2.5 levels.
- **Deep Learning Model**: Utilizes **LSTM** (RNN) architecture to capture temporal dependencies in time-series data.
- **Dynamic AQI Calculation**: Computes AQI based on predicted pollutant concentrations using standard **EPA breakpoints**.
- **Interactive Dashboard**:
    - 🗺️ **Geospatial Visualization**: Leaflet map showing predicted AQI for different US locations.
    - 📈 **Trend Analysis**: Line charts and histograms for analyzing temporal patterns.
- **Recursive Forecasting**: Generates multi-step future predictions (up to 10 days) using a sliding window approach.

## 📂 Dataset
The analysis is based on a comprehensive dataset of daily air quality measurements. The raw data is aggregated by **Date** and **Location (Latitude, Longitude)**.

**Key Variables:**
- **Temperature**: Daily average temperature ($^\circ$C).
- **Ozone ($O_3$)**: Daily average concentration (ppm).
- **PM2.5**: Daily average fine particulate matter ($\mu g/m^3$).
- **AQI**: Calculated Air Quality Index.

*Data Source: [EPA Air Quality Data / User Provided Dataset]*

## �️ Methodology

### 1. Data Preprocessing
- **Aggregation**: Daily averages computed for each location.
- **Normalization**: Features scaled to $[0, 1]$ range for optimal model performance.
- **Feature Engineering**: Generated **5-day lag features** to incorporate past trends into the model input.
- **Sequence Creation**: Constructed time-series sequences of **10 days** for LSTM training.

### 2. LSTM Modeling
Three separate LSTM models were trained for **Temperature**, **$O_3$**, and **PM2.5**:
- **Architecture**:
    - `LSTM Layer 1`: 50 units, `return_sequences=TRUE`
    - `LSTM Layer 2`: 50 units
    - `Dense Layer`: 1 unit (Output)
- **Training**:
    - **Optimizer**: Adam ($lr=0.001$)
    - **Loss Function**: Mean Squared Error (MSE)
    - **Callbacks**: Early Stopping (monitor: `val_loss`, patience: 5)
    - **Epochs**: 50 (Batch size: 32)

### 3. Forecasting & Evaluation
- **Recursive Prediction**: Predicted values are fed back as input for subsequent time steps to forecast up to 10 days ahead.
- **Denormalization**: Predictions are transformed back to original scales.
- **AQI Computation**: Determine individual AQI for $O_3$ and PM2.5 using piecewise linear interpolation (EPA standard) and take the maximum as the **Final AQI**.

## 📊 Visualizations

### Forecasting Dashboard
The project includes a **Shiny App** (`visualizations.R`) that provides:
1.  **AQI Map**: Color-coded markers (Green/Orange/Red) indicating air quality levels.
2.  **Time Series Plots**: Visualizing the predicted AQI trajectory.
3.  **Histograms**: Distribution of AQI values.

## � Installation & Usage

### Prerequisites
Ensure you have **R** installed along with the following libraries:

```r
install.packages(c("keras", "tensorflow", "dplyr", "ggplot2", "lubridate", 
                   "tibble", "readr", "scales", "tidyr", "tidygeocoder", 
                   "leaflet", "shiny", "pheatmap"))
```

### Running the Project

1.  **Data Preparation & Analysis**:
    ```r
    source("notebooks/Data_analysis.R")
    ```
2.  **Model Training & Forecasting**:
    Run the LSTM model script. *Note: Ensure `Air_data` is loaded in your environment.*
    ```r
    source("notebooks/LSTM_model.R")
    ```
3.  **Launch Dashboard**:
    After generating forecasts, run the visualization script to start the Shiny app.
    ```r
    source("notebooks/visualizations.R")
    ```

## � Future Improvements
- [ ] Integrate real-time weather API for live data fetching.
- [ ] Add more environmental features like **Humidity**, **Wind Speed**, and **$NO_2$**.
- [ ] Deploy the Shiny app to **shinyapps.io** for public access.
- [ ] Implement **Transformer-based models** for potentially better long-term forecasting.

## 🤝 Contributing
Contributions are welcome! Please fork the repository and submit a Pull Request.

## 📜 License
This project is licensed under the **MIT License**.

---
**Author**: Vineeth
**Contact**: [Link to Profile/Email]
