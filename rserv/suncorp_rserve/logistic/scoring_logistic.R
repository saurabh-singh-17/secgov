#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : scoring_logistic.R                         
#-- Description  : Performs logistic regression scoring in R     
#-- Return type  : csv              
#-- Author       : saurabh singh
#------------------------------------------------------------------------------------------------------#
#libraries Required.

library(car)
library(QuantPsyc)
library(statmod)
library(Hmisc)
library(aod)
library(ResourceSelection)
library(ROCR)
library(reldist)

## reading the data and modelobject---------------------------------------------------

# dataworking<-read.csv(paste(grouppath,"bygroupdata.csv",sep="/"))
load(paste(grouppath,"/bygroupdata.RData",sep=""))
load(file=paste(modelpath,"/logmodelobj.RData",sep=""))


#---------------------------converting the class variables to factors
classvariables<-row.names(as.data.frame(unlist(lmobj$contrasts)))
if (length(classvariables)) {
  for (lm in 1:length(classvariables)) {   
    levels <- unique(as.character(bygroupdata[, classvariables[[lm]]]))
    bygroupdata[, classvariables[[lm]]] <- factor(as.character(bygroupdata[,classvariables[[lm]]]), levels=levels)
  }
}

dataworking <- bygroupdata
rm("bygroupdata")

#subset on validation----------------------------------------------------------------

if(validationvar != "")
{
  if (typelogit=="build")
  {
    col_num<-which(names(dataworking)==validationvar)
    dataworking<-dataworking[which(dataworking[col_num]==1),]
  }
  if (typelogit=="validation")
  {
    col_num<-which(names(dataworking)==validationvar)
    dataworking<-dataworking[c(which(dataworking[col_num]==0)),]
  }
}

#### validation completed ---------------------------------------------------------------------#

#### gettin predicted -------------------------------------------------------------------------#
scored<-as.data.frame(predict(lmobj,type="response",dataworking))

##### condis table created to facilitate creation of other tables and some other stats calculated---#


event_initial<-event

if(grepl("/",dependentvariable)) {
  dataworking$actual <- 0
  dataworking$actual<-eval(parse(text=dependentvariable),envir=dataworking)
  dependentvariable <- 'actual'
  non_event_initial <- 0
  event_initial <- 1
  dataworking$depvar<-dataworking$actual
  dataworking$depvar<-apply(dataworking[dependentvariable],1,function(x){if(x >= 0.5){return(1)}else{return(0)}})
} else {
  non_event_initial<-dataworking[which(dataworking[,dependentvariable] != event_initial)[1],dependentvariable]
  dataworking$depvar<-apply(dataworking[dependentvariable],1,function(x){if(x == event){return(1)}else{return(0)}})
}

dependentvariable<-"depvar"
event<-1





condis<-cbind(dataworking[dependentvariable],scored)


number_of_response_levels<-2
Number_of_Observations_Read<-nrow(dataworking)

missing<- length(unique(which(is.na(dataworking))%%nrow(dataworking)))
noofobs<-nrow(dataworking)
noofobsused<-noofobs-missing
Number_of_Observations_Used<-noofobsused

count_event<-length(which(dataworking[dependentvariable] == event))

count_non_event<-(Number_of_Observations_Used-count_event)

colnames(condis)<-c("actual","predicted")
condis<-condis[order(condis$predicted,decreasing=T),]
condis$rownumber<-c(nrow(condis):1)
condis<-cbind(condis,as.data.frame(cut2(condis[,3],g=10)))
percent<-apply(as.data.frame(as.numeric(condis[,4])),1,FUN=function(x){y=10-x
                                                                       z<-(x+y)+(y*10)
                                                                       return(z)})
condis$percent_customers<-percent
condis<-condis[c(1,2,5)]


####lift and gains charts ####################################################################
if(flaglift == "true"){
  randomguess<-count_event/Number_of_Observations_Used
  lifttable<-aggregate(condis[,1],condis[3],function(x){length(which(x==as.numeric(event)))})
  lifttable$individual_lift<-(lifttable[,2]/(randomguess*Number_of_Observations_Used/10))
  lifttable$cumulative_lift<-NULL
  
  for(i in 1:nrow(lifttable))
  {
    lifttable[i,"cumulative_lift"] <-mean(lifttable[c(1:i),3])
  }
  
  lifttable$base<-1
  lifttable<-lifttable[c(1,5,4,3)]
  
}

