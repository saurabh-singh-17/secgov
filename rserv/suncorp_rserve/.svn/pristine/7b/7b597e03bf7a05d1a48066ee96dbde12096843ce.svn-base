#=================================================================================
#parameters required
#=================================================================================
# deactivated_var <- c()
# grp_flag <- '1_1_1'
# n_grp <- '0'
# inputpath <- 'D:/data'
# outputpath <- 'D:/temp'
# n <- '150'
# n_1 <- ''
# seed <- '55'
# out <- 'strata5'
# out_1 <- ''
# indicatorvarname <- '11'
# indicatorvarname_1 <- ''
# strataVar <- c('geography')
# without_replacement <- c()
#=================================================================================
#parameter play
#=================================================================================


c_path_in          <- input_path
c_path_out         <- output_path
n_grp              <- as.numeric(n_grp)
sample1_id         <- indicatorvarname
method             <- 'SRS'


c_strata_variable  <- strataVar
c_susv             <- c(0)  
c_swsv             <- c(0)
c_grp_flag         <- grp_flag


if(length(c_strata_variable)>0)
{
  c_susv           <- c(1)
  c_swsv           <- c(0)
}else
{
  c_swsv             <- c(1)
  c_susv             <- c(0)
}


c_var_grp          <- paste("grp", n_grp, "_flag", sep="")

library(sampling)
#==================================================================================
# loading/reading the csv file 
#================================================================================== 
# load(file=paste(c_path_in, "/", c_data_in, ".RData", sep=""))
# dataworking <- read.csv(file=paste(c_path_in, "/", c_data_in, ".csv", sep=""), 
#                         stringsAsFactors=F)

load(paste(c_path_in,"/dataworking.RData",sep=""))

#=================================================================================
#subsetting the data for required panel
#=================================================================================
runcount <- 1
if((out_1 == '')==FALSE){
  runcount <- 2
}
for(i in 1:runcount){
  
  if(i==2)
  {
    n<-n_1
    out<-out_1
    c_path_out         <- output_path_1
    if(length(without_replacement)>0)
    {
      without_replacement <- c(without_replacement,sample1_id)
    }
    
    indicatorvarname<-indicatorvarname_1
    seed<-as.numeric(seed)+10
    
  }
  subset <- T
  n_sample_size      <- as.numeric(n)
  c_indicator        <- paste('in_',indicatorvarname,sep="")
  n_seed             <- as.numeric(seed)
  
  # select=setdiff(names(dataworking),deactivated_var)
  data     <- subset(x=dataworking, subset=subset, select=active_var)
  if(n_grp) {
    subset <- data[, c_var_grp] == c_grp_flag
    data     <- subset(x=data, subset=subset, select=active_var)
  }
  if(length(without_replacement)>0) {
    indicators <- paste("in_",without_replacement,"=='0'",sep="",collapse="&")
    data<-subset(data,eval(parse(text=indicators)),select=active_var)
    apply_subset<-F
  }
 
  file.remove(paste(c_path_out,"/ERROR.txt",sep=""))
  
  if (nrow(data)< n_sample_size){
    write("Number of rows after subsetting for selected per group by is less than sample size provided",
          file=paste(c_path_out,"/ERROR.txt",sep=""))
    stop("Number of rows after subsetting for selected per group by is less than sample size provided")
  }
  if(n_seed)
  {
    set.seed(seed=n_seed)
  }
  
  
  #==========================================================================================
  # sampling without strata variable
  #==========================================================================================
  
  n_records <- nrow(data)
  sam <-NULL
  if(c_swsv==1)
  {  
    sam            <- srswor(n_sample_size[1],n_records[1])
    names          <- names(data)
    sample_dataset <- subset(x=data, subset=as.logical(sam),select=names(data))
    #  index          <- which(sam!=0)
    
    
  }
  
  #==========================================================================================
  # sampling with strata variable
  #==========================================================================================
  
  if(c_susv==1)
  {
    # calculating
    new<-as.vector(table(data[c_strata_variable]))
    new<-as.vector(ceiling((new/nrow(data))*(n_sample_size)))
    data<-data[do.call("order", data[c_strata_variable]), ]
    
    rec_error <- try(sam <- as.data.frame(strata(data=data,stratanames=
                                                   c_strata_variable,size=new,method="srswor")),silent=T)
    if (class(rec_error) == "try-error"){
      write(paste("Not enough observations in one/multiple stratums in ",c_strata_variable,
                  ". This could be possible because of NA's in the variable.",sep=""),
            file=paste(c_path_out,"/ERROR.txt",sep=""))
      stop(paste("Not enough observations in one/multiple stratums in ",c_strata_variable,
                 ". This could be possible because of NA's in the variable.",sep=""))
    }
    
    index          <- sam[,"ID_unit"] 
    subset         <- rep(F,nrow(data))
    subset[index]  <- T
    names          <- names(data)
    sample_dataset <- subset(x=data, subset=subset,select=names(data))
  }
  
  sd_index       <- sample_dataset$primary_key_1644
  index          <-which(dataworking$primary_key_1644 %in% sd_index)
  dataworking[,c_indicator]             <- 0
  dataworking[index,c_indicator]        <- 1
  write.csv(dataworking, paste(c_path_in, "/dataworking",".csv",
                               sep=""),row.names=F, quote=F) 
  
  #Removes the unnecessary columns from the sample dataset
  cols<-colnames(dataworking)
  sample_indexes<-grep(pattern = "in_[1234567890]{1,}",cols,perl=TRUE,fixed=FALSE)
  if(length(sample_indexes)>0){
    sample_dataset<-sample_dataset[-sample_indexes]
  }
  groupby_indexes<-grep(pattern = 'grp[1234567890]{1,}_flag',cols, fixed=FALSE, perl=TRUE)
  if(length(groupby_indexes)>0){
    sample_dataset<-sample_dataset[-groupby_indexes]
  }
  
  sample_dataset$primary_key_1644<-NULL
  
  
  
  
  write.csv(sample_dataset, paste(c_path_out, "/",out,".csv",
                                  sep=""),row.names=F, quote=F) 
  
  save(dataworking,file=paste(c_path_in,"/dataworking.RData",sep=""))
  
  #==================================================================================
  # completed txt
  #==================================================================================
  write("completed", file=paste(c_path_out, "/randomsampling_completed", ".txt",
                                sep=""))
  #==================================================================================
  
  
}



