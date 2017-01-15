#made some changes to this code assuming this is called only for validation scenario--vasanth

#------------------------------------------------------------------------------------------------------#
#-- Process Name : MRx_indicatorVariableCreation.R                         
#-- Description  : Performs indicators for the filters     
#-- Return type  : txt              
#-- Author : Arun Pillai
#------------------------------------------------------------------------------------------------------#
if(per_method =="random"){
flag_forecast <- "false"
}
#libraries Required.
library(sampling)

#request the reader not to delete it or make any changes without proper research.
# writing a function to recognise  a date format
dateformat<-function(date){
  form<-NULL
  temp<-as.character(date[1])
  if(any(grepl("[[:alpha:]]",date) == "TRUE"))
  {
    return("unknown")
  }
  if(grepl(" ",temp)){
    date<-apply(as.data.frame(date),1,function(x){strsplit(as.character(x)," ")[[1]][1]})
  }
  date<-as.character(date)
  if (is.null(date))
    return("unknown")  
  if(is.na(mean(as.numeric(date),na.rm=T)) == "FALSE")
  {
    return("unknown")
  }
  if((length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == FALSE)))   &
       (length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == FALSE))))
    return("unknown")
  if (all(is.na(date))) 
    return(NA)
  val<-length(date)
  if(val > 100){val= 100}
  date[which(date=='')] <- NA
  if(!is.na(as.numeric(substr(date[1],1,4)))){
    decide<-apply(as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split<-substr(date[1],5,5)
    decide<-as.data.frame(decide)
    max1<-max(as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    max2<-max(as.numeric(as.character(as.matrix(decide[3,]))),na.rm=T)
    if(max1 > 12 & max2 <= 12){form<-paste("%Y",split,"%d",split,"%m",sep="")}
    if(max1 <= 12 & max2 >= 12){form<-paste("%Y",split,"%m",split,"%d",sep="")}
    if(max1 <= 12 & max2 <= 12){form<-paste("%Y",split,"%m",split,"%d",sep="")}
  }else{
    decide<-apply(as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split<-substr(date[1],6-(10-nchar(date[1])),6-(10-nchar(date[1])))
    decide<-as.data.frame(decide)
    max1<-max(as.numeric(as.character(as.matrix(decide[1,]))),na.rm=T)
    max2<-max(as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    if(max1 > 12 && max2 <= 12){form<-paste("%d",split,"%m",split,"%Y",sep="")}
    if(max1 <= 12 & max2 >= 12){form<-paste("%m",split,"%d",split,"%Y",sep="")}
    if(max1 <= 12 & max2 <= 12){form<-paste("%m",split,"%d",split,"%Y",sep="")}
  }
  if(max(nchar(date)) <= 8)
  {
    decide<-apply(as.data.frame(date[1:val]),1,function(x){unlist(strsplit(x,"[[:punct:]]"))})
    split<-substr(date[1],nchar(date[1])-2,nchar(date[1])-2)
    decide<-as.data.frame(decide)
    max1<-max(as.numeric(as.character(as.matrix(decide[1,]))),na.rm=T)
    max2<-max(as.numeric(as.character(as.matrix(decide[2,]))),na.rm=T)
    if(max1 > 12 && max2 <= 12){form<-paste("%d",split,"%m",split,"%y",sep="")}
    if(max1 <= 12 & max2 >= 12){form<-paste("%m",split,"%d",split,"%y",sep="")}
    if(max1 <= 12 & max2 <= 12){form<-paste("%m",split,"%d",split,"%y",sep="")}
  }
  if(nchar(temp[1]) > 10 & nchar(temp[1]) <= 16){form<- paste(form," %H:%M",sep="")}
  if(nchar(temp[1]) > 16){form<- paste(form," %H:%M:%S",sep="")}
  return(form)
}
load(paste(group_path,"/bygroupdata.RData",sep=""))
dataworking<-bygroupdata
rm("bygroupdata")


#Per Group By 
if (as.integer(grp_no)!= 0)
{
  temp_var=paste("grp",grp_no,"_flag",sep="")
  
  index<-which(names(dataworking)==temp_var)
  dataworking<-subset(dataworking,dataworking[index]==grp_flag)
  
}

result = rep("",nrow(dataworking))

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
  form<-dateformat(dateVal)
  dateVal=as.Date(dateVal,format=form)
  dateValunique=unique(dateVal)
  datedata <- cbind.data.frame(dateValunique,1:length(dateValunique))
  
  if(flag_forecast!="true")
  {
    index=s_date:e_date
    zero=validateStart_date:validateEnd_date
  }else{
    forecast=forecastStart_date:forecastEnd_date
    index=s_date:e_date
    zero=validateStart_date:validateEnd_date
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