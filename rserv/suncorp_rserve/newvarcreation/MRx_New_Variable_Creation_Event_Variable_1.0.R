
#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_New_Variable_Creation_Event_Variable                                                                 --#
#-- Description  :  Creates flag variable based on Date in MRx                                --#
#-- Return type  :  Generates csvs at given location                            --#
#-- Author       :                                                                  --#                 
#------------------------------------------------------------------------------------------------------#

#--------------------------------------Parameters--------------------------------------------------------
#input_path="C:\\MRx\\r\\g3oct5-8-Oct-2012-09-29-53\\1"
#output_path="C:\\MRx\\r\\g3oct5-8-Oct-2012-09-29-53\\1\\NewVariable\\EventVariable\\29"
#input_xml="C:\\MRx\\r\\g3oct5-8-Oct-2012-09-29-53\\1\\NewVariable\\EventVariable\\29\\evtXML.xml"
#date_var="Date"
#prefix="a1c1_"


#library Required
library(XML)

#---------------------------------------------------------------------------------------------------------


#reading data from csv
#inputdata<-read.csv(file=paste(input_path,"dataworking.csv",sep="\\"))
load(paste(input_path,"dataworking.RData",sep="/"))
inputdata <- dataworking
rm("dataworking")
#adding one column 
#inputdata$eventvariable<-0

result=rep(0,nrow(inputdata))

#reading data from xml
xmldata<-xmlToDataFrame(input_xml)
#changing into Date type 
# xmldata<-as.character.Date(xmldata)
# indexofDate<-which(names(inputdata)==date_var)
# tempDate<-as.character.Date(inputdata[,indexofDate])
# form<-dateformat(tempDate)
# tempDate<-as.Date(tempDate,form)
#loop to create  flag for  all event variables
# i=1
# 
# while(i< nrow(xmldata))
# {
#     start_date=xmldata[i,]
#     end_date=xmldata[sum(i,1),]
#     start_date<-as.Date(as.character.Date(start_date))
#     end_date<-as.Date(as.character.Date(end_date))
#     #start_date<-as.Date(start_date)
#     #end_date<-as.Date(end_date)
#     indexlist<-intersect(which(tempDate>=start_date),which(tempDate<=end_date))
#     if(length(indexlist) >0)
#     {
#       result[indexlist] =1
#     }  
# i=i+2  
# }

resfinal<-NULL
newVarxml<-newXMLNode("TABLE")

for (i in 1:length(date_var)) {
 tempdate                        <- inputdata[, date_var[i]]

 xmldata[, i]                    <- as.Date(x=as.character(xmldata[, i]),
                                            format="%m/%d/%Y")
 index                           <- NULL
 
 for (j in 1:(length(xmldata[, i]) / 2)) {
   x_temp                        <- (j - 1) * 2
   x_temp                        <- which(tempdate >= xmldata[x_temp + 1, i] & tempdate <= xmldata[x_temp + 2,i])
   index                         <- c(index, x_temp)
 }
 
 newcolname<-paste(prefix,"event",i,"_",date_var,sep="")
 res<-rep(0,nrow(inputdata))
 res[index]<-1
 resfinal<-as.data.frame(cbind(resfinal,res))
 colnames(resfinal)[ncol(resfinal)]<-paste(prefix,"event",i,"_",date_var[i],sep="")
 newVarnode<-newXMLNode("NEW_VARNAME",parent=newVarxml)
 newVarvalue<-newXMLNode("new_varname",paste(prefix,"event",i,"_",date_var[i],sep=""),parent=newVarnode)
}

inputdata=cbind.data.frame(inputdata,resfinal)
dataworking <- inputdata

#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(resfinal) > 6000) {
  x_temp                       <- sample(x=nrow(resfinal),
                                         size=6000,
                                         replace=FALSE)
  resfinal                     <- resfinal[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------

write.csv(resfinal,paste(output_path,"eventIndicatorVariable_subsetViewpane.csv",sep="/"),quote=F,row.names=FALSE)
save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))

#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

saveXML(newVarxml,paste(output_path,"eventIndicatorVariable_new_varname.xml",sep="/"))

write.table("EVENT_INDICATOR_VARIABLE_COMPLETED",paste(output_path,"EVENT_INDICATOR_VARIABLE_COMPLETED.txt",sep="/"),sep="\t")
