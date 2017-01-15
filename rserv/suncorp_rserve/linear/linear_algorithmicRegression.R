#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : MRx_Linear_Modeling.R                         
#-- Description  : Performs Algorithmic Linear Operation     
#-- Return type  : csv              
#-- Author : saurabh singh
#------------------------------------------------------------------------------------------------------#

#libraries Required.
library(car)
library(XML)
library(QuantPsyc)
library(lmtest)

#manipulation with the path address ----------------------------------------------------------------

input_path<-gsub("//","/",input_path)
group_path<-gsub("//","/",group_path)
output_path<-gsub("//","/",output_path)

important_variables <- unlist(strsplit(important_variables,","))
current_iter        <- model_iteration
repeat_iter         <- "TRUE"
jobs                <- NULL
remove_var          <- "nil"
keep_var            <- NULL
initial_path        <- paste(output_path,model_iteration,sep="/")

while(repeat_iter != "FALSE"){
  out_path <- paste(output_path,current_iter,sep="/")
  dir.create(path=out_path,recursive=T)
  
  if(current_iter != model_iteration){
    proceed<-"TRUE"  
    independent_variables <- paramest$Original_Variable
    if(no_intercept_model != "true")
    {
      try(independent_variables <- independent_variables[-which(independent_variables %in% c("Intercept"))],silent=TRUE)
      paramest<-paramest[which(paramest$Original_Variable %in% independent_variables),]
    }
    while(proceed != "FALSE"){ 
      remove_var=NULL
      
      if(max(as.numeric(as.character(paramest$Original_VarianceInflation))) > as.numeric(vif_cutoff) & as.numeric(vif_cutoff) != 0){
        index<-which(max(as.numeric(as.character(paramest$Original_VarianceInflation)),na.rm=T) == as.numeric(as.character(paramest$Original_VarianceInflation)))
        remove_var<-as.character(paramest[index,"Original_Variable"])
      }else if(max(as.numeric(as.character(paramest$Original_Probt))) > as.numeric(pvalue_cutoff) & as.numeric(pvalue_cutoff) != 0){
        index<-which(max(as.numeric(as.character(paramest$Original_Probt)),na.rm=T) == as.numeric(as.character(paramest$Original_Probt)))
        remove_var<-as.character(paramest[index,"Original_Variable"])
      }else if(as.numeric(pvalue_cutoff) == 0){
        repeat_iter = "FALSE"
      }else{
        repeat_iter = "FALSE"
      }
      
      if(any(important_variables %in% remove_var)){
        proceed<-"TRUE"
        paramest<-paramest[-index,]
      }else{
        proceed<-"FALSE"
        if(!is.null(remove_var)){  
          independent_variables<-independent_variables[-c(which(independent_variables %in% remove_var))] 
        }
      }
    }
    if(varnum_min != ""){
      if(length(independent_variables) <= as.numeric(varnum_min)){
        repeat_iter = "FALSE"
      }
    }
  }
  
  #reading the dataset----------------------------------------------------------------
  if(repeat_iter == "TRUE"){
    if(model_iteration == 1){
      load(paste(input_path,"dataworking.RData",sep="/"))
    }else{
      load(paste(group_path,"bygroupdata.RData",sep="/"))
      dataworking = bygroupdata
      rm("bygroupdata")
    }
    
    if(flag_bygrp_update == "true")
    {
      if(file.exists(paste(group_path,"bygroupdata.RData",sep="/"))){
        load(paste(group_path,"bygroupdata.RData",sep="/"))
        bygroup = bygroupdata
        rm("bygroupdata")
        load(paste(input_path,"dataworking.RData",sep="/"))
        datawork = dataworking
        rm("dataworking")
        dataworking<-merge(bygroup,datawork,all.x=TRUE,by="primary_key_1644")
        col<-colnames(dataworking)
        newcol<-col[-c(which(grepl("\\.y",col)))]
        dataworking<-dataworking[newcol]
        newcol<-gsub("\\.x","",newcol)
        colnames(dataworking)<-newcol
        #   write.csv(dataworking,paste(group_path,"bygroupdata.csv",sep="/"))
        bygroupdata <- dataworking
        save(bygroupdata, file = paste(group_path,"bygroupdata.RData", sep="/"))
        rm("bygroupdata")
        rm("bygroup")
        rm("datawork")
      }else{
        bygroupdata <- dataworking
        save(bygroupdata, file = paste(group_path,"bygroupdata.RData", sep="/"))
        rm("bygroupdata")
      }
    }
    
    #subset on group---------------------------------------------------------------------
    
    if (as.integer(grp_no)!= 0){
      temp_var=paste("grp",grp_no,"_flag",sep="")
      
      index<-which(names(dataworking)==temp_var)
      dataworking<-subset(dataworking,dataworking[index]==grp_flag)
    }  
    dataworking$actual<-0
    dataworking$actual<-dataworking[,dependent_variable]
    # write.csv(dataworking,paste(group_path,"bygroupdata.csv",sep="/"))
    bygroupdata <- dataworking
    save(bygroupdata, file = paste(group_path,"bygroupdata.RData", sep="/"))
    rm("bygroupdata")
    
    #subset on validation----------------------------------------------------------------
    
    if(validation_var != ""){
      col_num<-which(names(dataworking)==validation_var)
      dataworking<-dataworking[which(dataworking[col_num]==1),]
    }
    #outlier_scenario-----------------------------------------------------------------------
    if(outlier_var != ""){
      col_num<-which(names(dataworking)==outlier_var)
      dataworking<-dataworking[which(dataworking[col_num]==1),]
    }
    independent_variables<-as.character(independent_variables)
    data<-dataworking[c("actual",dependent_variable,independent_variables,"primary_key_1644")]
    rm("dataworking")
    
    missing_count<-as.data.frame(apply(data[independent_variables],2,function(x){length(which(is.na(x) | x==""))}))
    missing_perc<-as.data.frame((missing_count/nrow(data))*100)
    appData_missing<-cbind.data.frame(independent_variables,missing_count,missing_perc)
    colnames(appData_missing)<-c("variable","nmiss","miss_per")
    write.csv(appData_missing,file=paste(out_path,"appData_missing.csv",sep="/"),quote=FALSE,row.names=FALSE)
    
    
    variable<-colnames(data)
    
    if(length(which(is.na(data)==TRUE))){
      index<-which(is.na(data)==TRUE)%%nrow(data)
      if(length(which(index == 0))){index[c(which(index == 0))]=nrow(data)}
      data<-data[-c(index),]
    }
    
    #   checking for number of rows
    if(nrow(data) < length(independent_variables))
    {
      errorText <- "Number of rows are too less to perform algorithmic linear regression"
      write(errorText,file=paste(output_path,"/error.txt",sep=""),append=T)
      
    }
    
    #formula creation for model---------------------------------------------------------------
    
    #Checking if length of independent variable variable is equal to or more than 1; If not stoping the process
    #----------------------------------------------------------------------------------------------------------
    if(length(independent_variables)==0){
      errorText <- "No independent variable(s) to build model; Possibly all the variables are eliminated. Please recheck the condition and try again"
      write(errorText,file=paste(output_path,"/error.txt",sep=""),append=T)
      
    }
    
    
    if(no_intercept_model=="true")
    {
      formulaobj=paste(dependent_variable,"~",paste("0",paste(independent_variables,collapse="+"),sep="+"))
    }else{formulaobj=paste(dependent_variable,"~",paste(independent_variables,collapse="+"))
    }
    
    #linear regression-------------------------------------------------------------------------
    lmobj <- lm(formulaobj,data=data)
    
    
    #Variable summary---------------------------------------------------------------------------
    
    freq<-rep(summary(lmobj)$df[2],ncol(data))
    Mean=round(apply(data.matrix(data),2,mean),4)
    Min=round(apply(data.matrix(data),2,min),4)
    Max=round(apply(data.matrix(data),2,max),4)
    StdDev=round(apply(data.matrix(data),2,sd),4)
    variablesummary<-as.data.frame(cbind(variable,freq,Mean,Min,Max,StdDev))
    colnames(variablesummary)[1:2]<-c("Variable","Freq")
    
    primaryKey_index = match(x="primary_key_1644",table=colnames(data))
    
    if(!is.na(primaryKey_index)){
      variablesummary=variablesummary[-primaryKey_index,]
    }
    #Parameter_estimates---------------------------------------------------------------------------
    lmtable<-coef(summary(lmobj))
    independent_variables2<-independent_variables
    vif1<-data.frame(rep("NA",nrow(lmtable)))
    if(length(which(is.na(coefficients(lmobj)))) == 0)
    {
      try(vif1<-vif(lmobj),silent=TRUE)
    }else{
      
      independent_variables2<-row.names(lmtable)
      if(no_intercept_model != "true"){
        try(independent_variables2 <- independent_variables2[-which(independent_variables2 %in% c("(Intercept)"))],silent=TRUE)
      }
      #formula creation for model---------------------------------------------------------------
      if(no_intercept_model=="true"){
        formulaobj=paste(dependent_variable,"~",paste("0",paste(independent_variables2,collapse="+"),sep="+"))
      }else{
        #independent_variables2<-independent_variables2[-1]
        formulaobj=paste(dependent_variable,"~",paste(independent_variables2,collapse="+"))
      }
      
      #linear regression-------------------------------------------------------------------------
      lmobj2 <- lm(formulaobj,data=data)
      vif1<-vif(lmobj2)
    }
    
    #-------------------------stdest----------------------
    
    modelVar = c(dependent_variable,independent_variables2)
    summaryResult=apply(data[modelVar],2,sd)
    sdDF = summaryResult
    sd_variables= sdDF
    
    std_estimates =function (estimates,sd) 
    {
      if(no_intercept_model == "false")
      {
        b <- estimates[-1]
      }else{
        b <- estimates}
      sx <- sd[-1]
      sy <- sd[1]
      beta <- b * sx/sy
      return(beta)
    }
    
    if(length(which(is.na(lmobj$coefficients)))){
      coeffstd <- lmobj$coefficients[-which(is.na(lmobj$coefficients))]
    }else{
      coeffstd <- lmobj$coefficients
    }
    stdest<-try(std_estimates(estimates=coeffstd ,sd =sd_variables),silent=T)
    if(class(stdest) == "try-error")
    {
      stdest<-std_estimates(estimates=lmobj2$coefficients ,sd =sd_variables)
    }
    if(no_intercept_model == "false")
    {
      stdest<-c(0,stdest)
    }
    
    
    #----------------------------------------------------------------------------
    fdummy<-summary(lmobj)$fstatistic
    hetroskedasticityPvalue<-as.data.frame(rep(pf(fdummy[1],fdummy[2],fdummy[3],lower.tail=TRUE),nrow(lmtable)))
    Model<-rep(paste("MODEL","1",sep=""),nrow(lmtable))
    Dependent<-rep(dependent_variable,nrow(lmtable))
    DF<-rep(model_iteration,nrow(lmtable))
    #------------------------------------------------------
    if(no_intercept_model=="false")
    {
      vif1<-c("0",vif1)
    }
    
    
    paramest<-as.data.frame(cbind(Model,Dependent,row.names(lmtable),DF,lmtable,stdest,vif1,hetroskedasticityPvalue))
    colnames(paramest)<-c("Model","Dependent","Original_Variable","DF","Original_Estimate","Original_StdErr","Original_tValue","Original_Probt","Original_StandardizedEst","Original_VarianceInflation","Heteroskedastic_P_Value")
    
    #ActualsVsPredicted-------------------------------------------------------------------------------------
    
    actual<-as.data.frame(lmobj$mode[1])
    residuals<-as.data.frame(round(residuals(lmobj),4))
    predicted<-as.data.frame(round(fitted(lmobj),4))
    std_pred<-scale(predicted[,1])
    leverage<-((std_pred^2) + 1)/nrow(predicted)
    actvspred<-cbind.data.frame(actual,predicted,residuals,leverage)
    colnames(actvspred)<-c("actual","pred","res","leverage")
    
    #Modelstats---------------------------------------------------------------------------------------
    
    #-- #~!@# #4694,NEW,Modelling,Linear,25feb2013,1354
    variables_used<-ncol(data)-3 #Subtracting 1, cos the data has the dependent variable also
    #-- #~!@# #4694,NEW,Modelling,Linear,25feb2013,1354
    observations_used<-nrow(data)
    #---------------------MAPE--------------------------
    calcMape = function(actual, predicted) 
    {    #Removing NA and zero values from the actual vector 
      
      index = (1:nrow(actual))[!is.na(actual)] 
      index = index[actual[index,1] != 0] 
      actual = actual[index,1] 
      predicted = predicted[index,1] 
      mape = mean(abs((actual - predicted)/actual))*100 
      return(mape) 
    }
    mape<-calcMape(actual,predicted)
    #-----------------------------------------------------
    rsquare<-summary(lmobj)$r.squared
    adjrsq<-summary(lmobj)$adj.r.squared
    aic<-AIC(lmobj)
    dependentmean<-mean(data[dependent_variable])
    rmserror<-summary(lmobj)$sigma
    fdummy<-summary(lmobj)$fstatistic
    fvalue<-summary(lmobj)$fstatistic[1]
    dwstatistic<-try(as.numeric(dwtest(lmobj)[1]))
    if(class(dwstatistic) == "try-error")
    {
      dwstatistic<-'NA'
    }
    firstordercorrelation<-c("0")
    pvaluemodel<-pf(fdummy[1],fdummy[2],fdummy[3],lower.tail=FALSE)
    heteroskedastic_pvalue<-pf(fdummy[1],fdummy[2],fdummy[3],lower.tail=TRUE)
    modelstats<-cbind(variables_used,observations_used,rsquare,aic,adjrsq,dwstatistic,firstordercorrelation,dependentmean,rmserror,pvaluemodel,fvalue,mape,heteroskedastic_pvalue)
    
    #outdata-------------------------------------------------------------------------------
    avp<-actvspred
    colnames(avp)<-c(paste(dependent_variable,"1",sep=""),"pred","res","leverage")
    avp$modres<-abs(avp$res)
    avp$mapeindi<-(avp[,5]/avp[,1])*100
    outdata<-cbind.data.frame(data,avp)
    
    
    
    #----------------out_betas---------------------------------------------------------------
    
    out_betas<-NULL
    MODEL<-rep(paste("MODEL","1",sep=""),6)
    TYPE<-c("PARMS","STDERR","T","PVALUE","L95B","U95B")
    DEPVAR<-rep(dependent_variable,6)
    RMSE<-rep(summary(lmobj)$sigma,6)
    lmtablet<-t(lmtable)
    L95B<-lmtablet[1,]-(2*lmtablet[2,])
    U95B<-lmtablet[1,]+(2*lmtablet[2,])
    lmtablet<-rbind(lmtablet,L95B,U95B)
    coldv<-c(dependent_variable,"","","","","")
    IN<-c(length(independent_variables),"","","","","")
    P<-c(length(independent_variables)+1,"","","","","")
    EDF<-c(summary(lmobj)$df[2],"","","","","")
    RSQ<-c(summary(lmobj)$adj.r.squared,"","","","","")
    AIC<-c(AIC(lmobj),"","","","","")
    out_betas<-cbind(MODEL,TYPE,DEPVAR,RMSE,lmtablet,L95B,U95B,coldv,IN,P,EDF,RSQ,AIC)
    colnames(out_betas)[which(colnames(out_betas)=="(Intercept)")]<-"Intercept"
    colnames(out_betas)[which(colnames(out_betas)=="coldv")]<-dependent_variable
    
    
    #******************jobs creation *******************************************************#
    
    VAR_REMOVED<-remove_var
    START_ITERATION<-start_iteration
    MODEL_ITERATION<-current_iter 
    VARIABLES_USED<-length(independent_variables)
    OBSERVATIONS_USED<-nrow(data)  
    RSQUARE<-rsquare  
    MAPE<-mape
    ADJRSQ<-adjrsq
    AIC<-aic
    
    temp<-cbind(VAR_REMOVED,START_ITERATION,MODEL_ITERATION,VARIABLES_USED,OBSERVATIONS_USED,RSQUARE,MAPE,ADJRSQ,AIC)  
    jobs<-rbind(jobs,temp)  
    
    
    
    #writing the CSV and XML----------------------------------------------------------------#
    
    #-------------modelstats---------------------------------------------------------------
    write.csv(modelstats,file=paste(out_path,"stats.csv",sep="/"),quote=FALSE,row.names=FALSE)
    #------------------------actual vs predicted----------------------------------------------
    
    write.csv(actvspred,file=paste(out_path,"normal_chart.csv",sep="/"),quote=FALSE,row.names=FALSE)
    #     actvspred1<-cbind.data.frame(data[dependent_variable],actvspred)    
    #----------------------parameter estimates---------------------------------------------
    if(no_intercept_model=="false")
    { 
      paramest$Original_Variable<-as.character(paramest$Original_Variable)
      paramest[1,"Original_Variable"]<-"Intercept"
    }
    write.csv(paramest,file=paste(out_path,"estimates.csv",sep="/"),quote=FALSE,row.names=FALSE)
    
    #-------------------------variable summary------------------------------------------------
    if(var_summary=='true'){
      write.csv(variablesummary,file=paste(out_path,"var_summary.csv",sep="/"),quote=FALSE,row.names=FALSE)
    }
    
    #-------------------------------------------------------------------------
    # Creating the model equation
    #-------------------------------------------------------------------------
    formatEquation=function(x)
    {
      if (x > 0.09)
      {
        return (round(x,2))
      } else {
        return (format(x,scientific=T,digits=3))
      }
    }
    
    equation <- paste(dependent_variable,"=")
    for(tempi in 1:nrow(paramest)){
      equation <- paste(equation," + (",formatEquation(paramest[tempi,"Original_Estimate"]),")",paramest[tempi,"Original_Variable"],sep="")
    }
    equation <- gsub(pattern="= +",replacement="=",x=equation,fixed=T)
    equation <- gsub(pattern="+ (-",replacement="- (",x=equation,fixed=T)
    # Writing the equation as a txt
    write(equation,paste(out_path,"MANUAL_REGRESSION_EQUATION.txt",sep="/"))
    
    #------------------------outdata-----------------------------------------------------------
    write.csv(outdata,file=paste(out_path,"outdata.csv",sep="/"),quote=FALSE)
    #----------------------------------------------------------------------------------------
    
    #------------------------out_betas-----------------------------------------------------------
    write.csv(out_betas,file=paste(out_path,"out_betas.csv",sep="/"),quote=FALSE,row.names=FALSE)
    #----------------------------------------------------------------------------------------
    
    #-----------------------saving the linear model object---------------------------------
    
    write.table("Manual Regression",paste(out_path,"MANUAL_REGRESSION_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)
    #   write.table("ALGORITHMIC_REGRESSION_EQUATION",paste(out_path,"ALGORITHMIC_REGRESSION_EQUATION.txt",sep="/"),quote=F,row.names=F,col.names=F)
    current_iter<-as.numeric(current_iter)+1
    
    print(equation)
  }
}

write.csv(jobs,file=paste(initial_path,"jobs.csv",sep="/"),quote=FALSE,row.names=FALSE)

write.table("ALGORITHMIC_REGRESSION_COMPLETED",paste(initial_path,"ALGORITHMIC_REGRESSION_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)