if(flaggains == "true"){
  
  gainstable<-NULL
  gainstable$percent_customers <- as.data.frame(unlist(lifttable$percent_customers))
  gainstable$random<- lifttable$percent_customers
  gainstable$percent_positive_response<-0
  gainstable<-as.data.frame(gainstable)
  
  for(i in 1:nrow(gainstable))
  {
    gainstable[i,"percent_positive_response"]<-sum(lifttable[c(1:i),"individual_lift"])*10
  }
  colnames(gainstable)[1]<-"percent_customers"
  
}
####################classification table################################################
library(parallel)
clusters <- makeCluster(getOption("cl.cores", 4))
  ProbLevel<-seq(0.000,1.000,0.001)
  classification_table<-as.data.frame(ProbLevel)
  calc<-function(x,condis){
    condis$binaryresponse<-0
    condis$binaryresponse[which(condis[2]>=x)]<-1
    return(c(length(which((condis[,"actual"] == condis[,"binaryresponse"]) & condis[,"actual"] == 1)),
             length(which(condis[,"actual"] == condis[,"binaryresponse"] & condis[,"actual"] != 1)),
             length(which((condis[,"actual"] != condis[,"binaryresponse"]) & condis[,"binaryresponse"] == 1)),
             length(which((condis[,"actual"] == 1) & condis[,"binaryresponse"] != 1))))
  }
  new<-parApply(cl=clusters,as.data.frame(ProbLevel),1,calc,condis=condis)
  new<-t(as.data.frame(new))
  colnames(new)<-c("CorrectEvents","CorrectNonevents","IncorrectEvents","IncorrectNonevents")
  classification_table<-cbind(classification_table,new)
  
  classification_table["Correct"]<-(classification_table["CorrectEvents"]+classification_table["CorrectNonevents"])/
    (classification_table["CorrectEvents"]+classification_table["CorrectNonevents"]+classification_table["IncorrectEvents"]+classification_table["IncorrectNonevents"])*100
  classification_table["Sensitivity"]<-classification_table["CorrectEvents"]/(classification_table["CorrectEvents"]+classification_table["IncorrectNonevents"])*100
  classification_table["Specificity"]<-classification_table["CorrectNonevents"]/(classification_table["CorrectNonevents"]+classification_table["IncorrectEvents"])*100
  classification_table["FalsePositive"]<-classification_table["IncorrectEvents"]/(classification_table["CorrectEvents"]+classification_table["IncorrectEvents"])*100
  classification_table["FalseNegative"]<-classification_table["IncorrectNonevents"]/(classification_table["CorrectNonevents"]+classification_table["IncorrectNonevents"])*100
  classification_table[,1]<-as.character(classification_table[,1])
  classification_table[,"One_minus_Specificity"]<-1-(classification_table[,"Specificity"]/100)
  classification_table[1,1]<-"0.000"
  fun_change<-function(x){if(x!=1){len=length(unlist(strsplit(x,"")))
                                 text1=paste(rep("0",5-len),collapse="")
                                 y=paste(x,text1,sep="")}else{
                                   y="1.000"}
                        return(y)}
  classification_table[1]<-apply(classification_table[1],1,fun_change)
  write.csv(classification_table,paste(outputpath,"classification_table.csv",sep="/"),row.names=F,quote=F)
  
  
############classification table completed #####################################################################

###########################roc_s#############################################
if(flagrocs == "true"){
  roc_s<-as.data.frame(classification_table[c("ProbLevel","Sensitivity","Specificity")])
  roc_s$Sensitivity<-roc_s$Sensitivity/100
  roc_s$Specificity<-roc_s$Specificity/100
  colnames(roc_s)<-c("_PROB_","SENSITIVITY","SPECIFICITY")
  write.csv(roc_s,paste(outputpath,"roc_s.csv",sep="/"),row.names=F,quote=F)
}

########## roc_s completed ######################################################

##########################ROC1 ###################################################

if(flagroc1 == "true"){
  roc1<-roc_s[c("SPECIFICITY","SENSITIVITY")]
  roc1$SPECIFICITY<-c(1-roc1$SPECIFICITY)
  colnames(roc1)[1]<-c("ONE_MINUS_SPECIFICITY")
  roc1<-roc1[c(1001:1),]
  write.csv(roc1,paste(outputpath,"roc1.csv",sep="/"),row.names=F,quote=F)
}

###########################actual vs predicted###################################################

