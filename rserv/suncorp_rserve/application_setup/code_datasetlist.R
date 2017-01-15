
path<-paste(input_path,"data",sep="/");
fileNames<-as.data.frame(list.files(path,"*.csv"),rownames=F);
names<-as.vector(fileNames[,1])

for ( i in 1 : length(names))
{
  names[i] = substr(names[i],0,nchar(names[i])-4)
}
fileNames<-as.data.frame(names)
names(fileNames)<-"Name";
write.csv(fileNames,file=paste(input_path,"dataset_list.csv",sep="/"),row.names=F,quote=F)


