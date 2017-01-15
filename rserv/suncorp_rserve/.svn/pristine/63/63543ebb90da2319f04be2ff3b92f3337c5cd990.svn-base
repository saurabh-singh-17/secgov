#-------------------------------------------------------------------------------
# purpose : gets the unique value of one variable
# where it is called from : ProjectSetup > ScenarioBuilder
# TODO : can unique values code be used here?
# TODO : why the spec_char_button check?
#-------------------------------------------------------------------------------
if (spec_char_button == "true") {
  load(paste(output_path, "/dataworking.RData", sep=""))
  x_temp                         <- lapply(X = dataworking[var_name],
                                           FUN = function(x) sort(unique(x)))
  #-------------------------------------------------------------------------------
  #calls the useDateFunction to format date variables into the original format 
  #------------------------------------------------------------------------------- 
  x_temp <- useDateFormat(c_path_in=output_path ,x = x_temp)
  #------------------------------------------------------------------------------- 
  df_uniqueValue                 <- data.frame(x_temp[[var_name]],
                                               1:length(x_temp[[var_name]]))
  colnames(df_uniqueValue)       <- c("actual_name", "unique_key")
  write.csv(df_uniqueValue,
            file = paste(output_path, "/variable_missing_grp.csv", sep=""),
            quote = FALSE,
            row.names = FALSE)
  write("VARMISS_GRP_COMPLETED",
        file = paste(output_path, "/VARMISS_GRP_COMPLETED.txt", sep="")) 
}
#-------------------------------------------------------------------------------
