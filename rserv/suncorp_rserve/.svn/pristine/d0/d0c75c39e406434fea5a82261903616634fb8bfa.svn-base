
#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Visualization basic - Time Series                                                            --#
#-- Description  :  Contains some functions to enable basic visualization in MRx                     --#
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Saurabh vikash singh                                                             --#                 
#------------------------------------------------------------------------------------------------------#

#Parameters required
#-----------------------------------------------------------------
#input_path="C:/MRx/r/newproject-18-Oct-2012-09-59-06/1"
#output_path<- "D:/"
#dataset_name = c('dataworking')
#timeseries_metrics = c('total','average')
#combined_varlist = c('Total_Selling_Area','ACV')
#grp_no = '0'
#grp_flag = c('1_1_1')
#date_var = c('Date')
#config_date_level = c('day')
#selected_date_level = c('qtr')
#flag_multiplemetric='false'
#split_axis = c('2','1','3','1')
#split_axis_name = c('geography','Store_format','geography|Store_format','Store_format')
#unique_split_axis = c('2','3','1')
#split_axis_sub = c('2_1_1','2_1_1','3_1_1','1_1_1')
#split_axis_sub_name = c('north','supercenter','north|food_drugcombo','supermarket')
#perc_change ='' #/ base
#perc_date = ''


#Libraries required
#-----------------------------------------------------------------
library(Hmisc)
library(XML)



#Reading the dataworking.csv  
#-----------------------------------------------------------------
#dataworking=read.csv(paste(input_path,"/dataworking.csv",sep=""),header=T)
load(paste(input_path,"/dataworking.RData",sep=""))
if(grp_no!=0){
dataworking=eval(parse(text=paste("subset.data.frame(dataworking,grp",grp_no,"_flag=='",grp_flag,"')",sep="")))
}
resultDF= NULL
#---------------------------------------------------------------------------

#-------function for week of month and quater of year------------------------

week_of_month=function(tempdate)
{
tempDate<-tempdate[,1]  

result<-dataworking[,date_var]

result1<- strftime(result, "%W")
result2<- strftime(result , format="%Y")
result3<- paste(result1,"w","-",result2,sep="")
return(result3)
}
quaterinyear=function(tempdate)
{
tempDate<-tempdate[,1]    

result<-dataworking[,date_var]

result1=quarters(dataworking[date_var[i]])
result2<- strftime(result , format="%Y")
result3<- paste(result1,"-",result2,sep="")
return(result3)
}

#-------------------------------------------------------------------------------
group_var =c()
group_variable =c()

