#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : MRx_Linear_Modeling.R                         
#-- Description  : Performs Generalized Linear Operation     
#-- Return type  : csv              
#-- Author : saurabh singh
#------------------------------------------------------------------------------------------------------#

#libraries Required.

library(car)
#library(XML)
library(QuantPsyc)
library(statmod)
library(tweedie)
library(Hmisc)


output_path<-outputPath
#*********************************************************************************************#
#*********************cleaning up of independent variable*************************************#
#*********************************************************************************************#
if(is.null(independentVariables)){
  char.error <- "Cannot build model with only class variables. "
  write(char.error, file=paste(output_path, "/error.txt", sep=""), append=T)
  
}

if(length(which(independentVariables %in% classVariables == "TRUE")) == length(independentVariables)){
  char.error <- "Cannot build model with only class variables. "
  write(char.error, file=paste(output_path, "/error.txt", sep=""), append=T)
 
}

index1<-c()
if(length(classVariables)){
  # sorting class variables in decreasing order of their length
  lengthofclass<-data.frame(unlist(lapply(strsplit(classVariables,""),length)))
  colnames(lengthofclass)<-"lenghtvalue"
  lengthofclass<-cbind(lengthofclass[1],seq(1:length(classVariables)))
  lengthofclass<-lengthofclass[order(lengthofclass[,1],decreasing=TRUE),]
  sequence<-lengthofclass[,2]
  classVariables<-classVariables[sequence]
  for(i in 1:length(classVariables))
  {
    index2<-which(independentVariables %in% classVariables[i])
    index1<-c(index1,index2)
  }
  if(length(index1))
  {
    independentVariables<-independentVariables[-index1]
  }
  #Error handling
  if(weightVariable %in% classVariables)
  {
    errorText <- "Class variables and weight variables can not be same"
    write(errorText,file=paste(output_path,"/error.txt",sep=""),append=T)

  }
}

# sorting independent variables in decreasing order of their length

lengthofindep<-data.frame(unlist(lapply(strsplit(independentVariables,""),length)))
colnames(lengthofindep)<-"lenghtvalue"
lengthofindep<-cbind(lengthofindep[1],seq(1:length(independentVariables)))
lengthofclass<-lengthofindep[order(lengthofindep[,1],decreasing=TRUE),]
sequence<-lengthofclass[,2]
independentVariables<-independentVariables[sequence]



# converting numerical class variables as factors
if (length(classVariables)) {
  for (lm in 1:length(classVariables)) {   
    bygroupdata[, classVariables[lm]] <- factor(as.character(bygroupdata[,classVariables[lm]]))
  }
}

#*********************************************************************************************#
#*********************cleaning up of independent variable ends here***************************#
#*********************************************************************************************#


independentVariables<-c(independentVariables,classVariables)
if(offsetVariable != "" & weightVariable != ""){
  dataworking<-bygroupdata[c(eval(parse(text=actual)),independentVariables,offsetVariable,weightVariable)]
}
if(offsetVariable != "" & weightVariable == ""){
  dataworking<-bygroupdata[c(eval(parse(text=actual)),independentVariables,offsetVariable)]
}
if(offsetVariable == "" & weightVariable == ""){
  dataworking<-bygroupdata[c(eval(parse(text=actual)),independentVariables)]
}
if(offsetVariable == "" & weightVariable != ""){
  dataworking<-bygroupdata[c(eval(parse(text=actual)),independentVariables,weightVariable)]
}

