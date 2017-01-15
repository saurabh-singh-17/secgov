#------------------------------------------------------------------------------#
#--                                                                          --#
#-- Project Name :  MRx_Correlation_1.0                                      --#
#-- Description  :  Contains some functions to enable correlation in MRx     --#
#-- Return type  :  Generates csvs at given location                         --#
#-- Author       :  Shankar Kumar Jha                                        --#
#------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------
# Parameters required
#-------------------------------------------------------------------------------
# input_path <- 'C:/MRx/r/L_1-6-Oct-2012-15-34-36/2'
# output_path <- 'C:/MRx/r/L_1-6-Oct-2012-15-34-36/2/0/1_1_1/EDA/Correlation/2'
# dataset_name <- 'dataworking'
# dataset_path <- 'C:/MRx/r/L_1-6-Oct-2012-15-34-36/2'
# xvars <- c('channel_3','channel_2','channel_1','black_hispanic','ACV')
# yvars <- c('channel_3','channel_2','channel_1','black_hispanic','ACV')
# trans_type <- 'rec sqr cub log sin cos'
# adstock_type <- 'simple'
# ad_start <- '0.3'
# ad_end <- '0.6'
# ad_step <- '0.1'
# lag <- '2'
# lead <- '2'
# corr_cutoff <- '0'
# grp_flag <- '1_1_1'
# grp_no <- '0'
# cormat_selectVars <- 'true'
# cormat_allVars <- 'true'
# flag_cormat <- 'true'
#-------------------------------------------------------------------------------

#Deleting the error.txt from server location

if (file.exists(paste(output_path,"/error.txt",sep = ""))){
  file.remove(paste(output_path,"/error.txt",sep = ""))
}

#-------------------------------------------------------------------------------
# Libraries required
#-------------------------------------------------------------------------------
library(zoo)
library(XML)
library(ltm)
library(plyr)
library(msm)
library(polycor)
#-------------------------------------------------------------------------------





#-- #~!@#4526,NEW,EDA,correlation,26feb2013,1609
#------------------------------------------------------------------------------
# Custom function 1 : To make NA and Inf values blank
#------------------------------------------------------------------------------
makeItBlank <- function(theValues,flag.na=F,flag.inf=F){
  theValues <- as.character(theValues)
  na <- NULL
  inf <- NULL
  if(flag.na){
    na <- which(is.na(theValues))
  }
  if(flag.inf){
    inf <- which(theValues='Inf')
  }
  naInf<-c(na,inf)
  theValues[naInf] <- ''
  return(theValues)
}
#------------------------------------------------------------------------------
#-- #~!@#4526,NEW,EDA,correlation,26feb2013,1609



