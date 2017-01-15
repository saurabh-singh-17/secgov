#R-Code
#last edited by saurabh singh

#For missing detection 
#   With/without special value
#For outlier detection-
#   Based on IQR
#     one tailed/two tailed
#   Based on percentile

#=============================Sample Parameters================================== 
# input_path <- 'C:/Users/Tushar.Gupta/MRx/r/g_new-29-Sep-2014-10-24-20/1'
# output_path <- 'C:/Users/Tushar.Gupta/MRx/r/g_new-29-Sep-2014-10-24-20/1/0/1_1_1/variabletreatment'
# var_list <- c('ACV','black_hispanic')
# flag_missing <- 'true'
# outlier_type_side <- one/two/perc
# missing_spl <- c()
# iqr_value <- 2
# perc_lower <- 
# perc_upper <- 
# grp_vars <- ''
# flag_outlier <- 'true'
#================================================================================== 

#=================================================================================
# In Case percentiles mentioned by the user
#================================================================================= 
perc_lower <- as.numeric(perc_lower)
perc_upper <- as.numeric(perc_upper)
#=================================================================================

#=================================================================================
#loading the dataset 
#================================================================================= 
load(paste(input_path,"/dataworking.RData",sep=""))
data <- dataworking
rm("dataworking")
#data<-read.csv(paste(input_path,sep=""))
#================================================================================= 
if (n_grp != 0){
  index_s <- which(data[,paste("grp",n_grp,"_flag",sep="")]==grp_flag)
  data<- data[index_s,]
}
#=================================================================================
#if across group by option is selected
#================================================================================= 
if(grp_vars != ""){
  
  newVar                        <-  data.frame(apply(data[grp_vars],1,function(x){paste(x,collapse="_")}))
  data                          <-cbind(data,newVar)
  colnames(data)[ncol(data)]    <-"dummy"
  unique_val<-unique(newVar)
}else{
  unique_val                    <-NULL
}

if(is.null(unique_val)){
  data$dummy                    <-0
  unique_val                    <-as.data.frame(0)
}

subset.org                      <- subset(data, select=c(var_list, "dummy"))
#================================================================================= 
# for (tempi in 1:ncol(subset.org)) {
#   subset.org[, tempi] <- as.numeric(as.character(subset.org[, tempi]))
# }

try(unlink(paste(output_path, "multiVar_detection.csv", sep="/")),silent=TRUE)
#================================================================================== 
# Making vector for pre defined percentile valyes to be shown in the front end 
#================================================================================== 
perc_values      <- c(0,.02,.04,.06,.08,.1,.2,.3,.4,.5,.25,.75,.95,.96,.97,.98,.99, .991, .992, .993, .994, .995, .996, .997, .998, .999, 1)
output           <- as.data.frame(NULL)
perc             <- as.data.frame(NULL)

