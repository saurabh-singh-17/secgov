#--------------------------------------------------------#
# Project:- Verify Merge 
# author :- Rakesh Biradar and saurabh vikash singh
# Date :- 23-09-2012
# version:- v 1.0
#--------------------------------------------------------#

# deleting the output files if they are already present
unlink(x=paste(output_path,"/VERIFY_COMPLETED.txt",sep=""))
unlink(x=paste(output_path,"/verification.csv",sep=""))

split_path=unlist(strsplit(input_path,split="||",fixed=TRUE))
split_dataset_names=unlist(strsplit(dataset_names,split="||",fixed=TRUE))

key_var=unlist(strsplit(key_variables,split=" ",fixed=TRUE))
comm_var=key_variables

dataset=NULL

for(i in 1:length(split_path))
{
  fetch_data_path=paste(split_path[[i]],split_dataset_names[[i]],sep="/")
  fetch_data_path1=paste(fetch_data_path,".RData",sep="")
#  dataset[[i]]=read.csv(fetch_data_path1,sep=",",row.names=NULL)
  load(paste(fetch_data_path,".RData",sep=""))
  dataset[[i]]= dataworking
}


merge_poss=1

for(i in 1:length(split_path))
{
  for(j in 1:length(key_var))
  {
    if((i+1)<=length(split_path))
    {
      x_temp_1 <- class(dataset[[i]][,which(colnames(dataset[[i]])==comm_var[j])])
      x_temp_2 <- class(dataset[[i+1]][,which(colnames(dataset[[i+1]])==comm_var[j])])
      if (x_temp_1 == "integer" | x_temp_1 == "numeric") {
        x_temp_1 <- "numeric"
      }
      if (x_temp_1 == "factor" | x_temp_1 == "character") {
        x_temp_1 <- "character"
      }
      if (x_temp_2 == "integer" | x_temp_2 == "numeric") {
        x_temp_2 <- "numeric"
      }
      if (x_temp_2 == "factor" | x_temp_2 == "character") {
        x_temp_2 <- "character"
      }
      if(x_temp_1 != x_temp_2) {
        merge_poss=0
      }
    }  
  }
}


if(merge_poss == 0)
{ 
  verify=data.frame(cbind("no","NA"),row.names=NULL,stringsAsFactors=FALSE)
  colnames(verify)=c("Merge_possible","type")
  write.csv(verify,paste(output_path,"/verification.csv",sep=""),quote=FALSE,row.names=FALSE) 
}

if(merge_poss==1) 
{ 
  tempmerge<- merge(dataset[[1]],dataset[[2]],by=comm_var,all=FALSE)
  tempmerge<-as.data.frame(tempmerge[,comm_var])
  colnames(tempmerge)<-comm_var
  
  for(i in 1:length(comm_var))
  {
    dataset1<-dataset[[1]][c(which(dataset[[1]][,c(which(colnames(dataset[[1]]) == comm_var[i]))] %in% tempmerge[,i])),]
    dataset2<-dataset[[2]][c(which(dataset[[2]][,c(which(colnames(dataset[[2]]) == comm_var[i]))] %in% tempmerge[,i])),]
  }
  for(i in 1:length(comm_var)){
  dataset[[1]]<- dataset1[c(which(dataset[[1]][,c(which(colnames(dataset[[1]]) == comm_var[i]))] %in% dataset1[,c(which(colnames(dataset[[1]]) == comm_var[i]))])),]
  dataset[[2]]<- dataset2[c(which(dataset[[2]][,c(which(colnames(dataset[[2]]) == comm_var[i]))] %in% dataset2[,c(which(colnames(dataset[[2]]) == comm_var[i]))])),]
  }
  if(length(input_path) == 2){
    if((nrow(unique(dataset1[c(key_variables)])) == nrow(dataset[[1]][c(key_variables)])) && (nrow(unique(dataset2[c(key_variables)])) == nrow(dataset[[2]][c(key_variables)]))){
      verify=data.frame(cbind("yes","one to one"),row.names=NULL,stringsAsFactors=FALSE)
    }
    else if((nrow(unique(dataset1[c(key_variables)])) == nrow(dataset[[1]][c(key_variables)])) && (nrow(unique(dataset2[c(key_variables)])) != nrow(dataset[[2]][c(key_variables)]))){
      verify=data.frame(cbind("yes","many to one"),row.names=NULL,stringsAsFactors=FALSE)
    }
    else if((nrow(unique(dataset1[c(key_variables)])) != nrow(dataset[[1]][c(key_variables)])) && (nrow(unique(dataset2[c(key_variables)])) == nrow(dataset[[2]][c(key_variables)]))){
      verify=data.frame(cbind("yes","one to many"),row.names=NULL,stringsAsFactors=FALSE)
    }
    else if((nrow(unique(dataset1[c(key_variables)])) != nrow(dataset[[1]][c(key_variables)])) && (nrow(unique(dataset2[c(key_variables)])) != nrow(dataset[[2]][c(key_variables)]))){
      verify=data.frame(cbind("yes","many to many"),row.names=NULL,stringsAsFactors=FALSE)
    }
  }else{
    verify=data.frame(cbind("yes","NA"),row.names=NULL,stringsAsFactors=FALSE)
  }
  
  if (type_join == "left_join_only" | type_join == "right_join_only") {
    verify=data.frame(cbind("yes","NA"),row.names=NULL,stringsAsFactors=FALSE)
  }
  
  colnames(verify)=c("Merge_possible","type")
  write.csv(verify,paste(output_path,"/verification.csv",sep=""),quote=FALSE,row.names=FALSE)
}
# verify File
write.csv("VERIFY_COMPLETED",paste(output_path,"/VERIFY_COMPLETED.txt",sep=""))
