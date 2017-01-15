#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  datasetprop_update                                                                     --#
#-- Description  :  used to update the dataset information after a new variable is created                                --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Saurabh Singh                                                                    --#                 
#------------------------------------------------------------------------------------------------------


#------Content in the file-------#
dataset_name<-'dataworking'
if(exists("input_path") == "FALSE"){
input_path<-inputPath  
}
# input_path<-gsub("dataworking.csv","",input_path)  
input_path<-gsub("dataworking.RData","",input_path)  
# dataset_prop=read.csv(paste(input_path,"/",dataset_name,".csv",sep=""))
load(paste(input_path,"/",dataset_name,".RData",sep=""))
dataset_prop = dataworking

Obs=nrow(dataset_prop)
Vars=ncol(dataset_prop)
FileSize <- object.size(dataset_prop)
FileSize <- round(FileSize/1048576,1)


dataset_prop=cbind(dataset_name,Obs,Vars,FileSize)
dataset_prop=as.data.frame(dataset_prop)

colnames(dataset_prop)[1]=as.character("FILE_NAME")
colnames(dataset_prop)[2]=as.character("NO_OF_OBS")
colnames(dataset_prop)[3]=as.character("NO_OF_VARS")
colnames(dataset_prop)[4]=as.character("FILE_SIZE")
write.csv(dataset_prop,file=paste(input_path,"dataset_prop.csv",sep="/"),row.names=F,quote=FALSE)
# save(dataset_prop, file = paste(input_path,"dataset_prop.csv",sep="/"))

#completed.text
write("DATASET_PROPERTIES_COMPLETED", file = paste(input_path, "DATASET_PROPERTIES_COMPLETED.txt", sep="/"))