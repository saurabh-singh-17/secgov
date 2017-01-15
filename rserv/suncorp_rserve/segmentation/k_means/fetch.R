#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# rm(list=ls())
# c_path_in        <- c('D:/data')
# c_path_iter      <- c('D:/')
# c_path_out       <- c('D:/temp')
# c_var_in_fetch   <- c('Date', 'ACV', 'sales')
# n_obs_start      <- c(11)
# n_obs_stop       <- c(21)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
c_csv_fetch           <- c('fetch')
c_data_iter           <- c('final_cluster')
c_rdata_cluster       <- "df_cluster"
c_txt_completed       <- c('completed')
c_txt_error           <- c('error')
c_txt_warning         <- c('warning')
c_var_cluster         <- c('murx_n_cluster')
c_var_in_fetch        <- unique(c_var_in_fetch)
c_var_key             <- c('primary_key_1644')
c_file_delete         <- c(paste(c_path_out, "/", c_csv_fetch, ".csv", sep=""),
                           paste(c_path_out, "/", c_txt_error, ".txt", sep=""),
                           paste(c_path_out, "/", c_txt_warning, ".txt", sep=""),
                           paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
n_obs_start           <- as.numeric(n_obs_start)
n_obs_stop            <- as.numeric(n_obs_stop)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# delete file
#-------------------------------------------------------------------------------
for (tempi in c_file_delete) {
  unlink(x=tempi)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# fetch
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
load(file=paste(c_path_iter, "/", c_rdata_cluster, ".RData", sep=""))
df_fetch <- cbind.data.frame(dataworking[n_obs_start:n_obs_stop,
                                         c(c_var_in_fetch, c_var_key), drop=FALSE],
                             df_cluster[n_obs_start:n_obs_stop,
                                        c_var_cluster, drop=FALSE])
rm(list=c("dataworking", "df_cluster"))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : fetch csv
#-------------------------------------------------------------------------------
write.csv(df_fetch, paste(c_path_out, "/", c_csv_fetch, ".csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------