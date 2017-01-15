#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#
#-- Project Name :  saveTimeseriesVar                                                                --#
#-- Description  :  Adds the newly created timeseries variable to the dataset and writes saveVar.csv --#
#-- Return type  :  None                                                                             --#
#-- Author       :  Vasanth M M 20feb2013 1835                                                       --#
#-- Last Edited  :                                                                                   --#
#-- Known Issues :                                                                                   --#
#------------------------------------------------------------------------------------------------------#



#------------------------------------------------------------------------------
# Parameters Required
#------------------------------------------------------------------------------
# input_path='D:/timeseries'
# output_path='D:/timeseries/output'
# var_list='sales'
# prefix='ad'
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Reading dataworking.csv
#------------------------------------------------------------------------------
#dataworking <- read.csv(paste(input_path,'dataworking.csv',sep="/"))
load(paste(input_path,'dataworking.RData',sep="/"))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Read the previously saved R object and add it to dataworking
#------------------------------------------------------------------------------
# Load the previously saved R object
load(file=paste(output_path,'timeSeriesVar',sep="/"))
# Add the prefix to the names
names(timeSeriesVar) <- paste(prefix,names(timeSeriesVar),sep="_")
# renaming the timeSeriesVar SC component
names(timeSeriesVar)[2] <- c(paste(prefix,var_list,"SC",sep="_"))
# Add timeSeriesVar to dataworking
dataworking <- cbind(dataworking,timeSeriesVar[2])
# Add the original variable to timeSeriesVar
toBeWritten <- cbind(dataworking[,var_list],timeSeriesVar[2])
# Naming the column newly added to timeSeriesVar
names(toBeWritten) <- c(var_list,paste(prefix,var_list,"SC",sep="_"))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Write dataworking.csv, the newly created dataframe as saveVar.csv and completed.txt
#------------------------------------------------------------------------------
save(dataworking, file=paste(input_path,'dataworking.RData',sep="/"))
write.csv(toBeWritten,paste(output_path,'saveVar.csv',sep="/"),row.names=F,quote=F)
write("MODELING - TIMESERIES_ADVANCED_NEW_VARIABLE_SAVED_COMPLETED",paste(output_path,"TIMESERIES_ADVANCED_NEW_VARIABLE_SAVED_COMPLETED.txt",sep="/"))
#------------------------------------------------------------------------------