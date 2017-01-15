#---Author:--------------Harshit Raj-------------#
###------CHeck Event TRials Code------####
 #dataset_path<-C:/MRx/sas/eddd-5-Apr-2013-15-56-17/1;
 #output_path<-C:/MRx/sas/eddd-5-Apr-2013-15-56-17/1;
 # dataset_name<-dataworking;
 #events_var<-ACV;
 #trials_var<-channel_1;


#inputData<- read.csv(paste(dataset_path,'/dataworking.csv',sep=''),header=TRUE)
load(paste(dataset_path,'/dataworking.RData',sep=''))
inputData <- dataworking
rm("dataworking")
data<-inputData[c(events_var,trials_var)]
data[which(is.na(data[,1])==TRUE),1]=1
data[which(is.na(data[,2])==TRUE),1]=1

Count<-0
if(is.numeric(data[,events_var]) ==FALSE | is.numeric(data[,trials_var])==FALSE)
  {Count<-Count+1}
if(any(data[trials_var] == 0)){Count=1}
if(Count==0)
{
for(i in 1:nrow(data))
{
  if((data[i,1]/data[i,2])>1)
  {Count<-Count+1}
}
}
if(Count>0)
{ write("INVALID", file = paste(output_path, "check_eventsTrials.txt", sep="/"))
}else
{write("VALID", file = paste(output_path, "check_eventsTrials.txt", sep="/"))}


write("EVENTS_TRIALS_CHECK_COMPLETED", file = paste(output_path, "EVENTS_TRIALS_CHECK_COMPLETED.txt", sep="/"))

