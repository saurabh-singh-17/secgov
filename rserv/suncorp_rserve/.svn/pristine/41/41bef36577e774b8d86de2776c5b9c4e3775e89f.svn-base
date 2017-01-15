#------------------------------------------------------------------------------------------------------#
# Last Edited By: #~!@#4493,new,eda,univariate,vasanth,08feb13,1723                                  --#
#------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_UnivariateAnalysis_AcrossGroupBy_1.0                                                --#
#-- Descrption  :  Generates Univariate Summary                                                 --#
#-- Return type  : Creates summary  of the variables selected                                                                                   --#
#-- Author       : Jeevitha Gajendran                                                                 --#                 
#------------------------------------------------------------------------------------------------------#
if (file.exists(paste(output_path, "UNIVARIATE_ACROSSGRPBY_COMPLETED.txt", sep="/"))){
  file.remove(paste(output_path, "UNIVARIATE_ACROSSGRPBY_COMPLETED.txt", sep="/"))
}

if (file.exists(paste(output_path, "error.txt", sep="/"))){
  file.remove(paste(output_path, "error.txt", sep="/"))
}
library(moments)
library(modeest)
library(XML)
library(tseries)


#==========================================================================
#Univariate summary function
#========================================================================== 
univariateSummary<-function(data)
{
  uni<-NULL
  univarvector<-NULL      
  subset.data<-data
  mean<-mean(subset.data,na.rm=T)
  stddev<-sd(subset.data,na.rm=T)
  max<-max(subset.data,na.rm=T)
  min<-min(subset.data,na.rm=T)
  median<-median(subset.data,na.rm=T)
  range<-max-min
  observations_used<-length(data)
  iqr<-IQR(x = subset.data, na.rm = TRUE) 
  number_of_missing<-sum(is.na(subset.data))
  uc <- sapply(subset.data,quantile,0.75,na.rm=TRUE) + (1.5 *(sapply(subset.data,IQR, na.rm=TRUE)))
  lc<-sapply(subset.data,quantile,0.25,na.rm=TRUE)-(1.5*(sapply(subset.data,IQR, na.rm=TRUE)))
  noofoutliers<-length(which(subset.data > uc | subset.data < lc))
  no_of_zeros=length(which(data==0))
  mode<-(mlv(data, method = "mfv", na.rm = TRUE))$M    
  result<-data.frame(c(mean,stddev,max,min,median,range,observations_used,iqr,number_of_missing,noofoutliers,no_of_zeros,mode[1]))
  names(result)="estimate"
  statistic=c("mean","stddev","max","min","median","range","observations_used","iqr","number_of_missing","no_of_outliers","no_of_zeros","mode")
  result<-cbind.data.frame(statistic,result)
  result<-result[order(result$statistic),]
  return(result)
} 


#==========================================================================
#Standard error
#========================================================================== 

#std Error for acf and pacf
standardError<-function(x,n)
{
  len=length(x)
  stdResult<-NULL
  if(len<=1)
  {
    return(0)
  }
  for(iterator in 1:len)
  {
    temp=c(1:iterator)
    tempSqr=sqrt(sum(temp*temp) + 1)/n
    stdResult=c(stdResult,tempSqr)
  }
  #result<-c(result,length(result))
  return(stdResult)
}




#==========================================================================
#   Mean
#========================================================================== 
# function to calculate mean & sd percentiles
meanFunction <- function(subset.data) {
  if (length(subset.data) <= 1) {
    ret           <- NULL
  } else {
    percentile    <- seq(from = 5, to = 100, by = 5)
    x_temp        <- quantile(x = subset.data, probs = percentile / 100, na.rm = TRUE)
    FUN           <- function(x) subset.data[which(subset.data <= x)]
    x_temp        <- lapply(X = x_temp, FUN = FUN)
    mean          <- sapply(X = x_temp, FUN = mean, na.rm = TRUE)
    stddev        <- sapply(X = x_temp, FUN = sd, na.rm = TRUE)
    ret           <- data.frame(mean, stddev, percentile, stringsAsFactors = FALSE)
    rownames(ret) <- NULL
  }
  return(ret)
}




#==========================================================================
#Loading the data and flow starts here
#========================================================================== 

load(file = paste(input_path,"/dataworking.RData",sep=""))
inputdata <- dataworking
rm("dataworking")


#==========================================================================
#Error check for entirely missing values
#========================================================================== 
error_var_final <- NULL
n_obs_dataworking <- nrow(inputdata)

