#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : MRx_General_Linear_Modeling.R                         
#-- Description  : Performs General Linear regression     
#-- Return type  : csv              
#-- Author : Proma majumdar and saurabh singh.
#------------------------------------------------------------------------------------------------------#

#libraries Required.
#-------------------------------------------------------------------------------------

library(rgr)
library(car)
library(stringr)
library(vegan)
library(lsmeans)
library(Hmisc)
#reading the dataset-----------------------------------------------------------------------------------
if(is.null(independent_variables))
{
  char.error <- "Cannot build model with only class variables. "
  write(char.error, file=paste(output_path, "/ERROR.txt", sep=""), append=T)
  
}

if(length(which(independent_variables %in% class_variables == "TRUE")) == length(independent_variables)){
  char.error <- "Cannot build model with only class variables. "
  write(char.error, file=paste(output_path, "/ERROR.txt", sep=""), append=T)
  
}



if(flag_bygrp_update == "true" && model_iteration != 1){
  load(paste(group_path,"bygroupdata.RData",sep="/"))
  load(paste(input_path,"dataworking.RData",sep="/"))
  dataworking<-merge(bygroupdata,dataworking,all.x=TRUE,by="primary_key_1644")
  col<-colnames(dataworking)
  newcol<-col[-c(which(grepl("\\.y",col)))]
  dataworking<-dataworking[newcol]
  newcol<-gsub("\\.x","",newcol)
  colnames(dataworking)<-newcol
  uniquecol<-unique(colnames(dataworking))
  dataworking<-dataworking[uniquecol]
}else{
  if(model_iteration == 1){
    load(paste(input_path,"/dataworking.RData",sep=""))
  }else{
    load(paste(group_path,"/bygroupdata.RData",sep=""))
    dataworking <- bygroupdata
    rm("bygroupdata")
  }
}


#*********************************************************************************************#
#*********************cleaning up of independent variable*************************************#
#*********************************************************************************************#

index1<-c()
if(length(class_variables)){
  
  # sorting class variables in decreasing order of their length
  lengthofclass<-data.frame(unlist(lapply(strsplit(class_variables,""),length)))
  colnames(lengthofclass)<-"lenghtvalue"
  lengthofclass<-cbind(lengthofclass[1],seq(1:length(class_variables)))
  lengthofclass<-lengthofclass[order(lengthofclass[,1],decreasing=TRUE),]
  sequence<-lengthofclass[,2]
  class_variables<-class_variables[sequence]
  for(i in 1:length(class_variables))
  {
    index2<-which(independent_variables %in% class_variables[i])
    index1<-c(index1,index2)
  }
  if(length(index1))
  {
    independent_variables<-independent_variables[-index1]
  }
}

# sorting independent variables in decreasing order of their length

lengthofindep<-data.frame(unlist(lapply(strsplit(independent_variables,""),length)))
colnames(lengthofindep)<-"lenghtvalue"
lengthofindep<-cbind(lengthofindep[1],seq(1:length(independent_variables)))
lengthofclass<-lengthofindep[order(lengthofindep[,1],decreasing=TRUE),]
sequence<-lengthofclass[,2]
independent_variables<-independent_variables[sequence]


#*********************************************************************************************#
#*********************cleaning up of independent variable ends here***************************#
#*********************************************************************************************#

#subset on treatment process---------------------------------------------------------------------------


if (as.integer(grp_no)!= 0)
{
  temp_var=paste("grp",grp_no,"_flag",sep="")
  
  index<-which(names(dataworking)==temp_var)
  dataworking<-subset(dataworking,dataworking[index]==grp_flag)
}  
dataworking$actual<-0
dataworking$actual<-dataworking[,dependent_variable]
bygroupdata <- dataworking
save(bygroupdata,file=paste(group_path,"/bygroupdata.RData",sep=""))
rm("bygroupdata")

#subset on validation/validate model-------------------------------------------------------------------

