#-----------------------------------------------------------------
# Function to subset the dataset based on levels and sublevels
#-----------------------------------------------------------------

subsetF <- function(dataworking,levelVars,sublevelVars){
  index <- NULL
  for(s in 1:length(levelVars)){
    tempLevel <- unlist(strsplit(x=levelVars[s],split="  "))
    if(length(tempLevel)>1){
      temp  <- apply(dataworking[tempLevel],1,function(x){paste(x,collapse="|",sep="")})
      index <- c(index,which(temp==sublevelVars[s]))
    }else{
      if(sublevelVars[s]=='NA'){
        index <- c(index,which(is.na(dataworking[,tempLevel])))
      }else{
        index <- c(index,which(dataworking[,tempLevel]==sublevelVars[s]))
      }
    }
  }
  # index <- as.numeric(names(which(table(index)==length(levelVars))))
  index <- unique(index)
  return(dataworking[index,])
}
#-----------------------------------------------------------------



#-----------------------------------------------------------------
# Function to do visualisation basic
#-----------------------------------------------------------------

writeVarlistCSV <- function(dataworking,var_list,metrics,selected_varlist,levelVars,sublevelVars){
  if(length(levelVars)==0) levelVars="notAllowed"
  levelVarsOrg <- levelVars
  for(i in 1:length(var_list)){
    # For combined variable
    tempVar=unlist(strsplit(var_list[i],split="$",fixed=TRUE))
    if(length(tempVar)>1){
      data=apply(dataworking[tempVar],1,function(x){paste(x,collapse="|")})
      dataworking=cbind(dataworking,data)
      colnames(dataworking)[ncol(dataworking)]=var_list[i]
    }
    resultDF2 <- NULL
    levelVars <- levelVarsOrg
    
    
    
    for(k in 1:length(levelVars)){
      if(levelVars == "notAllowed"){
        dataworkingK <- dataworking
      }else{
        dataworkingK <- subsetF(dataworking,levelVars[k],sublevelVars[k])
        if(nrow(dataworkingK) == 0){
          write("No datapoints for the this combination",paste(output_path,"/","error.txt",sep=""))
          next;
        }
        # More than one variable in the panel
        levelTemp=unlist(strsplit(levelVars[k],split="  ",fixed=TRUE))
        if(length(levelTemp)>1){
          newlevelVar=apply(dataworkingK[levelTemp],1,function(x){paste(x,collapse="|",sep="")})
          dataworkingK=data.frame(dataworkingK,newlevelVar,stringsAsFactors = FALSE)
          levelVars[k]="newlevelVar"
        }
      }
      
      resultDF=NULL
      j=1
      for(j in 1:length(selected_varlist)){  
        if(metrics[j]=="SUM"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){sum(as.numeric(x,na.rm=T))})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){sum(as.numeric(x,na.rm=T))})
          
        }
        if(metrics[j]=="MAX"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){max(x,na.rm=T)})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){max(x,na.rm=T)})
          
        }
        if(metrics[j]=="MIN"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){min(x,na.rm=T)})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){min(x,na.rm=T)})
          
        }
        if(metrics[j]=="AVG"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){mean(x,na.rm=T)})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){mean(x,na.rm=T)})
          
        }
        if(metrics[j]=="STD"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){sd(x,na.rm=T)})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){sd(x,na.rm=T)})
          
        }
        if(metrics[j]=="RANGE"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){diff(range(x,na.rm=T))})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){diff(range(x,na.rm=T))})
          
        }
        if(metrics[j]=="VAR"){
          
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],as.character(dataworkingK[var_list[i]][,1]),sep="##"),function(x){var(x,na.rm=T)})
          
          result=tapply(dataworkingK[,which(colnames(dataworkingK)== selected_varlist[j])],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),function(x){var(x,na.rm=T)})
          
        }
        if(metrics[j]=="COUNT"){
          result=tapply(dataworkingK[selected_varlist[j]][,1],paste(dataworkingK[,which(tolower(colnames(dataworkingK))==tolower(unique(levelVars[k])[1]))],dataworkingK[,which(colnames(dataworkingK)== var_list[i])],sep="##"),length)
        }
        names=unlist(strsplit(names(result),split="##",fixed=T))
        names.gVar=names[seq(from=1,to=length(names),by=2)]
        names.xVar=names[seq(from=2,to=length(names),by=2)]
        
        #names.xVar=sort(names.xVar)
        
        #names.xVar=sort(as.numeric(names.xVar))
        
        metric=rep(paste(metrics[j],"(",selected_varlist[j],")",sep=""),nrow(result))
        metric_unique=rep(metrics[j],nrow(result))
        resultDFInter=data.frame(names.xVar,metric,metric_unique,result,names.gVar,stringsAsFactors = FALSE)
        resultDFInter=resultDFInter[order(names.xVar),]
        resultDFInter=resultDFInter[order(names.xVar,names.gVar),]
        resultDF=rbind.data.frame(resultDF,resultDFInter[which(is.na(resultDFInter$result)==FALSE),])
        row.names(resultDF)=NULL
        rm(resultDFInter)
      }# j loop ends here
      resultDF2 <- rbind.data.frame(resultDF2,resultDF)
    }# k loop ends here
    colnames(resultDF2)[c(1,4,5)]=c("variable","value","lineby1")
    #resultDF2$variable=as.numeric(as.character(resultDF2$variable))
    #     resultDF2=resultDF2[with(resultDF2, order(metric_unique,variable)),]
    resultDF2=data.frame(resultDF2, stringsAsFactors=FALSE)
    #resultDF2=resultDF2[c("metric","metric_unique","value","lineby1","variable")]
    resultDF2=resultDF2[c("variable","metric","metric_unique","value","lineby1")]
    resultDF2=unique(resultDF2)
    if(flag_multiplemetric=="true"){
      resultDF2=resultDF2[-5]
    }
    #print(resultDF2)
    
    c_var_all                    <- colnames(resultDF2)
    for (j in c_var_all) {
      if (class(resultDF2[, j]) %in% c("numeric", "integer")) {
        next
      }
      
      if (class(resultDF2[, j]) == "factor") {
        resultDF2[, j]           <- as.character(resultDF2[, j])
      }
      
      x_temp                     <- resultDF2[, j] %in% "muRx_missing"
      if (any(x_temp)) {
        resultDF2[x_temp, j]     <- ""
      }
    }
    
    write.csv(resultDF2,paste(output_path,"/",var_list[i],".csv",sep=""),row.names=FALSE,quote=FALSE)
  }# i loop ends here
}# function ends here
#-----------------------------------------------------------------



