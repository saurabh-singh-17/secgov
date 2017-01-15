#====================Categorical Variable missing detection code======================= 
#Written by : Tushar Gupta
#Time       : July 2014
#Purpose    : Categorical missing detection code for across Dataset option 
#====================================================================================== 
#==============================SAMPLE PARAMETERS=======================================
#input_path <-'D:/datasets/CSV DATASETS/dataworking.csv'
#ouput_path <- 'D:/datasets/CSV DATASETS/'
#categorical_varlist  <- c('Chiller_flag',"Store_Format",'channel_1')
#grp_vars   <- c('Store_Format')
#data       <- read.csv("D:/datasets/CSV DATASETS/Cluster_EDA.csv")
#======================================================================================   

#data <-read.csv("D:/datasets/CSV DATASETS/dataworking_new.csv")
#==============================LOADING THE DATASET=====================================
load(paste(input_path,"/dataworking.RData",sep=""))
data <- dataworking
#====================================================================================== 
# For converting factors to character if any
#====================================================================================== 
for (i in 1:length(categorical_varlist)){
  if (class(data[,categorical_varlist[i]])=="factor"){
    data[,categorical_varlist[i]] <- as.character(data[,categorical_varlist[i]])
  }
}

#============================INITIALIZING DATAFRAME====================================
# For different variables loop has been applied later, each variable's table gets 
# appended in this initialized data frame
#====================================================================================== 
split_final <-data.frame() 



#=========================LOOPING FOR MULTIPLE VARIABLES===============================
for (i in 1:length(categorical_varlist)){
  
  
  #====================================================================================   
  #   This condition is checked for numeric variables to convert NA's back to missing 
  #   For string missing remains as missing so no need to check
  #====================================================================================   
  
  #   if (class(data[,categorical_varlist[i]]) != "character"){
  index <- c(which(is.na(data[,categorical_varlist[i]])),which(data[,categorical_varlist[i]]==""))
  if (length(index) != 0) {
    data[index,categorical_varlist[i]] <- "MISSING"
  }
  
  
  
  #====================================================================================  
  
  #==================================================================================== 
  # This condition checks whether the scenario is across dataset or across grp by,
  # else part of the loop takes care of across dataset   
  #====================================================================================
  
  #   if (grp_vars!=""){
  #     
  #     # concatenates the grpbyvars into one variables to use later for aggregate function
  #     dummy_var                     <- data.frame(apply(data[grp_vars],1,
  #                                                         function(x){paste(x,collapse="_")}))
  #     data                          <- cbind(data,dummy_var)
  #     colnames(data)[ncol(data)]    <-"dummy"
  #     split                         <- as.data.frame(aggregate(x=data[,var[i]],
  #                                                                by=list(data[,"dummy"]),
  #      store_final <-""                                                          FUN=length))
  #     for (i in 1:unique(data[,grp_vars[i]])){
  #       store_new <-length(which(is.na(data[,var[i]],)))
  #       store_final <- c(store_new,store_final)
  #     }
  #   }else{
  split                         <- as.data.frame(aggregate(x=data[,categorical_varlist[i]],
                                                           by=list(data[,categorical_varlist[i]]),
                                                           FUN=length))
  
  
  
  
  #====================================================================================   
  #For calculating row percent and cummulative percentage
  #====================================================================================
  
  total_value                     <- sum(as.numeric(split$x),na.rm=TRUE)
  row_percentage                  <- (split$x / total_value) * 100
  split                           <- cbind(split,row_percentage)
  variable                        <- rep(categorical_varlist[i],nrow(split))
  split                           <- cbind(split,variable)
  cumulative_sum                  <- cumsum(x=split$x)
  cumm_percentage                 <- as.vector((cumulative_sum/total_value)*100)
  #   ordered                         <- order(cumm_percentage,decreasing=F)
  #   cumm_percentage                 <- cumm_percentage[ordered]
  split                           <- cbind(split,cumm_percentage)
  
  if (length(index)==0) {
    Group.1<-c(split$Group.1,"MISSING")
    x <- c(split$x,0)
    row_percentage<- c(split$row_percentage,0)
    cumm_percentage<-c(split$cumm_percentage,0)
    variable <- c(as.character(split$variable),categorical_varlist[i])
    split<-data.frame(Group.1,x,row_percentage,variable,cumm_percentage,stringsAsFactors=FALSE)
  }
  
  split_final                     <- rbind.data.frame(split_final,split)
}

#======================================================================================
# Rearranging columns and naming the columns according to the requirement
#====================================================================================== 

split_final <- split_final[,c(4,1,2,3,5)]
colnames(split_final) <- c('variable','levels','num_obs','percent_obs','cumm_per_obs')
split_final[,"actual_name"]  <- split_final[,"variable"] 

#======================================================================================
# exporting the split_final dataset to csv for flex to read it
#======================================================================================

write.csv(x=split_final,file=paste(output_path,"/CategoricalSummary.csv",sep="")
          ,row.names=F ,quote=F)


#======================================xxxx============================================
write("completed",paste(output_path,"/CATEGORICAL_DETECTION_COMPLETED.txt",sep=""))


