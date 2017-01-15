#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : create_folder 
#-- Description  : creates folders in unix server
#-- Return type  : csv              
#-- Author : saurabh singh
#------------------------------------------------------------------------------------------------------#


#cleaning the folder address

folder_path<-gsub("/+","/",folder_path)

#code

dir.create(folder_path,recursive=TRUE)
Sys.chmod(folder_path, mode = "777", use_umask = TRUE)


#COMPLETED TEXT GENERATED

write.table("create_folder_complete",paste(output_path,"CREATE_FOLDER_COMPLETE.txt",sep="/"),quote=F,row.names=F,col.names=F)
