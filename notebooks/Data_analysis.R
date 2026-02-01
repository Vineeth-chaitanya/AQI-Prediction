install.packages('ggplot2')
install.packages('pheatmap')

library(ggplot2)
library(pheatmap)

# plotting the AQI over time
ggplot(Air_data, aes(x = Date, y = AQI)) +
  geom_line(color = 'blue', size = 1) +
  labs(title = 'AQI trend over time', x = 'Date', y = 'AQI') +
  theme_minimal()

summary(Air_data)

# correlation analysis
cor_matrix <- cor(Air_data[, c('AQI','wind','temperature','humidity','pressure','SO2','NO2','CO','O3','PM2.5')])

# creating a heatmap using pheatmap
pheatmap(cor_matrix,
         color = colorRampPalette(c("blue","white","red"))(50),
         main = "Correlation Heatmap")