for (i in 1:length(var_list)) {
  n_index <- inputdata[, var_list[i]] == ""
  x_temp  <- is.na(inputdata[,var_list[i]])
  n_index <- which(n_index | x_temp)
  n_invalid_obs <- length(n_index)
  
  if (n_invalid_obs == n_obs_dataworking) {
    error_var_final <- c(error_var_final, var_list[i])
  }
}

if (length(error_var_final)){
  error_text <- paste("The variable(s) ", 
                      paste(error_var_final,
                            collapse= ", "),
                      " have all values missing. Please deselect them.",
                      sep="")
  write(error_text, paste(output_path,"/error.txt",sep=""))
  stop(error_text)
}

#-- #~!@#4493,new,eda,univariate,vasanth,08feb13,1723
if(!exists('date_var')){
  date_var<-NULL
}else{
  if(date_var=='') date_var<-NULL
}
#-- #~!@#4493,new,eda,univariate,vasanth,08feb13,1723

var_list<-unlist(strsplit(var_list,split=" "))
newgrp_vars<-unlist(strsplit(grp_vars,split=" "))
univar_subset<-inputdata[c(newgrp_vars,var_list)]
panelCombined<-apply(univar_subset[newgrp_vars],1,function(x){ paste(x,collapse="_")})
uniqPanels=unique(as.character(panelCombined))
inputdata<-cbind(inputdata,panelCombined)
#grp vars csv and xml 
grp_names<-NULL
grp_names["grp_variable"]<-as.data.frame(unique(panelCombined))
write.csv(grp_names,paste(output_path,"unique_grp_var.csv",sep="/"),quote=F,row.names=F)

# sorting the dataset by the date variable
if (!is.null(date_var)) {
  
  inputdata <- inputdata[order(inputdata[, date_var]), ]
}

