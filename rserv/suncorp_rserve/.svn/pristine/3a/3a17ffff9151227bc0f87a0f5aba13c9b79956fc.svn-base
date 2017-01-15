#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  NumericalCategorical.R                                                           --#
#-- Description  :  Categorizes the variable                      									 --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Arun Pillai                                                                      --#                 
#------------------------------------------------------------------------------------------------------#

# writing a function to recognise  a date format
# source(paste(rcodePath, "/common/functions.R", sep =""))

#------------------------------------------------------------------------------
# parameter play
#------------------------------------------------------------------------------
frequency=as.numeric(frequency)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# loading the data
#------------------------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))
dataworking <- subset(x=dataworking, select=var_names)
#------------------------------------------------------------------------------
# 
# 
# 
# #------------------------------------------------------------------------------
# # Getting the class of all variables
# # Separating them into numeric, string & date 
# #------------------------------------------------------------------------------
c_numeric_string                 <- as.character(sapply(dataworking,class))
c_numeric_string                 <- gsub(pattern="logical",
                                         replacement="numeric",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="integer",
                                         replacement="numeric",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="factor",
                                         replacement="string",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="character",
                                         replacement="string",
                                         x=c_numeric_string)

# n_index_string                   <- which(c_numeric_string == "string")
# if (length(n_index_string)) {
#   x_temp                         <- dataworking[, n_index_string, drop=FALSE]
#   x_temp                         <- apply(as.matrix(x_temp),2,dateformat)
#   x_temp                         <- as.data.frame(x_temp)
#   n_index_date                   <- which(x_temp != "unknown")
#   if (!length(n_index_date)) break
#   n_index_date                   <- n_index_string[n_index_date]
#   c_numeric_string[n_index_date] <- "date"
# }
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Categorical/Continuous
#------------------------------------------------------------------------------
n_freq                           <- sapply(X=dataworking,
                                           FUN=function(x) length(unique(x)))
c_continuous_categorical         <- rep("continuous", length(n_freq))
n_index_categorical              <- which(n_freq <= frequency)
if (length(n_index_categorical)) {
  c_continuous_categorical[n_index_categorical] <- "categorical"
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# output
#------------------------------------------------------------------------------
var.class=data.frame(c_numeric_string,c_continuous_categorical,n_freq,var_names)
names(var.class)=c("NUM_STR","CATEGORY","FREQ","NAME")

write.csv(var.class,
          file = paste(output_path, "categorical_reconfig.csv", sep="/"), 
          quote=FALSE, row.names=FALSE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# completed
#------------------------------------------------------------------------------
write("MANUAL_CATEGORIZATION_COMPLETED",
      file = paste(output_path, "categorical_completed.txt", sep="/"))
#------------------------------------------------------------------------------