dataworking<-cbind(dataworking,bygroupdata["primary_key_1644"])
variable<-colnames(dataworking)
if(validationVar != ""){
  dataworking<-cbind(dataworking,bygroupdata[validationVar])
}
noofobs<-nrow(dataworking)
if(length(which(is.na(dataworking)==TRUE))){
  index<-which(is.na(dataworking)==TRUE)%%nrow(dataworking)
  if(length(which(index == 0))){index[c(which(index == 0))]=nrow(dataworking)}
  dataworking<-dataworking[-c(index),]
}
missing<-noofobs-nrow(dataworking)
if(distribution == "gamma")
{ if(length(which(dataworking[,dependentVariable] <= 0))){
  dataworking<-dataworking[-c(which(dataworking[,dependentVariable] <= 0)),]
  }
}
if(weightVariable != ""){
  ind<-which(dataworking[,weightVariable] == 0)
  if(length(ind)){
  dataworking<-dataworking[-c(ind),]  
  }
}
if(is.null(dataworking) | nrow(dataworking) == 0)
{
  write.table("No valid observations after removing zero and negative values in dependent variable",paste(output_path,"ERROR.txt",sep="/"),quote=F,row.names=F,col.names=F)

}
#subset on validation----------------------------------------------------------------

if(validationVar != "")
{
  if (validationType=="build")
  {
    col_num<-which(names(dataworking)==validationVar)
    dataworking<-dataworking[which(dataworking[col_num]==1),]
  }
  if (validationType=="validation")
  {
    col_num<-which(names(dataworking)==validationVar)
    dataworking<-dataworking[c(which(dataworking[col_num]==0)),]
  }
}
#outlier_scenario-----------------------------------------------------------------------
#if(outlier_var != "")
#{
#  col_num<-which(names(dataworking)==outlier_var)
#  dataworking<-dataworking[which(dataworking[col_num]==1),]
#}

##### providing check for unique levels in all the variables -----------------------------------------

func_len_uniq<-function(x){length(unique(x))}
new<-apply(dataworking[c(dependentVariable,independentVariables)],2,func_len_uniq)
new<-cbind(names(new),new)
class_const_var<-new[which(as.numeric(new[,2]) == 1 ),1]
if(length(class_const_var) != 0)
{
  text_1=paste("Following variable(s) have only one level: ",paste(class_const_var,collapse=" , "),". Hence can not run the model.",sep="")
  write(text_1,paste(output_path,"error.txt",sep="/"))

}

if(nrow(dataworking) < 10)
{
  text_1="Model can not be build as there are less than 10 observations after filtering. "
  write(text_1,paste(output_path,"error.txt",sep="/"))

}



independentVariables_copy<-independentVariables
#formula creation for model---------------------------------------------------------------
counter=0
while(counter == 0){
  
  if(grepl("noint",modelOptions))
  {
    formulaobj=paste(dependentVariable,"~",paste("0",paste(independentVariables,collapse="+"),sep="+"))
  }else{formulaobj=paste(dependentVariable,"~",paste(independentVariables,collapse="+"))
  }
  
  #creating the family for model--------------------------------------------------------------------
  
  switch(distribution,
         normal = dist<-gaussian,
         poisson  = dist<-poisson,
         binomial = dist<-binomial,
         gamma = dist<-Gamma(link='log'),
         tweedie= dist<-tweedie(var.power=tweedieP, link.power=1-var.power))
  
  if(offsetVariable != "")
  {  dataworking[,offsetVariable]<-as.numeric(dataworking[,offsetVariable]) }
  
  #generalized linear regression-------------------------------------------------------------------------
  if(distribution=="negbin"){
    model="glm.nb"
    if(weightVariable == ""){
      lmobj<- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking)",sep=""))),silent=T)}else{
      lmobj <- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking,weights=",weightVariable,")",sep=""))),silent=T)}
  }else{
  model="glm"
  if(weightVariable == "" & offsetVariable == "")
  {
    lmobj <- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking,family=dist)",sep=""))),silent=T)
  }
  if(weightVariable == "" & offsetVariable != "")
  {
    lmobj <- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking,family=dist,offset=",offsetVariable,")",sep=""))),silent=T)
  }
  if(weightVariable != "" & offsetVariable == "")
  {
    lmobj <- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking,family=dist,weights=",weightVariable,")",sep=""))),silent=T)
  }
  if(weightVariable != "" & offsetVariable != "")
  {
    lmobj <- try(eval(parse(text=paste(text=model,"(formulaobj,data=dataworking,family=dist,weights=",weightVariable,",offset=",offsetVariable,")",sep=""))),silent=T)
  }
  }
  
  if(class(lmobj)=="try-error"){
    errorText <- "Cannot build model with current set of parameters."
    write(errorText,file=paste(output_path,"/error.txt",sep=""),append=T)

  }
  
  #   checking for NA coefficients and building a valid model
  if(length(which(is.na(coefficients(lmobj)))) != 0)
  {
    coeff<-as.data.frame(summary(lmobj)$coefficients)
    indep<-row.names(coeff)
    false_indep<-names(which(is.na(lmobj$coeff)))
    # filtering out new independentVariables
    index3<-which(indep %in% independentVariables == TRUE)
    indep<-indep[index3]
    if(length(classVariables)){
      remove_index=c()
      for(mn in 1:length(classVariables))
      {
        if(any(grepl(classVariables[mn],false_indep)))
        {
          remove_index<-c(remove_index,mn)
        }
      }
      newclass<-c()
      if(length(remove_index))
      {
        newclass<-classVariables[-c(remove_index)]
      }
      if(length(newclass)){indep<-c(indep,newclass)}  
    }
    
    if(length(which(indep %in% "(Intercept)")))
    {
      indep<-indep[-c(which(indep %in% "(Intercept)"))]
    }
    independentVariables<-indep
  }else{
    counter=1
  }
}
independentVariables<-independentVariables_copy



