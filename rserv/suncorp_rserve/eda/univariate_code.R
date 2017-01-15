# things not to do: NEVER RUN THE PROGRAM 2 TIMES CONTINUOSLY WITHOUT RUNNING THE PARAMETERS AGAIN.
# ----------------------                    
# SAMPLE PARAMETERS
# input_path               <- 'C:/Users/Jerin.Sam/MRx/r/jer_PGD1-24-Jun-2014-15-12-22/1'
# output_path              <- 'C:/Users/Jerin.Sam/MRx/r/jer_PGD1-24-Jun-2014-15-12-22/1/univariateAnalysis/1'
# var_list                 <- c('sales','ACV') 
# var_id                   <- c(1,2)
# grp_no                   <- 3
# grp_flag                 <- c("3_1_1")
# flag_fitdistr            <- 'tru'
# flag_lognormal           <- 'true'
# flag_exponential         <- 'true'
# flag_weibull             <- 'true'
# flag_gamma               <- 'true'
# flag_box_plot            <- 'true'
# flag_runseq_plot         <- 'tru'
# run_against              <- 'sorted'
# flag_prob_plot           <- 'true'
# flag_whiteNoise_test     <- 'tru'   
# flag_seasonality         <- "false"
# flag_unit_test           <- 'tru'
# flag_acf_plot            <- 'tru'
# flag_pacf_plot           <- 'tru'
# flag_histogram           <- 'tru'
# flag_timeSeries_plot     <- 'true'
# breakpoints                       <- c(.1,.3,.7)
# date_var                 <- "Date"
#----------------------------  
library(MASS)
library(ADGofTest)
library(moments)
library(modeest)
library(XML)
library(tseries)
library(reshape2)
library(zoo)

if (grp_no == 0){
  grp_flag<-'1_1_1'
}


flag_normal              <- FALSE
flag_lognormal           <- FALSE
flag_exponential         <- FALSE
flag_weibull             <- FALSE
flag_gamma               <- FALSE


if(flag_percentile == 'true')
  breakpoints           <- breakpoints/100
if(flag_percentile != 'true')
  breakpoints           <- 0

if (flag_fitdistr =="true"){
  if("Normal"      %in% (histogram_options))
    flag_normal            <- 'true'
  
  if("LogNormal"   %in% (histogram_options))
    flag_lognormal         <- 'true'
  
  if("Weibull"     %in% (histogram_options))
    flag_weibull           <- 'true'
  
  if("Gamma"       %in% (histogram_options))
    flag_gamma             <- 'true'
  
  if("Exponential" %in% (histogram_options))
    flag_exponential       <- 'true'
}

col_goodfit<-NULL

