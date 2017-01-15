#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  projList_delete.R-#
#-- Description  :  deletes a project information from project.cs                                   --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Saurabh Singh                                                                    --#                 
#------------------------------------------------------------------------------------------------------#

csvpath<-paste(input_path,"project.csv",sep="/")

project<-read.csv(csvpath)
index<-which(project$projectName == projectName 
             & project$userName==userName
             & project$userAccount==userAccount)
project<-project[-index,]


write.csv(project,csvpath,row.names=F,quote=F)

#******************** code completed **************************************************************#


