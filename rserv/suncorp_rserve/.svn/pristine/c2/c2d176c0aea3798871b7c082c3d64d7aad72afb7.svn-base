#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : modeling_outlierDetection.R                         
#-- Description  : Performs modeling outlier treatment based on r student, hatdiag and other stats
#-- Return type  : csv              
#-- Author : Saurabh singh
#------------------------------------------------------------------------------------------------------#

reading the outdata from the # making the outdata_path
outdata_path<-gsub("outlier","",inter_output_path)

# loading the rdata object for the outdata
load(paste(outdata_path,"outdata.RData",sep="/"))

# filtering the data based on the required cutoff and the variable and keeping the required columns the final dataset
outdata<-data.table(outdata)
index<-which(outdata[,flag_var] < cutoff_val)
if(length(index)){
  outdata[index,flag_var]<-1
  outdata[-c(index),flag_var]<-0
  outdata<-outdata[c(flag_var,"primary_key_1644")]
}

# reading the bygroupdata

bygroup<-read.csv(paste(input_path,"bygroupdata.RData",sep="/"))
bygroup<-merge.data.frame(bygroup,outdata,by="primary_key_1644",all.x=TRUE)
save(bygroup, file = paste(input_path,"bygroupdata.RData", sep="/"))
write("MODELING_OUTLIER_TREATMENT_COMPLETED",paste(inter_output_path,"MODELING_OUTLIER_TREATMENT_COMPLETED.txt",quote=F,row.names=F)


