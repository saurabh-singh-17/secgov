

#-------------------------------------------------------------------------------
# path of the project csv
#-------------------------------------------------------------------------------
c.path.projectcsv <- paste(input_path, "project.csv", sep="/")
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# getting the projectId
#-------------------------------------------------------------------------------

  df.temp   <- read.csv(c.path.projectcsv, header=T)
  df.temp[,"projectName"]<- as.character(df.temp[,"projectName"])
  
  file.rename(from = paste(input_path,"/projects/",projectName,sep=""),
              to =paste(input_path,"/projects/",newProjectName,sep=""))
    index<- which(df.temp$projectId == projectId)
    df.temp[index,"projectName"] <- newProjectName
 
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# dataframe containing information about the new project
#-------------------------------------------------------------------------------

#------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# writing the information to project.csv(appending if it already exists)
#-------------------------------------------------------------------------------
write.csv(x=df.temp,
            file=c.path.projectcsv,
            row.names=F,
            quote=F,
            )
#-------------------------------------------------------------------------------
write("completed",paste(input_path,"/projList_rename_completed.txt",sep=""))
