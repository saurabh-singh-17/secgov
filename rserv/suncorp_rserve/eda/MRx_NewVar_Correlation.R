#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_NewVarCorrelation_1.0                                                        --#
#-- Description  :  Contains some functions to enable correlation in MRx                             --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#



#-----------------------------------------------------------------
# Parameters required
#-----------------------------------------------------------------
#prefix="nVar"
#input_path="C:\\MRx\\sas\\newProject_SAS-7-Oct-2012-16-28-55\\1"
#output_path="C:\\MRx\\sas\\newProject_SAS-7-Oct-2012-16-28-55\\1"
#csv_path="C:\\MRx\\sas\\newProject_SAS-7-Oct-2012-16-28-55\\1\\0\\1_1_1\\EDA\\Correlation\\4"
#adstock_type=""
#dataset_name="dataworking"
#-----------------------------------------------------------------



#-----------------------------------------------------------------
# Reading the Correlation new variable csv  
#-----------------------------------------------------------------
variables=read.csv(paste(csv_path,"/corr_varCreation.csv",sep=""),header=T,stringsAsFactors=F)
#-----------------------------------------------------------------



#-----------------------------------------------------------------
# Doing all the changes
#-----------------------------------------------------------------
variables[,"transform"] <- gsub(pattern=" ",replacement="",x=variables[,"transform"],ignore.case=T)
variables[,"transform"] <- gsub(pattern="reciprocal",replacement="rec",x=variables[,"transform"],ignore.case=T)
variables[,"transform"] <- gsub(pattern="square",replacement="sqr",x=variables[,"transform"],ignore.case=T)
variables[,"transform"] <- gsub(pattern="cube",replacement="cub",x=variables[,"transform"],ignore.case=T)
variables[,"transform"] <- gsub(pattern="Cosine",replacement="cos",variables$transform,fixed=TRUE)
variables[,"transform"] <- gsub(pattern="Sine",replacement="sin",variables$transform,fixed=TRUE)
variables[,"transform"] <- gsub(pattern="Log",replacement="log",variables$transform,fixed=TRUE)
variables[,"transform"] <- gsub(pattern="decay",replacement="ad",variables$transform,fixed=TRUE)
variables[,"transform"] <- gsub(pattern="lag",replacement="lg",variables$transform,fixed=TRUE)
variables[,"transform"] <- gsub(pattern="lead",replacement="ld",variables$transform,fixed=TRUE)
#-----------------------------------------------------------------



#-----------------------------------------------------------------
# Making the variable names
#-----------------------------------------------------------------
varNames <- NULL

index <- which(!is.na(as.numeric(variables[,"transform"])))
if(length(index)) {
  varNames <- paste("bc_",
                    gsub(pattern="\\.|\\-",
                         replacement="_",
                         x=as.character(variables[index,"transform"])),
                    "_",
                    substr(x=variables[index,"x_vars"],start=1,stop=24),
                    sep="")
  
  variables <- variables[-index, ]
}

if(nrow(variables)) {
  index    <- grep(pattern="-",x=variables[,"transform"])
  
  indexminus <- 1:nrow(variables)
  if(length(index))
    indexminus <- indexminus[-index]
  varNames <- c(varNames,
                paste(variables[indexminus,"transform"],variables[indexminus,"x_vars"],sep="_"))
  
  if(length(index)) {
    temp  <- variables[grep(pattern="-",x=variables[,"transform"]),"transform"]
    temp  <- unlist(strsplit(x=temp,split="-"))
    alpha <- temp[(1:length(temp))%%2!=0]
    num   <- temp[(1:length(temp))%%2==0]
    num[which(alpha=="ad")] <- paste("_",num[which(alpha=="ad")],sep="")
    temp  <- variables[grep(pattern="-",x=variables[,"transform"]),"x_vars"]
    temp  <- paste(alpha,"_",temp,num,sep="")
    varNames <- c(varNames,temp)
  }
  varNames <- gsub(pattern=" ",replacement="",x=varNames)
}

varNames <- gsub(pattern="[^[:alnum:]]",replacement="_",x=varNames)
#-----------------------------------------------------------------



#-----------------------------------------------------------------
# Taking the variables in varNames from corr_charts.csv and adding them to dataworking
#-----------------------------------------------------------------
# Reading corr_charts.csv
corr_charts_csv <- read.csv(paste(csv_path,"/corr_charts.csv",sep=""),header=T)

# Taking the variables in varNames from corr_charts.csv
corr_charts_csv <- as.data.frame(corr_charts_csv[,varNames])

# Prefixing the prefix to the variable names
colnames(corr_charts_csv) <- paste(prefix,"_",substr(varNames,1,27),sep="")

# Loading the dataset
load(paste(input_path,"/dataworking.RData",sep=""))

# Adding the new variables to dataworking
dataworking <- cbind.data.frame(dataworking,corr_charts_csv)

# Saving the dataset
save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))

# ======================================================
# code for updating the dataset properties information
# ====================================================== 

source(paste(genericCode_path,"datasetprop_update.R",sep="/"))

# ------------------------------------------------------

# Required Output
colname <- as.data.frame(names(corr_charts_csv))
colnames(colname) <- "newVar"
write.csv(colname,paste(output_path,"/corr_newVar.csv",sep=""),row.names=FALSE,quote=FALSE)
write.csv(colname,paste(csv_path,"/corr_newVar.csv",sep=""),row.names=FALSE,quote=FALSE)
#-----------------------------------------------------------------