if(validation_var != "")
{
  if (type_glm=="build")
  {
    col_num<-which(names(dataworking)==validation_var)
    dataworking<-dataworking[which(dataworking[col_num]==1),]
  }
  if (type_glm=="validation")
  {
    col_num<-which(names(dataworking)==validation_var)
    dataworking<-dataworking[c(which(dataworking[col_num]==0)),]
  }
}
# converting numerical class variables as factors

if (length(class_variables)) {
  for (lm in 1:length(class_variables)) {   
    dataworking[, class_variables[lm]] <- factor(as.character(dataworking[,class_variables[lm]]))
  }
}
# 
#outlier_scenario--------------------------------------------------------------------------------------
if(length(outlier_var) != 0)
{
  col_num<-which(names(dataworking)==outlier_var)
  dataworking<-dataworking[which(dataworking[col_num]==1),]
}


if(length(class_variables)){
  independent_variables1<-c(independent_variables,class_variables)
  independent_variables1<-unique(independent_variables1)
}else{
  independent_variables1=independent_variables
}
if(any(apply(as.data.frame(independent_variables),1,function(x){grepl("*",x,fixed=T)})) != T)
{
  data<-dataworking[c(dependent_variable,independent_variables)]
}else{
  data<-dataworking[c(dependent_variable,unlist(strsplit(independent_variables,"*",fixed=T)))]
}
variable<-colnames(data)
if(length(which(is.na(data)==TRUE))){
  index<-which(is.na(data)==TRUE)%%nrow(data)
  if(length(which(index == 0))){index[c(which(index == 0))]=nrow(data)}
  data<-data[-c(index),]
  dataworking<-dataworking[-c(index),]
}
# datatest<-data[1,c(which(independent_variables %nin% class_variables) + 1)]
# removecol<-colnames(datatest)[which(apply(datatest,2,function(x){grepl("[[:punct:]]",x)}) == "TRUE")]
# if(length(removecol)){
#   independent_variables<-independent_variables[-c(which(independent_variables == removecol))]
# }


