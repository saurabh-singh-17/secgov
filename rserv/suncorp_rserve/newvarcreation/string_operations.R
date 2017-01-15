#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : string_operations.R                         
#-- Description  : Performs string manipulation    
#-- Return type  : csv              
#-- Author : saurabh singh
#------------------------------------------------------------------------------------------------------#


#----------- parameters------------------------------------------------------

# input_path <- "D:/dataworking.csv"
# output_path="D:/exceloutput/"
# dataset_name <- 'dataworking'
# var_list <- c('geography',"ACV","Store_Format","black_hispanic")
# operations <- c('blanks')
# values <- c('leading')
# prefix <- ''
# postfix <- ''


#-------------------------------code----------------------------------------
#reading the dataset

# dataworking<- read.csv(input_path)
load(paste(input_path,"/dataworking.RData",sep=""))
#library---------------------------------------------------------------
library(stringr)

#------- operations---------------------------------------------------------
temp_var=NULL
temp_var1<-NULL
for(i in 1:length(var_list))
{
 temp_var<-dataworking[var_list[i]]
 temp_var<-as.character(temp_var[,1])
 for(j in 1:length(operations))
   {
   if(operations[j]=="left")
     {
     val<-as.numeric(unlist(strsplit(values[j],",",fixed=TRUE)))
     temp_var<-substr(temp_var,val[1],val[2])
     }
   if(operations[j]=="right")
     {
     val<-as.numeric(unlist(strsplit(values[j],",",fixed=TRUE)))
     for(k in 1:nrow(dataworking)){
     temp_var1[k]<-paste(rev(unlist(strsplit(as.character(temp_var[k]),split="",fixed=TRUE))),collapse="")
     }
     temp_var1<-substr(temp_var1,val[1],val[2])
     for(k in 1:nrow(dataworking)){
       temp_var[k]<-paste(rev(unlist(strsplit(temp_var1[k],split="",fixed=TRUE))),collapse="")
     }
    }
   if(operations[j]=="replace")
   {
     val<-unlist(strsplit(values[j],"!!",fixed=TRUE))
     temp_var<-gsub(val[1],val[2],temp_var,fixed=TRUE)
   }
   if(operations[j]=="compress")
   {
     val<-unlist(strsplit(values[j],"_",fixed=TRUE))
     temp_var<-gsub(val[1],"",temp_var,fixed=TRUE)
   }
   if(operations[j]=="blanks")
   {
     if(values[j]=="leading"){
     temp_var<-str_trim(temp_var,side="left")}
     if(values[j]=="trailing"){
       temp_var<-str_trim(temp_var,side="right")}
     if(values[j]=="all"){
       temp_var<-temp_var<-gsub(" ","",temp_var,fixed=TRUE)}
   }
   }
 temp_var<-as.data.frame(temp_var)
 if(prefix!=""){
   coln<-paste(prefix,var_list[i],sep="_")
  }else if(postfix!=""){coln<-paste(var_list[i],postfix,sep="_")
   }else{
     coln<-var_list[i]
     }
 colnames(temp_var)[ncol(temp_var)]<-coln
 if(i==1){
   final<-as.data.frame(temp_var)
  }else{
 final<-cbind.data.frame(final,temp_var)}
 }
if(prefix =="" & postfix ==""){
  colname<-colnames(final)
  index<-which(colnames(dataworking) %in% colname)
  dataworking<-dataworking[-c(index)]
}
dataworking<-cbind.data.frame(dataworking,final)

#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(final) > 6000) {
  x_temp                       <- sample(x=nrow(final),
                                         size=6000,
                                         replace=FALSE)
  final                        <- final[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------
write.csv(final,file=paste(output_path,"String_operations.csv",sep="/"),quote=FALSE,row.names=FALSE)
save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))

#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

write.table("STRING_OPERATIONS_COMPLETED",paste(output_path,"STRING_OPERATIONS_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)