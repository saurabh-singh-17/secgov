
if(exists("inputPath")){inputpath<-inputPath}
if(file.exists(paste(groupPath,"bygroupdata.RData",sep="/")) == "FALSE"){
  load(paste(inputpath,"/dataworking.RData",sep=""))
  if(exists("grpno")){grpNo<-grpno}
  if(exists("grpflag")){grpFlag<-grpflag}
  if (as.integer(grpNo)!= 0)
  {
    temp_var=paste("grp",grpNo,"_flag",sep="")
    index<-which(names(dataworking)==temp_var)
    bygroupdata<-subset(dataworking,dataworking[index]==grpFlag)
    
  }else{bygroupdata<-dataworking}
  save(bygroupdata, file = paste(groupPath,"bygroupdata.RData", sep="/"))
  rm("dataworking")
}