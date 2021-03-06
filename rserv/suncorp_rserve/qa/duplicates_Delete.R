

# Written by : Tushar Gupta
# Time:        Sep 2014
#================================================================================ 
# inputPath <-
# outputPath<-
# scenarioName <- 'abcd'
# datasetName  <- 
# datasetOption

#================================================================================= 
load(file=paste(inputPath,"/","dataworking.RData", sep=""))
#================================================================================= 
#for keeping first occurence (both as option and for auto ticking in view of first )

if (datasetOption =="CREATE"){
  index <-which(dataworking[,paste("murx_",scenarioName,sep="")]==1)
  new_data<- dataworking[index,]
  new_data<- new_data[,datasetVar]
  new_data <- useDateFormat(c_path_in = inputPath,
                            x = new_data)
  write.csv(new_data,paste(outputPath,"/",datasetName,".csv",sep=""),row.names=F,quote=F)
  write("Completed",paste(outputPath,"/DUPLICATE_CREATED_COMPLETED.TXT",sep=""))
}
#===================================================================================== 
# if (datasetOption =="EXISTING"){
#   index <-which(dataworking[,paste("murx_",scenarioName,sep="")]==1)
#   dataworking<- dataworking[index,] 
#   dataworking$primary_key_1644<- NULL
#   dataworking[,"primary_key_1644"]<-rep(1:nrow(dataworking)) 
  #   text<- paste("c(",paste(datasetVar,collapse=","),")")
  #   expr<- parse(text=text)
  #   data <- subset(x=data,subset=T,select=eval(expr))
#===================================================================================== 
#updating the dataset properties and dataworking  
#===================================================================================== 
#   dataset_properties <-read.csv(paste(inputPath,"/dataset_Properties.csv",sep=""))
#   dataset_properties$no_of_obs<-nrow(x=dataworking)
# #   fil<-round(file.info(paste(inputPath,"/dataset_properties.csv",sep="")))
# #   dataset_properties$file_size<-round(file.info(paste(inputPath,"/dataset_properties.csv",sep="")))$size/1048576,2))
#   write.csv(dataset_properties,paste(inputPath,"/dataset_properties.csv",sep=""),row.names=F,quote=F)
#   
# write.csv(dataworking,paste(inputPath,"/dataworking.csv",sep=""),row.names=F,quote=F)
#   save(dataworking,file=paste(paste(inputPath, "/", "dataworking.RData", sep="")))
#   write("Completed",paste(inputPath,"/DUPLICATE_EXISTING_COMPLETED.TXT",sep=""))
# }
#==================================================================================== 


