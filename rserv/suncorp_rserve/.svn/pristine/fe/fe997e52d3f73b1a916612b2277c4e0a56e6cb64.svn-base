#----------------------------------------------------------------------------------------------------
# Code for DQA > Unique Values for Variables
#----------------------------------------------------------------------------------------------------
load(paste(input_data,"/dataworking.RData",sep=""))
# dataworking <- subset(x=read.csv(input_data),select=var_list)
output      <- lapply(dataworking,unique)
maxLen      <- max(sapply(output,length))
for(i in seq_along(output)){
  output[[i]] <- as.character(output[[i]])[order(x=as.numeric(as.character(output[[i]])),na.last=T)]
  output[[i]][which(as.character(output[[i]])=='')] <- 'MISSING'
  output[[i]] <- c(output[[i]],rep("", maxLen - length(output[[i]])))
}
output <- as.data.frame(output)
write.csv(output, paste(output_path,file = "uniqueValues.csv",sep="/"), quote=FALSE, row.names=FALSE)
write("UNIQUE_VALUES_COMPLETED", file = paste(output_path, "UNIQUE_VALUES_COMPLETED.txt", sep="/"))