#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_time_series_split_1.0                                                                      --#
#-- Description  :  Contains functions to give CSVs for viusalization time series split                                --#
#-- Return type  :  Generates csvs at given location                                                 --#
#-- Author       :  Saurabh Vikash Singh                                                                    --#                 
#------------------------------------------------------------------------------------------------------

#Parameters required
#-----------------------------------------------------------------
# input_path <- 'C:/MRx/r/newproject-18-Oct-2012-09-59-06/1'
# output_path="D:/exceloutput"
# selected_vars <- c("ACV")
# grp_vars <- c()
# date_vars <- c("Date")
# date_level <- 'day'
# flag_rollup <- 'true'
# rollup_level <- 'week'
# rollup_metric <- 'total' #or average or beginning or middle or end;
# plot_metric <- ''#or average
# plot_select <- 'month' #or week or year or qtr
# plot_across <- 'week' #or week or month or qtr or year
# plot_over <- 'year'


#Libraries required
#-----------------------------------------------------------------

library(chron)

# writing a function to recognise  a date format


#Reading the dataworking.csv  
#-----------------------------------------------------------------
#dataworking=read.csv(paste(input_path,"dataworking.csv",sep="/"),header=T)
load(paste(input_path,"dataworking.RData",sep="/"))
output_path<-paste(output_path,"/",sep="")
rollup_metric<-gsub("beginning","begin",rollup_metric,fixed=TRUE)
if(!is.null(grp_vars))
{
  for(i in 1:length(grp_vars))
  {
    dataworking[,grp_vars[i]]<-gsub("[[:punct:]]","_",dataworking[,grp_vars[i]])  
  }
}  
resultDF= NULL
uniquenames<-NULL
if(flag_rollup == 'false'){
  rollup_level=date_level 
  rollup_metric='average'
}
if(is.null(grp_vars)){
  dataworking$dummy=0
  grp_vars="dummy"
}
#---------------------------------------------------------------------------
week_of_month=function(aDate){
 
  a=as.POSIXlt(aDate)$year + 1900 # gets year out of date
  b=as.character(substr(aDate,6,7))
  c=as.Date(paste(b,"/","01/",a,sep=""),format="%m/%d/%Y")# first date of month gets created
  lag=with( month.day.year(c), day.of.week(month,day,year) )
  w=as.integer((as.numeric(aDate) - as.numeric(c) + (lag-1))/7)+1 # equation for week no.
  w<-apply(as.data.frame(w),1,function(x){paste("Week0",x,sep="")})
  return(w)
}

week_of_year=function(tempdate)
{ 
  result<-dataworking[,date_vars]
  result1<- strftime(result, "%W")
  result1<-apply(as.data.frame(result1),1,function(x){paste("Week",x,sep="")})
  return(result1)
}
quaterinyear=function(tempdate)
{
  result1=quarters(dataworking[,date_vars])
  return(result1)
}

