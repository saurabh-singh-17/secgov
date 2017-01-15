#------------------------------------------------------------------------------#
#--                                                                          --#
#-- Project Name :  projList_update.R                                        --#
#-- Description  :  generates project csv for the first time and then update --#
#--                 it from next time                                        --#
#-- Return type  :  Generates csvs at given location                         --#
#-- Author       :  Arun Pillai                                              --#
#------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------
# path of the project csv
#-------------------------------------------------------------------------------
c.path.projectcsv <- paste(input_path, "project.csv", sep="/")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# getting the projectId
#-------------------------------------------------------------------------------
if (file.exists(c.path.projectcsv)) {
  df.temp   <- read.csv(c.path.projectcsv, header=T)
  
  #check for max of the finite projectIds
  x_temp <- max(df.temp$projectId[is.finite(df.temp$projectId)], na.rm = TRUE)
  
  if(is.finite(x_temp)){
    projectId <- x_temp + 1
  }else{
    projectId <- 1
  }
 
  col.names <- F
  rm("df.temp")
} else {
  projectId <- 1
  col.names <- T
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# dataframe containing information about the new project
#-------------------------------------------------------------------------------
df.project <- data.frame(projectId,projectName,userName,userAccount)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# writing the information to project.csv(appending if it already exists)
#-------------------------------------------------------------------------------
write.table(x=df.project,
            file=c.path.projectcsv,
            row.names=F,
            quote=F,
            append=T,
            sep=",",
            col.names=col.names)
#-------------------------------------------------------------------------------