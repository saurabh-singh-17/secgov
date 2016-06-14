library(shiny)
library(data.table)
library(scales)

#reading the data
data<-fread("C:/Users/saurabh/Desktop/shiny/Consumer_Complaints.csv",sep=",")

#changing the column names to remove special characters
setnames(data,colnames(data),gsub("[^[:alnum:]]","_",colnames(data)))



# Define UI for slider demo application
shinyUI(fluidPage(
  
  #  Application title
  titlePanel("Shiny Capability presentation using Consumer Complaints data"),
  
  # Sidebar with sliders that demonstrate various available
  # options
  sidebarLayout(
    sidebarPanel(
      selectInput("company",label = "Select the Bank", choices = unique(data$Company)),
      selectInput("product",label = "Select the Product", choices = unique(data$Product)),
      selectInput("subproduct",label = "Select the Sub-Product", choices = unique(data$Sub_product)),
      dateRangeInput("daterange",label="Select the Date", start=min(data$Date_received),end=max(data$Date_received))
       ),
    
    # Show a table summarizing the values entered
    mainPanel(
      tabsetPanel(type = "tabs", 
                  tabPanel("Product Complaints", plotOutput("productReport")),
                  tabPanel("Sub-Product Complaints", plotOutput("subproductReport")),
                  tabPanel("Issues with the Sub-Product", plotOutput("issuesubproductReport")),
                  tabPanel("Complaints Region", plotOutput("region")),
                  tabPanel("Overall Product Complaints", plotOutput("overallproductReport")),
                  tabPanel("Overall Complaints Region", plotOutput("overallregion"))
      )
    )
                  
  )
))