#------------------------------------------------------------------------------
# Delete these error TXTs if they already exist
#------------------------------------------------------------------------------
deleteThese <- paste(output_path,"/ERROR.txt",sep="")
unlink(deleteThese,force=T)
#------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Check if there are any valid observations
#-------------------------------------------------------------------------------
if (!nrow(dataworking)) {
  char.error <- "Model cannot be run as there are no observations present to build a model due to the presence of missing values ."
  write(char.error, file=paste(output_path, "/ERROR.txt", sep=""), append=T)
  
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Checking if the class variables have more than one level
#-------------------------------------------------------------------------------
if(length(independent_variables1)){
  independentVariablesChk <- unlist(sapply(independent_variables1, function(x) strsplit(x,"\\*")))
  errorText <- NULL
  for(tempi in 1:length(independentVariablesChk)){
    if(length(unique(dataworking[,independentVariablesChk[tempi]])) == 1){
      errorText <- c(errorText,independentVariablesChk[tempi])
    }
  }
  if(length(errorText)){
    if(length(errorText) > 1){
      errorText <- paste(errorText,collapse=" , ")
      errorText <- gsub(pattern="(.*),",replacement="\\1and",x=errorText)
      errorText <- paste("The selected variables ",errorText," have only 1 unique level. Regression will not run.",sep="")
    }else{
      errorText <- paste("The selected variable ",errorText," has only 1 unique level. Regression will not run.",sep="")
    }
    write(errorText,file=paste(output_path,"/ERROR.txt",sep=""))
    
  }
}
#-------------------------------------------------------------------------------

# minimum observations check

if (nrow(dataworking) < 10){
  char.error <- "Model can not be built as there are less than 10 observations after filtering. "
  write(char.error, file=paste(output_path, "/ERROR.txt", sep=""), append=T)
  
}


independent_variables_copy<-independent_variables1
#formula creation for model---------------------------------------------------------------
counter=0
while(counter == 0){
  
  #formula creation for model----------------------------------------------------------------------------
  
  if(length(which(regression_options %in% 'noint'))!=0)
  {
    formulaobj=paste(dependent_variable,"~",paste("0",paste(independent_variables1,collapse="+"),sep="+"))
  }else{
    formulaobj=paste(dependent_variable,"~",paste(independent_variables1,collapse="+"))
  }
  
  #general linear model object---------------------------------------------------------------------------
  glmobj <- glm(formulaobj,data=dataworking)
  save(glmobj, file = paste(output_path,"/glmobj.RData", sep=""))
  
  if(glmobj$converged == "FALSE"){
    char.error <- "Algorithm did not converge for the current selection. "
    write(char.error, file=paste(output_path, "/ERROR.txt", sep=""), append=T)
    
  }
  
  #   checking for NA coefficients and building a valid model
  if(length(which(is.na(coefficients(glmobj)))) != 0)
  {
    coeff<-as.data.frame(summary(glmobj)$coefficients)
    indep<-row.names(coeff)
    false_indep<-names(which(is.na(glmobj$coeff)))
    # filtering out new independent_variables
    index3<-which(indep %in% independent_variables == TRUE)
    indep<-indep[index3]
    if(length(class_variables)){
      remove_index=c()
      for(mn in 1:length(class_variables))
      {
        if(any(grepl(class_variables[mn],false_indep)))
        {
          remove_index<-c(remove_index,mn)
        }
      }
      newclass<-c()
      if(length(remove_index))
      {
        newclass<-class_variables[-c(remove_index)]
      }
      if(length(newclass)){indep<-c(indep,newclass)}  
    }
    
    if(length(which(indep %in% "(Intercept)")))
    {
      indep<-indep[-c(which(indep %in% "(Intercept)"))]
    }
    independent_variables1<-indep
  }else{
    counter=1
  }
}
independent_variables1<-independent_variables_copy

#Parameter_estimates-----------------------------------------------------------------------------------
if(flag_only_vif != 'true')
{
  param_est_add=NULL
  param_est <- as.data.frame(summary(glmobj)$coefficients)
  param_est<-cbind(row.names(param_est),param_est)
  colnames(param_est) <- c("Variable", "Estimate", "StdErr","tValue","PValue")
  param_est[,1]<-gsub(":","*",param_est[,1])
  write.csv(param_est,file=paste(output_path,"ParameterEstimates.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
#ActualsVsPredicted-------------------------------------------------------------------------------------

actual<- as.data.frame(dataworking[dependent_variable],na.omit= TRUE)
residuals<- as.data.frame(round(glmobj$residuals,4))
predicted<- as.data.frame(round(glmobj$fitted.values,4))
leverage<- as.data.frame(influence(glmobj , do.coef = TRUE)[1])
#dep_var<- actual
#perc_err<- (abs(residuals)*100)/dep_var
#std_err <- as.data.frame(0)
#actvspred<-cbind.data.frame(actual,predicted,residuals,leverage,dep_var,perc_err)
actvspred<-cbind.data.frame(actual,predicted,residuals,leverage)
#actvspred <- cbind.data.frame(actvspred , std_err)
#colnames(actvspred)<-c("actual","pred","resid","leverage" ,paste(dependent_variable), "perc_err" ,"std_error_resid")
colnames(actvspred)<-c("actual","pred","resid","leverage")
#actvspred <- actvspred[c(5,2,3,7,4,6,1)]
actvspred <- actvspred[c(2,1,3,4)]
write.csv(actvspred,file=paste(output_path,"normal_chart.csv",sep="/"),quote=FALSE,row.names=FALSE)


#creating RData for Predicted Variable creation --------------------------------

predicted<- actvspred["pred"]
primary_key_1644 <- dataworking["primary_key_1644"]
predictedData <- cbind.data.frame(predicted , primary_key_1644)
save(predictedData, file = paste(output_path,"predictedData.RData",sep="/"))


#---------------------Model Statistics------------------------------------------------------------------
#---------------------MAPE--------------------------
if(flag_only_vif != 'true')
{
  calcMape = function(actual, predicted) 
  {    #Removing NA and zero values from the actual vector 
    
    index = (1:nrow(actual))[!is.na(actual)] 
    index = index[actual[index,1] != 0] 
    actual = actual[index,1] 
    predicted = predicted[index,1] 
    mape = mean(abs((actual - predicted)/actual))*100 
    return(mape) 
  }
  MAPE<-calcMape(actual,predicted)
  
  Number_of_Observations_Read <- nrow(dataworking)
  Number_of_Observations_Used <- nrow(dataworking)
  RSquare<-RsquareAdj(glmobj)$r.squared
  Adj_Rsquare<-RsquareAdj(glmobj)$adj.r.squared
  AIC<-glmobj$aic
  Dependent_Mean<-mean(dataworking[dependent_variable])
  a<-lm(formulaobj,data=dataworking)
  Root_MSE<-summary(a)$sigma
  Coeff_Var<-100*Root_MSE/Dependent_Mean
  Sum_of_Squares_Error<-summary(glmobj)$deviance
  Mean_Square_Error<-Sum_of_Squares_Error/summary(glmobj)$df[2]
  Sum_of_Squares<-try(sum(anova(glmobj)$Deviance,na.rm=TRUE),silent=T)
  if(class(Sum_of_Squares) == "try_error")
  {
    Sum_of_Squares<-NA
  }
  Mean_Square<-try(Sum_of_Squares/(nrow(anova(glmobj))-1),silent=T)
  if(class(Mean_Square) == "try-error"){
    Mean_Square=NA
  }
  fdummy<-summary(a)$fstatistic
  Model_F_Statistic<-summary(a)$fstatistic[1]
  P_Value_Model<-pf(fdummy[1],fdummy[2],fdummy[3],lower.tail=FALSE)
  modelstats<-rbind(Number_of_Observations_Read, Number_of_Observations_Used,RSquare,Adj_Rsquare,AIC,Coeff_Var,Root_MSE,Dependent_Mean,Sum_of_Squares,Mean_Square,Model_F_Statistic,P_Value_Model,Sum_of_Squares_Error,Mean_Square_Error,MAPE)
  modelstats<-cbind(row.names(modelstats),modelstats)
  colnames(modelstats)<-c("Statistics","Value")
  modelstats <- as.data.frame(modelstats , row.names = "FALSE")
  modelstats[,1]<-as.character(modelstats[,1])
  modelstats[3,1]<-"R-Square"
  modelstats[1,1]<-"Number of Observations Read"
  modelstats[2,1]<-"Number of Observations Used"
  classvar = NULL
  classvar2 = NULL
  newadd=NULL
  newadd2=NULL
  if(length(class_variables) != 0){
    for(i in 1 : length(class_variables)){
      pastenew<-""
      class_name = paste(colnames(dataworking[class_variables[i]]) , "Levels" ,sep = " ")
      class_values = paste(colnames(dataworking[class_variables[i]]) , "Values" ,sep = " ")
      class_level  = nrow(unique(dataworking[class_variables[i]])) 
      names <-unique(dataworking[class_variables[i]])
      for(j in 1:nrow(names)){
        pastenew<-paste(pastenew,names[j,1],sep=" ")
      }
      class_info <-  cbind.data.frame(class_name , class_level )
      class_val <- cbind.data.frame(class_values , pastenew)
      classvar <- rbind(classvar , class_info)
      colnames(classvar) = c("Statistics" , "Value")
      classvar2 <- rbind(classvar2 , class_val)
      colnames(classvar2) = c("Statistics" , "Value")
      newadd<-rbind.data.frame(classvar , classvar2)
      newadd2<-rbind.data.frame(newadd2,newadd)
      classvar=NULL
      classvar2=NULL
      newadd=NULL
    }
    modelstats <- rbind.data.frame(newadd2 , modelstats)
  }
  write.csv(modelstats,file=paste(output_path,"Model_Statistics.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
#model anova-------------------------------------------------------------------------------------------
#------------ type1--------------------------------------------------------------- 

#************************************ calculating VIF*************************************************#
if(exists("indep"))
{
  if(length(indep) == 1){
    vif="NA"  
    vif <- as.data.frame(vif)
  }else{
    vif<-vif(glmobj)
    vif <- as.data.frame(vif)
  }
}else{
  if(length(independent_variables) != 1){ 
    vif<-vif(glmobj)
    vif <- as.data.frame(vif)
  }else{
    vif="NA"  
    vif <- as.data.frame(vif)
  }
}

#************************************ calculating VIF ends   *****************************************#
if(flag_only_vif=='true'){
  vif<-cbind.data.frame(row.names(vif),vif[,1])
  colnames(vif)<-c("Variable","VIF")
  vif<-vif[c(which(as.character(vif$Variable) %in% vif_variables)),]
  write.csv(vif,file=paste(output_path,"ModelAnova.csv",sep="/"),quote=FALSE,row.names=FALSE)
}else{
  type1stats = NULL
  type1stats<-as.data.frame(anova(glmobj,test="F"))
  type1stats <- type1stats[-c(3,4)]
  ms1 <- as.data.frame(type1stats$Deviance / type1stats$Df)
  colnames(ms1) <-"ms1"
  vif<-cbind.data.frame(row.names(vif),vif[,1])
  hypothesis1<-as.data.frame(rep(1,nrow(type1stats)))
  type1stats<-cbind(hypothesis1,row.names(type1stats),type1stats,ms1)
  type1stats<-merge(type1stats,vif,by.x="row.names(type1stats)",by.y="row.names(vif)",all.x=TRUE)
  colnames(type1stats)<-c("Variable","HypothesisType","DF","SS","FValue","PValue","MS","VIF")
  
  #--------------type3-------------------------------------------------------------
  type3stats = NULL
  type3stats<-Anova(glmobj, test="F")
  ms3 <- as.data.frame(type3stats$SS / type3stats$Df)
  colnames(ms3) <-"ms3"
  hypothesis3<-as.data.frame(rep(3,nrow(type3stats)))
  type3stats<-cbind(hypothesis3,row.names(type3stats),type3stats ,ms3)
  type3stats<-merge(type3stats,vif,by.x="row.names(type3stats)",by.y="row.names(vif)",all.x=TRUE)
  colnames(type3stats)<-c("Variable","HypothesisType","SS","DF","FValue","PValue","MS","VIF")
  modelanova = NULL
  modelanova <- rbind.data.frame(type1stats , type3stats)
  modelanova<-modelanova[c(order(modelanova$Variable)),]
  modelanova<-modelanova[-c(which(modelanova$Variable == "NULL" | modelanova$Variable == "Residuals")),]
  #modelanova <- cbind.data.frame(HypothesisType , Variable , DF , SS ,MS ,FValue ,PValue , VIF)
  #modelanova<-modelanova[c(2,1,3,4,7,5,6,8)]
  modelanova<-modelanova[c(4,7,5,1,2,3,6,8)]
  write.csv(modelanova,file=paste(output_path,"ModelAnova.csv",sep="/"),quote=FALSE,row.names=FALSE)
}

#lsmeans-----------------------------------------------------------------------------------------------

if(length(ls_means_variables)!= 0){
  
  lstable<-NULL
  for(i in 1:length(ls_means_variables)){
    dataworking[,ls_means_variables[i]]<-as.factor(as.character(dataworking[,ls_means_variables[i]]))
    formulas<- paste("lsmeans(glmobj, pairwise ~ ",ls_means_variables[i],")",sep=" ")
    newlstable<-as.data.frame(eval(parse(text=formulas))[1])
    Variable<-rep(class_variables[i],nrow(newlstable))
    PValue <- rep("<.0001" ,nrow(newlstable))
    newlstable<-cbind(Variable,newlstable,PValue)
    newlstable <- newlstable[c(1,2,3,4,ncol(newlstable))]
    colnames(newlstable)<-c("Variable","Level","LSMean","StandardError","PValue")
    lstable<-rbind(lstable,newlstable)
    newlstable = NULL
  }
  write.csv(lstable,file=paste(output_path,"Lsmeans.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
#saving the linear model object-------------------------------------------------------------------------
save(glmobj, file=paste(output_path,"/glmobjimage.R",sep=""))

write.table("GENERAL_LINEAR_MODEL_COMPLETED",paste(output_path,"GENERAL_LINEAR_MODEL_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)
