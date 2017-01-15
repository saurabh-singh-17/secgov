#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#
#-- Project Name :  MRx_DQA_1.0                                                                      --#
#-- Description  :  multivariate treatment                                                           --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Saurabh Singh                                                                    --#
#------------------------------------------------------------------------------------------------------#



#----------------------------------------------------------------------------------------------
# Parameters Required
#----------------------------------------------------------------------------------------------
#input_path <- 'C:/MRx/r/new-16-Nov-2012-14-22-35/1/dataworking.csv'
#output_path <- 'C:/MRx/r/new-16-Nov-2012-14-22-35/1/0/1_1_1/variabletreatment/newp'
#var_list <- c('ACV','aDAS_week2_Date','black_hispanic')
#procedure <- 0
#treatment<- 'missing'
#outlier_type_side <- 'perc'
#iqr_value  <- 0
#missing_spl <- c(44200000)
#treatment_newVar <- 'new'
#treatment_type<- '
#treatment_prefix <- 'newp'
#custom_treat_val<-  
#pref <- 'outlier'
#perc_lower <- 5
#perc_upper <- 95
#----------------------------------------------------------------------------------------------



#----------------------------------------------------------------------------------------------
# Libraries required
#----------------------------------------------------------------------------------------------
library(moments)
library(e1071)
library(psych)
library(reshape)
library(gtools)
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------
# Custom functions
#----------------------------------------------------------------------------------------------
functionuc <- function(x){
  uc<-quantile(x,(perc_upper/100),na.rm=TRUE)
  return(uc)
}
functionlc <- function(x){
  lc<-quantile(x,(perc_lower/100),na.rm=TRUE)
  return(lc)
}
iqrupper<- function(x){
  iqrthree<-iqr_value*IQR(x,na.rm=TRUE)
  outlier<-(quantile(x,.75,na.rm=TRUE)+iqrthree)
  return(outlier)
}
iqrlower<- function(x){
  iqrthree<-iqr_value*IQR(x,na.rm=TRUE)
  outlier<-(quantile(x,.25,na.rm=TRUE)-iqrthree)
  return(outlier)
}
#----------------------------------------------------------------------------------------------

dataworkingfinal<-NULL
outtreatmissfinal<-NULL
outtreatfinal<-NULL

#----------------------------------------------------------------------------------------------
# Parameter play
#----------------------------------------------------------------------------------------------
if(is.null(missing_spl)) missing_spl=""
#----------------------------------------------------------------------------------------------



flagAcrossGroupBy <- exists('grp_vars')
#----------------------------------------------------------------------------------------------
# Reading the dataset
#----------------------------------------------------------------------------------------------
#dataworkingtotal<- read.csv(input_path,header=T)
load(paste(input_path,"/dataworking.RData",sep=""))
if (n_grp != 0){
  index_s <- which(dataworking[,paste("grp",n_grp,"_flag",sep="")]==grp_flag)
  dataworking_rem <- dataworking[-index_s,]
  dataworking <- dataworking[index_s,]
}
dataworkingtotal <- dataworking

for(k in 1:length(var_list)){
  index <- which((is.na(dataworkingtotal[var_list[k]]) | dataworkingtotal[var_list[k]]=="" | dataworkingtotal[,var_list[k]] %in% missing_spl))  
  
  #----------------------------------------------------------------------------------------------
  # Missing Value Indicator
  #----------------------------------------------------------------------------------------------
  try(if(Create_ind_flag=='true'){
    missing_indicator <- as.data.frame(rep(0,nrow(dataworkingtotal)))
    missing_indicator[index,] <- 1
    if(treatment_newVar=='new'){
      colnames(missing_indicator) <- paste(treatment_prefix,"MI",var_list[k],sep="_") 
    }
    if (treatment_newVar=='replace'){
      colnames(missing_indicator) <- paste(treatment_prefix,"MI",var_list[k],sep="_")
    }
    dataworkingtotal <- cbind.data.frame(dataworkingtotal,missing_indicator)
  },silent=TRUE)
}
if(exists('grp_vars')){
  newVar=data.frame(apply(dataworkingtotal[grp_vars],1,function(x){paste(x,collapse="_")}))
  dataworkingtotal<-cbind(dataworkingtotal,newVar)
  colnames(dataworkingtotal)[ncol(dataworkingtotal)]<-"dummy"
  unique_val<-unique(newVar)
}else{
  dataworkingtotal$dummy<-"abcd"
  unique_val<-as.data.frame("abcd")
}
grp_vars <- "dummy"
if(exists("grp_vars")){
  data <- subset(x=dataworkingtotal,select=c(var_list,grp_vars))
}else{
  data <- subset(x=dataworkingtotal,select=var_list)
}
indexcol <- which(colnames(dataworkingtotal) %in% var_list)
#----------------------------------------------------------------------------------------------



