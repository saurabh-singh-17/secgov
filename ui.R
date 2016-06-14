library(shiny)
library(data.table)
library(scales)

#reading the data
data<-fread("C:/Users/u472290/workfolder/shiny_capability2/Consumer_Complaints.csv",sep=",")

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
      selectInput("product",label = "Select the Bank", choices = unique(data$Product))
       ),
    
    # Show a table summarizing the values entered
    mainPanel(
      tabsetPanel(type = "tabs", 
                  tabPanel("Product Complaints", plotOutput("productReport")),
                  tabPanel("Sub-Product Complaints", plotOutput("subproductReport"))
      )
    )
                  
  )
))