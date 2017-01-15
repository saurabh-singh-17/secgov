#-------------------------------------------------------------------------------
# code    : qa/UniqueValues.R
# description : loads the dataset
#   finds out the unique values of the specified variables
#   formats the unique values
#   (optional) treats missing values in the specified way
#   pads the unique values with ""
#   writes a csv at the specified location
# purpose : to be called to find the unique values of variables
# author  : Vasanth MM
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameters required
#-------------------------------------------------------------------------------
c_path_in                        <- input_path
c_path_out                       <- output_path
c_var_in                         <- var_list
c_missingTreatment               <- "none"
if (exists("isDQA")) {
  c_missingTreatment             <- "replaceBlanksWithMISSING"
} else {
  c_missingTreatment             <- "NAOmit"
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# load the data
#-------------------------------------------------------------------------------
load(paste(input_path, "/dataworking.RData", sep=""))
dataworking                      <- subset(x=dataworking, select=c_var_in)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# find the unique values
#-------------------------------------------------------------------------------
FUN                              <- function(x) {
  x                              <- unique(x)
  if (!all(is.na(x)) & !all(x %in% "")) {
    x                            <- sort(x)
  }
}
x_output                         <- lapply(dataworking, FUN = FUN)
rm("dataworking")
n_maxLength                      <- max(sapply(x_output, length))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# format the unique values
#-------------------------------------------------------------------------------
x_output                         <- useDateFormat(c_path_in = c_path_in,
                                                  x = x_output)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loop de loop
#-------------------------------------------------------------------------------
for (i in seq_along(x_output)) {
  # convert factor into character
  # so that we can pad the unique values with ""
  x_temp                         <- class(x_output[[i]])
  if (x_temp == "factor") {
    x_output[[i]]                <- as.character(x_output[[i]])
  }
  
  # treat the missing values
  if (c_missingTreatment == "NAOmit") {
    x_output[[i]]                <- na.omit(x_output[[i]])
  } else if (c_missingTreatment == "replaceBlanksWithMISSING") {
    x_temp                       <- which(x_output[[i]] %in% "")
    if (length(x_temp)) {
      x_output[[i]][x_temp]      <- "MISSING"
    }
  }
  
  # pad the unique values with ""
  # to make every variable have the same number of unique values
  # to make a data.frame
  x_output[[i]]                  <- c(x_output[[i]],
                                      rep("", n_maxLength - length(x_output[[i]])))
}
x_output                         <- data.frame(x_output, stringsAsFactors = FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : unique values csv
#-------------------------------------------------------------------------------
write.csv(x_output,
          paste(c_path_out,
                "/uniqueValues.csv",
                sep=""),
          quote=FALSE,
          row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="UNIQUE_VALUES_COMPLETED",
      file=paste(c_path_out,
                 "/UNIQUE_VALUES_COMPLETED.txt",
                 sep=""))
#-------------------------------------------------------------------------------
