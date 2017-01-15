############------------Harshit Raj----------------################

# inputData=read.csv(paste(input_path,"\\dataworking.csv",sep=""))
load(paste(input_path,"/dataworking.RData",sep=""))
inputData <- dataworking
rm("dataworking")

#-------------------------------------------------------------------------------
# Parameter play
#-------------------------------------------------------------------------------
condition <- gsub(pattern="\n",
                  replacement="",
                  x=condition)
condition <- gsub(pattern=" +",
                  replacement=" ",
                  x=condition)
#-------------------------------------------------------------------------------

colnames<-colnames(inputData)
# colnames_new<-unlist(lapply(colnames,FUN=function(x){return(gsub('\\_','',x))}))
# colnames(inputData)<- colnames_new
cond<- condition
library(stringr)
library(Hmisc)
# for(i in 1:length(colnames))
# {
#   cond<-gsub(paste('\\(',colnames[i],sep=''),paste('\\(',colnames_new[i],sep=''),cond)
# }
finalres<- rep('',nrow(inputData))
for(i in 1:length(cond))
{
  Pattern_Between<-"[[:digit:]] AND"
  Pattern_Between2<-"BETWEEN"
  strpos_count=unlist(str_locate_all(cond[i],pattern=Pattern_Between))
  if(length(strpos_count)>0){
    for(j in 1:(length(strpos_count)/2))
    {
      if(length(str_locate_all(cond[i],pattern=Pattern_Between))==0)
      {break}
      strpos1=unlist(str_locate(cond[i],pattern=Pattern_Between))
      strpos2=unlist(str_locate(cond[i],pattern=Pattern_Between2))
      var<-''
      strt<-2
      str<-0
      while(str<1)
      {
        get<-substr(cond[i],strpos2[1]-strt,strpos2[1]-strt)
        print(get)
        if(length(grep('\\(',get))==1)
        {break}
        
        var<-paste(get,var,sep='')
        print(var)
        strt=strt+1
      }
      substr(cond[i],strpos1[1]+1,strpos1[2]+1)<- "x@rep"
      substr(cond[i],strpos2[1]-strt+1,strpos2[2]-7)<- paste(toupper(var),'@',sep='')
      cond[i]<-gsub(paste(toupper(var),'@',sep=''),"",cond[i])
      cond[i]<-gsub("x@rep",paste(" < ",var,' & ',var," < ",sep=''),cond[i])
      print(cond[i])
    }
  }
  
  conditions<- c('\\) AND \\(','\\) OR \\(','BETWEEN','NOT IN ','IN ','\\=')
  replace<-c(') & (',') | (','','%nin% c','%in% c','==')
  for(k in 1:length(conditions))
  {
    print(k)
    cond[i]<-gsub(conditions[k],replace[k],cond[i])
    print(cond[i])
  }
  evaluate_exp=function(input_expn)
  {
    transformed_value=eval(parse(text=(input_expn)),envir=inputData)                         
    return(transformed_value)
  }
  
  result<-eval(parse(text=(cond[i])),envir=inputData)
  result[which(is.na(result==TRUE))]=FALSE
  finalres[which(result==TRUE)]=value[i]
}

print(finalres)
data<-as.data.frame(finalres)
if(var_type  == "numeric"){
  data[,1]<-as.numeric(as.character(data[,1]))
}
colnames(data)<- var_name
colnames(inputData)<-colnames
inputData=cbind.data.frame(inputData,data)

dataworking <- inputData
save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))

#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(data) > 6000) {
  x_temp                       <- sample(x=nrow(data),
                                         size=6000,
                                         replace=FALSE)
  data                         <- data[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------

write.csv(data,paste(output_path,"/newvar.csv",sep=""),row.names = FALSE, quote=FALSE)

#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

write("CONDITIONAL_NEWVAR_CREATION_COMPLETED",paste(output_path,"/CONDITIONAL_NEWVAR_COMPLETED.txt",sep=""))