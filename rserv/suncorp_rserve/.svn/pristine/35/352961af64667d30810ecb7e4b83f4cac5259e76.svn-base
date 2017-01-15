#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Date_Manipulation_1.0                                                        --#
#-- Description  :  Contains some functions to enable Date Manipulation in MRx                       --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Proma Majumdar                                                                   --#                 
#------------------------------------------------------------------------------------------------------#

#Parameters required
#-----------------------------------------------------------------
# input_path="C:\\MRx\\datevariable-11-Sep-2012-18-48-37\\1"
# output_path="C:\\MRx\\datevariable-11-Sep-2012-18-48-37\\1\\NewVariable\\DateManipulation\\5"
# dataset_name="dataworking"
# pref="ad"
# univariate="true"
# univ_datevars=c("Date" , "Date1")
# univ_func="increment"
# inc_dec_value="2"
# bivariate="true"
# bi_x_datevars=c("Date" , "Date1")
# bi_func="addition"
# bi_y_datevars="ACV"
# bi_y_type="numeric"

#Reading the dataworking.csv  
#----------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))

#Two function definations to enable Date Manipulation in MRx 
#-----------------------------------------------------------------
#Function to perform univariate Date manipulations
#parameter 1 : univ_datevars contains a list of 1 or more selected Date variable
#parameter 2 : univ_func contains the operation (increment or decrement)
#parameter 3 : inc_dec_value is the amount by which increment/decrement has to be done
date_univariate=function(univ_datevars, univ_func, inc_dec_value){
  result <- NULL
  
  for (i in 1:length(univ_datevars)) {
    c_var_in_now  <- univ_datevars[i]
    c_var_new_now <- paste(pref,
                           substr(c_var_in_now,1,18),
                           substring(univ_func,1,4),
                           inc_dec_value,
                           sep="_")
    
    if (univ_func == "increment") {
      newVar <- dataworking[, c_var_in_now] + as.numeric(inc_dec_value)
    }
    if(univ_func == "decrement"){
      newVar <- dataworking[, c_var_in_now] - as.numeric(inc_dec_value)
    }
    newVar <- data.frame(newVar, stringsAsFactors = FALSE)
    colnames(newVar) <- c_var_new_now
    if (i == 1) {
      result <- newVar
    } else {
      result <- cbind.data.frame(result, newVar)
    }
    dateFormat <- getDateFormat(input_path, c_var_in_now)
    setDateFormat(input_path, c_var_new_now, dateFormat)
  }
  return(result)
}

#Function to perform bivariate Date manipulations
#parameter 1 : bi_x_datevars contains a list of 1 or more selected Date variable
#parameter 2 : bi_y_datevars contains the 2nd operand
#parameter 3 : bi_func is the operation(addition/subtraction) to be done
#parameter 3 : bi_y_type is the amount by which the operation(addition/subtraction) has to be done
date_bivariate <- function(bi_x_datevars, bi_y_datevars, bi_func, bi_y_type) {
  result <- NULL
  
  for (i in 1:length(bi_x_datevars)) {   
    c_var_in_now  <- bi_x_datevars[i]
    c_var_new_now <- paste(pref,
                           substr(c_var_in_now,1,10),
                           substring(bi_func,1,3),
                           substring(bi_y_datevars,1,9),
                           sep="_")
    
    if (bi_func == "addition") {
      newVar <- dataworking[, c_var_in_now] + dataworking[, bi_y_datevars]      
    }
    if (bi_func == "subtraction") {
      newVar <- dataworking[, c_var_in_now] - dataworking[, bi_y_datevars]      
    }
    newVar <- data.frame(newVar, stringsAsFactors = FALSE)
    colnames(newVar) <- c_var_new_now
    if (i == 1) {
      result <- newVar
    } else {
      result <- cbind.data.frame(result, newVar)
    }
    
    if (class(newVar[, 1]) == "Date") {
      dateFormat <- getDateFormat(input_path, c_var_in_now)
      setDateFormat(input_path, c_var_new_now, dateFormat)
    }
  }
  return(result)
}

resultDF <- NULL
if (univariate == "true") {
  resultDF=date_univariate(univ_datevars, univ_func, inc_dec_value)
}
if (bivariate=="true") {
  if (is.null(resultDF)) {
    resultDF=date_bivariate(bi_x_datevars, bi_y_datevars, bi_func, bi_y_type)
  } else {
    resultDF=cbind.data.frame(resultDF,
                              date_bivariate(bi_x_datevars, bi_y_datevars, bi_func, bi_y_type))
  }
}
dataworking=cbind.data.frame(dataworking,resultDF)
save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))

#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(resultDF) > 6000) {
  x_temp                       <- sample(x=nrow(resultDF),
                                         size=6000,
                                         replace=FALSE)
  resultDF                     <- resultDF[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#calls the useDateFunction to format date variables into the original format 
#------------------------------------------------------------------------------- 
resultDF <- useDateFormat(c_path_in=input_path ,x = resultDF)
#------------------------------------------------------------------------------- 



#------------------------------------------------------------------------------- 
#output csv containing the new Date variables
#------------------------------------------------------------------------------- 
write.csv(resultDF,paste(output_path,"/new_Datevars.csv",sep=""),quote=FALSE,row.names=FALSE)
#------------------------------------------------------------------------------- 



#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

#writing the completed text at the output location
write("DATE_MANIPULAION_COMPLETED", file = paste(output_path,"/DATE_MANIPULATION_COMPLETED.txt", sep=""))
