#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : MRx_arimax_obj_Modeling.R                         
#-- Description  : Performs arimax_obj Modeling      
#-- Return type  : csv              
#-- Author : Subarna Rana
#------------------------------------------------------------------------------------------------------#

#libraries Required.
library(car)
library(ggplot2)
library(graphics)






# Reading Data-----------------------------------------------------------------------------------------#
if(model_iteration == 1){
  load(paste(input_path,"/dataworking.RData",sep=""))
}else{
  load(paste(group_path,"/bygroupdata.RData",sep=""))
  dataworking <- bygroupdata
  rm("bygroupdata")
}
if(flag_bygrp_update == "true" & model_iteration != '1')
{
  load(paste(group_path,"/bygroupdata.RData",sep=""))
  load(paste(input_path,"/dataworking.RData",sep=""))
  dataworking<-merge(bygroupdata,dataworking,all.x=TRUE,by="primary_key_1644")
  col<-colnames(dataworking)
  newcol<-col[-c(which(grepl("\\.y",col)))]
  dataworking<-dataworking[newcol]
  newcol<-gsub("\\.x","",newcol)
  colnames(dataworking)<-newcol
}

#subset on group-----------------------------------------------------------------------------------#
if (as.integer(grp_no)!= 0)
{
  temp_var=paste("grp",grp_no,"_flag",sep="")
  index<-which(names(dataworking) == temp_var)
  dataworking<-subset(dataworking,dataworking[index] == grp_flag) 
}
bygroupdata <- dataworking
save(bygroupdata,file=paste(group_path,"/bygroupdata.RData",sep=""))
rm("bygroupdata")

#subset on treatment process---------------------------------------------------------------------------#
if (as.integer(grp_no)!= 0)
{
  temp_var=paste("grp",grp_no,"_flag",sep="") 
  index<-which(names(dataworking)==temp_var)
  dataworking<-subset(dataworking,dataworking[index]==grp_flag)
}  

if(validation_var != "")
{
  if (type_arimax=="build")
  {
    col_num<-which(names(dataworking)==validation_var)
    dataworking<-dataworking[which(dataworking[col_num]==1),]
  }
  if (type_arimax=="validation")
  {
    col_num<-which(names(dataworking)==validation_var)
    dataworking<-dataworking[c(which(dataworking[col_num]==0)),]
  }
}


# **************************sorting the data according to the date*******************************

date_data<-dataworking[,id_variable]
index12<-order(date_data)
dataworking<-dataworking[index12,]


# Creating output file num.csv-----------------------------------------------------------------------#
num_csv = as.data.frame(nrow(dataworking))
names(num_csv) = c("_FREQ_")

write.csv(num_csv,paste(output_path,"num_obs.csv",sep="/"), quote=F, row.names = F)

if(nrow(dataworking) <= 24)
{
  msg = paste("Not enough observations in the " , type_arimax, "sample. Modeling not possible.")
  write(msg, file = paste(output_path,"Check.txt", sep="/"))
  write("ARIMAX_NOT_COMPLETED", file = paste(output_path,"ARIMAX_NOT_COMPLETED.TXT", sep="/"))
  stop(msg,call.=T)
}
write.csv(num_csv,paste(output_path,"num_obs.csv",sep="/"), quote=F, row.names = F)

# Case: Only VIF------------------------------------------------------------------------- 
if (flag_only_vif == "true")
{
  formulaobj = paste(dependent_variable,"~",paste(estimate_variables,collapse="+"))
  lmobj = lm(formulaobj,data=dataworking, singular.ok=TRUE)
  if(length(estimate_variables) == 1)
  {
    VIF = 1
  }else 
  {
    VIF = vif(lmobj)
  }      
  rm(lmobj)
  rm(formulaobj)
  Variable = c(estimate_variables )
  Only_vif = cbind.data.frame(Variable,VIF)  
  write.csv(Only_vif,paste(output_path,"ParameterEstimates.csv",sep="/"),quote=F, row.names = F)
  write("ARIMAX_COMPLETED", file = paste(output_path,"ARIMAX_COMPLETED.TXT", sep="/"))
 # q(save = "default")
}

# Extracting dependent variable--------------------------------------------------------

