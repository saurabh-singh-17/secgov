#-------------------------------------------------------------------------------
# parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/project_setup/sort_and_filter/param_verify_and_save.R
# c_path_in                      : path of input dataset(dataworking.RData)
# c_path_out                     : path of the output from this code
# c_path_filter_param            : path of the param for filtering
# c_path_filter_code             : path of the code for filtering
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# c_path_in                      <- /../<dataset>/
# c_path_out                     <- /../<dataset>/project_setup/sort_and_filter/
# c_path_filter_param            <- /../<dataset>/project_setup/sort_and_filter/<scenario>/param_filter.R
# c_path_filter_code             <- /../project_setup/sort_and_filter.R

# c_path_in                        <- c("D:/data")
# c_path_out                       <- c("D:/temp")
# c_path_filter_param              <- c("D:/temp/param_sort_and_filter.R")
# c_path_filter_code               <- c("D:/code/sort_and_filter.R")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing
#-------------------------------------------------------------------------------
unlink(x=paste(c_path_out, "/completed.txt", sep=""))
unlink(x=paste(c_path_out, "/verify_and_save.csv", sep=""))
source(file=c_path_filter_param)
source(file=c_path_filter_code)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()

for (c.tempi in a.all) {
  
  if (!length(grep(pattern="^(c|n|b|l|x)_", x=c.tempi))) next
  
  x_tempi <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi)) next
  if (x_tempi != "") next
  
  assign(x=c.tempi, value=NULL)
  print(c.tempi)
  
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the dataset
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# filter and sort the dataset
#-------------------------------------------------------------------------------
n_obs_b4                         <- nrow(dataworking)
dataworking                      <- muRx_filter_sort(df_x=dataworking,
                                                     c_text_filter_dc=c_text_filter_dc,
                                                     c_text_filter_vs=c_text_filter_vs,
                                                     c_text_sort=c_text_sort,
                                                     c_var_date_sort_filter=c_var_date_sort_filter,
                                                     c_var_required=colnames(dataworking))
n_obs_a4                         <- nrow(dataworking)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output validation : does the filtered dataset have any observations
#-------------------------------------------------------------------------------
if (n_obs_a4 == 0) {
  c_text_error                   <- "There are 0 observations in the filtered dataset"
  write(x=c_text_error, file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_text_error)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : verify_and_save.csv
#-------------------------------------------------------------------------------
c_temp_1                         <- paste(c(c_text_filter_dc,
                                            c_text_filter_vs),
                                          collapse=" AND ")
c_temp_1                         <- paste("", c_temp_1)
c_temp_2                         <- paste(c_text_sort,
                                          collapse=" AND ")
c_temp_2                         <- paste("", c_temp_2)
c_label                          <- c("Is the filter applicable",
                                      "Number of observations in the original data",
                                      "Number of observations in the filtered data",
                                      "Number of observations lost",
                                      "Filter conditions",
                                      "Sort conditions")
c_value                          <- c(ifelse(test=n_obs_a4>0,
                                             yes="Yes",
                                             no="No"),
                                      n_obs_b4,
                                      n_obs_a4,
                                      n_obs_b4 - n_obs_a4,
                                      c_temp_1,
                                      c_temp_2)
df_verify_and_save               <- data.frame(label=c_label,
                                               value=c_value,
                                               stringsAsFactors=FALSE)
df_verify_and_save[5,2]<-gsub(pattern="\n",replacement="",x=df_verify_and_save[5,2])
df_verify_and_save[5,2]<-gsub(pattern=",",replacement=" ",x=df_verify_and_save[5,2])
write.csv(df_verify_and_save,
          paste(c_path_out, "/verify_and_save.csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="completed",
      file=paste(c_path_out, "/completed.txt", sep=""))
#-------------------------------------------------------------------------------