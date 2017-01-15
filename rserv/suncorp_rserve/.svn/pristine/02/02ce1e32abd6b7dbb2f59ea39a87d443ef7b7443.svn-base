#reading the dataset----------------------------------------------------------------
if(exists("inputpath")){
  inputPath<-inputpath
}
if(exists("inputPath")){
  inputpath<-inputPath
}
if(file.exists(paste(groupPath,"bygroupdata.RData",sep="/")) == "TRUE"){
  load(paste(groupPath,"/bygroupdata.RData",sep=""))
  # bygroupdata<-read.csv(paste(groupPath,"bygroupdata.csv",sep="/"))
}else{
  load(paste(inputPath,"/dataworking.RData",sep=""))
  # dataworking<-read.csv(paste(inputPath,"dataworking.csv",sep="/"))
}