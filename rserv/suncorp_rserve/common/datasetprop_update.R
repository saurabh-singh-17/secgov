#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  datasetprop_update                                                                     --#
#-- Description  :  used to update the dataset information after a new variable is created                                --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Saurabh Singh                                                                    --#                 
#------------------------------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# loading the data
#------------------------------------------------------------------------------
if(!exists("input_path")) {
  try(expr=assign(x="input_path", value=inputPath), silent=TRUE)
  try(expr=assign(x="input_path", value=c_path_in), silent=TRUE)
}

input_path                       <- gsub("dataworking.RData", "", input_path)
c_path_file_in_data              <- paste(input_path,
                                          "/dataworking.RData",
                                          sep="")
load(c_path_file_in_data)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Creating a dataset with dataset properties
#------------------------------------------------------------------------------
n_file_size                      <- file.info(c_path_file_in_data)$size
n_file_size                      <- round(x=n_file_size/1048576, digits=2)

dataset_properties               <- data.frame(file_name="dataworking",
                                               no_of_obs=nrow(dataworking),
                                               no_of_vars=ncol(dataworking),
                                               file_size=n_file_size)
write.csv(dataset_properties,
          file=paste(input_path,
                     "/dataset_prop.csv",
                     sep=""),
          quote=FALSE,
          row.names=FALSE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# completed txt
#------------------------------------------------------------------------------
write("DATASET_PROPERTIES_COMPLETED", file = paste(input_path, "DATASET_PROPERTIES_COMPLETED.txt", sep="/"))
#------------------------------------------------------------------------------