#-------------------------------------------------------------------------
# Saving the model object so that it can be used for scoring
#-------------------------------------------------------------------------
save(lmobj,file=paste(output_path,"/modelObject.RData",sep=""))
#-------------------------------------------------------------------------

####ParameterEstimates---------------------------------------------------------------------
lmtable<-data.frame(coef(summary(lmobj)))
df<-rep(1,nrow(lmtable))
lmtablet<-as.data.frame(t(lmtable))
LowerWaldCL<-t(data.frame(lmtablet[1,]-(2*lmtablet[2,])))
colnames(LowerWaldCL)<-"LowerWaldCL"
UpperWaldCL<-t(data.frame(lmtablet[1,]+(2*lmtablet[2,])))
colnames(UpperWaldCL)<-"UpperWaldCL"
chisqval<-Anova(lmobj, type=c("II","III", 2, 3), 
                test.statistic=c("LR", "Wald", "F"), 
                error, error.estimate=c("pearson", "dispersion", "deviance"))
type1LR<- anova(lmobj,test=c("Chisq"))
chitab<-cbind(row.names(chisqval),(chisqval[,c(1,3)]))
paramest<-cbind(lmtable[,1:2],as.data.frame(df),as.data.frame(LowerWaldCL),as.data.frame(UpperWaldCL))
paramest<-merge(paramest,chitab,by.x="row.names",by.y="row.names(chisqval)",all=TRUE)
if(paramest[1,1] == "(Intercept)"){paramest[1,1] = "Intercept"}
colnames(paramest)<-c("Variable","Estimate","StdErr","DF","LowerWaldCL","UpperWaldCL","ChiSq","PValue")
####Model (Type 1 LR statistics and type 3 wald statistics)---------------------------------------------------------------------------------------------

chisqval<-as.data.frame(Anova(lmobj, type=c("II","III", 2, 3), 
                test.statistic=c("LR", "Wald", "F"), 
                error, error.estimate=c("pearson", "dispersion", "deviance")))
type1LR<-drop1(lmobj,test=c("Chisq"))

index <- which(row.names(type1LR) == "<none>")
if(length(index)){
  type1LR<-as.data.frame(type1LR[-index,])
}
# if(length(which(is.na(coefficients(lmobj)))) == 0)
# {
#   VIF<-as.data.frame(vif(lmobj))
# }else{VIF<-data.frame(rep("NA",nrow(type1LR)))}
model<-cbind(type1LR[,c(3,1,4,5)],chisqval[c(1,3)])
model<-cbind(row.names(model),model)
colnames(model)<-c("Variable","Deviance","DF","Type1ChiSq","Type1PValue","Type3ChiSq","Type3PValue")
if(exists("vif1"))
{
  Vif_Model<-merge(model,vif1,by="Variable",all.x=TRUE)
}else{
  Vif_Model<-model
}



