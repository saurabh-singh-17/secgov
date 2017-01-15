#------------------------------------------------------------------------------------------------------#
#-- Process Name : modeling_outlierTreatment_preview.R                         
#-- Description  : filters the oulier based on the cutoff and displays the output in form of a CSV
#-- Return type  : csv              
#-- Author :saurabh singh
#------------------------------------------------------------------------------------------------------#


reading the outdata from the # making the outdata_path
outdata_path<-gsub("outlier","",inter_output_path)

# loading the rdata object for the outdata
load(paste(outdata_path,"outdata.RData",sep="/"))

# filtering the data based on the required cutoff and the variable and keeping the required columns the final dataset
outdata<-data.table(outdata)
index<-which(outdata[,flag_var] >= cutoff_val)
if(length(index)){
outdata<-outdata[index,]
}
write.csv(outdata,paste(output_path,"outermodeling_outlierTreatment_preview.csv",sep="/"),quote=F,row.names=F)
write.table("MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED",paste(output_path,"MODELING_OUTLIER_TREATMENT_PREVIEW_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)
