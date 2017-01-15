#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : MRx_transpose_verify.R                         
#-- Description  : Performs verification Operation     
#-- Return type  : csv              
#-- Author : Arun Pillai
#------------------------------------------------------------------------------------------------------#
#--------library------------------------------------------------------------------
library(plyr)
library(reshape)        
#-----------------------------------------------------------------------------------
#input data set
# dataworking=read.csv(paste(input_path,"/",dataset_name,".csv",sep=""))
load(paste(input_path,"/dataworking.RData",sep=""))
transposeFlag=TRUE
uniqVar=as.character(dataworking[,unique_var])
missingVal=c(NA,"",NULL)
missingUniqVar=which(uniqVar %in% missingVal)
uniqVar_1=uniqVar[which(uniqVar %in% missingVal==FALSE)]
missing=0
detail=c("FALSE","FALSE","0")

if(unique_level_flag=="true")
{
  uniqGroup=as.character(dataworking[,unique_level_vars])
  missingGroup=which(uniqGroup %in% missingVal)
  if(length(missingGroup)>0)
  {
    detail[1]="TRUE"
    missing=missingGroup
  }
  
  x_temp <- !(dataworking[, unique_var] %in% missingVal)
  count=tapply(X=dataworking[x_temp, unique_var],
               INDEX=dataworking[x_temp, unique_level_vars],
               FUN=length)
  distinctCount=tapply(X=dataworking[x_temp, unique_var],
                       INDEX=dataworking[x_temp, unique_level_vars],
                       FUN=function(x){length(unique(x))})
  
  check=sum(count-distinctCount, na.rm=T)
  if(check >0)
  {
    detail[2] ="TRUE"
    transposeFlag=FALSE
  }
  
}   

if(unique_level_flag=="false")
{
  count=length(uniqVar_1)
  distinctCount=length(unique(uniqVar_1))
  check=sum(count-distinctCount)
  if(check >0)
  {
    detail[2] ="TRUE"
    
  }
  
  missing =sum(is.na(uniqVar_1))
  
}


detail=detail[-1]
detail[2]=length(uniqVar) - length(uniqVar_1)
detail=as.data.frame(detail)

# write into csv
write.csv(detail,paste(output_path,"/transpose_verification.csv",sep=""),row.names = FALSE, quote = FALSE)


if(detail[1,]=="TRUE")
{
  transposeFlag=FALSE
}

#repeating=length(uniqVar) - length(uniqVar_1)

#transpose_properties= cbind(missing,repeating)

# write into csv
#write.csv(transpose_properties,paste(output_path,"/transpose_properties.csv",sep=""),row.names = FALSE, quote = FALSE)


#------------------------------------------------------------------------------------------------------#                                                                                                  --#   
#-- Process Name : transposeFunction                        
#-- Description  : Performs transpose Operation     
#-- Return type  : dataframe transposed values              
#-- Author : Arun Pillai
#------------------------------------------------------------------------------------------------------#

transposeFunction <- function(data,var_list,uniqueVar)
{
  transpose=matrix("",nrow=length(var_list),ncol=length(uniqueVar))
  colnames(transpose)=uniqueVar
  rownames(transpose)=var_list
  
  for( i in 1:length(var_list))
  {
    vardata=data[c(unique_var,var_list[i])]
    names(vardata)[1]="var"
    
    for( j in 1:length(uniqueVar))
    {
      temprec=subset(vardata[j,],subset=var %in% uniqueVar)
      if(nrow(temprec)>0)
      {
        #transpose[i,j]=as.character(temprec[,2])
        transpose[i,j]=""
      }
    }
  }
  
  return(transpose)
}


if(transposeFlag==TRUE)
{
  
  prefix=""
  uniqueVar=unique(uniqVar)
  varName=apply(cbind(prefix,uniqueVar),1,function(x){paste(x,collapse="_")})
  
  if(nrow(dataworking) >50)
  {
    #     index=sample(x=1:nrow(dataworking),size=10)
    dataworking=dataworking[1:10,]
    
  }
  
  # format the output
  dataworking <- useDateFormat(c_path_in = input_path,
                               x = dataworking)
  
  if(unique_level_flag=="false")
  {
    tempdata=dataworking[c(var_list,unique_var)]
    uniqueVar=tempdata[,unique_var]
    result=transposeFunction(data=tempdata,var_list=var_list,uniqueVar=uniqueVar)
    result=cbind(var_list,result)
    row.names(result)=NULL
    result=as.data.frame(result)
    varName=apply(cbind(prefix,as.character(uniqueVar)),1,function(x){paste(x,collapse="_")})
    names(result)=c("new_name",varName)
  }
  
  
  if(unique_level_flag=="true")
  {
    
    uniqueVar=as.character(dataworking[,unique_var])
    varName=t(as.matrix(apply(cbind(prefix,as.character(uniqueVar)),1,function(x){paste(x,collapse="_")})))
    colnames(varName)<-varName[1,]
    varName[1,]<-""
    
    result<-NULL
    func<-function(x){rep(x,length(var_list))}
    tempdata<-dataworking[unique_level_vars]
    unique1<-unique(tempdata)
    vartable<-as.data.frame(dataworking[var_list][1:nrow(unique1),])
    colnames(vartable)<-var_list
    var_unique<-cbind(unique1,vartable)
    final<-melt(var_unique,id=unique_level_vars)
    for(i in 1:length(unique_level_vars))
    {
      final<-final[order(final[unique_level_vars[i]]),]
    }
    final<-final[1:(length(unique_level_vars)+1)]
    colnames(final)[ncol(final)]<-"new_name"
    result<-rbind.fill(final,as.data.frame(varName))
    result<-result[1:(nrow(result)-1),]
    result[(length(unique_level_vars)+2):ncol(result)]<-""
    
  }
  if(nrow(result)>50)
  {
    result<-result[c(1:50),]
  }
  
  # writing it into New Dataset
  names(result) <- gsub(pattern="[^[:alnum:]]",replacement="_",x=names(result))
  write.csv(result,paste(output_path,"/sketch.csv",sep=""),row.names = FALSE, quote = FALSE)
  
}

#writing the completed text at the output location
#-----------------------------------------------------------------
write("TRANSPOSE", file = paste(output_path, "TRANSPOSE_VERIFY_COMPLETED.txt", sep="/"))