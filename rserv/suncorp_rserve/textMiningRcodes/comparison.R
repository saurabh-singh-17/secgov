#Parameters required
#-----------------------------------------------------------------
# inputPath1 <- 'C:/Users/Anvita.srivastava/MRx/r/frequency-26-Sep-2014-12-22-39/1/0/1_1_1/text mining/frequency analysis/1/Verbatim'
# inputPath2 <- 'C:/Users/Anvita.srivastava/MRx/r/frequency-26-Sep-2014-12-22-39/1/0/1_1_1/text mining/frequency analysis/2/Verbatim'
# outputPath <- 'C:/Users/Anvita.srivastava/MRx/r/frequency-26-Sep-2014-12-22-39'

#---------------------------------------------------------------------------------------
# Loading the libraries
#---------------------------------------------------------------------------------------

library(irr)


#---------------------------------------------------------------------------------------
# Loading the csv's
#---------------------------------------------------------------------------------------

termList1         <- read.csv(paste(inputPath1,"/termsList.csv",sep=""))
termList2         <- read.csv(paste(inputPath2,"/termsList.csv",sep=""))


#---------------------------------------------------------------------------------------
# merge the frequency datasets to calucate the chi square value
#---------------------------------------------------------------------------------------

finalData         <- merge.data.frame(x=termList1[c("word","freq","freqShare")],
                                      y=termList2[c("word","freq","freqShare")],by="word")

chiObj <- as.data.frame(c())
if(!nrow(finalData) <= 2)
{
  chiObj            <- chisq.test(x=finalData[,"freq.x"],y=finalData[,"freq.y"])
  kappaObj          <- kappa2(finalData[c("freq.x","freq.y")])
  kappaVal          <- kappaObj$value
}else{
  chiObj[1,"statistic"] <- 'NA'
  chiObj[1,"p.value"]   <- 'NA'
  kappaVal              <- 'NA'
}

similarWords      <- nrow(finalData)
dissimilarWords   <- nrow(termList1) + nrow(termList2) - (2*nrow(finalData))

Statistics        <- c("ChiSq-Value","P-Value","Kappa-Value","Similar Words","Dissimilar Words")
Values            <- c(chiObj$statistic,chiObj$p.value,kappaVal,
                       similarWords,dissimilarWords)

outputdata        <- cbind(Statistics,Values)


#---------------------------------------------------------------------------------------
# export the required csv's and completed file
#---------------------------------------------------------------------------------------
write.csv(outputdata,file=paste(outputPath, "/comparison.csv", sep=""),
          row.names=FALSE , quote=FALSE)

write("COMPARISON_ANALYSIS", file = paste(outputPath, "COMPARISON_COMPLETED.TXT", sep="/"))
