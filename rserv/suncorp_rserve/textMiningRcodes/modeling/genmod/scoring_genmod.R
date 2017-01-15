#-------------------------------------------------------------------------------------------------#
#--	Description		:	Scoring for GENMOD														--#
#--	Logic			:	Reading the model object of the iteration								--#
#--						Applying it on the specified part of bygroupdata(validation or entire)	--#
#--						Calculating predicted and residual										--#
#--						Writing ActualvsPredicted.csv											--#
#-- Author			:	Vasanth M M 4261														--#
#--	Edited History	:	Started writing on 04jul2013 1349										--#
#-------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------------------------#
# Libraries Required
#-------------------------------------------------------------------------------------------------#
library(ROCR)
library(Hmisc)
#-------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------------------------#
# Parameters Required
#-------------------------------------------------------------------------------------------------#
# groupPath			<- "C:/Users/vasanth.mm/MRx/r/abcdefg-4-Jul-2013-11-55-04/1/0/1_1_1"
# outputPath		<- "C:/Users/vasanth.mm/MRx/r/abcdefg-4-Jul-2013-11-55-04/1/0/1_1_1/GENMOD/1/4/scoring/validation"
# dependentVariable	<- "sales"
# validationType	<- ''
# validationVar		<- 'XXX_1'
#-------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------------------------#
# Reading the model object of the iteration
#-------------------------------------------------------------------------------------------------#
iterationPath	<- outputPath
iterationPath	<- gsub(pattern="/scoring/validation",replacement="",x=iterationPath)
iterationPath	<- gsub(pattern="/scoring/entire",replacement="",x=iterationPath)
load(file=paste(iterationPath,"/modelObject.RData",sep=""))
#-------------------------------------------------------------------------------------------------#


# converting numerical class variables as factors
if (length(classVariables)) {
  for (lm in 1:length(classVariables)) {   
    bygroupdata[, classVariables[lm]] <- factor(as.character(bygroupdata[,classVariables[lm]]))
  }
}


#-------------------------------------------------------------------------------------------------#
# Applying it on the specified part of bygroupdata(validation or entire)
# Calculating predicted and residual and writing ActualvsPredicted.csv
#-------------------------------------------------------------------------------------------------#
# bygroupdata	<- read.csv(paste(groupPath,"/bygroupdata.csv",sep=""))
# load(paste(groupPath,"/bygroupdata.RData",sep=""))
if(validationType != ""){
  bygroupdata	<- bygroupdata[bygroupdata[,validationVar]==0,]
}
Actual		<- bygroupdata[,dependentVariable]
Predicted	<- predict(lmobj,type="response",bygroupdata)
Residual	<- Actual-Predicted
actvspred <- cbind.data.frame(Actual,Predicted,Residual)
colnames(actvspred)<-c("Actual","Predicted","Residual")
write.csv(actvspred,paste(outputPath,"/ActualvsPredicted.csv",sep=""),row.names=F,quote=F)
#-------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------------------------#
# rank order chart
#-------------------------------------------------------------------------------------------------#
actvspred <- cbind.data.frame(Actual,Predicted,Residual)
if(numberOfGroups!=""){
  if(weightVariable==""){
    actvspred$weight<-1
  }else{
    actvspred$weight <- bygroupdata[,weightVariable]
  }
  rankfinal1<-NULL
  num<-length(unique(actvspred$Predicted))
  if(as.numeric(numberOfGroups)>num){numberOfGroups=num}
  funcrank<-function(x){cutdata<-cut2(x,g=as.numeric(numberOfGroups))
                        cutdata<-factor(cutdata,labels=c(rev(seq(from=0,to=(as.numeric(numberOfGroups)-1),by=1))))
                        if(is.null(rankfinal1)){rankfinal1<-cutdata}else{
                          rankfinal1<-cbind.data.frame(rankfinal1,as.data.frame(cutdata))}
                        return(rankfinal1)}
  rod<-funcrank(actvspred$Predicted)
  rod<-cbind(rod,actvspred)
  rodfinal<-NULL
  for(k in 0:(as.numeric(numberOfGroups)-1))
  {
    index<-which(rod$rod == k)
    
    Predicted<-sum((rod[index,"Predicted"]*rod[index,"weight"])*100)/sum(rod[index,"weight"])
    Actual<-sum((rod[index,"Actual"]*rod[index,"weight"])*100)/sum(rod[index,"weight"])
    Weight<-sum(rod[index,"weight"])
    PredictedByActual<-Predicted/Actual
    Quantiles=k
    rod2<-cbind(Quantiles,Predicted,Actual,PredictedByActual,Weight)
    rodfinal<-rbind(rodfinal,rod2)
  }
  rodfinal<-as.data.frame(rodfinal)
  Mean<-mean(rodfinal$Actual)
  rodfinal$Mean<-0
  rodfinal$Mean<-Mean
  rodfinal<-rodfinal[c(1,2,3,6,4,5)]
  
  index <- which(colnames(rodfinal) %in% "Weight")
  if (weightVariable == "") {
    rodfinal <- rodfinal[, -index]
  }
  write.csv(rodfinal,file=paste(outputPath,"RankOrderedChart.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
#-------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------------------------#
# Copy paste the needed CSVs from the current iteration
#-------------------------------------------------------------------------------------------------#
from	<- c("Model.csv","ModelStatistics.csv","ParameterEstimates.csv","Vif_Model.csv")
to		<- c("Model.csv","ModelStatistics.csv","ParameterEstimates.csv","Model.csv")
for(tempi in 1:length(from)){
  file.copy(from=paste(iterationPath,from[tempi],sep="/"),to=paste(outputPath,to[tempi],sep="/"),overwrite=T)
}
#-------------------------------------------------------------------------------------------------#