if(length(selected_date_level)){
dateCols=NULL
colnam=NULL
for(i in 1:length(selected_date_level)){
  
  if(selected_date_level=="day"){
    col=strftime(dataworking[date_var[i]], format="%d-%m-%Y")
  }  
  if(selected_date_level=="month"){
    col=strftime(dataworking[,date_var[i]],format="%m-%Y")
  }
  if(selected_date_level=="week"){
    col=week_of_month(dataworking[date_var[i]])
  }
  if(selected_date_level=="qtr"){
    col=quaterinyear(dataworking[date_var[i]])
  }
  if(selected_date_level=="year"){
    col=format(dataworking[date_var[i]],"%Y")
  }
  colnam=c(colnam=paste(date_var[i],"_",sep=""))
  dateCols=cbind(dateCols,col)
}
group_variable=c(group_variable,colnam)
dataworking=cbind.data.frame(dataworking,factor(dateCols))
colnames(dataworking)[((ncol(dataworking)-length(selected_date_level))+1):ncol(dataworking)]<-colnam
}
funcbegin<- function(x){ rownumber= which(x== dataworking1[c(cont_var[l])])
                         datenew<- dataworking1[c(rownumber),]
                         result= datenew[1,c(cont_var[l])]
                         return(result)
}
funcend<- function(x){ rownumber= which(x== dataworking1[c(cont_var[l])])
                         datenew<- dataworking1[c(rownumber),]
                         result= datenew[c(nrow(datenew)),c(cont_var[l])]
                         return(result)
}
funcmid<- function(x){ rownumber= which(x== dataworking1[c(cont_var[l])])
                       datenew<- dataworking1[c(rownumber),]
                       rownumber2<- round(nrow(datenew))
                       result= datenew[c(rownumber2),c(cont_var[l])]
                       return(result)
}
resultfunc <- function(result1){result1$variables <- paste(tm_metrics[l],"(",cont_var[l],")",sep="")
                                result1$metrics<- tm_metrics[l]
                                result1$group <- ''
                                for(h in 1:nrow(result1)){
                                  index1<- which(split_axis_sub %in% result1[h,1])
                                  result1[h,'group']<-  split_axis_sub_name[index1]
                                }
                                result1<- result1[c(3:6,2)]
                                colnames(result1)[1]<- 'value'
                                colnames(result1)[5]<- date_var[i]
                                new<-t(as.data.frame(strsplit(as.character(result1[,5]),"-",fixed=TRUE)))  
                                result2<-cbind(result1,new,row.names=NULL) 
                                if(selected_date_level != 'year')
                                {
                                result3<-result2[c(order(result2["2"],result2["1"])),] 
                                }else{
                                result3<-result2[c(order(result2["new"])),]  
                                }
                                result3<-result3[1:5]
                                rm(result2)
                                unilevel<-unique(result3$group)
                                resultfi<-NULL
                                for(ab in 1:length(unique(result3$group)))
                                {
                                  result1<-result3[c(which(result3$group == unilevel[ab])),]
                                  result1$runningtotal<-NA
                                  result1$twoperiodmoving<-NA
                                  result1$trendline<-NA
                                  if(nrow(result1) > 1){
                                  result1[1,"runningtotal"]<-result1[1,1]
                                  for(p in 2:(nrow(result1))){
                                    result1[p,"runningtotal"]<-result1[(p-1),"runningtotal"]+result1[p,1]
                                  }
                                  result1$twoperiodmoving<-""
                                  for(p in 2:(nrow(result1))){
                                    result1[p,"twoperiodmoving"]<-round(((result1[p,1]+result1[(p-1),1])/2), digits=2)
                                  }
                                  result1$countcol<-c(1:nrow(result1))
                                  yl<-sum(result1[c(1:round(nrow(result1)/2)),"value"])/round(nrow(result1)/2)
                                  tl<-sum(result1[c(1:round(nrow(result1)/2)),"countcol"])/round(nrow(result1)/2)
                                  yu<-sum(result1[c((round(nrow(result1)/2)+1):nrow(result1)),"value"])/round(nrow(result1)/2)
                                  tu<-sum(result1[c((round(nrow(result1)/2)+1):nrow(result1)),"countcol"])/round(nrow(result1)/2)
                                  m<-(yu-yl)/(tu-tl)
                                  b<-yl-m*tl
                                  result1$trendline<-m*(result1$countcol) + b
                                  result1<-result1[,-c(which(colnames(result1) == "countcol"))]
                                  }
                                  resultfi<-rbind(resultfi,result1)
                                }  
                                index<-which(resultfi$twoperiodmoving == "")
                                resultfi[c(index),"twoperiodmoving"]<-NA
                                return(resultfi)
                                
}
resultfunc1 <- function(result1){result1$variables <- paste(tm_metrics[l],"(",cont_var[l],")",sep="")
                                result1$metrics<- tm_metrics[l]
                                result1$group <- ''
                                for(h in 1:nrow(result1)){
                                  index1<- which(split_axis_sub %in% result1[h,1])
                                  if(result1[h,'group'] != ''){
                                  result1[h,'group']<-  split_axis_sub_name[index1]
                                }
                                }
                                result1<- result1[c(2:5,1)]
                                colnames(result1)[1]<- 'value'
                                colnames(result1)[5]<- date_var[i]
                                new<-t(as.data.frame(strsplit(as.character(result1[,5]),"-",fixed=TRUE)))  
                                result2<-cbind(result1,new) 
                                 if(selected_date_level != 'year')
                                 {
                                   result3<-result2[c(order(result2["2"],result2["1"])),] 
                                 }else{
                                   result3<-result2[c(order(result2["new"])),]  
                                 }
                                 result3<-result3[1:5]
                                 unilevel<-unique(result3$group)
                                 resultfi<-NULL
                                 for(ab in 1:length(unilevel))
                                 {
                                   result1<-result1<-result3[c(which(result3$group == unilevel[ab])),]
                                   if(nrow(result1)>1){
                                   result1[1,"runningtotal"]<-result1[1,1]
                                   for(p in 2:(nrow(result1))){
                                     result1[p,"runningtotal"]<-result1[(p-1),"runningtotal"]+result1[p,1]
                                   }
                                   result1$twoperiodmoving<-""
                                   for(p in 2:(nrow(result1))){
                                     result1[p,"twoperiodmoving"]<-(result1[p,1]+result1[(p-1),1])/2
                                   }
                                   }
                                   result1$countcol<-c(1:nrow(result1))
                                   yl<-sum(result1[c(1:round(nrow(result1)/2)),"value"])/round(nrow(result1)/2)
                                   tl<-sum(result1[c(1:round(nrow(result1)/2)),"countcol"])/round(nrow(result1)/2)
                                   yu<-sum(result1[c((round(nrow(result1)/2)+1):nrow(result1)),"value"])/round(nrow(result1)/2)
                                   tu<-sum(result1[c((round(nrow(result1)/2)+1):nrow(result1)),"countcol"])/round(nrow(result1)/2)
                                   m<-(yu-yl)/(tu-tl)
                                   b<-yl-m*tl
                                   result1$trendline<-m*(result1$countcol) + b
                                   result1<-result1[,-c(which(colnames(result1) == "countcol"))]
                                   resultfi<-rbind(resultfi,result1)
                                 }   
                                index<-which(resultfi$twoperiodmoving == "")
                                resultfi[c(index),"twoperiodmoving"]<-NA 
                                return(resultfi)
}
funcperchange<- function(result){
                                if(perc_change == ''){}
                                if(is.null(perc_change)) {}
                                if(perc_change == 'base'){
                                  row_no<- which(dataworking1[c(date_var[i])] == perc_date) 
                                  basevalue<- dataworking1[c(row_no),c(colnam[i])]
                                  row_noresult<- which(result[,5]== basevalue)
                                  result$percchange = 0
                                  result$percchange= ((result[,1]-result[row_noresult,1])/result[row_noresult,1])*100
                                }
                                if(perc_change == 'relative'){
                                  result$percchange = 0
                                  if(nrow(result) > 1){
                                  for( h in 2:nrow(result)){
                                  result[h,"percchange"] = ((result[h,1]-result[(h-1),1])/result[(h-1),1])*100
                                }
                                }
                                }
                                return(result)
}
resultDF=NULL
split_grp_no<- split_axis
split_grp_flag<- split_axis_sub
uniquesplit<- unique(split_axis)
splitaxisname<- split_axis_name
splitaxissubname<- split_axis_sub_name
for(i in 1:length(date_var))
{
  if(flag_multiplemetric == 'false' & !is.null(split_axis)){
    for(n in 1: length(uniquesplit))
  {
  index= which(uniquesplit[n] == split_grp_no)
  split_axis= rep(uniquesplit[n], length(index))
  split_axis_sub= split_grp_flag[c(index)]
  split_axis_name= splitaxisname[c(index)]
  split_axis_sub_name =splitaxissubname[c(index)]
  if(length(split_axis) == 1){
    dataworking1=eval(parse(text=paste("subset.data.frame(dataworking,grp",split_axis,"_flag=='",split_axis_sub,"')",sep="")))
  }else{
  text=paste("subset.data.frame(dataworking,(",sep="")
  textfinal=""
  for(k in 1: length(split_axis))
    {
    if(k != length(split_axis)){
      text1=paste("grp",split_axis[k],"_flag =='",split_axis_sub[k],"') | (",sep="")
    }
    if(k== length(split_axis)){
      text1= paste("grp",split_axis[k],"_flag =='",split_axis_sub[k],"'))",sep="")  
    }
    textfinal=paste(textfinal,text1,sep="")
    }
  textfinal=paste(text,textfinal,sep="")
  dataworking1=eval(parse(text=textfinal))
  }
  group_var=c(paste("grp",uniquesplit[n],"_flag",sep=""),group_variable[i])
  dataworking1<- dataworking1[c(order(dataworking1[,c(date_var[i])]),decreasing=FALSE),]
  for(j in 1:length(combined_varlist))
    {
    cont_var<-unlist(strsplit(combined_varlist[j],"|",fixed=TRUE))
    tm_metrics<- unlist(strsplit(timeseries_metrics[j],"|",fixed=TRUE))
    for(l in 1:length(cont_var))
      {
      switch(tm_metrics[l],
           average = {result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],mean,na.rm=TRUE)
                      result<- resultfunc(result)
                      result<-funcperchange(result)
                      resultDF<- rbind(resultDF,as.matrix(result))},
           total = {result<-aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],sum)
                    result<- resultfunc(result)
                    result<- funcperchange(result)
                    resultDF<- rbind(resultDF,as.matrix(result))},
           beginning ={result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcbegin)
                       result<- resultfunc(result)
                       result<- funcperchange(result)
                       resultDF<- rbind(resultDF,as.matrix(result))},
           middle={result<-aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcmid)
                    result<- resultfunc(result)
                    result<- funcperchange(result)
                    resultDF<- rbind(resultDF,as.matrix(result))},
           end ={result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcend)
                 result<- resultfunc(result)
                 result<- funcperchange(result)
                 resultDF<- rbind(resultDF,as.matrix(result))})
      }
    }
  }
  write.csv(resultDF,paste(output_path,"/","timeseries_viewer_",date_var[i],".csv",sep=""),row.names=FALSE,quote=FALSE)  
  }
  if(flag_multiplemetric == 'true' | is.null(split_axis))
  {
  dataworking1<- dataworking[c(order(dataworking[,c(date_var[i])]),decreasing=FALSE),]
  group_var<- group_variable[i]
  for(j in 1:length(combined_varlist))
    {
    cont_var<-unlist(strsplit(combined_varlist[j],"|",fixed=TRUE))
    tm_metrics<- unlist(strsplit(timeseries_metrics[j],"|",fixed=TRUE))
    for(l in 1:length(cont_var))
      {
      switch(tm_metrics[l],
             average = {result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],mean,na.rm=TRUE)
                        result<- resultfunc1(result)
                        result<- funcperchange(result)
                        resultDF<- rbind(resultDF,as.matrix(result))},
             total = {result<-aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],sum)
                      result<- resultfunc1(result)
                      result<- funcperchange(result)
                      resultDF<- rbind(resultDF,as.matrix(result))},
             beginning ={result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcbegin)
                         result<- resultfunc1(result)
                         result<- funcperchange(result)
                         resultDF<- rbind(resultDF,as.matrix(result))},
             middle ={result<-aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcmid)
                      result<- resultfunc1(result)
                      result<- funcperchange(result)
                      resultDF<- rbind(resultDF,as.matrix(result))},
             end ={result<- aggregate(dataworking1[c(cont_var[l])],dataworking1[c(group_var)],funcend)
                   result<- resultfunc1(result)
                   result<- funcperchange(result)
                   resultDF<- rbind(resultDF,as.matrix(result))})
      } 
    }
    resultDF<-resultDF[!duplicated(resultDF),]
    write.csv(resultDF,paste(output_path,"/","timeseries_viewer_",date_var[i],".csv",sep=""),row.names=FALSE,quote=FALSE)
    }
    }

write("TIMESERIES- TIMESERIES_VIEWER_COMPLETED", file = paste(output_path, "TIMESERIES_VIEWER_COMPLETED.txt", sep="/"))