#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Visualization_1.0                                                            --#
#-- Description  :  Contains some functions to enable basic visualization in MRx                     --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#

#Parameters required
#-----------------------------------------------------------------
#  input_path="C:\MRx\Visuals_Pro-18-Sep-2012-17-28-27\1"
#  output_path="C:\MRx\Visuals_Pro-18-Sep-2012-17-28-27\1\0\1_1_1\EDA\visualization_2b\3"
#  grp_flag="1_1_1"
#  grp_no="0"
#  var_list="channel_1"
#  metrics="SUM"
#  selected_varlist="ACV"
#  level=" STORE_FORMAT # STORE_FORMAT # STORE_FORMAT # STORE_FORMAT # STORE_FORMAT # GEOGRAPHY # GEOGRAPHY"
#  sublevel="Food/Drug Combo#Super Combo#Supercenter#Supermarket#Superstore#north#south"
#  flag_normal="true"
#  flag_multiplemetric="false"

#Libraries required
#-----------------------------------------------------------------
library(Hmisc)
library(XML)

#Reading the dataworking.csv  
#-----------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))
if(grp_no!=0){
  dataworking=eval(parse(text=paste("subset.data.frame(dataworking,grp",grp_no,"_flag=='",grp_flag,"')",sep="")))
}


#-------------------------------------------------------------------------------
# make sure the output path is clean
#-------------------------------------------------------------------------------
c_filesToDelete                  <- list.files(path = output_path,
                                               full.names = TRUE,
                                               recursive = TRUE,
                                               include.dirs = TRUE)
x_temp                           <- c(paste(output_path,
                                            "/param_MRx_Visualization_2.0.R",
                                            sep = ""),
                                      paste(output_path,
                                            "/code_MRx_Visualization_2.0.R",
                                            sep = ""))
