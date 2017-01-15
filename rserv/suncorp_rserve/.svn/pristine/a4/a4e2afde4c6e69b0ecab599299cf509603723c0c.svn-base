#made some changes to this code assuming this is called only for validation scenario--vasanth
#------------------------------------------------------------------------------------------------------#
#-- Process Name : MRx_indicatorVariableCreation.R                         
#-- Description  : Performs indicators for the filters     
#-- Return type  : txt              
#-- Author : Arun Pillai
#------------------------------------------------------------------------------------------------------#



flag_forecast <- "false"
#=============================================================================== 
#libraries Required
#===============================================================================
library(sampling)
#=============================================================================== 




load(paste(group_path,"/bygroupdata.RData",sep=""))
dataworking <- bygroupdata
rm("bygroupdata")

#==================================================================================== 
#filtering based on Per Group By 
#==================================================================================== 
if (as.integer(grp_no)!= 0)
{
  temp_var=paste("grp",grp_no,"_flag",sep="")
  
  index<-which(names(dataworking)==temp_var)
  dataworking<-subset(dataworking,dataworking[index]==grp_flag)
  
}
#===================================================================================

#=================================================================================== 
#initiating result to blank, later on will fill based on   
result = rep("",nrow(dataworking))
#===================================================================================  

if(var_type=="per_var")
{
  recLen=as.numeric(percent)*(as.numeric(end_row)-as.numeric(start_row)+1)
  
  if(per_method=="seq") 
  {
    if(flag_forecast!="true")
    {
      index=start_row:(recLen+as.numeric(start_row)-1)
      zero=(round(recLen)+as.numeric(start_row)-1):end_row
    }else
    {
      forecast=forecaststart_row:forecastend_row
      index=start_row:(recLen+as.numeric(start_row)-1)
      zero=(round(recLen)+as.numeric(start_row)-1):end_row
    }
    result[zero]=0
  }
  
  if(per_method =="random")
  {
    set.seed(seed)
    index=sample(x=1:(as.numeric(end_row)-as.numeric(start_row)+1),size=recLen)
    zero=(start_row:end_row)[-c(index)]
    result[zero]=0
  }
}    


if(var_type=="time_var")
{ 
  
  dateVal=dataworking[,var_name]
  
  dateValunique=unique(dateVal)
  datedata <- cbind.data.frame(dateValunique,1:length(dateValunique))
  format_s_date <- as.Date(x=s_date)
  format_e_date <- as.Date(x=e_date)
  format_validateStart_date <-as.Date(x=validateStart_date)
  format_validateEnd_date <-as.Date(x=validateEnd_date)
  if(flag_forecast!="true")
  {
    index= which(format_s_date < dateVal & dateVal < format_e_date)
    
    zero= which(format_validateStart_date < dateVal & dateVal< format_validateEnd_date)
  }else{
    #     forecast=forecastStart_date:forecastEnd_date
    index <- which(format_s_date < dateVal & dateVal < format_e_date)
    zero= which(format_validateStart_date < dateVal & dateVal< format_validateEnd_date)
  }
  #   startDate=as.Date(s_date, "%d%b%Y")
  #   endDate=as.Date(e_date, "%d%b%Y")
  #   scenario_variable<-intersect(which(dateVal>startDate),which(dateVal<endDate))
  result[zero]=0 
}

if(var_type=="grp_var")
{
  grpVar=as.character(dataworking[,var_name])
  index = which(grpVar %in% grp_values)
  zero.index <- which(!(grpVar %in% grp_values))
  result[zero.index] <- 0
}

result[index]=1
if(flag_forecast=="true")
{
  result[forecast]=2
  
}
dataworking=cbind(dataworking,result)
names(dataworking)[ncol(dataworking)]=scenario_variable
bygroupdata<-dataworking
save(bygroupdata, file=paste(output_path,"/bygroupdata.RData",sep=""))


load(paste(input_path,"/dataworking.RData",sep=""))
primary_key_1644_dataworking <- data.frame(primary_key_1644=dataworking[,"primary_key_1644"])
primary_key_1644_result_bgd  <- cbind.data.frame(primary_key_1644=bygroupdata[,"primary_key_1644"],result)
result.data.frame            <- merge(x=primary_key_1644_dataworking,y=primary_key_1644_result_bgd,by="primary_key_1644",all.x=T)
if(!identical(order(dataworking[,"primary_key_1644"]),1:nrow(dataworking))){
  dataworking <- dataworking[order(dataworking[,"primary_key_1644"]),]
}
dataworking <- cbind.data.frame(dataworking,result.data.frame$result)
names(dataworking)[ncol(dataworking)]=scenario_variable
save(dataworking, file=paste(input_path,"/dataworking.RData",sep=""))

write("Scenario_CREATION_COMPLETED", file = paste(output_path, "indicator_var.txt", sep="/"))