outputfinal      <-NULL
percfinal        <-NULL
#================================================================================== 
for(j in 1:nrow(unique_val))
{
  subset            <-as.data.frame(subset.org[c(which(subset.org$dummy == unique_val[j,1])),var_list])
  colnames(subset)  <-var_list
  for (i in 1:length(var_list))
  {
    #===============================================================================
    #   
    output[i, "variable"]        <- var_list[i]
    #     missing_index<-NULL
    #     outlier_index<-NULL
    if (flag_missing == "true")
    {
      
      output[i, "missing_count"] <- length(which(is.na(subset[var_list[i]]))==T)
      #=================================================================================       
      #In case value has been specified to be treated as missing
      #================================================================================= 
      if (!is.null(missing_spl))
      {
        output[i, "missing_count"] <- output[i, "missing_count"] + length(which(subset[,var_list[i]] %in% missing_spl))
        #         missing_index<-c(missing_index,which(subset[,var_list[i]] %in% missing_spl))
      }
      #================================================================================= 
      output[i, "missing_perc"] <- (output[i, "missing_count"]/nrow(subset))*100
    }
    #=================================================================================
    # If outlier detection has been selected
    #================================================================================== 
    if (flag_outlier == "true")
    {
      
      #based on IQR criteria       
#       if (outlier_type_side == "iqr")
#       {
        if (outlier_type_side == "two")
        {
          output[i, "upper_cutoff"]   <- quantile(as.numeric(subset[,var_list[i]]), 0.75, na.rm=TRUE) + (iqr_value * IQR(subset[,var_list[i]], na.rm=TRUE))
          output[i, "lower_cutoff"]   <- quantile(as.numeric(subset[,var_list[i]]), 0.25, na.rm=TRUE) - (iqr_value * IQR(subset[,var_list[i]], na.rm=TRUE))
          output[i, "outlier_count"]  <- length(which(subset[,var_list[i]] > output[i, "upper_cutoff"] | subset[,var_list[i]] < output[i, "lower_cutoff"]))
          #           outlier_index   <- c(outlier_index,which(subset[,var_list[i]] > output[i, "upper_cutoff"] | subset[,var_list[i]] < output[i, "lower_cutoff"]))
        }
        if (outlier_type_side == "one")
        {
          output[i, "upper_cutoff"]   <- quantile(as.numeric(subset[,var_list[i]]), 0.75, na.rm=TRUE) + (iqr_value * IQR(subset[,var_list[i]], na.rm=TRUE))
          output[i, "outlier_count"]  <- length(which(subset[,var_list[i]] > output[i, "upper_cutoff"]))
          #           outlier_index <- c(outlier_index,which(subset[,var_list[i]] > output[i, "upper_cutoff"]))
        }
#       }
      #based on percentile       
      if (outlier_type_side == "perc")
      {
        if (!is.null(perc_upper))
        {
          output[i, "upper_cutoff"]    <- quantile(subset[,var_list[i]], perc_upper/100, na.rm=TRUE)
        }
        if (!is.null(perc_lower))
        {
          output[i, "lower_cutoff"] <- quantile(subset[,var_list[i]], perc_lower/100, na.rm=TRUE)
        }
        
        if (!is.null(perc_upper) & !is.null(perc_lower))
        {
          output[i, "outlier_count"] <- length(which(subset[,var_list[i]] > output[i, "upper_cutoff"] | subset[,var_list[i]] < output[i, "lower_cutoff"]))
          #           outlier_index<-c(outlier_index,which(subset[,var_list[i]] > output[i, "upper_cutoff"] | subset[,var_list[i]] < output[i, "lower_cutoff"]))
        }
        if (!is.null(perc_upper) & is.null(perc_lower))
        {
          output[i, "outlier_count"] <- length(which(subset[,var_list[i]] > output[i, "upper_cutoff"]))
          #           outlier_index<-c(outlier_index,which(subset[,var_list[i]] > output[i, "upper_cutoff"]))
        }
        if (is.null(perc_upper) & !is.null(perc_lower))
        {
          output[i, "outlier_count"] <- length(which(subset[,var_list[i]] < output[i, "lower_cutoff"]))
          #           outlier_index<-c(outlier_index,which(subset[,var_list[i]] < output[i, "lower_cutoff"]))
        }
      }
      output[i, "outlier_perc"] <- (output[i, "outlier_count"]/nrow(subset))*100
    }
    
    output[i, "mean"] <- mean(as.numeric(subset[,var_list[i]]), na.rm=TRUE)
    output[i, "median"] <- median(as.numeric(subset[,var_list[i]]), na.rm=TRUE)
    
    
    if(length(which.max(subset[,var_list[i]])) != 0)
    {
      output[i, "mode"] <- subset[,var_list[i]][which.max(subset[,var_list[i]])]
    }else{output[i, "mode"]<-'NA'}
    output[i,"grp_var"]<-unique_val[j,1]
    # input the index of missing values and outliers
    #     output[i,"missing_index"] <- paste(missing_index,sep = "#",collapse = "#")
    #     output[i,"outlier_index"] <- paste(outlier_index,sep = "#",collapse = "#")
    
  }
  output1<-output
  
  outputfinal<-rbind(outputfinal,output1)
}
#================================================================================ 
#For binding the default percentile values shown in the frontend 
#================================================================================ 
for(k in 1:nrow(unique_val))
{
  subset<-as.data.frame(subset.org[c(which(subset.org$dummy == unique_val[k,1])),var_list])
  colnames(subset)<-var_list
  for (i in 1:length(var_list))
  {
    for (j in 1:length(perc_values))
    {
      perc[i,j] <- quantile(as.numeric(subset[,var_list[i]]), perc_values[j], na.rm=TRUE)
    }
    
    colnames(perc) <- c('p_0','p_0_2','p_0_4','p_0_6','p_0_8','p_1','p_2','p_3','p_4','p_5','p_25','p_75','p_95','p_96','p_97','p_98','p_99','p_99_1','p_99_2','p_99_3','p_99_4','p_99_5','p_99_6','p_99_7','p_99_8','p_99_9','p_100') 
  }
  perc1<-perc
  percfinal<-rbind(percfinal,perc1)
  
}
output <- cbind(outputfinal, percfinal)
#================================================================================== 
if(exists('grp_vars')==FALSE){
  output<-output[-c(which(colnames(output)=="grp_var"))]
}

#================================================================================
#writing csvs
#================================================================================ 
write.csv(output, file = paste(output_path, "multiVar_detection.csv", sep="/"), quote=FALSE, row.names=FALSE)

#completed.text
write("MULTIVAR_DETECTION_COMPLETED", file = paste(output_path, "MULTIVAR_DETECTION_COMPLETED.txt", sep="/"))# 
