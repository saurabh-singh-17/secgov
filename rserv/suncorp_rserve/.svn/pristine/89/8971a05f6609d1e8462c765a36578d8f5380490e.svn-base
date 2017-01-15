#------------------------------------------------------------------------------#
#--                                                                          --#   
#-- Project Name :  MRx_CategoricalIndicator_1.0                             --#
#-- Description  :  Some functions for creating categorical indicators       --#
#-- Return type  :  Creates CSV's at a location according to given inputs    --#
#-- Author       :  Shankar Kumar Jha                                        --#                 
#------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------
# parameters required
#-------------------------------------------------------------------------------
# input_path <- 'C:/MRx/r/new-16-Nov-2012-14-22-35/1'
# bivariate <- 'true'
# output_path <- 'C:/MRx/r/new-16-Nov-2012-14-22-35/1/NewVariable/categoricalIndicator/10'
# newvar_list <- 'mrx_bv_ACV'
# prefix <- 'pd12'
# input_xml <- 'C:/MRx/r/new-16-Nov-2012-14-22-35/1/NewVariable/categoricalIndicator/10/catInd_levels.xml'
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries required
#-------------------------------------------------------------------------------
library(XML)
library(Hmisc)
library(data.table)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function to create xml from dataframe
#-------------------------------------------------------------------------------
dfToXML=function(dataFrame,rowNode,location){
  xml <- xmlTree()
  xml$addTag("TABLE", close=FALSE)
  for (i in 1:nrow(dataFrame)) {
    xml$addTag(rowNode, close=FALSE)
    for(j in 1:ncol(dataFrame)){
      xml$addTag("new_varname", dataFrame[i, j])
    }
    xml$closeTag()
  }
  xml$closeTag()
  saveXML(xml,location)
}
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# preparing the data
#-------------------------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))

#-------------------------------------------------------------------------------
#Understanding the bins through XML  
#-------------------------------------------------------------------------------
input_xml <- xmlTreeParse(input_xml)
xmldata <- xmlToList(input_xml)
xmldata=as.data.frame(matrix(unlist(xmldata),ncol = 1,byrow = T))[1]
xmldata[,1]<-as.character(xmldata[,1])
colnames(xmldata)<-c("bincol")
#-------------------------------------------------------------------------------
bivarCol<-try({read.csv(paste(bivariate_report_path,"bindata.csv",sep="/"))[paste("bin_",newvar_list,sep="")]},silent=T)
if(class(bivarCol) == "try-error"){
  bivarCol<-read.csv(paste(bivariate_report_path,"bindata.csv",sep="/"))[newvar_list]  
}
bivarCol[,1]<-as.character(bivarCol[,1])
bivarCol[,1][is.na(bivarCol[,1])] <- "NA"
allVarName<-c()
for(i in 1:nrow(xmldata))
{
  current_level_treat<-gsub(" ","",xmldata[i,1])
  current_level_treat<-gsub("[^[:alnum:]]","_",current_level_treat)
  current_var_name<-paste(prefix,"_",current_level_treat,newvar_list[1],sep="")
  dataworking[,current_var_name]<-0
  index<-which(bivarCol[,1] == xmldata[i,1])
  dataworking[index,current_var_name] = 1  
  allVarName<-c(allVarName,current_var_name)
}


#-------------------------------------------------------------------------------
# outputs
#-------------------------------------------------------------------------------


write.csv(dataworking[allVarName],
          paste(output_path,
                "/categoricalVariableCreation_subsetViewpane.csv",
                sep=""),
          row.names=FALSE,
          quote=FALSE)


save(dataworking,
     file=paste(input_path,
                "/dataworking.RData",
                sep=""))


# ======================================================
# code for updating the dataset properties information
# ====================================================== 

source(paste(genericCode_path,"datasetprop_update.R",sep="/"))

# ------------------------------------------------------

dfToXML(as.data.frame(allVarName),
        "NEW_VARNAME",
        paste(output_path,
              "/categoricalVariableCreation_new_varname.xml",
              sep=""))

write("CATEGORICAL_VARIABLE_CREATION_COMPLETED",
      file=paste(output_path,
                 "/CATEGORICAL_VARIABLE_CREATION_COMPLETED.txt",
                 sep=""))
#-------------------------------------------------------------------------------

