#===========================Project Header=============================
#Process Name: Category
#Description:  categorises all variables based on the type
#Return type: variable categorization value csv
# Author : 
# date : 06- August 2012
#Version : Version1
#revised by: saurabh vikash singh
#=======================================================================

# writing a function to recognise  a date format
source(paste(rcodePath, "/dateformat.R", sep = ""))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Read dataworking from dataworking.RData
#------------------------------------------------------------------------------
load(paste(output_path,"/dataworking.RData",sep=""))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Getting the class of all variables
# Separating them into numeric, string & date 
#------------------------------------------------------------------------------
variableList <- as.character(sapply(dataworking,class))
variableList <- gsub(pattern="logical",replacement="numeric",x=variableList)
variableList <- gsub(pattern="integer",replacement="numeric",x=variableList)
variableList <- gsub(pattern="factor",replacement="string",x=variableList)

stringIndex  <- which(variableList == "string")
if(length(stringIndex) > 0){
  tempData   <- dataworking[stringIndex]
  tempFormat <- as.data.frame(apply(as.matrix(tempData),2,dateformat))
  dateIndex  <- which(tempFormat != "unknown")
  variableList[stringIndex[dateIndex]] <- "date"
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Getting the length of all the variable names in the dataset
#------------------------------------------------------------------------------
var_len=as.numeric(sapply(names(dataworking),nchar))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Categorical/Continuous
#------------------------------------------------------------------------------
variable_type <- variableList
variable_type <- gsub(pattern="numeric",replacement="continuous",x=variable_type)
variable_type <- gsub(pattern="date",replacement="continuous",x=variable_type)
variable_type <- gsub(pattern="string",replacement="categorical",x=variable_type)
#------------------------------------------------------------------------------
variable <- colnames(dataworking)
distinctvalues <-apply(as.matrix(variable),1,function(x){return(length(unique(dataworking[,x])))})

#------------------------------------------------------------------------------
# Create variable_categorization.csv
#------------------------------------------------------------------------------
variable_categorization <- cbind.data.frame(variable=colnames(dataworking),variable_type,distinctvalues,num_str=variableList,var_len,label="")
write.csv(variable_categorization,paste(output_path,"/variable_categorization.csv",sep=""),row.names=F,quote=F)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# The completed.txt file
#------------------------------------------------------------------------------
write("variable categorization", file = paste(output_path,"/categorical_gof_completed.txt",sep=""))
#------------------------------------------------------------------------------