x_temp                         <- !c_filesToDelete %in% x_temp
c_filesToDelete                <- c_filesToDelete[x_temp]
file.remove(c_filesToDelete)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# blank values in the x axis variabls make the code fail
# so replace the blank values by muRx_missing to make the code work
# and replace muRx_missing by blank just before writing the output csv

# checking only x axis variables for missing values
#   cos panel variables wont have missing values
#     cos we cant use variables with missing values to create a panel
#-------------------------------------------------------------------------------
c_var_all                        <- var_list
c_var_all                        <- c_var_all[c_var_all != ""]

for (i in c_var_all) {
  if (class(dataworking[, i]) %in% c("numeric", "integer")) {
    next
  }
  
  if (class(dataworking[, i]) == "factor") {
    dataworking[, i]             <- as.character(dataworking[, i])
  }
  
  x_temp                         <- dataworking[, i] %in% ""
  if (any(x_temp)) {
    dataworking[x_temp, i]       <- "muRx_missing"
  }
}
#-------------------------------------------------------------------------------


# dataworking[is.na(dataworking)] =0

if(flag_multiplemetric=="true" & flag_normal == 'true'){
  level=""
  sublevel=""
}
for(s in 1:sapply(strsplit(level, "#"), length))
{
  tempVar=strsplit(level,split="#",fixed=TRUE)[[1]][1]
  
  if(tempVar %in% colnames(dataworking)==FALSE)
  {
    if(sapply(strsplit(tempVar, " "), length)==2)
    {
      tempVar1=strsplit(tempVar,split=" ",fixed=TRUE)[[1]][1]
      tempVar2=strsplit(tempVar,split=" ",fixed=TRUE)[[1]][2]
      dataworking[,tempVar]<-paste(dataworking[,tempVar1],dataworking[,tempVar2],sep="|")
    }
    if(sapply(strsplit(tempVar, " "), length)==3)
    {
      tempVar1=strsplit(tempVar,split=" ",fixed=TRUE)[[1]][1]
      tempVar2=strsplit(tempVar,split=" ",fixed=TRUE)[[1]][2]
      tempVar3=strsplit(tempVar,split=" ",fixed=TRUE)[[1]][3]
      dataworking[,tempVar]<-paste(dataworking[,tempVar1],dataworking[,tempVar1],dataworking[,tempVar3],sep="|")
      
    }
    
  }
}


#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Function Name : visualization                                                            --#
#-- Description  :  visualization for Normal mode in MRx                     --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Shankar                                                               --#                 
#------------------------------------------------------------------------------------------------------#


visualization=function(var_list,selected_varlist,metrics,level,sublevel){
  
  
  var_list=unlist(strsplit(var_list,split=" ", fixed=T))
  metrics= unlist(strsplit(metrics,split=" ", fixed=T))
  metrics=unlist(strsplit(metrics,split="|",fixed=TRUE))
  selected_varlist=unlist(strsplit(selected_varlist,split=" ", fixed=T))
  selected_varlist=unlist(strsplit(selected_varlist,split="|",fixed=TRUE))
  #xVarIndex=which(colnames(dataworking)%in% var_list)
  #yvarIndex=which(colnames(dataworking)%in% selected_varlist)
  levelVars=unlist(strsplit(level,split="#", fixed=T))
  sublevelVars=unlist(strsplit(sublevel,split="#", fixed=T))
  # new line
  writeVarlistCSV(dataworking,var_list,metrics,selected_varlist,levelVars,sublevelVars)
  # new line
}

#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Function Name :  MRx_Visualization_1.0                                                            --#
#-- Description  :  comparison visualization in MRx                     --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Arun                                                               --#                 
#------------------------------------------------------------------------------------------------------#