#-------------------------------------------------------------------------------
# function : dfToXml
#-------------------------------------------------------------------------------
dfToXML=function(dataFrame,location){
  xml <- xmlTree()
  xml$addTag("TABLE", close=FALSE)
  for (i in 1:nrow(dataFrame)) {
    xml$addTag("CORMAT", close=FALSE)
    for(j in 1:ncol(dataFrame)){
      xml$addTag(colnames(dataFrame)[j], dataFrame[i, j])
    }
    xml$closeTag()
  }
  xml$closeTag()
  saveXML(xml,location)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : transformation
#-------------------------------------------------------------------------------
transformationFunction=function(xvars,trans_type){
  trans_type=unlist(strsplit(trans_type,split=" ",fixed=TRUE))
  data=dataworking[xvars]
  result<-NULL
  colname<-NULL
  for(j in 1:length(xvars)){
    for(i in 1:length(trans_type)){
      type=trans_type[i]
      #transformation operation starts here
      if(type=='rec'){               
        flag=1/data[,j]
      }
      if(type=='sqr'){               
        flag=data[,j]^2
      }
      if(type=='cub'){               
        flag=1/data[,j]^3
      }
      if(type=='log'){               
        flag=1/log1p(data[,j])
      }
      if(type=='sin'){               
        flag=sin(data[,j])
      }
      if(type=='cos'){               
        flag=cos(data[,j])
      }
      result=cbind(result,flag)
      colname<-c(colname,paste(type,"~",xvars[j],sep=""))
    }
  }
  result<-as.data.frame(result)
  colnames(result)<-colname
  return(result)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : adstock
#-------------------------------------------------------------------------------
adstockTransform=function(xvars,decay_rate,eqn_type){
  data=dataworking[xvars]
  decay_rate_vector=decay_rate
  adStockDF=NULL
  colname=NULL
  
  if(eqn_type=="simple") {
    #  corr=NULL
    for(i in 1:ncol(data)){
      for(j in 1:length(decay_rate_vector)){
        newVar=data[,i]
        #         index<-(which(is.na(newVar)==FALSE))
        #         newVar=data[index,i]
        # newVar[c(which(is.na(newVar) == "TRUE"))]<-0
        newVar<-Reduce(function(x,y){y+x*(1-decay_rate_vector[j])},newVar,accumulate=TRUE)
        adStockDF=as.data.frame(cbind(adStockDF,newVar))
        colname<-c(colname,paste("adstock~",xvars[i],"~",as.character(decay_rate_vector[j]),sep=""))
      }
    }
  }  
  colnames(adStockDF)<-colname
  return(adStockDF)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : lag
#-------------------------------------------------------------------------------
lagFunction=function(xvars,lag){
  
  data=dataworking[xvars]
  result=NULL
  colname=NULL
  colname2=NULL
  if(!(is.na(as.numeric(lag))))
  {
    for(i in 1:length(xvars)){
      for(j in 1:as.numeric(lag)){
        changedCol =as.numeric(lag(zoo(data[,i]),-j))
        changedCol = c(rep(NA,j),changedCol)
        #changedCol=na.omit(changedCol)
        result=cbind(result,changedCol)
        colname<-c(colname,paste("lag - ",j,"~",xvars[i],sep=""))
        colname2<-c(colname2,paste("lg_",xvars[i],j,sep=""))
      }
    }
  }
  
  result<-as.data.frame(result)
  colnames(result)<-colname
  lresult=list("result"=result,"colname2"=colname2)
  return(lresult)  
} 
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : lead
#-------------------------------------------------------------------------------
leadFunction=function(xvars,lead){
  
  data=dataworking[xvars]
  result=NULL
  colname=NULL
  colname2=NULL
  
  if(!(is.na(as.numeric(lead))))
  {
    for(i in 1:length(xvars)){
      for(j in 1:as.numeric(lead)){
        changedCol =as.numeric(lag(zoo(data[,i]),j))
        changedCol = c(changedCol,rep(NA,j))
        #changedCol=na.omit(changedCol)
        result=cbind(result,changedCol)
        colname<-c(colname,paste("lead - ",j,"~",xvars[i],sep=""))
        colname2<-c(colname2,paste("ld_",xvars[i],j,sep=""))
      }
    }
  }
  
  result<-as.data.frame(result)
  colnames(result)<-colname
  lresult=list("result"=result,"colname2"=colname2)
  return(lresult)  
}
#-------------------------------------------------------------------------------



rm("ydata")
chartResult<-NULL
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the data
#-------------------------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))
error_var_final <- NULL
vars_check <- c(xvars,yvars)




#Per Group By 
if (as.integer(grp_no)!= 0) {
  temp_var=paste("grp",grp_no,"_flag",sep="")
  
  index<-which(names(dataworking)==temp_var)
  dataworking<-subset(dataworking,dataworking[index]==grp_flag)
}


for (i in 1:length(vars_check)) {
  blank_logical<- dataworking[, vars_check[i]] == ""
  na_logical <- is.na(dataworking[,vars_check[i]])
  fin_logical <- (blank_logical | na_logical)
  
  
  if (any(fin_logical) ){
    error_var_final <- c(error_var_final, vars_check[i])
  }
}

if (length(error_var_final)){
  error_text <- paste("The variable(s) ", 
                      paste(error_var_final,
                            collapse= ", "),
                      " have missing values. Please treat them and then select again.",
                      sep="")
  write(error_text, paste(output_path,"/error.txt",sep=""))
  stop(error_text)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sorting the dataset by the date variable
#-------------------------------------------------------------------------------
if(dateVarName != '')
{
 
  dataworking<-dataworking[order(dataworking[,dateVarName]),]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# error check : boxcox
#-------------------------------------------------------------------------------
if(as.logical(box_cox)){
  new<-apply(dataworking[xvars],2,function(x){length(which(x == 0))})
  invalid_var<-paste(names(which(new != 0)),collapse=",")
  if(invalid_var != ""){
    write(paste("Following selected variable(s) have zero values- "
                ,invalid_var,". Box-Cox transformation can not be performed"
                ,sep=""),file=paste(output_path,"error.txt", sep="/"))
  }
}
#-------------------------------------------------------------------------------




resultDF.1=NULL
resultDF.2=NULL
resultDF.3=NULL
resultDF.4=NULL
adResult=NULL
llResult=NULL
tranResult=NULL
chartResult=NULL
flag=0

if ((trans_type == "") & (ad_start=="") & (lag=="0") & (lead=="0") & (ad_start=="") & (box_cox=='false') )
{
  flag=1
}
#-------------------------------------------------------------------------------




if(flag ==0)
{
  if(!(trans_type=="")){
    result=transformationFunction(xvars,trans_type) 
    
    if(is.null(chartResult)){
      chartResult=result
    }else{
      chartResult=cbind.data.frame(chartResult,result)
    }
    tranResult=result
    collist=unlist(strsplit(colnames(result),split="~",fixed=TRUE))
    xvarlistname=collist[seq(2,length(collist),by=2)]
    classesname=collist[seq(1,length(collist),by=2)]
    corr_value=NULL
    p_value=NULL
    yvarslist=NULL
    xvarlist=NULL
    classes=NULL
    #     for(i in 1:length(yvars))
    #     {  
    #       k<- dataworking[which(is.na(dataworking[yvars[i]])==FALSE),yvars[i]]
    #       if(all(is.na(dataworking[yvars[i]]))==FALSE && class(k)=="integer")
    #       {level<- NULL
    #        level<- unlist(unique(dataworking[yvars[i]]))
    #        dataworking[which(is.na(dataworking[yvars[i]])==TRUE),yvars[i]] = level[2]}
    #     }
    #     
    #     for(i in 1:length(xvars))
    #     { 
    #       k<- dataworking[which(is.na(dataworking[xvars[i]])==FALSE),xvars[i]]
    #       if(all(is.na(dataworking[xvars[i]]))==FALSE && class(k)=="integer")
    #       { level<- NULL
    #         level<- unlist(unique(dataworking[xvars[i]]))
    #         dataworking[which(is.na(dataworking[xvars[i]])==TRUE),xvars[i]] = level[2]}
    #     }
    
    ydata=dataworking[yvars]
    for(i in 1:ncol(ydata)){
      for(j in 1:ncol(result)){
        corObj=cor.test(ydata[,i],result[,j],na.action=na.exclude)
        corr_value=c(corr_value,round(corObj$estimate,4))
        p_value=c(p_value,round(corObj$p.value,4)) 
        xvarlist=c(xvarlist,xvarlistname[j])
        yvarslist=c(yvarslist,yvars[i])
        classes=c(classes,classesname[j])
      }
    }
    type=rep("transformations",length(classes))
    resultDF.1=data.frame(type,yvarslist,xvarlist,classes,corr_value,p_value,type,stringsAsFactors = FALSE)
    
  }
  
  if(!(ad_start=="")){
    decay_rate=seq(as.numeric(ad_start),as.numeric(ad_end),by=as.numeric(ad_step))
    result=adstockTransform(xvars = xvars,decay_rate = decay_rate,eqn_type = adstock_type)
    adResult=result
    if(is.null(chartResult)){
      chartResult=result
    }else{
      chartResult=cbind.data.frame(chartResult,result)
    }
    collist=unlist(strsplit(colnames(result),split="~",fixed=TRUE))
    xvarlistname=collist[seq(2,length(collist),by=3)]
    classesname=collist[seq(3,length(collist),by=3)]
    
    corr_value=NULL
    p_value=NULL
    yvarslist=NULL
    xvarlist=NULL
    classes=NULL
    
    #     for(i in 1:length(yvars))
    #     {  
    #       k<- dataworking[which(is.na(dataworking[yvars[i]])==FALSE),yvars[i]]
    #       if(all(is.na(dataworking[yvars[i]]))==FALSE && class(k)=="integer"){
    #         level<- NULL
    #         level<- unlist(unique(dataworking[yvars[i]]))
    #         dataworking[which(is.na(dataworking[yvars[i]])==TRUE),yvars[i]] = level[2]
    #       }
    #     }
    #     
    #     for(i in 1:length(xvars))
    #     { 
    #       k<- dataworking[which(is.na(dataworking[xvars[i]])==FALSE),xvars[i]]
    #       if(all(is.na(dataworking[xvars[i]]))==FALSE && class(k)=="integer"){ 
    #         level<- NULL
    #         level<- unlist(unique(dataworking[xvars[i]]))
    #         dataworking[which(is.na(dataworking[xvars[i]])==TRUE),xvars[i]] = level[2]
    #       }
    #     }
    ydata=dataworking[yvars]
    for(i in 1:ncol(ydata)){
      for(j in 1:ncol(result)){
        corObj=cor.test(ydata[,i],result[,j],na.action=na.exclude)
        corr_value=c(corr_value,round(corObj$estimate,4))
        p_value=c(p_value,round(corObj$p.value,4)) 
        xvarlist=c(xvarlist,xvarlistname[j])
        yvarslist=c(yvarslist,yvars[i])
        classes=c(classes,paste("decay - ",classesname[j],sep=""))
      }
    }
    type=rep("adstock",length(classes))
    resultDF.2=data.frame(type,yvarslist,xvarlist,classes,corr_value,p_value,type,stringsAsFactors = FALSE)
    
  }
  
  if(lag!="0"){
    lresult=lagFunction(xvars,lag) 
    result=lresult$result
    colname2=lresult$colname2
    llResult=result
    colnames(llResult)<-colname2
    if(is.null(chartResult))
    {
      chartResult=llResult
    }else{
      chartResult=cbind.data.frame(chartResult,llResult)
    }
    collist=unlist(strsplit(colnames(result),split="~",fixed=TRUE))
    xvarlistname=collist[seq(2,length(collist),by=2)]
    classesname=collist[seq(1,length(collist),by=2)]
    #     for(i in 1:length(yvars))
    #     {  
    #       k<- dataworking[which(is.na(dataworking[yvars[i]])==FALSE),yvars[i]]
    #       if(all(is.na(dataworking[yvars[i]]))==FALSE && class(k)=="integer")
    #       {level<- NULL
    #        level<- unlist(unique(dataworking[yvars[i]]))
    #        dataworking[which(is.na(dataworking[yvars[i]])==TRUE),yvars[i]] = level[2]}
    #     }
    #     
    #     for(i in 1:length(xvars))
    #     { 
    #       k<- dataworking[which(is.na(dataworking[xvars[i]])==FALSE),xvars[i]]
    #       if(all(is.na(dataworking[xvars[i]]))==FALSE && class(k)=="integer")
    #       { level<- NULL
    #         level<- unlist(unique(dataworking[xvars[i]]))
    #         dataworking[which(is.na(dataworking[xvars[i]])==TRUE),xvars[i]] = level[2]}
    #     }
    corr_value=NULL
    p_value=NULL
    yvarslist=NULL
    xvarlist=NULL
    classes=NULL
    ydata=dataworking[yvars]
    for(i in 1:ncol(ydata)){
      for(j in 1:ncol(result)){
        corObj=cor.test(ydata[,i],result[,j],na.action=na.exclude)
        corr_value=c(corr_value,round(corObj$estimate,4))
        p_value=c(p_value,round(corObj$p.value,4)) 
        xvarlist=c(xvarlist,xvarlistname[j])
        yvarslist=c(yvarslist,yvars[i])
        classes=c(classes,classesname[j])
      }
    }
    type=rep("lag",length(classes))
    resultDF.3=data.frame(type,yvarslist,xvarlist,classes,corr_value,p_value,type,stringsAsFactors = FALSE)
  }
  
  
  if(lead!="0"){
    lresult=leadFunction(xvars,lead) 
    result=lresult$result
    colname2=lresult$colname2
    llResult=result
    colnames(llResult)<-colname2
    if(is.null(chartResult)){
      chartResult=llResult
    }else{
      chartResult=cbind.data.frame(chartResult,llResult)
    }
    collist=unlist(strsplit(colnames(result),split="~",fixed=TRUE))
    xvarlistname=collist[seq(2,length(collist),by=2)]
    classesname=collist[seq(1,length(collist),by=2)]
    #     for(i in 1:length(yvars))
    #     {  
    #       k<- dataworking[which(is.na(dataworking[yvars[i]])==FALSE),yvars[i]]
    #       if(all(is.na(dataworking[yvars[i]]))==FALSE && class(k)=="integer")
    #       {level<- NULL
    #        level<- unlist(unique(dataworking[yvars[i]]))
    #        dataworking[which(is.na(dataworking[yvars[i]])==TRUE),yvars[i]] = level[2]}
    #     }
    #     
    #     for(i in 1:length(xvars))
    #     { 
    #       k<- dataworking[which(is.na(dataworking[xvars[i]])==FALSE),xvars[i]]
    #       if(all(is.na(dataworking[xvars[i]]))==FALSE && class(k)=="integer")
    #       { level<- NULL
    #         level<- unlist(unique(dataworking[xvars[i]]))
    #         dataworking[which(is.na(dataworking[xvars[i]])==TRUE),xvars[i]] = level[2]}
    #     }
    corr_value=NULL
    p_value=NULL
    yvarslist=NULL
    xvarlist=NULL
    classes=NULL
    ydata=dataworking[yvars]
    for(i in 1:ncol(ydata)){
      for(j in 1:ncol(result)){
        corObj=cor.test(ydata[,i],result[,j],na.action=na.exclude)
        corr_value=c(corr_value,round(corObj$estimate,4))
        p_value=c(p_value,round(corObj$p.value,4)) 
        xvarlist=c(xvarlist,xvarlistname[j])
        yvarslist=c(yvarslist,yvars[i])
        classes=c(classes,classesname[j])
      }
    }
    type=rep("lead",length(classes))
    resultDF.4=data.frame(type,yvarslist,xvarlist,classes,corr_value,p_value,type,stringsAsFactors = FALSE)
  }
  
  
  boxCoxDF <- NULL
  #-- #~!@#4526,NEW,EDA,correlation,26feb2013,1609
  #------------------------------------------------------------------------------
  # If BoxCox is selected
  #------------------------------------------------------------------------------
  if(as.logical(box_cox)){
    
    boxcoxvaluesdf <- NULL
    lambdavalue <- NULL
    for(i in xvars){
      for(j in seq(from=as.numeric(box_start),to=as.numeric(box_stop),by=as.numeric(box_step))){
        if(j!=0){
          currentName <- paste("bc_",
                               gsub(pattern="\\.|\\-",replacement="_",x=as.character(j)),
                               "_",
                               substr(x=i,start=1,stop=24),
                               sep="")
          lambdavalue <- c(lambdavalue,j)
          assign(currentName,(((dataworking[,i]^j)-1)/j))
          if(is.null(boxcoxvaluesdf)){
            boxcoxvaluesdf <- as.data.frame(eval(parse(text=currentName)))
          }else{
            boxcoxvaluesdf <- cbind.data.frame(boxcoxvaluesdf,eval(parse(text=currentName)))
          }
          colnames(boxcoxvaluesdf)[ncol(boxcoxvaluesdf)] <- currentName 
        }
      }
    }
    
    p_value <- NULL
    corr_value <- NULL
    yvarslist <- NULL
    xvarlist <- NULL
    
    for(i in xvars){
      xvarlist <- c(xvarlist,rep(i,ncol(boxcoxvaluesdf)/length(xvars)))
    }
    for(i in yvars){
      for(j in colnames(boxcoxvaluesdf)){
        cortestobj <- cor.test(x=dataworking[,i],y=boxcoxvaluesdf[,j],use="na.or.complete")
        p_value <- c(p_value,cortestobj$p.value)
        corr_value <- c(corr_value,cortestobj$estimate)
        yvarslist <- c(yvarslist,i)
        loglikl <- NULL
        for(k in 1:length(xvars)){
          for(m in 1:length(yvars)){
            
            print(c(k,m))
            #             paste( yvars[m],'~',xvars[k]), data=dataworking)
            loglikl.temp<-try(data.frame(eval(parse(text=paste('boxcox(',yvars[m],'~',xvars[k],',data=dataworking,lambda = seq(as.numeric(box_start),as.numeric(box_stop),by=as.numeric(box_step)),plotit=F)',sep=''))),stringsAsFactors = FALSE),silent=TRUE)
            
            if(class(loglikl.temp)=="try-error"){
              x = seq(as.numeric(box_start),as.numeric(box_stop),by=as.numeric(box_step))
              y=rep(NA,length(x))
              loglikl.temp=data.frame(cbind(x,y))
              row.names(loglikl.temp)= NULL
            }
            loglikl <- rbind.data.frame(loglikl,loglikl.temp)
          }
        }
        loglikl.new <- NULL
        for(tempi in seq(from=as.numeric(box_start),to=as.numeric(box_stop),by=as.numeric(box_step))){
          if(tempi!=0){
            print(tempi)
            temp <- loglikl$x-tempi
            temp[which(temp<0)] <- Inf 
            temp <- which(temp==min(temp))
            temp <- temp[1]
            loglikl.new<- as.data.frame(rbind(loglikl.new,loglikl[temp,]))
          }
        }
        r_square<-as.data.frame(corr_value)
        RSquare<-r_square*r_square
      }
    }
    
    
    boxCoxDF <- data.frame(type="boxcox",yvarslist,xvarlist,classes=lambdavalue,corr_value,p_value,type="boxcox",stringsAsFactors = FALSE)
    boxCoxDF<- data.frame(boxCoxDF,loglikl.new$y,RSquare,stringsAsFactors = FALSE)
    colnames(boxCoxDF)[c(8,9)]<-c("LogLike","RSquare")
    for(tempi in 1:ncol(boxCoxDF)){
      boxCoxDF[,tempi] <- as.character(boxCoxDF[,tempi])
    }
  }
  #------------------------------------------------------------------------------
  #-- #~!@#4526,NEW,EDA,correlation,26feb2013,1609
  
  
  resultDFFinal=rbind.data.frame(resultDF.1,resultDF.2,resultDF.3,resultDF.4)
  if (nrow(resultDFFinal)) {
    resultDFFinal$LogLike <- NA
    resultDFFinal$RSquare <- NA
  }
  rm('resultDF.1','resultDF.2','resultDF.3','resultDF.4')
  resultDFFinal=rbind.data.frame(resultDFFinal,boxCoxDF)
  case=rep("Insignificant",nrow(resultDFFinal))
  index=which(as.numeric(as.character(resultDFFinal$corr_value))>as.numeric(corr_cutoff))
  case[index]="Significant"
  resultDFFinal<-cbind.data.frame(resultDFFinal[,-7],case,resultDFFinal[,7]) 
  colnames(resultDFFinal)[c(2,3,10)]<-c("y_vars","x_vars","category") 
  #   resultDFFinal<-resultDFFinal[order(resultDFFinal$type,resultDFFinal$y_vars,resultDFFinal$x_vars),]
  max=aggregate(as.numeric(as.character(resultDFFinal$corr_value)),list(resultDFFinal$y_vars,resultDFFinal$x_vars,resultDFFinal$type),max)
  min=aggregate(as.numeric(as.character(resultDFFinal$corr_value)),list(resultDFFinal$y_vars,resultDFFinal$x_vars,resultDFFinal$type),min)
  # high=rep(1,nrow(resultDFFinal))
  # low=rep(-1,nrow(resultDFFinal))
  # 
  # for(i in 1:nrow(max)){
  #   index=which(max[i,1]==resultDFFinal$y_vars  & max[i,2]==resultDFFinal$x_vars & max[i,3]==resultDFFinal$type)
  #   high[index]=max[i,3]
  #   low[index]=min[i,3]
  # }
  # difference=high-low
  #-- #~!@#25Jan2013,1650#
  resultDFFinal$high <- rep('',nrow(resultDFFinal))
  resultDFFinal$low  <- rep('',nrow(resultDFFinal))
  for(i in 1:nrow(resultDFFinal)){
    indx <- which(max[,1]==resultDFFinal$y_vars[i] & max[,2]==resultDFFinal$x_vars[i] & max[,3]==resultDFFinal$type[i])
    resultDFFinal$high[i] = max[indx,4] 
    resultDFFinal$low[i]  = min[indx,4]
  }
  resultDFFinal$difference = as.numeric(resultDFFinal$high)-as.numeric(resultDFFinal$low)
  resultDFFinal$classes <- gsub("rec","Reciprocal",resultDFFinal$classes)
  resultDFFinal$classes <- gsub("sqr","Square",resultDFFinal$classes)
  resultDFFinal$classes <- gsub("cub","Cube",resultDFFinal$classes)
  resultDFFinal$classes <- gsub("log","Log",resultDFFinal$classes)
  resultDFFinal$classes <- gsub("sin","Sine",resultDFFinal$classes)
  resultDFFinal$classes <- gsub("cos",'Cosine',resultDFFinal$classes)
  #-- #~!@#25Jan2013,1650#
  
  #resultDFFinal<-resultDFFinal[,c(2:(ncol(resultDFFinal)-3))]
  #resultDFFinal$type<-resultDFFinal$category
  #resultDFFinal<-resultDFFinal[c(ncol(resultDFFinal),1:(ncol(resultDFFinal)-1))]
  #resultDFFinal1<-apply(resultDFFinal[ncol(resultDFFinal)],1,function(x){if(x=="lag" | x=="lead"){x="lag-lead"}else{x=x}})
  #resultDFFinal<-cbind(resultDFFinal[1:(ncol(resultDFFinal)-1)],resultDFFinal1)
  #colnames(resultDFFinal)[ncol(resultDFFinal)]<-"category"
  
  resultDFFinal$category <- as.character(resultDFFinal$category)
  index <- which(resultDFFinal$category=="lag" | resultDFFinal$category=="lead")
  
  if(length(index))
  {
    resultDFFinal$category[index]="lag-lead"
  }
  
  write.csv(resultDFFinal,paste(output_path,"/correlation.csv",sep=""),row.names=FALSE,quote=FALSE)
  
  #Correlation of selected variables
  datax=dataworking[c(xvars,yvars)]
  datay=dataworking[c(xvars,yvars)]
  corSelectResult=as.data.frame(cor(datax,datay,use="na.or.complete"))
  variable=row.names(corSelectResult)
  corSelectResult=cbind.data.frame(variable,corSelectResult)
  colnames(corSelectResult)[1]="xvar"
  dfToXML(corSelectResult,paste(output_path,"/correlation.xml",sep=""))
  
  
  
  ### Creating correlation matrix for all possible variables in the dataset
  
  variableList = as.character(sapply(dataworking,class))
  
  # edited for taking all integer into account. 
  varIndex = which(variableList=="integer")
  if(length(varIndex) >0){
    variableList[varIndex] ="numeric"
  }
  index=which(variableList=="numeric")
  data=dataworking[,index]
  allVarCor=as.data.frame(cor(data,use="pairwise.complete.obs"))
  Variable=row.names.data.frame(allVarCor)
  allVarCor=cbind.data.frame(Variable,allVarCor)
  corFile=paste(output_path,"/corr_matrix/allVars_cormat.csv",sep="")
  write.csv(allVarCor,corFile,row.names=FALSE,quote=FALSE)
  
  colnames(corSelectResult)[1]="Variable"
  corFile=paste(output_path,"/corr_matrix/selectVars_cormat.csv",sep="")
  write.csv(corSelectResult,corFile,row.names=FALSE,quote=FALSE)
  
  # if(!is.null(llResult)){
  #   colnames(llResult)<-colname2
  # }
  #chartResult=as.data.frame(cbind(as.matrix(ydata),adResult,as.matrix(tranResult),as.matrix(llResult)))
  if((trans_type != "") | (ad_start !="") | (lag!="0") | (lead!="0") | (ad_start!="") | as.logical(box_cox))
  {
    if(!exists("ydata")) ydata <- dataworking[yvars]
    if(is.null(chartResult)){
      chartResult <- ydata
      colnames(chartResult) <- yvars
    }else{
      chartResult=cbind.data.frame(chartResult,as.matrix(ydata))
    }
    colnames(chartResult)=gsub(pattern="adstock",replacement="ad",colnames(chartResult),fixed=TRUE)
    colnames(chartResult) <- gsub(pattern="[^[:alnum:]]",replacement="_",x=colnames(chartResult))
    
    nam<-colnames(chartResult)
    index<-which(grepl(".1",nam,fixed=T)== "TRUE")
    if(length(index)){chartResult<-chartResult[,-c(index)]}
    nam1<-unique(colnames(chartResult))
    chartResult<-as.data.frame(chartResult[,c(nam1)])
    colnames(chartResult) <- nam1
    if(as.logical(box_cox)){
      chartResult <- cbind.data.frame(chartResult,boxcoxvaluesdf)
    }
    
    write.csv(chartResult,paste(output_path,"/corr_charts.csv",sep=""),row.names=FALSE,quote=FALSE)  
  }else{
    chartResult<-cbind(dataworking[c("primary_key_1644",xvars,yvars)])
    write.csv(chartResult,paste(output_path,"/corr_charts.csv",sep=""),row.names=FALSE,quote=FALSE)  
  }
}  


if(flag==1)
{
  corr_value=NULL
  p_value=NULL
  yvarslist=yvars
  xvarlist=xvars
  classes="Original_Variable"
  result=NULL
  
  for( i in 1:length(yvars))
  {
    corRes=rcor.test(dataworking[c(xvars,yvars[i])],use="na.or.complete")
    corVal=corRes$cor.mat
    corVal=corVal[,ncol(corVal)]
    corVal=corVal[-length(corVal)]
    corVal=round(corVal,4)
    pVal=as.data.frame(corRes$p.values)
    colnames(pVal)[2]="rec"
    pVal=subset(pVal,rec==max(pVal$rec))
    pVal=pVal$pvals
    pVal=round(pVal,4)
    res=data.frame(yvars[i],xvars,corVal,pVal,stringsAsFactors = FALSE)
    colnames(res)=c("y_vars","x_vars","corr_value","p_value")
    result=rbind.data.frame(result,res) 
  }
  
  result$classes="Original_Variable"
  result$case="Significant"
  result$category=""
  result$type=""
  result$High=result$corr_value
  result$Low=result$corr_value
  result$Difference=0
  #result<-result[1:(ncol(result)-4)]
  
  if (result$classes=="Original_Variable"){
    result$type="Original_Variable"
    result$category="Original_Variable"
  }
  
  write.csv(result,paste(output_path,"/correlation.csv",sep=""),row.names=FALSE,quote=FALSE)
  
  #Creating XML
  
  corXML<-newXMLNode("TABLE")
  for(i in 1:length(xvars))
  {
    yVarXML<-newXMLNode("CORMAT",parent=corXML)
    
    tempres=subset(result,x_vars==xvars[i])
    grpXML<-newXMLNode("xvar",xvars[i],parent=yVarXML)
    for( j in 1:length(yvars))
    {
      val1XML=newXMLNode(as.character((tempres$y_vars)[j]),tempres$corr_value[j],parent=yVarXML)
    }
    
  }
  saveXML(corXML,paste(output_path,"correlation.xml",sep="/"))
  
  
  ### Creating correlation matrix for all possible variables in the dataset
  
  variableList = as.character(sapply(dataworking,class))
  # edited for taking all integer into account. 
  varIndex = which(variableList=="integer")
  if(length(varIndex) >0){
    variableList[varIndex] ="numeric"
  }
  index=which(variableList=="numeric")
  data=dataworking[,index]
  allVarCor=as.data.frame(cor(data,use="pairwise.complete.obs"))
  Variable=row.names.data.frame(allVarCor)
  allVarCor=cbind.data.frame(Variable,allVarCor)
  corFile=paste(output_path,"/corr_matrix/allVars_cormat.csv",sep="")
  write.csv(allVarCor,corFile,row.names=FALSE,quote=FALSE)
  
  
  ### Creating correlation matrix for all selected variables in the dataset
  index=which(names(dataworking) %in% c(xvars,yvars))
  if(length(index)==1)
  {
    index <- rep(index,2)
  }
  data=dataworking[,index]
  allVarCor=as.data.frame(cor(data,use="na.or.complete"))
  Variable=row.names.data.frame(allVarCor)
  allVarCor=cbind.data.frame(Variable,allVarCor)
  colnames(allVarCor)[1]="Variable"
  corFile=paste(output_path,"/corr_matrix/selectVars_cormat.csv",sep="")
  write.csv(allVarCor,corFile,row.names=FALSE,quote=FALSE)
  
  # Creating corr Value chart
  cols<-unique(c(xvars,yvars))
  corrChart=dataworking[c("primary_key_1644",cols)]
  write.csv(corrChart,paste(output_path,"/corr_charts.csv",sep=""),row.names=FALSE,quote=FALSE)
  
  
}
if(nrow(dataworking)>6000)
{
  if(flag==0)
  {
    corrChart<-chartResult 
  }
  colnames_chart<- colnames(corrChart)
  for(i in 1:length(yvars))
  {
    if(grepl(yvars[i],colnames_chart[length(colnames_chart)-length(yvars)+i])==FALSE)
    {
      print(1)
      corrChart<-cbind(corrChart,dataworking[c(yvars[i])])}
  }
  
  colnames_chart<- colnames(corrChart)
  if(flag==1)
  {
    colnams_yvars<-colnames_chart[2:(length(colnames_chart)-length(yvars))]}else
    {colnams_yvars<-colnames_chart[1:(length(colnames_chart)-length(yvars))]}
  
  yvarlist<-NULL
  chartindex<-as.data.frame(rep(colnams_yvars,length(yvars)))
  for(i in 1:length(yvars))
  {  
    add<-rep(yvars[i],length(colnams_yvars))
    yvarlist<-c(yvarlist,add)
  }
  gplot<- rep('',nrow(chartindex))
  for(i in 1:nrow(chartindex))
  { if(i==1)
  {gplot[i]<-paste('gplot',sep='')}else
  {gplot[i]<-paste('gplot',i-1,sep='')}
  }
  chart_index<-cbind(as.data.frame(yvarlist),chartindex,as.data.frame(gplot))
  colnames(chart_index)<-c('yvar','xvar','chart')
  write.csv(chart_index,paste(output_path,'/','charts/',"chart_index.csv",sep=""),row.names=FALSE,quote=FALSE)
  
  
  for(i in 1:nrow(chart_index))
  {
    try(dev.off(),silent=T)
    if(i==1)
    {jpeg(paste(output_path,'/','charts/','gplot','.jpg',sep=''))}else
    {jpeg(paste(output_path,'/','charts/','gplot',i-1,'.jpg',sep=''))}
    
    k<-as.vector(corrChart[c(paste(chart_index[i,1]))])
    k2<-as.vector(corrChart[c(paste(chart_index[i,2]))])
    k3<-cbind(k2,k)
    print(colnames(k3))
    plot(k3,col="orange")
    dev.off()
  }
}
#writing the completed text at the output location
#-----------------------------------------------------------------
write("CORRELATION_COMPLETED", file = paste(output_path,"CORRELATION_COMPLETED.TXT", sep="/"))

#writing NOBS  at the output location
#-----------------------------------------------------------------
write.table(as.data.frame(nrow(dataworking))[1,1],paste(output_path,"/NOBS.txt",sep=""),row.names = FALSE, quote = FALSE,col.names=F)
