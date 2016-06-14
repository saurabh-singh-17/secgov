library(shiny)
library(data.table)
library(Hmisc)
library(ggplot2)
library(scales)
library(wordcloud)
#reading the data
data<-fread("C:/Users/u472290/workfolder/shiny_capability2/Consumer_Complaints.csv",sep=",",stringsAsFactors = FALSE)
state_codes<-fread("C:/Users/u472290/workfolder/shiny_capability2/state_codes.csv",sep=",",stringsAsFactors = FALSE)

#changing the column names to remove special characters
setnames(data,colnames(data),gsub("[^[:alnum:]]","_",colnames(data)))

# Define server logic for slider
shinyServer(function(input, output) {
  
  
  output$productReport<-renderPlot({
    subset<-data[Company == input$company]
    prod<-subset[,.(Counts=.N),by=Product]
    wordcloud(prod$Product,prod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })
  
  output$subproductReport<-renderPlot({
    subset<-data[Company == input$company & Product == input$product]
    subprod<-subset[,.(Counts=.N),by=Sub_product]
    wordcloud(subprod$Sub_product,subprod$Counts,scale=c(4,1),colors=brewer.pal(8, "Dark2"),random.color = T,fixed.asp = F,rot.per = 0)
  })
  
  
})


library(choroplethr)
data(df_pop_state)
data(continental_us_states)

state_choropleth(df_pop_state,
                 title  = "2012 State Population Estimates",
                 legend = "Population",
                 zoom   = continental_us_states)


prod<-data[,.(value=.N),by=State]
prod<-prod[State != ""]
setnames(prod,"State","region")



state_choropleth(prod,
                 title  = "2012 State Population Estimates",
                 legend = "Population",
                 zoom   = prod$State)
