# 🌍 Air Quality Prediction

## 📌 Project Overview
Air pollution is a major global concern that affects public health and environmental sustainability. This project aims to predict **Air Quality Index (AQI)** for different locations in the USA by forecasting **Temperature, Ozone (O₃) concentration, and PM2.5 concentration**. The forecasted values are then used to compute AQI using EPA’s AQI formula.

## 🚀 Key Features
- Forecasts **Temperature, O₃ concentration, and PM2.5 concentration** for the next **10 days**.
- Computes **AQI** using the maximum value method.
- Supports forecasting **AQI for locations not present in the dataset**.
- Uses **Machine Learning models** optimized with evaluation metrics like **RMSE, MAE, and MAPE**.
- Includes a **dynamic dashboard** displaying AQI predictions on an interactive USA map.

## 📂 Dataset
The dataset consists of air quality data across multiple locations with the following columns:
- `DATE` → Date of observation
- `LATITUDE` & `LONGITUDE` → Geolocation of the measurement station
- `TEMPERATURE` → Recorded temperature in °C
- `O3_CONCENTRATION` → Ozone concentration in µg/m³
- `PM2.5_CONCENTRATION` → PM2.5 concentration in µg/m³
- `AQI_TEMPERATURE`, `AQI_O3`, `AQI_PM2.5` → AQI values calculated for each pollutant
- `FINAL_AQI` → The highest AQI value among the pollutants, representing overall air quality

## 🔍 Methodology
1. **Data Preprocessing:**
   - Checked for missing values (Dataset contains no NA values).
   - Aggregated pollutant values per date & location (averaged pollutant levels, kept last recorded temperature value).
   - Normalized/Standardized data where necessary.

2. **Feature Engineering:**
   - Included past **5-day lag values** to improve forecasting accuracy.
   - Ensured **denormalization** before computing AQI.

3. **Model Training:**
   - Trained **three separate models** for forecasting **Temperature, O₃ concentration, and PM2.5 concentration**.
   - Used **Early Stopping** (Batch Size: 32, Epochs: 50).
   - Compared different forecasting models to achieve the best accuracy.

4. **AQI Calculation:**
   - Applied **EPA's AQI formula** to compute AQI values based on the predicted pollutant levels.
   - Used the **maximum AQI value** across pollutants to determine the final AQI for each location.

5. **Visualization & Dashboard:**
   - Created a **dynamic dashboard** where users can hover over a USA map to view predicted AQI values at different locations.
   - Implemented AQI **trend analysis** for different locations over time.

## 📊 Model Performance Metrics
To evaluate the model's effectiveness, the following metrics are used:
- **Root Mean Square Error (RMSE)**
- **Mean Absolute Error (MAE)**
- **Mean Absolute Percentage Error (MAPE)**

## 🎯 Future Improvements
- Incorporate **more environmental factors** such as wind speed, humidity, and NO₂ concentration.
- Implement **deep learning models** like LSTMs for better time series forecasting.
- Expand predictions to **global air quality forecasting**.
- Optimize dashboard performance for real-time AQI updates.

## 🛠 Tech Stack
- **R Programming** (Forecasting & Statistical Analysis)
- **Python** (NumPy, TensorFlow)
- **Machine Learning Models** (Time Series Forecasting(LSTM))
- **ggplot2, Shiny** (Data Visualization & Interactive Dashboard)
- **Leaflet & OpenStreetMap API** (Location-based mapping)

## 📢 Contributing
Contributions are welcome! If you’d like to improve the project, feel free to:
- Open an **issue** for feature requests or bug reports.
- Fork the repo, make changes, and submit a **pull request**.

## 📜 License
This project is licensed under the **MIT License**.

---
📩 **For inquiries or collaborations, reach out via [LinkedIn](https://www.linkedin.com/in/vineeth-chaitanya-1914101b5/)**

