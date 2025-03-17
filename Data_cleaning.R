wind <- read.csv('WindU.csv')
temp <- read.csv('TemperatureU.csv')
so2 <- read.csv('SO2_U.csv')
RH <- read.csv('Relative_humidity_U.csv')
pressure <- read.csv('Pressure_U.csv')
no2 <- read.csv('NO2_U.csv')
co <- read.csv('CO_U.csv')
O3 <- read.csv('O3_U.csv')
PM2.5 <- read.csv('PM2.5_U.csv')


library(dplyr)
library(purrr)

# creating a list
data_list <- list(wind, temp, so2, RH, pressure, no2, co, O3, PM2.5)

#using reduce to combine data sets
merged_data <- reduce(data_list, inner_join, by = c("Latitude","Longitude", "Date.Local"))

#making a copy of merged_data
write.csv(merged_data, "Airdata.csv", row.names = FALSE)

#calculating the Final AQI (maximum of all AQI values in each row)
Air_data <- read.csv('Airdata.csv')

Air_data <- Air_data %>%
  rowwise() %>%
  mutate(AQI = max(c(AQI_SO2,AQI_NO2,AQI_CO,AQI_O3,AQI_PM2.5), na.rm = TRUE)) %>%
  ungroup()

Air_data <- Air_data %>%
  rename(wind = Arithmetic.Mean_wind, temperature = Arithmetic.Mean_Temp, humidity = Arithmetic.Mean_RH, pressure = Arithmetic.Mean_pressure, SO2 = Arithmetic.Mean_SO2, NO2 = Arithmetic.Mean_NO2, CO = Arithmetic.Mean_CO, O3 = Arithmetic.Mean_O3, PM2.5 = Arithmetic.Mean_PM2.5)

# print the dataset
print(Air_data)

write.csv(Air_data, "Airdata.csv", row.names = FALSE)