if(is.null(estimate_variables)){
  dep_var = as.data.frame(dataworking[,(which(colnames(dataworking) == dependent_variable))])
  actual = dataworking[1:(nrow(dataworking)),(which(colnames(dataworking) == dependent_variable))]
}else{
  if(as.numeric(value_lead) > nrow(dataworking)){
    write("Forecasting not possible.Lead entered exceed number of observations available for modeling.", file = paste(output_path,"Check.txt", sep="/"))
    msg = "Forecasting not possible.Lead entered exceed number of observations available for modeling."
    write("ARIMAX_NOT_COMPLETED", file = paste(output_path,"ARIMAX_NOT_COMPLETED.TXT", sep="/"))
    stop(msg,call.=T)
  }
  dep_var = as.data.frame(dataworking[1:(nrow(dataworking) - as.numeric(value_lead)),(which(colnames(dataworking) == dependent_variable))])
  actual = as.data.frame(dataworking[,(which(colnames(dataworking) == dependent_variable))])
}

# Extracting estimate variables---------------------------------------------------------
if(!is.null(estimate_variables))
{
  for(i in 1:length(estimate_variables))
  {
    if(i == 1)
    {
      var_estimate = as.data.frame(dataworking[,which(colnames(dataworking) == estimate_variables[i])])
      colnames(var_estimate)[ncol(var_estimate)] = estimate_variables[i]
    }else
    {
      var_estimate = cbind.data.frame(dataworking[,which(colnames(dataworking) == estimate_variables[i])],var_estimate)
      colnames(var_estimate)[1] = estimate_variables[i]
    }
  }
# colnames(var_estimate) = estimate_variables
  var_estimate_arma = as.data.frame(var_estimate[1:(nrow(var_estimate) - as.numeric(value_lead)),])
  var_estimate_fore = as.data.frame(var_estimate[(nrow(var_estimate) - as.numeric(value_lead) + 1):nrow(var_estimate),])
  }


# Extracting Date variable---------------------------------------------------------------
var_date = as.data.frame(dataworking[,which(colnames(dataworking) == id_variable)])

roundoff <- function(object){
  object = signif(as.numeric(object), digits = 4)
  return (object)
}