group_var =c()
group_variable =c()
if(length(rollup_level)){
  dateCols=NULL
  colnam=NULL
  if(rollup_level=="month"){
    col_name<-c("month","qtr","year")
   
    col=strftime(dataworking[,date_vars], format="%B")
    if(plot_select == "qtr"){
      newcol<-as.data.frame(col)
      col<-unlist(apply(newcol,1,function(x){switch(x,"January"="01","February"="02","March"="03","April"="01","May"="02","June"="03","July"="01","August"="02","September"="03","October"="01","November"="02","December"="03","NA"="NA")}))
    }
    dataworking=cbind.data.frame(dataworking,col)
    col=quaterinyear(dataworking[date_vars])
    dataworking=cbind.data.frame(dataworking,col)
    col=format(dataworking[,date_vars],"%Y")
    dataworking=cbind.data.frame(dataworking,col)
    colnames(dataworking)[((ncol(dataworking)-length(col_name))+1):ncol(dataworking)]<-col_name
  }
  if(rollup_level =="day"){
    col_name<-c("day","week","month","qtr","year")

    if(plot_select == "week"){
      col=strftime(dataworking[,date_vars],format="%a")
      col<-apply(as.data.frame(col),1,function(x){switch(x,Mon="02",Tue="03",Wed="04",Thu="05",Fri="06",Sat="07",Sun="01","NA"="NA")})
    }else{
      col= strftime(dataworking[,date_vars], format="%d")
    }
    dataworking=cbind.data.frame(dataworking,col)
    col=week_of_year(dataworking[date_vars])
    dataworking=cbind.data.frame(dataworking,col)
    col=strftime(dataworking[,date_vars], format="%B")
    dataworking=cbind.data.frame(dataworking,col)
    col=quaterinyear(dataworking[date_vars])
    dataworking=cbind.data.frame(dataworking,col)
    col=format(dataworking[,date_vars],"%Y")
    dataworking=cbind.data.frame(dataworking,col)
    colnames(dataworking)[((ncol(dataworking)-length(col_name))+1):ncol(dataworking)]<-col_name
  }
  if(rollup_level=="week"){

    col_name<-c("week","month","year")
    col=week_of_month(dataworking[,date_vars])
    dataworking=cbind.data.frame(dataworking,col)
    col=strftime(dataworking[,date_vars], format="%B")
    dataworking=cbind.data.frame(dataworking,col)
    col=format(dataworking[,date_vars],"%Y")
    dataworking=cbind.data.frame(dataworking,col)
    colnames(dataworking)[((ncol(dataworking)-length(col_name))+1):ncol(dataworking)]<-col_name
  }
  if(rollup_level=="qtr"){
   
    col_name<-c("qtr","year")
    col=quaterinyear(dataworking[date_vars])
    dataworking=cbind.data.frame(dataworking,col)
    col=format(dataworking[,date_vars],"%Y")
    dataworking=cbind.data.frame(dataworking,col)
    colnames(dataworking)[((ncol(dataworking)-length(col_name))+1):ncol(dataworking)]<-col_name
  }
  if(rollup_level=="year"){
    col_name<- c("year")
   
    col=format(dataworking[,date_vars],"%Y")
    dataworking=cbind.data.frame(dataworking,col)
    colnames(dataworking)[((ncol(dataworking)-length(col_name))+1):ncol(dataworking)]<-col_name
  }
}
funcbegin<- function(x){ result<-as.data.frame(x)
                         result<-result[1,]
                         return(result)
}
funcend<- function(x){ result<-as.data.frame(x)
                       result<-result[nrow(result),]
                       return(result)
}
funcmid<- function(x){ result<-as.data.frame(x)
                       rownumber2<- ceiling(nrow(result)/2)
                       result<-result[rownumber2,]
                       return(result)
}
grp_vars_new<- c(grp_vars,col_name)
for(i in 1:length(selected_vars))
{ 
  dataworking<- dataworking[c(order(dataworking[,c(date_vars)]),decreasing=FALSE),]
  switch(rollup_metric,
         average = {result<- aggregate(as.numeric(as.matrix(dataworking[c(selected_vars[i])])),dataworking[c(grp_vars_new)],mean,na.rm=TRUE)
                    colnames(result)[ncol(result)]<- selected_vars[i]},
         total = {result<-aggregate(as.numeric(as.matrix(dataworking[c(selected_vars[i])])),dataworking[c(grp_vars_new)],sum)
                  colnames(result)[ncol(result)]<- selected_vars[i]},
         begin = {result<- aggregate(as.numeric(as.matrix(dataworking[c(selected_vars[i])])),dataworking[c(grp_vars_new)],funcbegin)
                  colnames(result)[ncol(result)]<- selected_vars[i]},
         middle ={result<- aggregate(as.numeric(as.matrix(dataworking[c(selected_vars[i])])),dataworking[c(grp_vars_new)],funcmid)
                  colnames(result)[ncol(result)]<- selected_vars[i]},
         end ={result<- aggregate(as.numeric(as.matrix(dataworking[c(selected_vars[i])])),dataworking[c(grp_vars_new)],funcend)
               colnames(result)[ncol(result)]<- selected_vars[i]})
  uniquelevels<-unique(result[1:length(grp_vars)])
  for(j in 1:nrow(uniquelevels))
  {
    subsetdata<- result
    text1=""
    for(k in 1:length(grp_vars))
    {
      subsetdata<- subset(subsetdata, subsetdata[,k] == uniquelevels[j,k])
      text1<- paste(text1,uniquelevels[j,k],sep="_")
    }
    un<-paste(selected_vars[i],text1,sep="")
    un<-gsub("/","",un, fixed=TRUE)
    un<-gsub(" ","",un,fixed=TRUE)
    un<-gsub(".","",un,fixed=TRUE)
    uniquenames<-rbind(uniquenames,un)
    
    if(plot_metric != '' & plot_select != ''){
      subsetdata<- subsetdata[c(plot_select,plot_across,colnames(subsetdata)[ncol(subsetdata)])]
      switch(plot_metric,
             total = result2 <- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],sum),
             average =result2<- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],mean))
      result2<- result2[c(3,2,1)]
      colnames(result2)[1]<-'varname'
      text1<-gsub("/","",text1, fixed=TRUE)
      text1<-gsub(" ","",text1,fixed=TRUE)
      text1<-gsub(".","",text1,fixed=TRUE)
      write.csv(result2,paste(output_path,selected_vars[i],text1,".csv",sep=""),row.names=FALSE,quote=FALSE)
      if(plot_across == 'qtr')
      {
        year<-unique(dataworking[,"year"])
        uniqueyears<-as.data.frame(as.character(year))
        colnames(uniqueyears)<-"year"
        write.csv(uniqueyears,paste(output_path,"uniqueyears.csv",sep=""),row.names=FALSE,quote=FALSE)
      }
    }
    if(plot_metric == '' & plot_over != ''){
      plot_metric1 <- 'average'
      subsetdata<- subsetdata[c(plot_select,plot_across,plot_over,colnames(subsetdata)[ncol(subsetdata)])]
      switch(plot_metric1,
             total = result2 <- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],sum),
             average =result2<- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],mean))
      result2<- result2[c(4,2,1,3)]
      colnames(result2)[1]<-'varname'
      uniqueyear <- unique(result2$year)
      for(p in 1:length(uniqueyear))
      {
        result3<- subset(result2,result2$year == uniqueyear[p])
        text2<- paste(text1,"_",uniqueyear[p],sep="")
        text2<-gsub("/","",text2, fixed=TRUE)
        text2<-gsub(" ","",text2,fixed=TRUE)
        text2<-gsub(".","",text2,fixed=TRUE)
        write.csv(result3,paste(output_path,selected_vars[i],text2,".csv",sep=""),row.names=FALSE,quote=FALSE)
      }
      uniqueyear1<-as.data.frame(unique(result$year))
      colnames(uniqueyear1)<-"year"
      write.csv(uniqueyear1,paste(output_path,"uniqueyears.csv",sep=""),row.names=FALSE,quote=FALSE)
    }
    if(plot_metric == '' & plot_over == '')
    {
      plot_metric1 <- 'average'
      subsetdata<- subsetdata[c(plot_select,plot_across,colnames(subsetdata)[ncol(subsetdata)])]
      switch(plot_metric1,
             total = result2 <- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],sum),
             average =result2<- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],mean))
      result2<- result2[c(3,2,1)]
      colnames(result2)[1]<-'varname'
      text1<-gsub("/","",text1, fixed=TRUE)
      text1<-gsub(" ","",text1,fixed=TRUE)
      text1<-gsub(".","",text1,fixed=TRUE)
      uniqueyear1<-as.data.frame(unique(result$year))
      colnames(uniqueyear1)<-"year"
      write.csv(uniqueyear1,paste(output_path,"uniqueyears.csv",sep=""),row.names=FALSE,quote=FALSE)
      write.csv(result2,paste(output_path,selected_vars[i],text1,".csv",sep=""),row.names=FALSE,quote=FALSE)
    }
    if(plot_select == ''){
      subsetdata<- subsetdata[c(plot_across,colnames(subsetdata)[ncol(subsetdata)])]
      switch(plot_metric,
             total = result2 <- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],sum),
             average =result2<- aggregate(subsetdata[ncol(subsetdata)],subsetdata[-ncol(subsetdata)],mean))
      result2<- result2[c(2,1)]
      colnames(result2)[1]<-'varname'
      text1<-gsub("/","",text1, fixed=TRUE)
      text1<-gsub(" ","",text1,fixed=TRUE)
      text1<-gsub(".","",text1,fixed=TRUE)
      write.csv(result2,paste(output_path,selected_vars[i],text1,".csv",sep=""),row.names=FALSE,quote=FALSE)
    }
    colnames(uniquenames)<-"names"
    write.csv(uniquenames,paste(output_path,"uniquenames.csv",sep=""),row.names=FALSE,quote=FALSE)
  }
}

write.table("TIME SERIES SPLIT",paste(output_path,"TIMESERIES_SPLIT_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)
