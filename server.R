library(shiny)
library(data.table)
library(Hmisc)
library(ggplot2)
library(scales)
library(wordcloud)
library(choroplethr)
library(choroplethrMaps)

#reading the data
data<-fread("C:/Users/saurabh/Desktop/shiny/Consumer_Complaints.csv",sep=",",stringsAsFactors = FALSE)
state_codes<-fread("C:/Users/saurabh/Desktop/shiny/state_codes.csv",sep=",",stringsAsFactors = FALSE)
data(continental_us_states)

#changing the column names to remove special characters
setnames(data,colnames(data),gsub("[^[:alnum:]]","_",colnames(data)))
setnames(state_codes,"State","region")

data[,Date_received := as.Date(Date_received,format="%m/%d/%Y")]
# Define server logic for slider
shinyServer(function(input, output) {
  
  
  output$productReport<-renderPlot({
    subset<-data[Company == input$company]
    subset<-subset[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    prod<-subset[,.(Counts=.N),by=Product]
    wordcloud(prod$Product,prod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })
  
  output$subproductReport<-renderPlot({
    subset<-data[Company == input$company & Product == input$product]
    subset<-subset[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    subprod<-subset[,.(Counts=.N),by=Sub_product]
    wordcloud(subprod$Sub_product,subprod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })
  
  output$issuesubproductReport<-renderPlot({
    subset<-data[Company == input$company & Product == input$product & Sub_product == input$subproduct]
    subset<-subset[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    subprod<-subset[,.(Counts=.N),by=Issue]
    wordcloud(subprod$Issue,subprod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })
  
  
  output$region<-renderPlot({
    subset<-data[Company == input$company]
    subset<-subset[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    prod<-subset[,.(value=.N),by=State]
    prod<-prod[State != ""]
    map_data<-merge(prod,state_codes,by.x="State",by.y="Abbreviation",all.x=T)
    map_data[,State := NULL]
    continental_us<-data.table(continental_us_states)
    map_data_f<-merge(map_data,continental_us,by.x="region",by.y="continental_us_states",all.y=T)
    
    state_choropleth(map_data_f,
                     title  = "State Complaints Estimates",
                     legend = "Complaints",
                     zoom   = map_data_f$region)
    
  })
  
  output$overallproductReport<-renderPlot({
    subset<-data[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    prod<-subset[,.(Counts=.N),by=Product]
    wordcloud(prod$Product,prod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })

  output$overallregion<-renderPlot({
    subset<-data[Date_received >= as.Date(input$daterange[1]) & Date_received <= as.Date(input$daterange[2])]
    prod<-subset[,.(value=.N),by=State]
    prod<-prod[State != ""]
    map_data<-merge(prod,state_codes,by.x="State",by.y="Abbreviation",all.x=T)
    map_data[,State := NULL]
    continental_us<-data.table(continental_us_states)
    map_data_f<-merge(map_data,continental_us,by.x="region",by.y="continental_us_states",all.y=T)
    
    state_choropleth(map_data_f,
                     title  = "State Complaints Estimates",
                     legend = "Complaints",
                     zoom   = map_data_f$region)
    
  })
  
  
  
  
})