#function to recognise dateformat
dateformat_identifier    <- function(   date    )
{
  form                  <- NULL
  temp                  <- as.character(date[1])
  if(any(grepl("[[:alpha:]]",date) == "TRUE"))
  {
    return("unknown")
  }
  if(grepl(" ",temp)){
    date                <- apply(as.data.frame(date),1,function(x){strsplit(as.character(x)," ")[[1]][1]})
  }
  date                  <- as.character(date)
  if (is.null(date))
    return("unknown")  
  if(is.na(mean(as.numeric(date),na.rm=T)) == "FALSE")
  {
    return("unknown")
  }
  if((length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == FALSE)))   &
       (length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == FALSE))))
    return("unknown")
  if (all(is.na(date))) 
    return(NA)
  val                   <- length(date)
  if(val > 100){val= 100}
  date[which(date=='')] <- NA
  if(!is.na(as.numeric(substr(date[1],1,4))))
  {
    decide              <- apply (as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split               <- substr(date[1],5,5)
    decide              <- as.data.frame(decide)
    max1                <- max   (as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    max2                <- max   (as.numeric(as.character(as.matrix(decide[3,]))),na.rm=T)
    if(max1  > 12 & max2 <= 12)  {form<-paste("%Y",split,"%d",split,"%m",sep="")}
    if(max1 <= 12 & max2 >= 12)  {form<-paste("%Y",split,"%m",split,"%d",sep="")}
    if(max1 <= 12 & max2 <= 12)  {form<-paste("%Y",split,"%m",split,"%d",sep="")}
  }else{
    decide              <- apply (as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split               <- substr(date[1],6-(10-nchar(date[1])),6-(10-nchar(date[1])))
    decide              <- as.data.frame(decide)
    max1                <- max   (as.numeric(as.character(as.matrix(decide[1,]))),na.rm=T)
    max2                <- max   (as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    if(max1 > 12 && max2 <= 12)  {form<-paste("%d",split,"%m",split,"%Y",sep="")}
    if(max1 <= 12 & max2 >= 12)  {form<-paste("%m",split,"%d",split,"%Y",sep="")}
    if(max1 <= 12 & max2 <= 12)  {form<-paste("%m",split,"%d",split,"%Y",sep="")}
  }
  if(max(nchar(date)) <= 8)
  {
    decide              <- apply (as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split               <- substr(date[1],nchar(date[1])-2,nchar(date[1])-2)
    decide              <- as.data.frame(decide)
    max1                <- max   (as.numeric(as.character(as.matrix(decide[1,]))),na.rm=T)
    max2                <- max   (as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    if(max1 > 12 && max2 <= 12)  {form<-paste("%d",split,"%m",split,"%y",sep="")}
    if(max1 <= 12 & max2 >= 12)  {form<-paste("%m",split,"%d",split,"%y",sep="")}
    if(max1 <= 12 & max2 <= 12)  {form<-paste("%m",split,"%d",split,"%y",sep="")}
  }
  if(nchar(temp[1]) > 10 & nchar(temp[1]) <= 16){form<- paste(form," %H:%M",sep="")}
  if(nchar(temp[1]) > 16)                       {form<- paste(form," %H:%M:%S",sep="")}
  return(form)
}
#distr func outputs "histogram" and "goodfit" CSVs
distr                    <- function(x,folder_id,varname,bp=breakpoints)
{  col_pdf               <- x
   if(flag_normal=="true")
   {
     ad                    <- NULL
     ad$p.value            <- NULL
     ks                    <- NULL
     ks$p.value            <- NULL
     normal                <- NULL
     fd_n                  <- try(fitdistr (x,"normal"),silent=TRUE)
     if(class(fd_n)=="try-error")
     { col_goodfit_pre     <- as.data.frame(cbind("normal","error","error"))
       col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
       normal              <- "error"
       col_pdf             <- as.data.frame(cbind(col_pdf,normal))
       ERROR               <- errorhandler("normal",varname,folder_id)
     }else{
       mean_n                <- fd_n$estimate[[1]]
       sd_n                  <- fd_n$estimate[[2]]
       normal                <- dnorm    (x,mean_n  ,sd_n)
       ks                    <- try(ks.test  (x,"pnorm", mean=mean_n, sd=sd_n),silent = TRUE)
       ad                    <- try(ad.test  (x, pnorm , mean=mean_n, sd=sd_n),silent = TRUE)
       if(class(ks) == "try-error" | class(ad) == "try-error")
       {
         ERROR               <- errorhandler("KS.test and AD.test",varname,folder_id)
       }else
       {
         col_goodfit_pre     <- as.data.frame(cbind("normal",ks$p.value,ad$p.value))
         col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
         col_pdf             <- as.data.frame(cbind(col_pdf,normal))  
       }
     }
   }
   if(flag_lognormal=="true")
   { 
     ad                    <- NULL
     ad$p.value            <- NULL
     ks                    <- NULL
     ks$p.value            <- NULL
     lognormal             <- NULL
     fd_ln                 <- try(fitdistr (x,"lognormal"),silent=TRUE)
     if(class(fd_ln)=="try-error")
     { col_goodfit_pre     <- as.data.frame(cbind("lognormal","error","error"))
       col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
       lognormal           <- "error"
       col_pdf             <- as.data.frame(cbind(col_pdf,lognormal))
       ERROR               <- errorhandler("lognormal",varname,folder_id)
     }else{
       mean_ln               <- fd_ln$estimate[[1]]
       sd_ln                 <- fd_ln$estimate[[2]]
       lognormal             <- dlnorm   (x,mean_ln ,sd_ln)
       #        if ((mean_ln==0) && (sd_ln==0)){
       #          write("Variables",varn  paste(output_path),"/error.txt",sep="")
       #        }
       ks                    <- ks.test  (x, "plnorm", meanlog=mean_ln, sdlog=sd_ln)
       ad                    <- ad.test  (x,plnorm,meanlog=mean_ln, sdlog=sd_ln)
       if(class(ks) == "try-error" | class(ad) == "try-error")
       {
         ERROR               <- errorhandler("KS.test and AD.test",varname,folder_id)
       }else
       {
         col_goodfit_pre       <- as.data.frame (cbind("lognormal",ks$p.value,ad$p.value))
         col_goodfit           <- as.data.frame (rbind(col_goodfit,col_goodfit_pre))
         col_pdf               <- as.data.frame (cbind(col_pdf,lognormal))
       }
     }
   }
   if(flag_exponential=="true")
   { ad                    <- NULL
     ad$p.value            <- NULL
     ks                    <- NULL
     ks$p.value            <- NULL
     exponential           <- NULL
     fd_e                  <- try(fitdistr (x,"exponential"),silent=TRUE)
     if(class(fd_e)=="try-error")
     { col_goodfit_pre     <- as.data.frame(cbind("exp","error","error"))
       col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
       exponential         <- "error"
       col_pdf             <- as.data.frame(cbind(col_pdf,exponential))
       ERROR               <- errorhandler("exponential",varname,folder_id)
     }else{
       rate_e                <- fd_e$estimate[[1]]
       exponential           <- dexp     (x,rate_e)
       
       ks                    <- try(ks.test  (x,"pexp", rate=rate_e),silent = TRUE)
       ad                    <- try(ad.test  (x, pexp , rate=rate_e),silent = TRUE)
       if(class(ks) == "try-error" | class(ad) == "try-error")
       {
         ERROR               <- errorhandler("KS.test and AD.test",varname,folder_id)
       }else
       {
         col_goodfit_pre       <- as.data.frame(cbind("exp",ks$p.value,ad$p.value))
         col_goodfit           <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
         col_pdf               <- as.data.frame(cbind(col_pdf,exponential))
       }
     }
   }
   if(flag_weibull=="true")
   {
     ks                    <- NULL
     ks$p.value            <- NULL
     ad                    <- NULL
     ad$p.value            <- NULL
     weibull               <- NULL
     fd_w                  <- try(fitdistr (x,"weibull"),silent=TRUE)
     if(class(fd_w)=="try-error")
     { col_goodfit_pre     <- as.data.frame(cbind("weibull","error","error"))
       col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
       weibull<-"error"
       col_pdf             <- as.data.frame(cbind(col_pdf,weibull))
       ERROR               <- errorhandler("weibull",varname,folder_id)
     }else{
       shape_w               <- fd_w$estimate[[1]]
       scale_w               <- fd_w$estimate[[2]]
       weibull               <- dweibull (x,shape_w ,scale_w)
       ks                    <- try(ks.test  (x, "pweibull", shape=shape_w, scale=scale_w),silent=TRUE)
       ad                    <- try(ad.test  (x,pweibull,shape=shape_w, scale=scale_w),silent=TRUE)
       if(class(ks) == "try-error" | class(ad) == "try-error")
       {
         ERROR               <- errorhandler("KS.test and AD.test",varname,folder_id)
       }else
       {
         col_goodfit_pre       <- as.data.frame (cbind("weibull",ks$p.value,ad$p.value))
         col_goodfit           <- as.data.frame (rbind(col_goodfit,col_goodfit_pre))
         col_pdf               <- as.data.frame (cbind(col_pdf,weibull)) 
       }
     }
   }
   if(flag_gamma=="true")
   { ks                    <- NULL
     ks$p.value            <- NULL
     ad                    <- NULL
     ad$p.value            <- NULL
     gamma                 <- NULL
     
     fd_g                  <- try(fitdistr(x,"gamma"),silent = TRUE)
     if(class(fd_g)=="try-error")
     { col_goodfit_pre     <- as.data.frame(cbind("gamma","error","error"))
       col_goodfit         <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
       gamma<-"error"
       col_pdf             <- as.data.frame(cbind(col_pdf,gamma))
       ERROR               <- errorhandler("gamma",varname,folder_id)
       
     }else{
       shape_g               <- fd_g$estimate[[1]]
       rate_g                <- fd_g$estimate[[2]] 
       gamma                 <- dgamma   (x,shape_g ,rate_g )
       ks                    <- try(ks.test  (x, "pgamma", shape=shape_g, rate=rate_g),silent =TRUE)
       ad                    <- try(ad.test  (x,pgamma,shape=shape_g, scale=rate_g),silent =TRUE)
       if(class(ks) == "try-error" | class(ad) == "try-error")
       {
         ERROR               <- errorhandler("KS.test and AD.test",varname,folder_id)
       }else
       {
         col_goodfit_pre       <- as.data.frame(cbind("gamma",ks$p.value,ad$p.value))
         col_goodfit           <- as.data.frame(rbind(col_goodfit,col_goodfit_pre))
         col_pdf               <- as.data.frame(cbind(col_pdf,gamma))
       }
     }
   } 
   #    ---------------------------------------------------------
   quantilevalues          <- as.vector(quantile(x,bp))
   result                  <- NULL
   
   if(flag_percentile == 'true')
   {
     histvector            <- hist(as.numeric(x),breaks=c(min(x),quantilevalues,max(x)),plot=FALSE)
   }
   if(flag_percentile != 'true')
   {
     histvector            <- hist(as.numeric(x),plot=FALSE)
   }
   
   
   grp_variable                   <- as.vector(uniq_lvls[i])
   result                  <- cbind(histvector$mids,histvector$counts,grp_variable)
   colnames(result)        <- c("increment","frequency","grp_variable")
   
   ------------------------------------------------------------------
     if(flag_fitdistr=="true" && length(col_goodfit)>1)
     {
       
       increment                    <- cut(x,histvector$breaks,labels = histvector$mid,include.lowest=TRUE)
       outputdata_goodfit           <- cbind.data.frame(col_goodfit,grp_variable)
       colnames(outputdata_goodfit) <- c("distributions","KStest","ADtest","grp_variable")
       outputdata_pdf               <- cbind.data.frame(col_pdf,increment,grp_variable=grp_variable)
       count_data                   <- cbind.data.frame(increment=histvector$mid,frequency=histvector$count)
       outputdata_pdf               <- merge(count_data,outputdata_pdf ,by=c("increment"),all=T)
       
       return(list(outputdata_pdf,outputdata_goodfit,result))
     }else
     {
       return(data.frame(result))
     }
   
}
univariateSummary        <- function(x,folder_id)
{
  univarvector           <- NULL      
  mean                   <- mean    (x,na.rm=T)
  stddev                 <- sd      (x,na.rm=T)
  max                    <- max     (x,na.rm=T)
  min                    <- min     (x,na.rm=T)
  median                 <- median  (x,na.rm=T)
  range                  <- max - min
  observations_used      <- length  (x)
  iqr                    <- IQR     (x,na.rm=T) 
  number_of_missing      <- sum     (is.na(x))
  uc                     <- quantile(x,0.75,na.rm=T)+(1.5*iqr)
  lc                     <- quantile(x,0.25,na.rm=T)-(1.5*iqr)
  noofoutliers           <- length  (which(x > uc | x < lc))
  no_of_zeros            <- sum     (x==0)
  mode                   <- (mlv(x, method = "mfv"))$M    
  result                 <- data.frame(c(mean,stddev,max,min,median,range,observations_used,iqr,number_of_missing,noofoutliers,no_of_zeros,mode[1]))
  names(result)          <- "estimate"
  statistic              <- c("mean","stddev","max","min","median","range","observations_used","iqr","number_of_missing","no_of_outliers","no_of_zeros","mode")
  grp_variable                  <- uniq_lvls[i]
  result                 <- cbind.data.frame(statistic,result,grp_variable)
  
  #     write.csv(result,file=paste(output_path,folder_id,"univariate.csv", sep="/"),row.names=F,quote=F)
  return(data.frame(result))
  
}
#Box Value
boxplotfun               <- function(subset.data)
{
  box_mean               <- mean    (subset.data,na.rm=T)
  p_100                  <- max     (subset.data,na.rm=T)
  p_75                   <- quantile(subset.data,0.75)
  p_50                   <- median  (subset.data,na.rm=T)     
  p_25                   <- quantile(subset.data,0.25)
  p_0                    <- min     (subset.data,na.rm=T)
  
  result                 <- c(box_mean,p_0,p_25,p_50,p_75,p_100)
  return(result)
}
BOXPLOT                  <- function(x,folder_id,varname)
{
  result                 <- NULL
  result                 <- try(boxplotfun(x),silent="TRUE")
  if(class(result)=="try-error")
  {
    ERROR                <- errorhandler("boxplot",varname)
  }else{
    result                 <- as.data.frame(matrix(c(varname,result),ncol=7))
    #   grpby                  <- uniq_lvls[i]
    colnames(result)       <- c("variable","box_mean","p_0","p_25","p_50","p_75","p_100")
    result<-cbind(result,grp_variable=uniq_lvls[i])
    #   write.csv(result, file=paste(output_path, folder_id, "boxplot.csv", sep="\\"), quote=FALSE, row.names=FALSE)
    return(data.frame(result))
  }
  
}
RUNSEQUENCE              <- function(x,folder_id,run_against_temp=run_against)
{
  # Run Sequence
  result                 <- NULL
  
  if(run_against_temp!="Sorted")
  {
    run_against_temp           <- univar_subset[,run_against_temp]
    result                <- cbind.data.frame(x,run_against_temp)
    result                <- result[order(as.Date(result$run_against_temp,format= dateformat_identifier(univar_subset[,date_var]))),]
  }else{
    run_against_temp           <- univar_subset[,"primary_key_1644"]
    
    result                <- sort(x)
    result                <- cbind.data.frame(result,run_against_temp)
    
  }
  grp_variable              <- uniq_lvls[i]
  result                 <- cbind.data.frame(result,grp_variable)
  colnames(result)       <- c("actual","primary_key","grp_variable")
  if (run_against != "sorted"){  
    index<- which(result$primary_key=="")
    if (length(index)!=0){
      result<- result[-index,]
    }}
  
  #   write.csv(result,paste(output_path,folder_id,"runsequence.csv",sep="/"),quote=F,row.names=F)
  return(data.frame(result))
}
#probability Function
pplotFunction            <- function(subset.data)
{
  prob_result            <- NULL
  tempResult             <- NULL  
  mu                     <- mean(subset.data,na.rm=T)
  sdev                   <- sd(subset.data,na.rm=T)
  for(tempIndex in 1 :100)
  {
    if(tempIndex==100)
    {
      break
    }
    else
    {
      pplot              <- tempIndex/100
      pplotvalue         <- mu+(sdev*qnorm(pplot))
      tempResult         <- rbind(tempResult,cbind(pplot,pplotvalue))
    }
  }
  return(tempResult)
}
PROBABILITY              <- function(x,folder_id)
{
  result                 <- NULL
  result                 <- try(pplotFunction(x),silent=TRUE)
  if(class(result)=="try-error")
  {
    ERROR                <- errorhandler("pplot",varname)
  }else{  
    result <-cbind.data.frame(result,uniq_lvls[i])
    colnames(result)       <- c("percentile","estimate","grp_variable")
    
    #   write.csv(result, file=paste(output_path, folder_id, "probplot.csv", sep="/"), quote=FALSE, row.names=FALSE)  
    return(data.frame(result))
  }
}
#white Noise Test
whiteNoiseFunction       <- function(subset.data)
{
  boxValues<-NULL
  for(boxlags in 1:4)
  {
    tempBox             <- Box.test(subset.data,lag=(6*boxlags))
    #
    chiSqVal            <- as.numeric(tempBox$statistic)
    DF                  <- as.numeric(tempBox$parameter)
    pval=as.numeric(tempBox$p.value)
    #     if(pval == 0)
    #     {
    #       pval<-"<2.2e-16"
    #     }
    tempVal             <- cbind(6*boxlags,chiSqVal,DF,pval)
    boxValues           <- rbind(boxValues,tempVal)
  }
  return(boxValues)
}
WHITENOISE               <- function(x,folder_id,varname)
{ result                <- NULL
  result                <- try(whiteNoiseFunction(x),silent=TRUE)
  if(class(result)=="try-error")
  {
    ERROR                <- errorhandler("whitenoise",varname)
  }else{
    xax                   <- acf(x, lag.max = 24, type = c("correlation"), plot = F, na.action = na.pass)
    
    One                   <- as.data.frame(rbind(xax$acf[1],xax$acf[7] ,xax$acf[13],xax$acf[19]))
    Two                   <- as.data.frame(rbind(xax$acf[2],xax$acf[8] ,xax$acf[14],xax$acf[20]))
    Three                 <- as.data.frame(rbind(xax$acf[3],xax$acf[9] ,xax$acf[15],xax$acf[21]))
    Four                  <- as.data.frame(rbind(xax$acf[4],xax$acf[10],xax$acf[16],xax$acf[22]))
    Five                  <- as.data.frame(rbind(xax$acf[5],xax$acf[11],xax$acf[17],xax$acf[23]))
    Six                   <- as.data.frame(rbind(xax$acf[6],xax$acf[12],xax$acf[18],xax$acf[24]))
    result                <- cbind(result,One,Two,Three,Four,Five,Six,uniq_lvls[i])
    colnames(result)      <- c("ToLags","ChiSq","DF","ProbChiSq","One","Two","Three","Four","Five","Six","grp_variable")
    #   write.csv(result, file=paste(output_path, folder_id, "WhiteNoiseTest.csv", sep="/"), quote=FALSE, row.names=FALSE)
    return(data.frame(result))
  }
}
#unit root test
unitRootFunction         <- function(subset.data)
{
  adfValues             <- NULL
  adflags               <- NULL
  for(adflags in 0:2){
    #   tempadf               <- try(adf.test(subset.data,k=adflags),silent=TRUE)
    #   if(class(tempadf)=="try-error")
    #   {
    #     tempadf             <- try(adf.test(subset.data,k=0),silent=TRUE)
    #   }
    #  
    
    tempadf             <- adf.test(subset.data,k=adflags[i])
    valLag              <- as.numeric(tempadf$parameter)
    rhoVals             <- as.numeric(tempadf$statistic)
    pval                <- as.numeric(tempadf$p.value)
    tempVal             <- c(valLag,rhoVals,pval)
    adfValues           <- rbind(adfValues,tempVal)
  }
  return(adfValues)
}
UNITROOT                 <- function(x,folder_id)
{
  if(length(x) > 7)
  {
    grp_variable             <- as.vector(uniq_lvls[i])
    result            <- NULL      
    res1              <- try(unitRootFunction(x),silent=T)
    if(class(res1)=="try-error")
    {
      res1            <- matrix(0,3,3)
    }
    result            <- rbind(result,res1)
    
    result            <- cbind(rep("ADF",nrow(result)),result,rep("-",nrow(result)),rep("-",nrow(result)),rep("-",nrow(result)),rep("-",nrow(result)),grp_variable)
    
    colnames(result)  <- c("Type","Lags","Rho","ProbRho","Tau","ProbTau","FValue","ProbF","grp_variable")
    #     write.csv(result, file=paste(output_path, folder_id, "UnitRootTests.csv", sep="/"), quote=FALSE, row.names=FALSE)
    return(data.frame(result))
    
  }
}
#Pacf
pacfFunction             <- function(subset.data)
{
  library(tseries)
  #no_zeros<-length(which(subset.data!=0)==T)
  
  if(length(subset.data)<=1 | length(which(length(unique(subset.data)==1)==T)))
  {
    return(NULL)
  }
  val                   <- pacf(x=subset.data,lag.max=24,plot=FALSE)
  Lag                   <- val$lag
  Correlation           <- val$acf
  StdErr                <- 1.96/sqrt(length(subset.data))
  StdErrX2              <- 2*StdErr
  Neg_StdErrX2          <- -1*StdErrX2
  grp_variable                <- uniq_lvls[i]
  result                <- cbind.data.frame(Lag,Correlation,StdErr,StdErrX2,Neg_StdErrX2,grp_variable)
  return(result)
}
PARTIAL_AUTOCORRELATION  <- function(x,folder_id)
{
  #Pacf 
  result                <- NULL
  
  result                <- try(pacfFunction(x),silent=TRUE)
  if(class(result)=="try-error")
  {
    ERROR                <- errorhandler("partial_autocorrelation",varname)
  }else{
    #   write.csv(result,paste(output_path,folder_id,"Partial_ACF_Sample.csv",sep="/"),quote=F,row.names=F) 
    return(data.frame(result))
  }
}
#Acf Function
#Standadard Error for Acf
standardError            <- function(x,n)
{
  len=length(x)
  stdResult             <- NULL
  if(len<=1)
  {
    return(0)
  }
  for(iterator in 1:len)
  {
    temp                <- c(1:iterator)
    tempSqr             <- sqrt((sum(temp*temp) * 2 + 1)/n)
    stdResult           <- c(stdResult,tempSqr)
  }
  #result<-c(result,length(result))
  return(stdResult)
}
acfFunction              <- function(subset.data)
{
  library(tseries)  
  val                   <- acf(x=as.numeric(subset.data),lag.max=24,plot=FALSE)
  Lag                   <- val$lag
  Correlation           <- val$acf
  StdErr                <- standardError(x=Lag,n=length(subset.data))
  StdErrX2              <- 2*StdErr
  Neg_StdErrX2          <- -1*StdErrX2
  grp_variable                 <- uniq_lvls[i]
  result                <- cbind.data.frame(Lag,Correlation,StdErr,StdErrX2,Neg_StdErrX2,grp_variable)
  return(result)
}
AUTOCORRELATION          <- function(x,folder_id,varname)
{
  #autocorr plot
  result                <- NULL
  result                <- try(acfFunction(x),silent=TRUE)
  if(class(result)=="try-error")
  {
    ERROR                <- errorhandler("autocorrelation",varname)
  }else{
    result                <- cbind(varname,result)
    colnames(result)[1]   <- ("variable_name")
    result                <- result[c("Lag","Correlation","variable_name","StdErr","StdErrX2","Neg_StdErrX2","grp_variable")]
    #   write.csv(result,file=paste(output_path,folder_id,"AutoCorrelation_Plot_Sample.csv",sep="/"),quote=F,row.names=F)   
    return(data.frame(result))
  }
}
#date_checker checks for unique intervals and repetition of dates in date variable chosen
date_checker             <- function(datevar,date_form)
{
  datevar               <- as.Date(datevar,format=date_form)
  sortddate             <- sort(datevar)
  date1                 <- zoo(sortddate)
  
  if (length(date1) == 1){
    return("error")
  }
  
  date2                 <- lag(date1,-1,na.pad = T)
  date_check            <- as.data.frame(cbind(date1,date2))
  date_diff             <- date_check$date1-date_check$date2
  date_check            <- as.data.frame(cbind(date1,date2,date_diff))
  return(date_check$date_diff)
}
TIMESERIES               <- function(x,folder_id,varname,datevar=univar_subset[,date_var])
{
  grp_variable                 <- as.vector(uniq_lvls[i])
  result                 <- NULL
  result                 <- cbind.data.frame(x,datevar,grp_variable)
  colnames(result)       <- c(varname,"Date","grp_variable")
  form                   <- dateformat_identifier(result$Date)
  result                 <- result[with(result, order(as.Date(result$Date,format=form))), ]
  
  #   write.csv(result,file=paste(output_path,folder_id,"timeseries.csv",sep="/"),quote=F,row.names=F)
  return(data.frame(result))
}
PRE_MERGER               <- function(temp_results,master_results)
{
  
  master_results          <- mapply(rbind,master_results,temp_results,SIMPLIFY = FALSE)
  return(master_results)
}
MERGER                   <- function(base,x)
{
  final_result<-rbind.data.frame(base,x)
  
  return(final_result)
}
uni_new_CSVcreator       <- function(entire_uni_result)
{
  
  melted       <- melt(entire_uni_result)
  final_result <- dcast(melted,statistic~grp_variable)
  
  return(final_result)
}
CSV_WRITER               <- function(dataset,folder_id,dataset_name)
{ 
  if(dataset_name== "Partial_ACF_Sample")
  {   dataset_name <- paste("_",dataset_name,sep="")
      write.csv(dataset, file=paste(output_path, folder_id, paste(dataset_name,".csv",sep=""), sep="/"), quote=FALSE, row.names=FALSE)  
      
  }  else
  {
    write.csv(dataset, file=paste(output_path, folder_id, paste(dataset_name,".csv",sep=""), sep="/"), quote=FALSE, row.names=FALSE)  
  }
}
WRITER                   <- function(dataset_list)
{
  
  result_dataset <- get(paste(dataset_list,"_result",sep=""))
  mapply(CSV_WRITER,result_dataset,var_id,dataset_list)
  
}
#errorhandler is used for printing error msgs
errorhandler             <- function(operator,varname,folder_id)
{ R_errormsg             <- geterrmessage()
  customizedmsg          <- paste("Not able to apply",operator,"on",varname,sep=" ")
  write.csv(paste(R_errormsg,customizedmsg,sep="\n"),file=paste(output_path,folder_id,paste(operator,"error.txt",sep="_"), sep="/"),row.names=F,quote=F)
}
#unique_finder is for checking wether the number of unique values of var_list elemnts are more than the no_bins chosen
# unique_finder            <-function(x,folder_id)
# {
#   length=nrow(unique(inputdata[x]))
#   if(length<=no_bins)
#   {
#     errorhandler("binning",paste(x," with no.of unique values less or equal to the no.of bins=",no_bins,sep=""),folder_id)
#   }
#   return(length)
# }
meanFunction<-function(subset_data,varname)
{
  if(length(subset_data)<=1)
  {
    return(NULL)
  }
  quant<-quantile(subset_data,seq(0.05,1,0.05))
  mean=apply(as.matrix(quant),1,function(x){mean(subset_data[which((subset_data<x)==TRUE)])})
  stddev=apply(as.matrix(quant),1,function(x){sd(subset_data[which((subset_data<x)==TRUE)])})
  percentile<-seq(5,100,5)
  meanMat<-cbind.data.frame(mean,stddev,percentile,grp_variable=uniq_lvls[i],variable=varname )
  names(meanMat)=c("mean","stddev","percentile","grp_variable","variable")
  row.names(meanMat)=NULL
  return(meanMat)
}



# FLOW STARTS
load(paste(input_path,"/dataworking.RData",sep=""))
inputdata                <- na.omit(dataworking)
rm(dataworking)

for (i in 1:length(var_id)){
  invisible(lapply(list.files(paste(output_path,"/",var_id[i],sep="" )), FUN=function(x) 
    file.remove(paste(paste(output_path,"/",var_id[i],sep="" ), x, sep="/" )))) 
  
}

# length_storer            <- mapply(unique_finder,var_list,var_id)
# var_list                 <- var_list[length_storer > no_bins]
# after updating the var_list,if the var_list contains 0 elements then stop executing
# if(length(var_list)==0)
# {
#   sapply( var_id,
#           errorhandler,
#           operator= "binning",
#           varname = "categorical variables with no.of unique values less or equal to the number of bins.
#           All the variables chosen have number of unique values less than number of bins.")
#   stop
# }
# var_id                   <- var_id[length_storer > no_bins]

if (grp_no == 0)
{
  inputdata              <-cbind(inputdata,grp0_flag="1_1_1")
}

grouping_column          <- paste("grp",grp_no,"_flag",sep="")
if ((grp_no != 0) && (length(grp_flag)== 1))
{  index<- which(inputdata[,paste("grp",grp_no,"_flag",sep="")]==grp_flag)
   if (length(index!=0)){
     inputdata<-inputdata[index,]
   }}else if(grp_no!=0){
     inputdata[grouping_column] <- data.frame(do.call(paste,c(inputdata[grp_vars],sep="_")))
   }
if(!(date_var==""))
{ 
  univar_subset          <- subset(inputdata, select= c(var_list,date_var,"primary_key_1644",grouping_column))
}else{
  univar_subset          <- subset(inputdata, select= c(var_list,"primary_key_1644",grouping_column))
}

if (flag_percentile=="true"){
  error_var<-NULL
  error_var_final<-NULL
  for (i in 1:length(var_list)){
    min<-min(inputdata[,var_list[i]])
    max<-max(inputdata[,var_list[i]])
    q<-quantile(x=inputdata[,var_list[i]],breakpoints)
    to_check<-c(min,q,max)
    if (length(to_check) != length(unique(to_check))){
      error_var<-var_list[i]
      error_var_final<-c(error_var,error_var_final)
      
    }}
  if(length(error_var_final) != 0)
  {
    error_message<- paste("For the following variables, values at percentiles in different bins are same and hence required binning cannot be performed: ",
                          paste(error_var_final,collapse=" , "),sep="")
    write(error_message,paste(output_path,"/verify_error.txt",sep=""))
    stop(error_message)
  }
}


 

naVarNames               <- NULL
if (flag_fitdistr =='true')
{
  if (("Lognormal" %in% (histogram_options)|("Weibull" %in% (histogram_options))))
  {
    final_error_var<-NULL
    for (i in 1:length(var_list)){
      if (any(inputdata[,var_list[i]]<=0)){
        error_var<-var_list[i]
        final_error_var<-c(error_var,final_error_var)
      } }
    if(length(final_error_var) != 0)
    {
      error_message<- paste("Following variables have zero or negative values due to which lognormal or weibull distribution cannot be applied: ",
                            paste(final_error_var,collapse=" , "),sep="")
      write(error_message,paste(output_path,"/verify_error.txt",sep=""))
      stop(error_message)
    }
  }
  if (flag_fitdistr == 'true') {
    final_sd_error<- NULL
    for (i in 1:length(var_list)){
      sd_var<- sd(inputdata[,var_list[i]],na.rm=T)
      if (sd_var== 0){
        sd_error<- var_list[i]
        final_sd_error<- c(sd_error,final_sd_error)
      }
      if(length(final_sd_error) != 0)
      {
        error_message<- paste("Standard devaiation of the following variables is zero due to which distributions cannot be applied: ",
                              paste(final_sd_error,collapse=" , "),sep="")
        write(error_message,paste(output_path,"/verify_error.txt",sep=""),append=T)
        stop(error_message)
      }
    }
  }
}



var_list                 <- unlist(strsplit(var_list,split=" ",fixed=TRUE))

naVarNames               <- NULL

for(v in var_list){
  if(length(na.omit(univar_subset[,v])) == 0) naVarNames <- c(naVarNames,v)
}


if(length(naVarNames) > 0){
  text                   <- paste("All values are missing in the variable(s) '",naVarNames,"'. Kindly deselect the variable(s).",sep="")
  write(text,paste(output_path,"/error.txt",sep=''))
}else if(nrow(univar_subset)!=0) {
  
  uniq_lvls              <- unique(inputdata[,grouping_column])
  
  if (flag_fitdistr=="true" )
  {
    pdf_result     <- list(list(NULL),list(NULL))
  }else
  {
    pdf_result     <- list(NULL)
  }  
  
  uni_result                         <- list(NULL)
  uni_new_result                     <- list(NULL)
  WhiteNoiseTest_result              <- list(NULL)
  Partial_ACF_Sample_result          <- list(NULL)
  timeseries_result                  <- list(NULL)
  AutoCorrelation_Plot_Sample_result <- list(NULL)
  
  boxplot_result                     <- list(NULL)
  runsequence_result                 <- list(NULL)
  probplot_result                    <- list(NULL)
  UnitRootTests_result               <- list(NULL)
  percentile_result                  <- list(NULL)
  
  #   temp_result<- list(NULL,NULL)
  pdf_result     <- list(list(NULL),list(NULL))
  for (i in 1:length(uniq_lvls))
  { 
    univar_subset <- inputdata[inputdata[,grouping_column] %in% uniq_lvls[i],]
    data                     <- as.data.frame(univar_subset[var_list])
    metric_list              <- NULL
    univar_subset[is.na(univar_subset)] = 0
    container                  <- list(a=data,b=var_id,c=var_list)
    
    results                    <- mapply(univariateSummary,container$a,container$b,SIMPLIFY = FALSE)
    uni_result                 <- mapply(MERGER,uni_result,results,SIMPLIFY = FALSE)
    
    metric_list                <- c(metric_list,"uni","uni_new")
    # metric_list                <- c(metric_list,"uni")
    
    if(flag_histogram == "true")
    { 
      col_goodfit              <- NULL
      col_pdf                  <- NULL
      results                  <- mapply(distr,container$a,container$b,container$c,SIMPLIFY = FALSE) 
      
      if(flag_fitdistr=="true")
        pdf_result               <- try(mapply(PRE_MERGER,results,pdf_result,SIMPLIFY = FALSE),silent=TRUE)
      if(flag_fitdistr!="true")
      {
        pdf_result               <- mapply(MERGER,pdf_result,results,SIMPLIFY = FALSE)
        histogram_result<- pdf_result
      }
      metric_list              <- c(metric_list,"histogram")
      
      if (i==length(uniq_lvls) & class(pdf_result)!="try-error" & flag_fitdistr== "true" )
      {
        
        metric_list             <- c(metric_list,"goodfit","pdf")
        
        temp_result             <- list(NULL)
        temp_result             <- pdf_result
        pdf_result              <- list(NULL)
        goodfit_result          <- list(NULL)
        histogram_result        <- list(NULL)
        for(k in 1:length(var_list))
        {
          goodfit_result[k]   <- temp_result[[k]][2]         
          pdf_result[k]       <- temp_result[[k]][1]          
          histogram_result[k] <- temp_result[[k]][3]        
        }
        
      }
      
      
      
      
    }
    if(flag_box_plot=="true")
    {
      results               <- mapply(BOXPLOT,container$a,container$b,container$c,SIMPLIFY = FALSE)
      boxplot_result        <- mapply(MERGER,boxplot_result,results,SIMPLIFY = FALSE)
      
      #       csvname_list          <- c(csvname_list,"boxplot")
      metric_list           <- c(metric_list,"boxplot")
    }
    
    if(flag_runseq_plot=="true")
    {
      results               <- mapply(RUNSEQUENCE,container$a,container$b,SIMPLIFY = FALSE)
      runsequence_result    <- mapply(MERGER,runsequence_result,results,SIMPLIFY = FALSE)
      
      #       csvname_list          <- c(csvname_list,"runsequence")
      metric_list           <- c(metric_list,"runsequence")
    }
    if(flag_prob_plot=="true")
    {
      results                <- mapply(PROBABILITY,container$a,container$b,SIMPLIFY = FALSE)
      probplot_result            <- mapply(MERGER,probplot_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"probplot")
    }
    if(flag_unit_test=="true")
    {
      results               <- mapply(UNITROOT,container$a,container$b,SIMPLIFY = FALSE)
      UnitRootTests_result       <- mapply(MERGER,UnitRootTests_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"UnitRootTests")
    }
    if(flag_acf_plot=="true")
    {
      results               <- mapply(AUTOCORRELATION,container$a,container$b,container$c,SIMPLIFY = FALSE)
      AutoCorrelation_Plot_Sample_result            <- mapply(MERGER,AutoCorrelation_Plot_Sample_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"AutoCorrelation_Plot_Sample")
      
    }  
    if(flag_timeSeries_plot=="true")
    { 
      
      dateformat            <- dateformat_identifier(univar_subset[,date_var])
      date_interval         <- date_checker(datevar=univar_subset[,date_var],
                                            date_form=dateformat)
      if(length(unique(na.omit(date_interval)))>1) 
      {
        errormsg<-paste("Chosen Date variable has unequal intervals or repeating values",sep="\n")
        write(errormsg,file=paste(output_path,"error.txt",sep="/"))
      }
      
      results             <- mapply(TIMESERIES,container$a,container$b,container$c,SIMPLIFY = FALSE)
      timeseries_result   <- mapply(MERGER,timeseries_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"timeseries")
      
    }
    if(flag_whiteNoise_test=="true")
    {
      results               <- mapply(WHITENOISE,container$a,container$b,SIMPLIFY = FALSE)
      WhiteNoiseTest_result     <- mapply(MERGER,WhiteNoiseTest_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"WhiteNoiseTest")
    }  
    if(flag_pacf_plot=="true")
    {
      results               <- mapply(PARTIAL_AUTOCORRELATION,container$a,container$b,SIMPLIFY = FALSE)
      Partial_ACF_Sample_result           <- mapply(MERGER,Partial_ACF_Sample_result,results,SIMPLIFY = FALSE)
      
      
      metric_list           <- c(metric_list,"Partial_ACF_Sample")
    }
    if(length(grp_flag)>1)
    {
      results               <- mapply(meanFunction,container$a,container$c,SIMPLIFY = FALSE)
      percentile_result     <- mapply(MERGER,percentile_result,results,SIMPLIFY = FALSE)
      metric_list           <- c(metric_list,"percentile")
    }
    
  }
  
  uni_new_result         <- mapply(uni_new_CSVcreator,uni_result,SIMPLIFY = FALSE)
  metric_list            <- as.list(metric_list)
  #writing all the CSVs into the output path.
  mapply(WRITER,metric_list)
  
  uni_new_vars_result    <- data.frame(grp_variable=uniq_lvls)
  #writing uni_new_vars CSV separately due to its diffenrent  structure
  sapply(var_id,CSV_WRITER,dataset=uni_new_vars_result,"uni_new_vars")
  write.csv(uni_new_vars_result,file=paste(output_path,"/unique_grp_var.csv",sep=""),row.names=F,quote=F)
  
  write.table("EDA - VARIABLE_CHARACTERISTICS_COMPLETED",paste(output_path, "VARIABLE_CHARACTERISTICS_COMPLETED.txt", sep="/"),quote=F,row.names=F,col.names=F)
}else{
  write.table("EDA - VARIABLE_CHARACTERISTICS_COMPLETED",paste(output_path, "VARIABLE_CHARACTERISTICS_COMPLETED.txt", sep="/"),quote=F,row.names=F,col.names=F)
}






