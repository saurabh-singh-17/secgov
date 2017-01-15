if(exists("byGroupUpdate")){flagbygrpupdate<-byGroupUpdate}
if(exists("inputPath")){inputpath<-inputPath}
if(flagbygrpupdate == "true"){
  load(paste(groupPath,"bygroupdata.RData",sep="/"))
  load(paste(inputpath,"dataworking.RData",sep="/"))
  bygroupdata<-merge(bygroupdata,dataworking,all.x=TRUE,by="primary_key_1644")
  col<-colnames(bygroupdata)
  newcol<-col[-c(which(grepl("\\.y",col)))]
  bygroupdata<-bygroupdata[newcol]
  newcol<-gsub("\\.x","",newcol)
  colnames(bygroupdata)<-newcol
  uniquecol<-unique(colnames(bygroupdata))
  bygroupdata<-bygroupdata[uniquecol]
  save(bygroupdata, file = paste(groupPath,"bygroupdata.RData", sep="/"))
}else{
  if(modeliteration == 1){
    load(paste(inputpath,"/dataworking.RData",sep=""))
    bygroupdata<-dataworking
    rm("dataworking")
  }else{
    load(paste(groupPath,"/bygroupdata.RData",sep=""))
  }
}