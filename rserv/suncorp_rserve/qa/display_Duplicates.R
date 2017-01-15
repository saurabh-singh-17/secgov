#Written by: Tushar Gupta
#Time:       Sep 2014 

#==================================================================================== 
# inputPath<-
# outputPath <-
# startIndex <-100
# rows <-60
#==================================================================================== 

#Reading the csv 
#==================================================================================== 
data<-read.csv(file=paste(inputPath,"/duplicates.csv",sep=""))
#==================================================================================== 
obs_dup<- nrow(data)
startIndex<-as.numeric(startIndex)
rows<-as.numeric(rows)

stopindex <- (startIndex+rows)-1
if (obs_dup < stopindex){
  stopindex <- obs_dup
}
index <- startIndex:stopindex
data<- data[index,]

#======================================================================================= 
write.csv(data,paste(outputPath,"/display_Duplicates.csv", sep=""),row.names=F,quote=F)
write("COMPLETED",paste(outputPath,"/DISPLAY_COMPLETED.TXT",sep=""))
#======================================================================================= 