#ActualsVsPredicted-------------------------------------------------------------------------------------

actual<-as.data.frame(lmobj$mode[1])
residuals<-as.data.frame(round(lmobj$residual,4))
predicted<-as.data.frame(round(fitted(lmobj),8))
leverage<-as.data.frame(influence(lmobj)[1])
actvspred<-cbind.data.frame(actual,predicted,residuals,leverage)
colnames(actvspred)<-c("Actual","Predicted","Residual","Leverage")


#creating RData for Predicted Variable creation --------------------------------

predicted<- actvspred["Predicted"]
primary_key_1644 <- dataworking["primary_key_1644"]
predictedData <- cbind.data.frame(predicted , primary_key_1644)
save(predictedData, file = paste(output_path,"predictedData.RData",sep="/"))


#model stats--------------------------------------------------------------------------------

log_likelihood<-logLik(lmobj)
deviance<-lmobj$deviance
sum_weights<-sum(lmobj$weights)
calcMape = function(actual, predicted) 
{    #Removing NA and zero values from the actual vector 
  
  index = (1:nrow(actual))[!is.na(actual)] 
  index = index[actual[index,1] != 0] 
  actual = abs(actual[index,1] )
  predicted = abs(predicted[index,1])
  mape = mean(abs((actual - predicted)/actual))*100 
  return(mape) 
}
mape<-calcMape(actual,predicted)
noofobsused<-nrow(dataworking)
link1<-(lmobj$family)$link

modelstats<-NULL
modelstats["Distribution"]<-distribution
modelstats["Link Function"]<-link1
modelstats["Dependent Variable"]<-dependentVariable
modelstats["Scale Weight Variable"]<-weightVariable
modelstats["Offset Variable"]<-offsetVariable
modelstats["Convergence Status"]<-lmobj$converged
modelstats["Number of Observations Read"]<-noofobs
modelstats["Number of Observations Used"]<-noofobsused
modelstats["Sum of Weights"]<-sum_weights
modelstats["Missing Values"]<-missing
modelstats["Deviance"]<-deviance
modelstats["Scaled Deviance"]<-noofobsused
modelstats["Pearson Chi-Square"]<-deviance
modelstats["Scaled Pearson X2"]<-noofobsused
modelstats["Log Likelihood"]<-log_likelihood
modelstats["MAPE"]<-mape
if(length(classVariables) != 0){
  for(j in 1:length(classVariables))
  {
    levels<-unique(dataworking[classVariables[j]])
    levels1<-levels[,1]
    new<-paste(levels1,collapse=" ")
    modelstats[paste(classVariables[j],"levels",sep="")]<-length(levels)
    modelstats[paste(classVariables[j],"Values",sep="")]<-new[1]
  }
}
modelstats<-as.data.frame(modelstats)
modelstats<-cbind(row.names(modelstats),modelstats)
colnames(modelstats)<-c("Statistics","Value")

#rank order chart-----------------------------------------------------------------
try(
  {if(numberOfGroups!=""){
  actvspred$weight<-0
  actvspred$weight<-lmobj$weights
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
  write.csv(rodfinal,file=paste(output_path,"RankOrderedChart.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
     },silent=T)
#----------------------writing the output csvs----------------------------------------------

write.csv(actvspred,file=paste(output_path,"ActualvsPredicted.csv",sep="/"),quote=FALSE,row.names=FALSE)
write.csv(modelstats,file=paste(output_path,"ModelStatistics.csv",sep="/"),quote=FALSE,row.names=FALSE)
write.csv(Vif_Model,file=paste(output_path,"Vif_Model.csv",sep="/"),quote=FALSE,row.names=FALSE)
write.csv(paramest,file=paste(output_path,"ParameterEstimates.csv",sep="/"),quote=FALSE,row.names=FALSE)

###########completed.txt------------------------------------------------------------------------

write.table("GENMOD_COMPLETED",paste(output_path,"GENMOD_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)

#****************-----------------genmod completed---------------------------*****************#
