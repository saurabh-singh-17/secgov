#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_errorGenerator  version : 1.0                                                --#
#-- Descrption  :  Generates error and outpur files                                                 --#
#-- Return type  : Creates R output at output location                                                                                  --#
#-- Author       : Shankar Kumar Jha                                                                                  --#                 
#------------------------------------------------------------------------------------------------------#
if(exists("inputpath")){
  input_path<-inputpath
}
check=try(length(output_path),silent=TRUE)
check1<-try(length(outputPath),silent=TRUE)
if(class(check)=="try-error" & class(check1)!="try-error")
{
  output_path=outputPath
}
if(class(check)=="try-error" & class(check1)=="try-error")
{
  output_path<-input_path
}

#deletes if any file with the same name
unlink(paste(output_path,"output.Rout",sep="/"))

#creates file for output
outputFile<- file(paste(output_path,"output.Rout",sep="/"), open="wt")
sink(outputFile,type="output")