if(flagactpred == "true"){
  
  predicted_actual<-NULL
  deciles<-seq(0,9,1)
  predicted_actual<-as.data.frame(deciles)
  predicted<-aggregate(condis$predicted,condis["percent_customers"],mean)
  predicted<-as.data.frame(predicted*100)[2]
  colnames(predicted)<-"predicted"
  
  condis$newactual<-apply(condis["actual"],1,function(x){if(x==event){return(1)}else{return(0)}})
  actual<-aggregate(condis$newactual,condis["percent_customers"],mean)
  actual<-as.data.frame(actual*100)[2]
  colnames(actual)<-"actual"
  
  predicted_actual<-cbind(predicted_actual,predicted,actual)
  predicted_actual$average_rate<-mean(predicted_actual$actual)
  predicted_actual$pred_by_actual<-predicted_actual$predicted/predicted_actual$actual
  
  write.csv(predicted_actual,paste(outputpath,"predicted_actual.csv",sep="/"),row.names=F,quote=F)
  
  average_rate<-as.data.frame(mean(predicted_actual$actual))
  colnames(average_rate)<-"average_rate"
  write.csv(average_rate,paste(outputpath,"average_rate.csv",sep="/"),row.names=F,quote=F)
  
}
##########################ks test###########################################################
# if(flagconfidence){
#   
#   rank_pred<-seq(0,9,1)
#   ks_out<-as.data.frame(rank_pred)
#   
#   count_events<-as.data.frame(aggregate(condis$actual,condis[3],function(x){length(which(x == event))})[,2])
#   colnames(count_events)<-"count_events"
#   
#   percent_events<-as.data.frame(apply(count_events[1],1,function(x){y=(x/sum(count_events[,1])*100) 
#                                                                     return(y)}))
#   colnames(percent_events)<-"percent_events"
#   
#   count_nonevents<-as.data.frame(aggregate(condis$actual,condis[3],function(x){length(which(x != event))})[2])
#   colnames(count_nonevents)<-"count_nonevents"
#   
#   percent_nonevents<-as.data.frame(apply(count_nonevents[1],1,function(x){y=(x/sum(count_nonevents[,1])*100) 
#                                                                           return(y)}))
#   colnames(percent_nonevents)<-"percent_nonevents"
#   
#   count_accts<-count_events+count_nonevents
#   colnames(count_accts)<-"count_accts"
#   
#   percent_accts<-as.data.frame(apply(count_accts[1],1,function(x){y=(x/sum(count_accts[,1])*100) 
#                                                                   return(y)}))
#   colnames(percent_accts)<-"percent_accts"
#   
#   cumm_accts<-cumsum(count_accts)
#   colnames(cumm_accts)<-"cumm_accts"
#   
#   pred_resp<-predicted_actual["predicted"]
#   colnames(pred_resp)<-"pred_resp"
#   
#   act_resp<-predicted_actual["actual"]
#   colnames(act_resp)<-"act_resp"
#   
#   minimum<-as.data.frame(aggregate(condis[,"predicted"],condis["percent_customers"],min)[2])
#   colnames(minimum)<-"minimum"
#   
#   maximum<-as.data.frame(aggregate(condis[,"predicted"],condis["percent_customers"],max)[2])
#   colnames(maximum)<-"maximum"
#   cumm_respr<-as.data.frame(seq(0,9,1))
#   colnames(cumm_respr)<-"cumm_respr"
#   for(i in 1:nrow(act_resp))
#   {
#     cumm_respr[i,"cumm_respr"] <-mean(act_resp[c(1:i),1])
#   }
#   cumresp<-cumsum(count_events)
#   colnames(cumresp)<-"cumresp"
#   pctresp<-cumsum(percent_events)
#   colnames(pctresp)<-"pctresp"
#   
#   ####ks test values  and gini #######################
#   ksvalfinal<-NULL
#   ginivalfinal<-NULL
#   condis$prednew<-apply(as.data.frame(condis[2]),1,function(x){if(x>=0.5){return(1)}else{return(0)}})
#   for(i in 1:10){
#     test<-condis[c(which(condis[,"percent_customers"] == (i*10))),]
#     ksval<-ks.test(test[,1],test[,5])
#     ksvalfinal<-c(ksvalfinal,(unlist(ksval[1])))
#     ginival<-gini(test[,1])
#     ginivalfinal<-c(ginivalfinal,ginival)
#   }
#   ks<-as.data.frame(ksvalfinal)
#   colnames(ks)<-"ks"
#   gini<-as.data.frame(ginivalfinal)
#   colnames(gini)<-"gini"
#   
#   
#   ###########ks values end here  gini ##################################
#   
#   gof<-rep("NA",10)
#   gof<-as.data.frame(gof)
#   colnames(gof)<-"gof"
#   
#   ###combining all into ks_out table################################
#   
#   ks_out<-cbind(rank_pred,count_events,  percent_events,  count_nonevents,	percent_nonevents,	count_accts,	percent_accts,	cumm_accts,	pred_resp,	act_resp,	minimum,	maximum,	cumm_respr,	cumresp,	pctresp,	ks,	gof,	gini)
#   
#   write.csv(ks_out,paste(outputpath,"ks_out.csv",sep="/"),row.names=F,quote=F)
#   
#   #########################################################################
#   
#   
#   ks_rep<-"badrate"
#   ks_rep<-as.data.frame(ks_rep)
#   colnames(ks_rep)<-"attribute"
#   ks_rep$order_flag<-NA
#   ks_rep$ranking<-"NOT SATISFACTORY"
#   ks_rep$set_rank<-NA
#   ks_rep$max_ks_dec<-which(ks_out$ks == max(ks_out$ks))
#   ks_rep$ks<-max(ks_out$ks)
#   ks_rep$gof<-NA
#   
#   
#   write.csv(ks_rep,paste(outputpath,"ks_rep.csv",sep="/"),row.names=F,quote=F)
#   
# }

############ks_rep completed ##################################################


#####--------------completed text file------------------------------###########

write("SCORING_LOGISTIC_COMPLETED.txt", file = paste(outputpath, "SCORING_LOGISTIC_COMPLETED.txt", sep="/"))

#**************---------logistic regression scoring completed ******************#