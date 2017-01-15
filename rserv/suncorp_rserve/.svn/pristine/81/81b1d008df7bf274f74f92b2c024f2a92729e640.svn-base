#-------------Sample Parameters-----------------------------------------------------

#c_path_in <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1'
#c_path_out <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1/0/1_1_1/KMEANS/1/6'
#c_path_iter <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1/0/1_1_1/KMEANS/1/6'
#c_var_in_addvar <- c('black_hispanic','channel_1')


#-------------------------------------------------------------------------------------


c_csv_addvar           <- c('addvar')
c_data_iter           <- c('final_cluster')
c_rdata_cluster       <- "df_cluster"
c_csv_CS              <- "ClusterMeans_BasicProf"
c_txt_completed       <- c('completed')
c_txt_error           <- c('error')
c_txt_warning         <- c('warning')
c_var_cluster         <- c('murx_n_cluster')
c_var_in_addvar        <- unique(c_var_in_addvar)
c_var_key             <- c('primary_key_1644')
c_file_delete         <- c(paste(c_path_out, "/", c_csv_addvar, ".csv", sep=""),
                           paste(c_path_out, "/", c_txt_error, ".txt", sep=""),
                           paste(c_path_out, "/", c_txt_warning, ".txt", sep=""),
                           paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# delete file
#-------------------------------------------------------------------------------
for (tempi in c_file_delete) {
  unlink(x=tempi)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# find means of new variable
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
load(file=paste(c_path_iter, "/", c_rdata_cluster, ".RData", sep=""))
df_addvar <- merge.data.frame(x=dataworking[,c(c_var_in_addvar, c_var_key)],
                             df_cluster[,c(c_var_cluster,c_var_key)],by = c_var_key )
rm(list=c("dataworking", "df_cluster"))
#-------------------------------------------------------------------------------

final<-aggregate(df_addvar[c_var_in_addvar],df_addvar[c_var_cluster],mean, na.rm=TRUE)
names(final)[names(final) == c_var_cluster] <- 'Cluster'
#-------------------------------------------------------------------------------
# merge the existing cluster means csv with new values
#-------------------------------------------------------------------------------
#df_cs <- read.csv(paste(c_path_out, "/", c_csv_CS, ".csv", sep=""))
#df_cs<-merge(df_cs, final[,c("Cluster",setdiff(colnames(final),colnames(df_cs)))], by="Cluster") 

#-------------------------------------------------------------------------------
# output : addvar csv and Cluster Means csv
#-------------------------------------------------------------------------------
write.csv(final, paste(c_path_out, "/", c_csv_addvar, ".csv", sep=""),
          row.names=FALSE, quote=FALSE)
write.csv(final, paste(c_path_out, "/", c_csv_CS, ".csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------