#----------------------------------------------------------------------------------------------
# Get the necessary values
#----------------------------------------------------------------------------------------------
for(l in 1:nrow(unique_val))
{
  dataworking<-dataworkingtotal[c(which(dataworkingtotal["dummy"] ==as.character(unique_val[l,1]))),]  
  pre_mean   <- as.data.frame(apply(dataworking[var_list],2,mean,na.rm=T))
  pre_median <- as.data.frame(apply(dataworking[var_list],2,median,na.rm=T))
  per_upper <- NULL
  per_lower <- NULL
  iqr_upper <- NULL
  iqr_lower <- NULL
  for(j in 1:length(var_list)){
    per_upper[j]<-functionuc(dataworking[,var_list[j]])
    per_lower[j]<-functionlc(dataworking[,var_list[j]])
    iqr_upper[j]<-iqrupper(dataworking[,var_list[j]])
    iqr_lower[j]<-iqrlower(dataworking[,var_list[j]])
  }
  #----------------------------------------------------------------------------------------------
  
  
  
  treat_value <- NULL
  #----------------------------------------------------------------------------------------------
  # Treating the variables
  # Treatment starts here
  #----------------------------------------------------------------------------------------------
  for(i in 1:length(var_list)){
    colindex <- which(colnames(dataworking)==var_list[i])
    
    #----------------------------------------------------------------------------------------------
    # Missing Treatment starts here
    #----------------------------------------------------------------------------------------------
    if(treatment=='missing'){
      treatment_vector   <- rep(treatment_option,length(var_list))
      treat_value <- c(treat_value,custom_treat_val)
      index <- which((is.na(dataworking[colindex]) | dataworking[colindex]=="" | dataworking[,colindex] %in% missing_spl))
      
      
      #----------------------------------------------------------------------------------------------
      if(treatment_option=="mean"){
        dataworking[c(index),colindex] <- mean(dataworking[,colindex],na.rm=T)
        treat_value[i] <- mean(dataworking[,colindex],na.rm=T)
      }
      if(treatment_option=="median"){
        dataworking[c(index),colindex] <- median(dataworking[,colindex],na.rm=T)
        treat_value[i] <- median(dataworking[,colindex],na.rm=T)
      }
      if(treatment_option=="trimmedmean"){
        dataworking[c(index),colindex] <- mean(dataworking[,colindex],na.rm=T,trim = 0.05)
        treat_value[i] <- mean(dataworking[,colindex],na.rm=T)
      }
      if(treatment_option=="custom_type"){
        dataworking[c(index),colindex] <- custom_treat_val
      }
      if(treatment_option=="delete"){
        if(length(index)){
          dataworking <- dataworking[-index,]
        }
      }
      if(treatment_option=="replace_with_existing"){
        dataworking[var_list[i]][index,] <- dataworking[missing_replacement_var[i]][index,]
        treat_value[i]<- missing_replacement_var[i]
       }
    }
    #Missing treatment ends here
    #----------------------------------------------------------------------------------------------
    
    #----------------------------------------------------------------------------------------------
    # Outlier Treatment starts here
    #----------------------------------------------------------------------------------------------
    if(treatment =='outlier'){
      treatment_vector   <- rep(treatment_option,length(var_list))
      treat_value <- c(treat_value,custom_treat_val)
      
      if(outlier_type_side=="perc"){
        # These two variables will be used when writing the CSV
        outlier_ub <- per_upper
        outlier_lb <- per_lower
        valL <- per_lower[i]
        valU <- per_upper[i]
        indexL <- which(dataworking[colindex] < valL)
        indexU <- which(dataworking[colindex] > valU)
        index  <- c(indexL,indexU)
      }
      
      if(outlier_type_side=="one" | outlier_type_side=="two"){
        # These two variables will be used when writing the CSV
        outlier_ub <- iqr_upper
        outlier_lb <- iqr_lower
        valL <- iqr_lower[i]
        valU <- iqr_upper[i]
        indexL <- which(dataworking[colindex] < valL)
        indexU <- which(dataworking[colindex] > valU)
        if(outlier_type_side=="one"){
          index <- indexU
        }else{
          index <- c(indexL,indexU)
        }
      }
      
      if(length(index)){  
        if(treatment_option=="mean"){
          dataworking[c(index),colindex] <- mean(dataworking[,colindex],na.rm=T)
          treat_value[i] <- mean(dataworking[,colindex],na.rm=T)
        }
        if(treatment_option=="trimmedmean"){
          dataworking[c(index),colindex] <- mean(dataworking[,colindex],na.rm=T,trim = 0.05)
          treat_value[i] <- mean(dataworking[,colindex],na.rm=T,trim = 0.05)
        }
        if(treatment_option=="median"){
          dataworking[c(index),colindex] <- median(dataworking[,colindex],na.rm=T)
          treat_value[i] <- median(dataworking[,colindex],na.rm=T)
        }
        if(treatment_option=="capping"){
          if(length(indexL)) dataworking[c(indexL),colindex] <- valL
          if(length(indexU)) dataworking[c(indexU),colindex] <- valU
        }
        if(treatment_option=="custom_type"){
          dataworking[c(index),colindex] <- custom_treat_val
          treat_value[i] <- custom_treat_val
        }
        if(treatment_option=="delete"){
          if(length(index)){
            dataworking<-dataworking[-index,]}
        }
      }
    }
    # Outlier Treatment ends here
    #----------------------------------------------------------------------------------------------
    
  }
  # Treatment ends here
  #----------------------------------------------------------------------------------------------
  
  
  
  #----------------------------------------------------------------------------------------------
  # If new variables have to be created
  #----------------------------------------------------------------------------------------------
  #----------------------------------------------------------------------------------------------
  
  
  
  #----------------------------------------------------------------------------------------------
  # All other stuff and write all the CSVs
  #----------------------------------------------------------------------------------------------
  outtreat     <- NULL
  outtreat     <- as.data.frame(var_list)
  perc_iqr     <- as.data.frame(rep(outlier_type_side,length(var_list)))
  replace_type <- as.data.frame(rep(treatment_newVar,length(var_list)))
  post_mean    <- as.data.frame(apply(dataworking[var_list],2,mean,na.rm=T))
  post_median  <- as.data.frame(apply(dataworking[var_list],2,median,na.rm=T))
  pervalue     <- c(0,0.002,0.004,0.006,0.008,.01,.02,.03,.04,.05,.25,.75,.95,.96,.97,.98,.99,.991,.992,.993,.994,.995,.996,.997,.998,.999,1)
  colper       <- c("p_0","p_0_2","p_0_4","p_0_6","p_0_8","p_1","p_2","p_3","p_4","p_5",
                    "p_25","p_75","p_95","p_96","p_97","p_98","p_99","p_99_1","p_99_2",
                    "p_99_3","p_99_4","p_99_5","p_99_6","p_99_7","p_99_8","p_99_9","p_100")
  functionper  <- function(x){resultquant<- quantile(x,pervalue,na.rm=TRUE)
                              return(resultquant)}
  percentile1  <- apply(dataworking[var_list],2,functionper)
  percen       <- as.data.frame(t(percentile1))
  colnames(percen) <- colper
  grp_var<-as.character(unique_val[l,1])
  if(treatment=='outlier'){
    outtreat<-cbind.data.frame(outtreat,perc_iqr,treatment_vector,treat_value,replace_type,outlier_ub,outlier_lb,pre_mean,pre_median,post_mean,post_median,percen,grp_var)
    colnames(outtreat)[1:11]<-c("var","pre_iqr","treatment","treat_value","replace_type","outlier_ub","outlier_lb","pre_mean","pre_median","post_mean","post_median")
    outtreatfinal<-rbind(outtreatfinal,as.matrix(outtreat))
  }
  
  if(treatment=='missing'){
    if(!is.null(missing_spl)){
      spl_char<-as.data.frame(rep(paste(missing_spl,collapse=" "),length(var_list)))
    }else{
      spl_char<-as.data.frame(rep("NO",length(var_list)))
    }
    outtreatmiss<-cbind.data.frame(outtreat,spl_char,treatment_vector,treat_value,replace_type,pre_mean,pre_median,post_mean,post_median,percen,grp_var)
    colnames(outtreatmiss)[1:9]<-c("variable","special_character","treatment","treat_value","replace_type","pre_mean","pre_median","post_mean","post_median")
    outtreatmissfinal<-rbind(outtreatmissfinal,as.matrix(outtreatmiss))
  }
  dataworkingfinal<-rbind(dataworkingfinal,dataworking)
}
if(treatment == 'outlier'){
  outtreatfinal<-data.frame(outtreatfinal, stringsAsFactors = FALSE)
  outtreatfinal<-outtreatfinal[c(1,ncol(outtreatfinal),2:(ncol(outtreatfinal)-1))]
  if(unique_val[1,1]=="abcd"){outtreatfinal<-outtreatfinal[1:(ncol(outtreatfinal)-1)]}
  if(!flagAcrossGroupBy) outtreatfinal <- outtreatfinal[,-which(colnames(outtreatfinal)=="grp_var")]
  write.csv(outtreatfinal, file = paste(output_path, "outlier_treatment.csv", sep="/"), quote=FALSE, row.names=FALSE)
}
if(treatment=='missing'){
  outtreatmissfinal<-data.frame(outtreatmissfinal, stringsAsFactors = FALSE)
  outtreatmissfinal<-outtreatmissfinal[c(1,ncol(outtreatmissfinal),2:(ncol(outtreatmissfinal)-1))]
  if(unique_val[1,1]=="abcd"){outtreatmissfinal<-outtreatmissfinal[1:(ncol(outtreatmissfinal)-1)]}
  if(!flagAcrossGroupBy) outtreatmissfinal <- outtreatmissfinal[,-which(colnames(outtreatmissfinal)=="grp_var")]
  write.csv(outtreatmissfinal, file = paste(output_path, "missing_treatment.csv", sep="/"), quote=FALSE, row.names=FALSE)
}
if(treatment_newVar == 'new'){
  colnames(dataworkingfinal)[indexcol] <- paste(treatment_prefix,colnames(dataworkingtotal[indexcol]),sep="_")
  dataworkingfinal <- cbind.data.frame(dataworkingfinal,data[1:length(var_list)])
}

# Write dataworking.csv
dataworkingfinal<-as.data.frame(dataworkingfinal)
dataworkingfinal<-as.data.frame(dataworkingfinal[-c(which(colnames(dataworkingfinal)== "dummy"))])
dataworking <- dataworkingfinal

if (n_grp != 0){
  if (treatment_newVar == 'new'){
  for (i in 1: length(var_list)){
    dataworking_rem[,paste(treatment_prefix,var_list[i],sep="_")]<-dataworking_rem[,var_list[i]]
  }}
  dataworking <- smartbind(dataworkingfinal,dataworking_rem)
  index_org<- order(dataworking[,"primary_key_1644"])
  dataworking <- dataworking[index_org,]
}

save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))
# Write completed.text
write("TREATMENT_COMPLETED",file=paste(output_path,"completed.txt",sep="/"))
#----------------------------------------------------------------------------------------------