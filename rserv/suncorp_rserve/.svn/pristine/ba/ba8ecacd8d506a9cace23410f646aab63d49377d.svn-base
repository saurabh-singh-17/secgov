#-------------Sample Parameters-----------------------------------------------------

#c_path_out  <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1/0/1_1_1/KMEANS/1/5'
#c_path_iter <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1/0/1_1_1/KMEANS/1/5'
#c_path_fetch <- 'C:/Users/nida.arif/MRx/r/clustering_1-21-Jul-2014-12-06-18/1/0/1_1_1'
#c_fetch_variable <- 'neg_channel_1'
#c_no_clusters <- 3
#c_add_observations <- c(2,3,7,4)


#-------------------------------------------------------------------------------------

c_csv_CS              <- "ClusterMeans"
c_csv_fetch           <- "fetch"
c_txt_completed       <- c('completed')
c_txt_error           <- c('error')
c_txt_warning         <- c('warning')
c_var_cluster         <- c('murx_n_cluster')
c_var_key             <- c('primary_key_1644')
c_file_delete         <- c(paste(c_path_out, "/", c_txt_error, ".txt", sep=""),
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
# Reading the Cluster Means csv and Fetch CSV 
#-------------------------------------------------------------------------------
df_cs <- read.csv(paste(c_path_iter, "/", c_csv_CS, ".csv", sep=""),
                  stringsAsFactors=FALSE)
df_cs <- df_cs[1:as.integer(c_no_clusters), ]
x_temp <- colnames(df_cs)

df_fetch <- read.csv(paste(c_path_fetch, "/", c_csv_fetch, ".csv", sep=""),
                     stringsAsFactors=FALSE)
df_fetch <- df_fetch[which(df_fetch[, c_var_key] %in% c_add_observations),]

df_fetch['Cluster'] <- df_fetch[c_fetch_variable]

df_fetch  <- df_fetch[,intersect(colnames(df_cs),colnames(df_fetch))]
df_cs     <- df_cs[,intersect(colnames(df_cs),colnames(df_fetch))]


#-------------------------------------------------------------------------------
# Appending the two data frames
#-------------------------------------------------------------------------------
row.names(df_fetch)<-NULL
df_cs <- rbind(df_cs,df_fetch)
df_cs <- df_cs[x_temp]
#-------------------------------------------------------------------------------
# output : Cluster Means csv
#-------------------------------------------------------------------------------

write.csv(df_cs, paste(c_path_iter, "/", c_csv_CS, ".csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------

