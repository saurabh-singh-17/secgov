#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  Export Dataset                                                      --#
#-- Description  :  Read and Write csv file for export dataset link button               --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Saurabh Vikash Singh                                                            --#                 
#----------------------------------------------------------------------------------------------------#

#Parameters required
#----------------------------------------------------------------
#input_path <- 'C:/MRx/sas/fdy-16-Oct-2012-14-17-19/1/'
#output_path <- 'D:/'
#app_datasetname<- 'dataworking'
#dataset_name <- 'dataset1'    #file name for output.



#Libraries required
#-----------------------------------------------------------------
#NONE

#For deleting output file
#-----------------------------------------------------------------
sink()
close(outputFile)
# flush(outputFile)
unlink(paste(output_path,"output.ROUT",sep="/"))


#Reading the dataset
#------------------------------------------------------------------
  # input_path = paste(input_path,"/dataworking.csv",sep="")
  #input_path1<- paste(input_path1,".csv",sep="")
  # dataworking=read.csv(input_path,header=T)
  load(paste(input_path,"/dataworking.RData",sep=""))

#Exporting the dataset
#-------------------------------------------------------------------
  output_path<- paste(output_path,"/",sep="")
  datasetName1 =paste(output_path,dataset_name,".csv",sep="")
  write.csv(dataworking,file = datasetName1 ,quote=FALSE, row.names=FALSE)
  