# Jumping to arimax_obj------------------------------------------------------------------------
if(flag_run_arimax == "true")
{     
  ## Creating differenced dependent var  
  if(flag_order_differencing == "true" )
  {
    diff_dep_var = diff(as.ts(dep_var), differences = as.numeric(value_order_differencing))
  }else
  {
    diff_dep_var = dep_var
  }
  if(flag_period_differencing == "true")
  {
    diff_dep_var = diff(as.ts(diff_dep_var), differences = as.numeric(value_period_differencing))
  }
  
  ## Creating ACF.csv----------------------------------------------------------------
  val_acf = acf(diff_dep_var, na.action = na.pass, lag.max = as.numeric(value_nlag), plot = FALSE)
  val_cov = acf(diff_dep_var, na.action = na.pass, demean = TRUE, lag.max = as.numeric(value_nlag), plot = FALSE, type = "covariance")
  Lag = val_acf$lag
  Correlation = val_acf$acf
  Covariance = val_cov$acf
  Variable = rep(dependent_variable,length(Lag))
  StandardError = as.data.frame(apply(Correlation, 1, function(x) qnorm(0.975)*x/sqrt(as.numeric(value_nlag))))
  colnames(StandardError) = "StandardError"
  AutoCorrGraph = cbind.data.frame(Variable, Lag, Covariance, Correlation,StandardError)
  write.csv(AutoCorrGraph,paste(output_path,"AutoCorrGraph.csv",sep="/"),quote=F, row.names = F)

  ## Creating PartialAutoCorrGraph.csv----------------------------------------------------------------
  val_acf = acf(diff_dep_var, na.action = na.pass, demean = TRUE, lag.max = as.numeric(value_nlag), plot = FALSE, type = "partial")
  Correlation = val_acf$acf
  Lag = as.vector(val_acf$lag)
  Variable = rep(dependent_variable,length(Lag))
  Autocorr = rep('PartialAutoCorrelation',length(Lag))
  AutoCorrGraph = cbind.data.frame(Variable, Lag, Correlation,Autocorr)
  write.csv(AutoCorrGraph,paste(output_path,"PartialAutoCorrGraph.csv",sep="/"),quote=F, row.names = F)
  rm(list = c('val_acf','val_cov','Lag','Correlation','Covariance','Variable','StandardError','AutoCorrGraph','Autocorr'))
    
  # Creating CrossCorrGraph.csv------------------------------------------------------- 
  if(!is.null(crossCorr_variables))
  {
    for(i in 1:length(crossCorr_variables))
    {
      if(i == 1)
      {
        var_crossCorr = as.data.frame(dataworking[,which(colnames(dataworking) == crossCorr_variables[i])])
        
      }else
      {
        var_crossCorr = cbind.data.frame(dataworking[,which(colnames(dataworking) == crossCorr_variables[i])],var_crossCorr)
      }
      val_ccf = ccf(as.vector(diff_dep_var), var_crossCorr[i],type = "correlation", na.action = na.pass, lag.max = as.numeric(value_nlag), plot = FALSE)
      val_cov_ccf = ccf(as.vector(diff_dep_var), var_crossCorr[i],type = "covariance", na.action = na.pass, lag.max = as.numeric(value_nlag), plot = FALSE)
      Lag = val_ccf$lag
      Correlation = val_ccf$acf
      Covariance = val_cov_ccf$acf
      Variable = rep(crossCorr_variables[i],length(Lag))
      tmp = cbind.data.frame(Variable, Lag,Covariance, Correlation)
      if(i==1)
      {
        CrossCorrGraph = tmp
      }else
      {
        CrossCorrGraph = rbind(CrossCorrGraph,tmp)
      }
    }
    write.csv(CrossCorrGraph,paste(output_path,"CrossCorrGraph.csv",sep="/"),quote=F, row.names = F)
    rm(list = c('val_ccf','val_cov_ccf','Lag','Correlation','Covariance','Variable','CrossCorrGraph','tmp'))
  }
    
  ## Creating StationarityTests.csv----------------------------------------------------
  if(stationarity_variable == "DICKEY")
  {
    library(fUnitRoots)
    adflags = 0
    tryadf = try(adfTest(as.ts(diff_dep_var), lags = adflags, type = "nc"), silent = TRUE)
    if(class(tryadf) != "try-error")
    {
      for(adflags in 0:6) 
      {
        tempadf = adfTest(as.ts(diff_dep_var), lags = adflags, type = "nc")
         tempadf = attributes(tempadf)
         rhoVals = as.numeric(tempadf$test$statistic) 
         pval = as.numeric(tempadf$test$p.value)
         tempVal = cbind("Zero Mean",adflags,rhoVals,pval)
         if(adflags == 0)
         {
           adf = tempVal
         }else
         {
           adf = rbind(adf,tempVal)
         }
      }
      for(adflags in 0:6) 
      {
        tempadf = adfTest(as.ts(diff_dep_var), lags = adflags, type = "c")
        tempadf = attributes(tempadf)
        rhoVals = as.numeric(tempadf$test$statistic) 
        pval = as.numeric(tempadf$test$p.value)
        tempVal = cbind("Single Mean",adflags,rhoVals,pval)
        adf = rbind(adf,tempVal)
      }
      for(adflags in 0:6) 
      {
        tempadf = adfTest(as.ts(diff_dep_var), lags = adflags, type = "c")
        tempadf = attributes(tempadf)
        rhoVals = as.numeric(tempadf$test$statistic) 
        pval = as.numeric(tempadf$test$p.value)
        tempVal = cbind("Trend",adflags,rhoVals,pval)
        adf = rbind(adf,tempVal)
      }
      colnames(adf) = c("Type", "Lags", "Tau", "ProbTau")
      adf = as.data.frame(adf)
      write.csv(adf,paste(output_path,"StationarityTests.csv",sep="/"),quote=F, row.names = F)
      rm(list = c('adflags','tempadf','rhoVals','pval','tempVal','adf'))
    }
  }

  # Stating p,q and P,Q values------------------------------------------------------------
  
  p = as.numeric(value_p)
  q = as.numeric(value_q)
  Ps = as.numeric(Seasonality_ar)
  Qs = as.numeric(Seasonality_ma)
  
  #   making the data into a time series object based on date level
  dep_var1<-dep_var
  if(interval_variable == "Week")
  {
    dep_var1<-ts(dep_var,frequency=7)  
  }
  if(interval_variable == "Month")
  {
    dep_var1<-ts(dep_var,frequency=12)  
  }
  if(interval_variable == "Quarter")
  {
    dep_var1<-ts(dep_var,frequency=4)  
  }
  
  # Running ARIMA--------------------------------------------------------------------------
  if(method_variable == "ml")
  {
    method = "ML"
  }else if(method_variable == "cls")
  {
    method = "CSS"
  }else
  {
    method = "CSS-ML"
  }
  if(!is.null(estimate_variables))
  {
    x = try(arima(dep_var1, order = c(p,as.numeric(value_order_differencing),q), transform.pars = F, seasonal = list(order = c(Ps,as.numeric(value_period_differencing), Qs), period = NA),
                  xreg = var_estimate_arma, method = method ), silent = TRUE)
    if(class(x) != "try-error")
    {
      arimax_obj = arima(dep_var1, order = c(p,as.numeric(value_order_differencing),q), transform.pars = F, seasonal = list(order = c(Ps,as.numeric(value_period_differencing), Qs), period = NA),
                         xreg = var_estimate_arma, method = method )
    } else
    {
      write("Pair of indepenent variables have very high correlation leading to Multicollinearity or number of rows are less than number of response variable. Try another model.", file = paste(output_path,"Check.txt", sep="/"))
      write("Pair of indepenent variables have very high correlation leading to Multicollinearity. Try another model.", file = paste(output_path,"ARIMAX_NOT_COMPLETED.txt", sep="/"))
      stop("System is computationally singular. Try another model")
    }
  }else
  {
    x = try(arima(dep_var1, order = c(p,as.numeric(value_order_differencing),q), transform.pars = F, seasonal = list(order = c(Ps,as.numeric(value_period_differencing), Qs), period = NA),
                                 xreg = NULL, method = method ), silent = TRUE)
    
    if(class(x) != "try-error")
    {
      arimax_obj = arima(dep_var1, order = c(p,as.numeric(value_order_differencing),q), transform.pars = F, seasonal = list(order = c(Ps,as.numeric(value_period_differencing), Qs), period = NA),
                         xreg = NULL, method = method )
    }else
    {
      write("Pair of indepenent variables have very high correlation leading to Multicollinearity or number of rows are less than number of response variable. Try another model.", file = paste(output_path,"Check.txt", sep="/"))
      write("ARIMAX_NOT_COMPLETED", file = paste(output_path,"ARIMAX_NOT_COMPLETED.txt", sep="/"))
      stop("System is computationally singular Try another model")
    }
  }
  
  param = as.matrix(arimax_obj$coef)
  param_names = rownames(param)
  parameters = param_names
  param_names[-c(which(param_names %in% estimate_variables))] = dependent_variable
  param_names[c(which(param_names %in% "intercept"))] = dependent_variable
  for(i in 1:value_p){
    ntmp = paste("ar",i,sep = "")
    param_names[c(which(param_names %in% ntmp))] = dependent_variable
  }
  for(i in 1:Seasonality_ar){
    ntmp = paste("sar",i,sep = "")
    param_names[c(which(param_names %in% ntmp))] = dependent_variable
  }
  for(i in 1:Seasonality_ma){
    ntmp = paste("sma",i,sep = "")
    param_names[c(which(param_names %in% ntmp))] = dependent_variable
  }
  for(i in 1:value_q){
    ntmp = paste("ma",i,sep = "")
    param_names[c(which(param_names %in% ntmp))] = dependent_variable
  }
  Estimate = as.data.frame(param[,1])
  StdErr = as.data.frame(sqrt((abs(diag(arimax_obj$var.coef)))))
  parameters = as.vector(as.matrix(parameters))
  PValue = as.data.frame((1-pnorm(abs(arimax_obj$coef)/sqrt(abs(diag(arimax_obj$var.coef)))))*2)
  tValue = as.data.frame(coef(arimax_obj)/sqrt(abs(diag(arimax_obj$var.coef))))
  parameter_estimates = cbind(as.data.frame(param_names), Estimate, StdErr,tValue,PValue,parameters)
  colnames(parameter_estimates) = c("Variable", "Estimate", "StdErr","tValue","PValue","Parameters")    
  
  if(!is.null(estimate_variables))
  {
    if(flag_vif == "true")
    {
      formulaobj = paste(dependent_variable,"~",paste(estimate_variables,collapse="+"))
      lmobj = lm(formulaobj,data=dataworking, singular.ok=TRUE)
      if(length(estimate_variables) == 1)
      {
        VIF = as.data.frame(1) 
        rownames(VIF) = estimate_variables
        colnames(VIF) = "VIF"
      }else 
      {
        VIF = as.data.frame(vif(lmobj))
        colnames(VIF) = "VIF"
      }      
   
      rm(lmobj)
      rm(formulaobj)
      parameter_estimates1 = merge(parameter_estimates,VIF,all=T,by="row.names")
      parameter_estimates = parameter_estimates1[-1]
      colnames(parameter_estimates) = c("Variable", "Estimate", "StdErr","tValue","PValue","Parameters","VIF")    
      parameter_estimates$VIF = roundoff(parameter_estimates$VIF)
    }
  }
  
  parameter_estimates$Estimate = roundoff(parameter_estimates$Estimate) 
  parameter_estimates$StdErr = roundoff(parameter_estimates$StdErr) 
  parameter_estimates$tValue = roundoff(parameter_estimates$tValue) 
  parameter_estimates$PValue = roundoff(parameter_estimates$PValue)
  
  write.csv(parameter_estimates,paste(output_path,"ParameterEstimates.csv",sep="/"),quote=F, row.names = F)
  rm(list = c('param','param_names','parameters','Estimate','StdErr','PValue','tValue'))
  
  ## Creating Model Stats-------------------------------------------------------------------
  Statistic = "AIC"
  Value = arimax_obj$aic
  modelstats = cbind(Statistic,Value)
  Statistic = "Conv" 
  Value = arimax_obj$code
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "LogLikelihood"
  Value = arimax_obj$loglik
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "MLE of the innovations variance"
  Value = arimax_obj$sigma2
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "MAPE"
  Value = (colSums((abs(as.numeric(arimax_obj$residuals)/dep_var)), na.rm = TRUE))/nrow(dep_var)
  names(Value) = NULL
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Mean of working series"
  Value = colMeans(dep_var,na.rm=TRUE)
  names(Value) = NULL 
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "NPARMS"
  Value = length(parameter_estimates$Estimate)
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Number of Observations"
  Value = nrow(dep_var)
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Number of Residuals"
  Value = length(arimax_obj$residuals)
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of AR"
  Value = value_p 
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of MA"
  Value = value_q 
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of Seasonal AR"
  Value = Seasonality_ar
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of Seasonal MA"
  Value = Seasonality_ma
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of Differencing"
  Value = value_order_differencing
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  Statistic = "Order of Seasonal Differencing"
  Value = value_period_differencing
  tmp = cbind(Statistic,Value)
  modelstats = rbind(modelstats, tmp)
  write.csv(modelstats,paste(output_path,"Model_Statistics.csv",sep="/"),quote=F, row.names = F)
  rm(list = c('Statistic','Value','tmp','modelstats','parameter_estimates'))
  
  ## Creating CorrelationofParameterEstimates.csv---------------------------------------------
  param_corr = as.data.frame(cov2cor(vcov(arimax_obj)))
  write.csv(param_corr,paste(output_path,"CorrelationofParameterEstimates.csv",sep="/"),quote=F, row.names = T)
  rm(list = c('param_corr'))
  
  ## Creating Forecast.csv---------------------------------------------------------------

  if(value_lead != '0')
  {
    if(!is.null(estimate_variables))
    {
      fore = as.data.frame(predict(arimax_obj,newxreg = var_estimate_fore,  n.ahead = value_lead,  se.fit = T))    
    }else
    {
      fore = as.data.frame(predict(arimax_obj,newxreg=NULL, n.ahead = value_lead ,se.fit = T))
    }
    colnames(fore) = c("pred","se")
    class(fore$pred) = "numeric"
    class(fore$se) = "numeric"
  }
  
  pred = data.frame(dep_var[,1] - as.numeric(arimax_obj$residuals))
  colnames(pred) = "pred"
  se = apply(pred, 1, function(x) qnorm(0.95)*x/sqrt(nrow(pred)))
  pred = cbind.data.frame(pred,as.data.frame(se))
  if(value_lead != 0)
  {
    forech = rbind(pred,fore)
  }else
  {
    forech = pred
  }
  lowerconf = as.data.frame(as.numeric(forech$pred) - 1.96*as.numeric(forech$se))
  highconf = as.data.frame(as.numeric(forech$pred) + 1.96*as.numeric(forech$se))
  res = as.vector(arimax_obj$residuals)
  if(is.null(estimate_variables)){
    if(value_lead != 0){
      fred <- as.data.frame( paste("Forecast",1:value_lead))
      colnames(fred) = colnames(var_date)[1]
      var_date = rbind(var_date, as.data.frame(fred))
      actt = as.vector(rep(NA,as.numeric(value_lead)))
      actual = as.vector(actual)
      actual = as.data.frame(c(actual,actt))
      ress = rep(NA,as.numeric(value_lead))
      res = as.data.frame(c(res,ress))
    } 
  }else{
    res = as.data.frame(actual - forech$pred)
  }
  forecast = cbind(var_date, as.data.frame(actual), as.data.frame(forech$pred), as.data.frame(forech$se), lowerconf, highconf, as.data.frame(res))
  colnames(forecast) = c(id_variable,"Actual","FORECAST", "STD","L95", "U95", "RESIDUAL")
  #arun's Edit: To remove NAs 
  #---------------------------
  ind = which(is.na(forecast$FORECAST)==TRUE)
  
  if(length(ind)>0){
    forecast = forecast[-ind,]
  }
  #---------------------------
  forecast<-merge(forecast,dataworking[c(id_variable,"primary_key_1644")],by=id_variable,all.x=T)
  
  
  date_data<-forecast[,id_variable]
  index12<-order(date_data)
  forecast<-forecast[index12,]
  
  write.csv(forecast,paste(output_path,"Forecast_Values.csv",sep="/"),quote=F, row.names = F)
  
  ## Creating AutoCorrelationCheckofResidual.csv------------------------------------------
  xax = acf(res, lag.max = 24, type = c("correlation"), plot = F, na.action = na.pass)
  
 if(as.numeric(value_p) + as.numeric(value_q) <= 6){
    fit = as.numeric(value_p) + as.numeric(value_q)
  }else{
    fit = 2
  }
          
  for(boxlags in 1:4)
  {
    tempBox=Box.test(res,lag=(6*boxlags), type = c("Ljung-Box"), fitdf = fit)
    chiSqVal=as.numeric(tempBox$statistic)
    DF=as.numeric(tempBox$parameter)
    pval=as.numeric(tempBox$p.value)
    tempVal=cbind(6*boxlags,chiSqVal,DF,pval)
    if(boxlags == 1)
    {
      boxValues = tempVal
    }else
    {
      boxValues=rbind(boxValues,tempVal)  
    }
  }
  
  One = as.data.frame(rbind(xax$acf[1],xax$acf[7],xax$acf[13],xax$acf[19]))
  Two = as.data.frame(rbind(xax$acf[2],xax$acf[8],xax$acf[14],xax$acf[20]))
  Three = as.data.frame(rbind(xax$acf[3],xax$acf[9],xax$acf[15],xax$acf[21]))
  Four = as.data.frame(rbind(xax$acf[4],xax$acf[10],xax$acf[16],xax$acf[22]))
  Five = as.data.frame(rbind(xax$acf[5],xax$acf[11],xax$acf[17],xax$acf[23]))
  Six = as.data.frame(rbind(xax$acf[6],xax$acf[12],xax$acf[18],xax$acf[24]))
  boxValues = cbind(boxValues, One, Two, Three, Four, Five, Six)
  colnames(boxValues) = c("ToLags", "ChiSquare", "DF", "ProbChiSq", "One", "Two", "Three", "Four", "Five", "Six")
  write.csv(boxValues,paste(output_path,"AutoCorrelationCheckofResidual.csv",sep="/"),quote=F, row.names = F)
  
}
if(nrow(forecast) > 6000){
plotnew<-function(x,y,name,ylab1,xlab1){
  png(filename = paste(output_path,"/",name,".png",sep=""),
      width = 1000, height = 480, units = "px", pointsize = 12)
  plot(x,y,col="orange",xlab=xlab1,ylab=ylab1)
  abline(lm(y~x))
  dev.off()
}

plotnew(forecast$Actual,forecast$FORECAST,"PredictedvsActual","Predicted","Actual")
plotnew(forecast$RESIDUAL,forecast$FORECAST,"PredictedvsResidual","Predicted","Residual")
plotnew(forecast$Actual,forecast$RESIDUAL,"ResidualvsActual","Residual","Actual")

plotnew2<-function(x,y,z,name,ylab1){
  png(filename = paste(output_path,"/",name,".png",sep=""),
      width = 1000, height = 480, units = "px", pointsize = 12)
  plot(y ,col="orange",type="l",ylab=ylab1)
  points(z,type="l",col = "green")
  dev.off()
}
plotnew2(x=forecast[,id_variable],y=forecast$Actual,z=forecast$FORECAST,name="ActualAndForecast","Actual and Predicted")
}
#writing the completed text at the output location
#-----------------------------------------------------------------
write("ARIMAX_COMPLETED", file = paste(output_path,"ARIMAX_COMPLETED.txt", sep="/"))


