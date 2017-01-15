#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : modeling_outlierDetection.R                         
#-- Description  : Performs modeling outlier treatment based on r student, hatdiag and other stats
#-- Return type  : csv              
#-- Author : Anvita Srivastava and saurabh singh
#------------------------------------------------------------------------------------------------------#

library(Hmisc)

# making the outdata_path
outdata_path<-gsub("outlier","",inter_output_path)

# loading the rdata object for the outdata
load(paste(outdata_path,"outdata.RData",sep="/"))

# keeping the required columns
result<-outdata[c("modres","hat_diag","r_student","cooks_dis","dffits",dependent_var)]
result<-data.frame(result)
# calculating mape for all the rows and number of groups to be created
result[,"mape"]<-result$modres/result[,dependent_var]
num_grps<-101

if(nrow(result) < 101){num_grps=nrow(result)}
final_result<-data.frame(NAME=seq(1:(num_grps)))
names_of_col<-c("hat_diag","r_student","cooks_dis","dffits")
for(i in 1:4){
x<-result[,names_of_col[i]]  
rank<-cut2(x,m=(nrow(result)/num_grps))
result$rankcol<-as.numeric(rank)
pre_result1<-aggregate(result[,names_of_col[i]],result["rankcol"],max)
pre_result2<-aggregate(result[,"mape"],result["rankcol"],max)
pre_result3<-aggregate(result[,"modres"],result["rankcol"],max)
colnamesnew<-c(names_of_col[i],paste("res",names_of_col[i],sep="_"),paste("mape",names_of_col[i],sep="_"))
pre_result<-cbind(pre_result1,pre_result2[2],pre_result3[2])
colnames(pre_result)[2:4]<-colnamesnew
final_result<-cbind(final_result,pre_result[2:4])
}
missper<-aggregate(result[,1],result["rankcol"],length)
missper$rankcol<-missper$rankcol-1
missper$no_of_outliers<-nrow(result)-cumsum(missper$x)
missper$percent_outliers<-100*missper$no_of_outliers/nrow(result)
final_result$NAME<-paste("p_",(final_result$NAME-1),sep="")
colnames(final_result)[1]<-"_NAME_"
final_result<-cbind(final_result,missper[c(3:4)])

write.csv(final_result,paste(inter_output_path,"modeling_outlierDetection",sep="/"))
write("MODELING_OUTLIER_DETECTION_COMPLETED",paste(inter_output_path,"MODELING_OUTLIER_DETECTION_COMPLETED.txt",sep="/"))