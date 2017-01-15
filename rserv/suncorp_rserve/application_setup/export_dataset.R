#-------------------------------------------------------------------------------
# parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/project_setup/sort_and_filter/<scenario>/param_verify_and_save.R
# inputpath                      : path of input dataset(dataworking.RData)
# outputpath                     : path of the output from this code
# indata                         : name of the filter scenario
# outdata                        : filter condition description
# keep                           : sort condition description
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# inputpath                      <- /../<dataset>/
# outputpath                     <- /../
# indata                         <- <string>
# outdata                        <- <string>
# keep                           <- <variable>

# inputpath                        <- c("D:/data")
# outputpath                       <- c("D:/temp")
# indata                           <- c("dataworking")
# outdata                          <- c("hahaha")
# keep                             <- c("ACV", "sales")

c_path_in                        <- inputPath
c_path_out                       <- outputPath
c_data_out                       <- newdatasetname
c_var_keep                       <- variables
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the dataset
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# exporting the dataset
#-------------------------------------------------------------------------------
write.csv(dataworking[, c_var_keep, drop=FALSE],
          paste(c_path_out, "/", c_data_out, ".csv", sep=""),
          quote=TRUE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="completed",
      file=paste(c_path_out, "/completed.txt", sep=""))
#-------------------------------------------------------------------------------