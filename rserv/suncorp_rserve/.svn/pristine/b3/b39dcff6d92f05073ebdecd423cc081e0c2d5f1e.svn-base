#-------------------------------------------------------------------------------
# parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/project_setup/sort_and_filter/param_boxes.R
# c_path_in                      : path of input dataset(dataworking.RData)
# c_path_out                     : path of the output from this code
# c_var_in_categorical           : categorical variable(s) selected
# c_var_in_continuous            : continuous variable(s) selected
# c_varid_in_date                : date variable(s) selected
# n_varid_in_categorical         : id of categorical variable(s) selected
# n_varid_in_continuous          : id of continuous variable(s) selected
# n_varid_in_date                : id of date variable(s) selected
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# c_path_in                      <- /../<dataset>/
# c_path_out                     <- /../<dataset>/project_setup/sort_and_filter/<scenario>/
# c_var_in_categorical           <- <variable>
# c_var_in_continuous            <- <variable>
# c_varid_in_date                <- <variable>
# n_varid_in_categorical         <- <number>
# n_varid_in_continuous          <- <number>
# n_varid_in_date                <- <number>

# c_path_in                      <- c("D:/data")
# c_path_out                     <- c("D:/temp")
# c_var_in_categorical           <- c("Chiller_flag")
# c_var_in_continuous            <- c("ACV", "sales")
# c_var_in_date                  <- c("Date")
# n_varid_in_categorical         <- c(1)
# n_varid_in_continuous          <- c(2,5)
# n_varid_in_date                <- c(7)
#-------------------------------------------------------------------------------






#-------------------------------------------------------------------------------
# preparing
#-------------------------------------------------------------------------------
unlink(x = paste(c_path_out, "/completed.txt", sep=""))
unlink(x = paste(c_path_out, "/filterData.csv", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the dataset
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# initialising the outputs
#-------------------------------------------------------------------------------
c_values                         <- character(0)
n_ID                             <- numeric(0)
c_variable                       <- character(0)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# getting the info for categorical variables
#-------------------------------------------------------------------------------
if (length(c_var_in_categorical)) {
  for (n_i_temp in 1:length(c_var_in_categorical)) {
    c_var_in_categorical_now     <- c_var_in_categorical[n_i_temp]
    x_temp                       <- unique(x=dataworking[, c_var_in_categorical_now])
    x_temp                       <- sort(x=x_temp)
    if (class(x_temp) != "numeric" & class(x_temp) != "integer") {
      n_temp                     <- which(x_temp == "")
      if (length(n_temp)) {
        x_temp                   <- x_temp[-n_temp]
      }
    }
    x_temp                       <- paste(x_temp, collapse="!!")
    c_values                     <- c(c_values, x_temp)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# getting the info for continuous variables
#-------------------------------------------------------------------------------
if (length(c_var_in_continuous)) {
  for (n_i_temp in 1:length(c_var_in_continuous)) {
    c_var_in_continuous_now      <- c_var_in_continuous[n_i_temp]
    x_temp                       <- paste(min(dataworking[, c_var_in_continuous_now],
                                              na.rm=TRUE),
                                          max(dataworking[, c_var_in_continuous_now],
                                              na.rm=TRUE),
                                          sep="!!")
    c_values                     <- c(c_values, x_temp)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# getting the info for date variables
#-------------------------------------------------------------------------------
if (length(c_var_in_date)) {
  for (n_i_temp in 1:length(c_var_in_date)) {
    c_var_in_date_now            <- c_var_in_date[n_i_temp]

    
    x_temp                       <- paste(min(dataworking[, c_var_in_date_now],
                                              na.rm=TRUE),
                                          max(dataworking[, c_var_in_date_now],
                                              na.rm=TRUE),
                                          sep="!!")
    c_values                     <- c(c_values, x_temp)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : boxes.csv
#-------------------------------------------------------------------------------
df_boxes                         <- data.frame(variable=c(c_var_in_categorical,
                                                          c_var_in_continuous,
                                                          c_var_in_date),
                                               ID=c(n_varid_in_categorical,
                                                    n_varid_in_continuous,
                                                    n_varid_in_date),
                                               values=c_values,
                                               stringsAsFactors=FALSE)

write.csv(df_boxes,
          paste(c_path_out, "/filterData.csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="boxes completed.txt",
      file=paste(c_path_out, "/completed.txt", sep=""))
#-------------------------------------------------------------------------------