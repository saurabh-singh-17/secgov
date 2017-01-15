#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_predicted variable creation                                              --#
#-- Descrption  :  Generates a new variable in the data working                                                --#
#-- Return type  : CSV                                                                                 --#
#-- Author       : saurabh vikash singh                                                              --#                 
#------------------------------------------------------------------------------------------------------#

library(Hmisc)

#dataworking<-read.csv(paste(input_path,"dataworking.csv",sep="/"))
load(paste(input_path,"dataworking.RData",sep="/"))
if (type_model == "linear")
{
  outdata<-read.csv(paste(iteration_path,"outdata.csv",sep="/"))
  outdata<-outdata[c("pred","primary_key_1644")]
  dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  outdata$primary_key_1644<-as.character(outdata$primary_key_1644)
  dataworking<-merge.data.frame(dataworking,outdata,by="primary_key_1644",all.x=T)
  colnames(dataworking)[which(colnames(dataworking)=="pred")]<-c(newVar_pred)
  
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}
if (type_model == "logistic")
{
  outdata<-read.csv(paste(iteration_path,"predprob.csv",sep="/"))
  dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  outdata$primary_key_1644<-as.character(outdata$primary_key_1644)
  if(newVar_pred != ""){
    dataworking<-merge.data.frame(dataworking,outdata[c("prob","primary_key_1644")],by="primary_key_1644",all.x=T)
    colnames(dataworking)[which(colnames(dataworking)=="prob")]<-c(newVar_pred)
  }
  if(newVar_resp != ""){
    dataworking<-merge(dataworking,outdata[c("pred","primary_key_1644")],by="primary_key_1644",all.x=T)
    colnames(dataworking)[which(colnames(dataworking)=="pred")]<-c(newVar_resp)
  }
  
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}
if (type_model == "arimax"){
  Forecast_Values<-read.csv(paste(iteration_path,"Forecast_Values.csv",sep="/"))
  Forecast_Values<-Forecast_Values[c("FORECAST","primary_key_1644")]
  # dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  # outdata$primary_key_1644<-as.character(outdata$primary_key_1644)
  dataworking<-merge.data.frame(dataworking,Forecast_Values,by="primary_key_1644",all.y=T)
  colnames(dataworking)[which(colnames(dataworking)=="FORECAST")]<-c(newVar_pred)
  
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}

if (type_model == "kmeans" |
      type_model == "agglomerative" |
      type_model == "lca" |
      type_model == "lcm") {
  c_path_in                      <- input_path
  c_path_iter                    <- iteration_path
  c_var_cluster                  <- "murx_n_cluster"
  c_var_key                      <- "primary_key_1644"
  c_var_new                      <- newVar_pred

  load(file=paste(c_path_iter, "/df_cluster.RData", sep=""))
  
  x_temp                         <- which(colnames(df_cluster) == c_var_cluster)
  colnames(df_cluster)[x_temp]   <- c_var_new
  dataworking                    <- merge(x=dataworking,
                                          y=df_cluster,
                                          by=c_var_key,
                                          all.x=TRUE)
  
  save(dataworking,
       file=paste(input_path,
                  "/dataworking.RData",
                  sep=""))
}

if (type_model == "glm")
{
  load(paste(iteration_path,"/predictedData.RData",sep=""))
  dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  predictedData$primary_key_1644<-as.character(predictedData$primary_key_1644)
  dataworking<-merge.data.frame(dataworking,predictedData,by="primary_key_1644",all.x=T)
  colnames(dataworking)[which(colnames(dataworking)=="pred")]<-c(newVar_pred)
 
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}

if (type_model == "genmod")
{
  load(paste(iteration_path,"/predictedData.RData",sep=""))
  dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  predictedData$primary_key_1644<-as.character(predictedData$primary_key_1644)
  dataworking<-merge.data.frame(dataworking,predictedData,by="primary_key_1644",all.x=T)
  colnames(dataworking)[which(colnames(dataworking)=="Predicted")]<-c(newVar_pred)
 
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}


if (type_model == "mixed")
{
  predictedData<-read.csv(paste(iteration_path,"/normal_chart.csv",sep=""))
  predictedData<-predictedData[c("Predicted","primary_key_1644")]
  dataworking$primary_key_1644<-as.character(dataworking$primary_key_1644)
  predictedData$primary_key_1644<-as.character(predictedData$primary_key_1644)
  dataworking<-merge.data.frame(dataworking,predictedData,by="primary_key_1644",all.x=T)
  colnames(dataworking)[which(colnames(dataworking)=="Predicted")]<-c(newVar_pred)
  
  save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
}

#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

#writing the completed text at the output location
#-----------------------------------------------------------------
write("PREDICTED_VAR_CREATION_COMPLETED", file = paste(input_path,"PREDICTED_VAR_CREATION_COMPLETED.txt", sep="/"))
