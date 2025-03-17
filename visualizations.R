library(tidygeocoder)
library(dplyr)
library(leaflet)

forecast_results <- as.data.frame(forecast_results)

# Ensure required columns exist
if (!all(c("Latitude", "Longitude","Date","Final_AQI") %in% colnames(forecast_results))) {
  stop("Error: 'forecast_results' does not contain 'Latitude' and 'Longitude' columns.")
}

# Convert Date column properly
forecast_results$Date <- as.Date(forecast_results$Date)

# performing reverse geocoding 
location_data <- forecast_results %>%
  distinct(Latitude, Longitude) %>%
  reverse_geocode(lat = Latitude, long = Longitude, method = "osm") %>%
  filter(!is.na(address))

# Merging with the forecast_results
forecast_results <- forecast_results %>%
  left_join(location_data %>% select(Latitude, Longitude, address), by = c("Latitude","Longitude")) %>%
  rename(location = address)

library(shiny)
library(ggplot2)
library(dplyr)

# Define UI
ui <- fluidPage(
  titlePanel("AQI Trend Visualization"),
  sidebarLayout(
    sidebarPanel(
      selectInput("selected_location", "Select Location",
                  choices = if(nrow(forecast_results) > 0) unique(forecast_results$location) else character(0),
                  selected = if(nrow(forecast_results) > 0) unique(forecast_results$location)[1] else NULL),
      
      dateInput("selected_date", "Select Date",
                value = max(forecast_results$Date, na.rm = TRUE),
                min = min(forecast_results$Date, na.rm = TRUE),
                max = max(forecast_results$Date, na.rm = TRUE))
    ),
    mainPanel(
      plotOutput("aqi_trend"),
      plotOutput("aqi_histogram"),
      leafletOutput("aqi_map")
    )
  )
)

# Define server
server <- function(input, output){
  
  filtered_data <- reactive({
    req(input$selected_location)
    forecast_results %>%
      filter(location == input$selected_location)%>%
      na.omit()
  })
  
  output$aqi_trend <- renderPlot({
    data <- filtered_data()
    
    if(nrow(data) == 0) return(NULL)
    
    ggplot(data, aes(x = as.Date(Date), y = Final_AQI)) +
      geom_line(color = 'blue', size = 1) +
      geom_point(aes(color = Final_AQI), size = 3)+
      geom_text(aes(label = round(Final_AQI, 1)), vjust = -1, size = 4)+
      geom_smooth(method = "loess", color = "black", linetype = "dashed") +
      scale_color_gradient(low = "green", high = "red") +
      labs(title = paste("AQI Trend for", input$selected_location),
           x = "Date", y = "AQI Value") +
      theme_minimal()
  })
  
  output$aqi_histogram <- renderPlot({
    data <- filtered_data()
    
    if(nrow(data) == 0) return(NULL)
    
    ggplot(data, aes(x = Final_AQI)) +
      geom_histogram(binwidth = 10, fill = "blue", color = "black", alpha = 0.7) +
      geom_vline(aes(xintercept = mean(Final_AQI, na.rm = TRUE)), color = "red", linetype = "dashed", size = 1) +
      labs(title = paste("AQI Distribution for", input$selected_location),
           x = "AQI Value", y = "Frequency") +
      theme_minimal()
  })
  
  output$aqi_map <- renderLeaflet({
    req(forecast_results, input$selected_date)
    
    # Filter data for the selected date
    filtered_map_data <- forecast_results %>%
      filter(Date == as.Date(input$selected_date))
    
    # If no data is available for the selected date, show an alert message
    if(nrow(filtered_map_data) == 0){
      showNotification("Please select a vaild date with available AQI data,", type = "error")
      return(NULL)
    }
    
    leaflet(forecast_results) %>%
      addTiles() %>%
      addCircleMarkers(
        ~Longitude, ~Latitude,
        radius = ~Final_AQI /20,
        color = ~ifelse(Final_AQI > 150, "red", ifelse(Final_AQI >100, "orange","green")),
        popup = ~paste0("<b>Location:</b> ", location, "<br><b>AQI:</b>", Final_AQI)
      )
  })
}

shinyApp(ui = ui, server = server)