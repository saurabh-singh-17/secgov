#==================================================================================
# Required Parameters for this code:
#==================================================================================
# inputPath        <- "C:/Users/Anvita.srivastava/MRx/r/CheckGLM-14-Aug-2014-11-15-37/2/0/1_1_1/text mining/data handling/pre processing/1/pre processing.csv"
# outputPath        <- "C:/Users/Anvita.srivastava/MRx/r/CheckGLM-14-Aug-2014-11-15-37/2"
# c_var_in         <- c("Verbatim_removeEmails","Verbatim_removeUrls","Verbatim_replaceCuswords")
# c_var_new        <- c("new1","new2","new3")
#==================================================================================

#==================================================================================
# loading/reading the csv file 
#================================================================================== 
load(file=paste(outputPath, "/", "dataworking.RData", sep=""))
preProcessing <- read.csv(inputPath)

#==================================================================================
# renaming the variable names
#==================================================================================

names(preProcessing)[names(preProcessing) %in% c_var_in] <- c_var_new

#==================================================================================
# merging with dataworking
#==================================================================================
dataworking <- merge(x=dataworking,y=preProcessing[c(c_var_new,"primary_key_1644")],by=c("primary_key_1644"),all.x=T)

#------------------------------------------------------------------------------
# Saving the dataset as dataworking.RData
#------------------------------------------------------------------------------
save(dataworking,file=paste(outputPath,"/dataworking.RData",sep=""))