visualization_comparison=function(var_list,metrics,level,sublevel){
  var_list=unlist(strsplit(var_list,split=" ", fixed=T))
  metrics= unlist(strsplit(metrics,split=" ", fixed=T))
  metrics=unlist(strsplit(metrics,split="|",fixed=TRUE))
  xVarIndex=which(colnames(dataworking)%in% var_list)
  levelVars=unique(unlist(strsplit(level,split="#", fixed=T)))
  levelVars=unique(unlist(strsplit(levelVars,split="  ", fixed=T)))
  
  if(length(levelVars) >1)
  {
    newlevelVar=apply(dataworking[levelVars],1,function(x){paste(x,collapse="|",sep="")})
    dataworking=data.frame(dataworking,newlevelVar,stringsAsFactors = FALSE)
    levelVars="newlevelVar"
  }
  
  sublevelVars=unlist(strsplit(sublevel,split="#", fixed=T))
  resultDF=NULL
  if(flag_multiplemetric == 'false')
  {
    for( i in 1:length(xVarIndex))
    {
     for( k in 1:length(metrics))
       {
      if(metrics[k]=="SUM"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){sum(x,na.rm=T)})
      }
      if(metrics[k]=="MAX"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){max(x,na.rm=T)})
      }
      if(metrics[k]=="MIN"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){min(x,na.rm=T)})
      }
      if(metrics[k]=="AVG"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){mean(x,na.rm=T)})
      }
      if(metrics[k]=="SD"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){sd(x,na.rm=T)})
      }
      if(metrics[k]=="RANGE"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){diff(range(x,na.rm=T))})
      }
      if(metrics[k]=="VAR"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],function(x){var(x,na.rm=T)})
      }
      if(metrics[k]=="COUNT"){
        result=tapply(dataworking[,which(colnames(dataworking)== var_list[i])],dataworking[,levelVars],length)
      }
      #lineby1=names(result)
      value=as.numeric(result)
      metricVal=paste(metrics[k],"(",var_list[[i]],")",sep="")
      lineby1=names(result)
      res=data.frame(var_list[i],metrics[k],metricVal,value,lineby1, stringsAsFactors = FALSE)
      names(res)=c("variable","metric_unique","metric","value","lineby1")
      if(flag_multiplemetric=="true")
      {
        index=ncol(res)
        res=res[-index]
      }
      resultDF=rbind.data.frame(resultDF,res)
    }
  }
  }  
  resultDF=unique(resultDF)
  
  
  
  if(flag_multiplemetric == 'true')
  {
    resultDF=NULL
    for( i in 1:length(var_list))
    {
      for( k in 1:length(metrics))
      {
        data=dataworking[,var_list[i]]
        if(metrics[k]=="SUM"){
          result==sum(data)
        }
        if(metrics[k]=="MAX"){
          result=max(data)
        }
        if(metrics[k]=="MIN"){
          result=min(data)
        }
        if(metrics[k]=="AVG"){
          result=mean(data)
        }
        if(metrics[k]=="SD"){
          result=sd(data)
        }
        if(metrics[k]=="RANGE"){
          result=diff(range(data))
        }
        if(metrics[k]=="VAR"){
          result=var(data)
        }
        if(metrics[k]=="COUNT"){
          result=length(data)
        }
        #lineby1=names(result)
        value=as.numeric(result)
        metricVal=paste(metrics[k],"(",var_list[[i]],")",sep="")
        res=data.frame(var_list[i],metrics[k],metricVal,value,stringsAsFactors = FALSE)
        names(res)=c("variable","metric_unique","metric","value")
        resultDF=rbind.data.frame(resultDF,res)
      }
    }
  }  
  
  # resultDF$variable=as.numeric(as.character(resultDF$variable))
  resultDF=unique(resultDF)
  resultDF=resultDF[with(resultDF, order(metric_unique,variable)),]
  
  c_var_all                      <- colnames(resultDF)
  for (i in c_var_all) {
    if (class(resultDF[, i]) %in% c("numeric", "integer")) {
      next
    }
    
    if (class(resultDF[, i]) == "factor") {
      resultDF[, i]              <- as.character(resultDF[, i])
    }
    
    x_temp                       <- resultDF[, i] %in% "muRx_missing"
    if (any(x_temp)) {
      resultDF[x_temp, i]        <- ""
    }
  }
  
  write.csv(resultDF,paste(output_path,"/column_chart.csv",sep=""),row.names=FALSE,quote=FALSE)
}




normal=try(length(selected_varlist),silent=TRUE)
if(class(normal)!="try-error")
{
  visualization(var_list,selected_varlist,metrics,level,sublevel)
}

if(class(normal)=="try-error")
{
  visualization_comparison(var_list,metrics,level,sublevel)
}
#completed.text
write("VISUALIZATION_2B_COMPLETED", file = paste(output_path, "VISUALIZATION_2B_COMPLETED.txt", sep="/"))