for(i in 1:length(var_list)){
  
  grp_names1<-as.data.frame(grp_names)
  colnames(grp_names1)<-("NAME")
  write.csv(grp_names1,paste(output_path,var_id[i],"uni_new_vars.csv",sep="/"),row.names=F,quote=F)
  #==========================================================================
  #Summary
  #========================================================================== 
  result<-NULL
  for(j in 1:length(uniqPanels)){      
    data=subset(inputdata,panelCombined==uniqPanels[j])
    res1<- univariateSummary(data[,var_list[i]])
    res1$grp_variable=uniqPanels[j]
    result=rbind.data.frame(result,res1)
  }
  colnames(result)<-c("statistic","value","grp_variable")
  result$value <- sapply(result$value, format, scientific=FALSE)
  csvdata=result[c("grp_variable","statistic","value")]
  
  write.csv(csvdata,paste(output_path,var_id[i],"uni.csv",sep="/"),row.names=F,quote=F)
  uniqueGrpVar <- unique(csvdata$grp_variable)
  basedataset <- matrix(as.character(unique(csvdata$statistic)),ncol=1)
  colnames(basedataset) <- "statistic"
  for(tempa in 1:length(uniqueGrpVar)){
    tempdataset <- csvdata[csvdata$grp_variable==uniqueGrpVar[tempa],c("statistic","value")]
    colnames(tempdataset)[2]<-uniqueGrpVar[tempa]
    basedataset <- merge(x=basedataset,y=tempdataset,by.x="statistic",by.y="statistic")
  }
  write.csv(basedataset,paste(output_path,var_id[i],"uni_new.csv",sep="/"),row.names=F,quote=F)
  write.csv(cbind.data.frame(result[3],result[1],result[2]),paste(output_path,"univarite.csv",sep="/"),row.names=F,quote=F)
  write.csv(result,paste(output_path,var_id[i],"univarite.csv",sep="/"),row.names=F,quote=F)
  
  
  #==========================================================================
  #Box plot function and results
  #========================================================================== 
  if  (flag_box_plot == 'true'){
    
    boxplotfun<-function(subset.data)
    {
      box_mean<-mean(subset.data,na.rm=T)
      p_100<-max(subset.data, na.rm=TRUE)
      p_75<-quantile(subset.data,0.75, na.rm=TRUE)
      p_50<-median(subset.data,na.rm=T)     
      p_25<-quantile(subset.data,0.25, na.rm=TRUE)
      p_0<-min(subset.data,na.rm=T)
      result<-c(box_mean,p_100,p_75,p_50,p_25,p_0)
      return(result)
    }
    
    
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data=subset(inputdata,panelCombined==uniqPanels[j])
      res1<- boxplotfun(data[,var_list[i]])
      result=rbind(result,res1)
    }
    result<-as.data.frame(result)      
    result<-cbind.data.frame(result,uniqPanels)
    names(result)<-c("box_mean","p_100","p_75","p_50","p_25","p_0","grp_variable")
    write.csv(result,paste(output_path,var_id[i],"boxplot.csv",sep="/"),quote=F,row.names=F)
  }
  
  
  #==========================================================================
  #Time series
  #========================================================================== 
  if (flag_timeSeries_plot == "true"){  
    data<-cbind.data.frame(inputdata[,var_list[i]],inputdata[date_var],inputdata["panelCombined"])
    data<-data[order(data["panelCombined"]),]
    result<-data
    colnames(result)<-c(var_list[i],date_var,"grp_variable")
    if (nrow(data) > 5500) {
      for (n in 1:length(grp_names[["grp_variable"]])) {
        x_temp  <- grp_names[["grp_variable"]][n]
        df_temp <- subset(x = result, subset = result[, "grp_variable"] == x_temp)
        x_temp  <- df_temp[,date_var]
        n_temp  <- order(df_temp[,date_var])
        
        png(filename=paste(output_path,
                           "/",
                           var_id[i],
                           "/timeseries",
                           n,
                           ".png",
                           sep=""))
        plot(x=x_temp[n_temp],
             y=df_temp[n_temp,var_list[i]],
             xlab=date_var,
             ylab=var_list[i],
             type="l",
             col="#800000")
        dev.off()
      }
    }
    write.csv(result,paste(output_path,var_id[i],"timeseries.csv",sep="/"),quote=F,row.names=F)
  }  
  
  #==========================================================================
  #Histogram
  #========================================================================== 
  if (flag_histogram == 'true'){
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      histvector<-hist(data[,var_list[i]],plot=F)
      histvector$breaks<-sapply(histvector$breaks,format,scientific=FALSE)
      hist_range<-NULL
      if(length(which(is.finite(unique(univar_subset[,var_list[i]])))) == 1)
      {
        #check for variables having single unique value, so returning the single unique value instead of range
        hist_range <- histvector$breaks[2]
      }else{
        hist_range<-paste(histvector$breaks[1:(length(histvector$breaks)-1)],histvector$breaks[2:length(histvector$breaks)],sep=" - ")
      }
      histdf<-cbind(hist_range,histvector$counts,uniqPanels[j])
      result<-rbind(result,histdf)
    }
    colnames(result)<-c("increment",  "frequency","grp_variable")
    write.csv(result, file=paste(output_path, var_id[i], "histogram.csv", sep="/"), quote=FALSE, row.names=FALSE) 
    
  }
  #==========================================================================
  #Run sequence
  #========================================================================== 
  if (flag_runseq_plot == 'true'){
    
    result<-NULL
    result<-cbind.data.frame(inputdata[,var_list[i]],inputdata["panelCombined"])
    result<-result[order(result["panelCombined"]),]
    result<-result[-3]
    result<-cbind.data.frame(inputdata["primary_key_1644"],result)
    colnames(result)<-c("primary_key","actual","grp_variable")
    result <- result[order(result[, "primary_key"]), ]
    if (nrow(result) > 5500) {
      for (n in 1:length(grp_names[["grp_variable"]])) {
        x_temp  <- grp_names[["grp_variable"]][n]
        df_temp <- subset(x = result, subset = result[, "grp_variable"] == x_temp)
        x_temp  <- order(df_temp[,"primary_key"])
        df_temp <- df_temp[x_temp, , drop = FALSE]
        
        png(filename=paste(output_path,
                           "/",
                           var_id[i],
                           "/runsequence",
                           n,
                           ".png",
                           sep=""))
        plot(x=df_temp[,"primary_key"],y=df_temp[,"actual"],xlab="Observations",ylab=var_list[i],type="p",col="#800000")
        dev.off()
      }
    }
    write.csv(result,paste(output_path,var_id[i],"runsequence.csv",sep="/"),quote=F,row.names=F)
    
  }
  #==========================================================================
  #Prob Plot
  #========================================================================== 
  if (flag_prob_plot == 'true' ) {
    
    pplotFunction<-function(subset.data)
    {
      prob_result<-NULL
      tempResult<-NULL  
      mu<-mean(subset.data,na.rm=T)
      sdev<-sd(subset.data,na.rm=T)
      for(tempIndex in 1 :100)
      {
        if(tempIndex==100)
        {
          break
        }
        else
        {
          pplot<- tempIndex/100
          pplotvalue <- mu+(sdev*qnorm(pplot))
          tempResult<-rbind(tempResult,cbind(pplot,pplotvalue))
        }
      }
      return(tempResult)
    }   
    
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-pplotFunction(data[,var_list[i]])
      result<-rbind(result,res1)
    }
    result<-cbind(result,rep(uniqPanels,each=99))
    colnames(result)<-c("percentile","estimate","grp_variable")
    result_prob <- data.frame(result)
    result_prob<-result_prob[c(3,1,2)]
    write.csv(result_prob, file=paste(output_path, var_id[i], "probplot.csv", sep="/"), quote=FALSE, row.names=FALSE)
  }
  
  #==========================================================================
  #acf function and results
  #========================================================================== 
  if (flag_acf_plot == 'true'){ 
    acfFunction = function(data)
    {
      library(tseries)
      x <- as.numeric(data)
      val=acf(x=x[is.finite(x)],lag.max=24,plot=FALSE)
      Lag=val$lag
      Correlation=val$acf
      significance_level_positive <- qnorm((1 + 0.95)/2)/sqrt(sum(!is.na(x)))
      significance_level_negative <- -1 * significance_level_positive
      result=cbind.data.frame(Lag,Correlation,significance_level_positive, significance_level_negative)
      return(result)
    }
    
    
    
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-acfFunction(data=data[,var_list[i]])
      res1$grp_variable=uniqPanels[j]
      result<-rbind(result,res1)
    }
    
    result["variable_name"] <- var_list[i]
    result <- result[c("Lag","Correlation","variable_name","grp_variable","significance_level_positive","significance_level_negative")]
    write.csv(result,file=paste(output_path,var_id[i],"AutoCorrelation_Plot_Sample.csv",sep="/"),quote=F,row.names=F)
    autoCorrCsv=result[c(2,6)]
    names(autoCorrCsv)=c("Autocorr","grp_variable")
    write.csv(autoCorrCsv,file=paste(output_path,var_id[i],"autocorrplot.csv",sep="/"),quote=F,row.names=F)   
    
  }
  #==========================================================================
  #Seasonality funciton and results
  #========================================================================== 
  if (flag_seasonality_test == 'true'){
    seasonalityFunction<-function(data)
    {
      adfValues=NULL
      
      for(adflags in 0:2)
      {
        tempadf=try(adf.test(data,k=adflags),silent=TRUE)
        if(class(tempadf)=="try-error")
        {
          tempadf=try(adf.test(data,k=0),silent=TRUE)
        }
        valLag=as.numeric(tempadf$parameter)
        rhoVals=as.numeric(tempadf$statistic)
        pval=as.numeric(tempadf$p.value)
        tempVal=c(valLag,rhoVals,pval)
        adfValues=rbind(adfValues,tempVal)
      }
      return(adfValues)
    }
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-try(seasonalityFunction(data[,var_list[i]]),silent=TRUE)
      if(class(res1)=="try-error")
      {
        res1=matrix(0,3,3)
      }
      res1=cbind(res1,uniqPanels[j])
      result<-rbind(result,res1)
    }
    row.names(result)=NULL
    result=as.data.frame(result)
    result=cbind.data.frame(result,0,0,"Single Mean")
    names(result)=c("Lags","Rho","ProbRho","grp_variable","Tau","ProbTau","Type")
    col=c("Type","Lags","Rho","ProbRho","Tau","ProbTau","grp_variable")
    result=result[col]
    write.csv(result, file=paste(output_path, var_id[i], "SeasonalityTests.csv", sep="/"), quote=FALSE, row.names=FALSE)
    
  }
  #==========================================================================
  #whitenoise
  #========================================================================== 
  
  if (flag_whiteNoise_test == 'true'){
    whiteNoiseFunction<-function(data)
    {
      boxValues<-NULL
      for(boxlags in 1:4)
      {
        tempBox=Box.test(data,lag=(6*boxlags))
        chiSqVal=as.numeric(tempBox$statistic)
        DF=as.numeric(tempBox$parameter)
        pval=as.numeric(tempBox$p.value)
        tempVal=cbind(6*boxlags,chiSqVal,DF,pval)
        boxValues<-rbind(boxValues,tempVal)
      }
      return(boxValues)
    }  
    
    
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-whiteNoiseFunction(data[,var_list[i]])
      result<-rbind(result,res1)
    }
    result<-cbind(result,rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(uniqPanels,each=4))
    colnames(result)<-c("ToLags","ChiSq","DF","ProbChiSq","One","Two","Three","Four","Five","Six","grp_variable")
    write.csv(result, file=paste(output_path, var_id[i], "WhiteNoiseTest.csv", sep="/"), quote=FALSE, row.names=FALSE)
    
  }
  #==========================================================================
  #Unit Root
  #========================================================================== 
  if (flag_unit_test =='false'){
    unitRootFunction<-function(data)
    {
      adfValues<-NULL
      tempadf=try(adf.test(data,k=adflags),silent=TRUE)
      if(class(tempadf)=="try-error")
      {
        tempadf=try(adf.test(data,k=0),silent=TRUE)
      }
      for(adflags in 0:2)
      {
        tempadf=adf.test(data,k=adflags)
        valLag=as.numeric(tempadf$parameter)
        rhoVals=as.numeric(tempadf$statistic)
        pval=as.numeric(tempadf$p.value)
        tempVal=c(valLag,rhoVals,pval)
        adfValues=rbind(adfValues,tempVal)
      }
      return(adfValues)
    }
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-try(unitRootFunction(data[,var_list[i]]),silent=TRUE)
      if(class(res1)=="try-error")
      {
        res1=matrix(0,3,3)
      }
      result<-rbind(result,res1)
    }
    result<-cbind(result,rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(0,nrow(result)),rep(uniqPanels,each=3))
    colnames(result)<-c("Type","Lags","Rho","ProbRho","Tau","ProbTau","FValue","ProbF","grp_variable")
    write.csv(result, file=paste(output_path, var_id[i], "UnitRootTests.csv", sep="/"), quote=FALSE, row.names=FALSE)
    
  }
  #==========================================================================
  #pacf
  #========================================================================== 
  if(flag_pacf_plot=="true"){ 
    
    #pacf 
    pacfFunction = function(subset.data)
    {
      library(tseries)
      #no_zeros<-length(which(subset.data!=0)==T)
      
      if(length(subset.data)<=1 | (length(which(is.finite(unique(subset.data)))) == 1))
      {
        return(NULL)
      }
      x <- as.numeric(subset.data)
      val=pacf(x=x[is.finite(x)],lag.max=24,plot=FALSE)
      Lag=val$lag
      Correlation=val$acf
      significance_level_positive <- qnorm((1 + 0.95)/2)/sqrt(sum(!is.na(x)))
      significance_level_negative <- -1 * significance_level_positive
      result=cbind.data.frame(Lag,Correlation,significance_level_positive,significance_level_negative)
      return(result)
    }
    
    result<-NULL
    for(j in 1:length(uniqPanels))
    {
      data<-subset(inputdata,panelCombined==uniqPanels[j])
      res1<-pacfFunction(subset.data=data[,var_list[i]])
      if(is.null(res1)==FALSE)
      {
        res1$grp_variable=uniqPanels[j]
      }
      result<-rbind(result,res1)
    }
    write.csv(result,paste(output_path,var_id[i],"_Partial_ACF_Sample.csv",sep="/"),quote=F,row.names=F) 
  }
  
  
  #==========================================================================
  #Percentile graph
  #========================================================================== 
  result<-NULL
  for(j in 1:length(uniqPanels))
  {
    data<-subset(inputdata,panelCombined==uniqPanels[j])
    res1<-meanFunction(data[,var_list[i]])
    if(is.null(res1)==F)
    {
      res1$grp_variable=uniqPanels[j]
      result<-rbind.data.frame(result,res1)
    }
  }
  
  
  result=result[order(result[,3]),]
  result=cbind.data.frame(result,var_list[i])
  names(result)[5]="variable"
  col=c("grp_variable","mean","stddev","variable","percentile")
  result=result[col]
  write.csv(result,paste(output_path,var_id[i],"percentile.csv",sep="/"),quote=F,row.names=F)
  
}
#==========================================================================
#Writing completed
#========================================================================== 

write.table("EDA - UNIVARIATE_ACROSSGRPBY_COMPLETED",paste(output_path,"UNIVARIATE_ACROSSGRPBY_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)