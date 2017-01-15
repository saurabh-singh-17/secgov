#-------------------------------------------------------------------------------
# purpose : gets the unique value of date variable(s)
# where it is called from : New Variable Creation > Event Variable
# why it is called for : to populate the from and to values in the calendar
#-------------------------------------------------------------------------------
load(paste(input_path, "/dataworking.RData", sep=""))

for (i in 1:length(var_list)) {
  x_temp                         <- dataworking[, var_list[i]]
  x_temp                         <- c(min(x_temp, na.rm=TRUE),
                                      max(x_temp, na.rm=TRUE))
  x_temp                         <- format(x=x_temp, format="%m/%d/%Y")
  x_temp                         <- data.frame(x_temp, stringsAsFactors = FALSE)
  
  if (i == 1) {
    df_minmax                    <- x_temp
  } else {
    df_minmax                    <- cbind.data.frame(df_minmax, x_temp)
  }
}
colnames(df_minmax)              <- var_list

write.csv(df_minmax,
          file=paste(output_path, "/uniqueValues.csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------
