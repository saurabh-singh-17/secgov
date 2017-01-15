# Written by: Tushar Gupta
# Time : Sep 2014 

#================================================================================= 
# inputPath<-
# outputPath<-
# customkEY<- 
# var_list <-c("Store_Format")
# scenarioName <- 'abcd'
# keepOption <-

#===============================for verify and save button======================== 
options(digits=10)
load(paste(inputPath,"/dataworking.RData",sep=""))
var_name<- paste("murx_",scenarioName,sep="")
if (length(var_list) != 1){
dataworking[,"var"] <-apply(dataworking[,var_list],1,function(x){paste(x,collapse="_")})
}else{
  dataworking[,"var"] <- dataworking[,var_list]
}
number_records <- nrow(dataworking)
duplicates<- duplicated(dataworking[,"var"])
duplicates_detected <- length(which(duplicates=="TRUE"))
Statistics <- c("Number of Observations", 
                "Number of Duplicates detected","Number of Duplicates Removed","Keep Option")

#================================================================================= 
#for keeping first occurence (both as option and for auto ticking in view of first 
if (keepOption == "FIRST"){

logical_vector_F <- duplicated(dataworking[,"var"])



dataworking[!logical_vector_F,var_name]  <- 1
# data_final_first <- data[!logical_vector_F,]
number_deleted <- duplicates_detected

}

#================================================================================= 

#================================================================================= 
#                             Keep the last occurence
#=================================================================================
if (keepOption == "LAST"){
  logical_vector_L <- duplicated(dataworking[,"var"],fromLast=T)
  dataworking[!logical_vector_L,var_name]  <- 1
  
#   data_final_last  <-data[!logical_vector_L,]
  number_deleted <-duplicates_detected
}
#Customized selection 
if (keepOption =="CUSTOM"){
  allDups <- !duplicated(dataworking[,"var"],fromLast=TRUE) & !duplicated(dataworking[,"var"])
  uniquekey<-which(allDups=="TRUE")
  if (length(uniquekey) != 0){
  customKey<- c(customKey,uniquekey)
  }
  
  dataworking[customKey,var_name] <-1
  number_deleted<-nrow(dataworking)-length(customKey)
}

#=============================================================================== 
#                         Number of Duplicate   
#===============================================================================
# number of duplicates detected
dataworking$var <- NULL
duplicates_deleted  <- number_deleted
records             <- cbind(duplicates_detected,duplicates_deleted)  
Value <- c(number_records,duplicates_detected,number_deleted,keepOption)
Observations <- cbind(Statistics,Value)
write.csv(Observations,paste(outputPath,"/","OBSERVATIONS.csv",sep=""),row.names=F,quote=F)
save(dataworking,file=paste(paste(inputPath, "/", "dataworking.RData", sep="")))
write("COMPLETED",file=paste(outputPath,"/","SCENARIO_COMPLETED.TXT",sep=""))  




