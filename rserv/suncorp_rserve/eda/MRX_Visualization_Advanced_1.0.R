# Parameters Required
#------------------------------------------------------------------------------
#input_path   <- "D:/"
#grp_vars     <- c('channel_1', 'channel_2', 'channel_3')
#stacked_vars <- 'Store_Format'
#xaxis_vars   <- c("channel_3","channel_4","channel_5")
#yaxis_vars   <- c("sales","ACV")
#metric       <- c("AVG","COUNT","MAX","RANGE","STD","SUM","VAR")




#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()

for (c.tempi in a.all) {
  
  if (!length(grep(pattern="^(c|n|b|l|x)_", x=c.tempi))) next
  
  x_tempi <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi)) next
  if (x_tempi != "") next
  
  assign(x=c.tempi, value=NULL)
  print(c.tempi)
  
}
#------------------------------------------------------------------------------- 
  
if(chart_type=="ac"){
  grpby1_vars <- grp_vars
  grpby2_vars <- stacked_vars
  varlist_use <- c(grpby1_vars,grpby2_vars)
}

if(chart_type=="pc"){
  xaxis_vars  <- colored_vars
  yaxis_vars  <- analysis_var
  grpby1_vars <- grp_vars
  grpby2_vars <- NULL
  varlist_use <- c(xaxis_vars,yaxis_vars,grpby1_vars,grpby2_vars)
}

if(chart_type=="bc"){
  xaxis_vars  <- x_axis_var
  yaxis_vars  <- c(y_axis_var,size_by_var)
  metric      <- c(y_axis_metric,size_by_metric)
  grpby1_vars <- grp_vars
  grpby2_vars <- NULL
  varlist_use <- c(xaxis_vars,yaxis_vars,grpby1_vars,grpby2_vars)
}
# xaxis_vars <- unique(xaxis_vars)
# yaxis_vars <- unique(yaxis_vars)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Libraries Required
#------------------------------------------------------------------------------
library(data.table)
library(Hmisc)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Loading the data
#------------------------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))

if (length(c_path_filter_param)) {
  source(file=c_path_filter_param)
  source(file=c_path_filter_code)
  
  if (length(c_text_filter_dc)) {
    if (c_text_filter_dc == "") c_text_filter_dc <- NULL
  }
  if (length(c_text_filter_vs)) {
    if (c_text_filter_vs == "") c_text_filter_vs <- NULL
  }
  if (length(c_text_sort)) {
    if (c_text_sort == "") c_text_sort <- NULL
  }
  if (length(c_var_date_sort_filter)) {
    if (c_var_date_sort_filter == "") c_var_date_sort_filter <- NULL
  }
  
  c_var_required               <- varlist_use
  dataworking                  <- muRx_filter_sort(df_x=dataworking,
                                                   c_text_filter_dc,
                                                   c_text_filter_vs,
                                                   c_text_sort,
                                                   c_var_date_sort_filter,
                                                   c_var_required)
}

select      <- unique(c(xaxis_vars,yaxis_vars,grpby1_vars,grpby2_vars))
select      <- select[which(select!="")]
dataworking <- subset(x=dataworking,select=select)
# Sorting the dataset by the xaxis_vars
text  <- NULL
comma <- NULL
for(tempi in 1:length(xaxis_vars)){
  text <- paste(text,comma,"dataworking[,xaxis_vars[",tempi,"]]",sep="")
  comma <- ","
}
text <- paste("dataworking <- as.data.frame(dataworking[order(",text,"), ])",sep="")
eval(parse(text=text))
colnames(dataworking) <- select
# Making a data.table out of the dataset
# datasort<-as.data.frame(apply(dataworking[xaxis_vars],2,function(x){as.numeric(as.character(x))}))
# ordertext<-eval(parse(text=paste("order(",paste(paste("datasort[,'",xaxis_vars,"']",sep=""),collapse=","),")",sep="")))
# dataworking<-dataworking[ordertext,]
dataworking[, unique(yaxis_vars)] <- apply(X=as.data.frame(dataworking[, unique(yaxis_vars)]), MARGIN=2, FUN=as.numeric)
datatable   <- data.table(dataworking)
rm("dataworking")

#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Pre error check
#------------------------------------------------------------------------------
j      <- paste(rep("all(is.na(",times=length(yaxis_vars)),yaxis_vars,rep("))",times=length(yaxis_vars)),sep="")
j      <- c(j,paste(rep("length(which(is.na(",times=length(yaxis_vars)),yaxis_vars,rep(")))",times=length(yaxis_vars)),sep=""))
j      <- c(j,paste(rep("length(",times=length(yaxis_vars)),yaxis_vars,rep(")",times=length(yaxis_vars)),sep=""))
listj  <- paste("list(",paste(j,collapse=","),")",sep="")
by     <- unique(c(grpby1_vars,grpby2_vars,xaxis_vars))
by     <- by[by!=""]
listby <- paste("by=list(",paste(by,collapse=","),")",sep="")
text   <- paste("datatable[,",listj,",",listby,"]",sep="")
output <- data.table(eval(parse(text=text)))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Error check
#------------------------------------------------------------------------------
na_vars <- paste(rep("V",times=length(yaxis_vars)),1:length(yaxis_vars),sep="")
text    <- paste("all(!(output[,c(",paste(na_vars,collapse=","),")]))",sep="")
value   <- eval(parse(text=text))

try(if(value==F){
  stop("!!ERROR!! NA values")
}, silent = TRUE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Parameter Play
#------------------------------------------------------------------------------
#metric       <- c("AVG","COUNT","MAX","RANGE","STD","SUM","VAR")
metric_start <- metric
metric_start <- gsub(pattern="AVG",replacement="mean(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="COUNT",replacement="length(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="MAX",replacement="max(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="RANGE",replacement="diff(range(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="STD",replacement="sd(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="SUM",replacement="sum(",x=metric_start,fixed=T)
metric_start <- gsub(pattern="VAR",replacement="var(",x=metric_start,fixed=T)
metric_stop  <- rep(",na.rm=T)",times=length(metric))
index        <- which(metric=="RANGE")
metric_stop[index]  <- ",na.rm=T))"
index         <- which(metric=="COUNT")
metric_stop[index]  <- ")"
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# If there is no metric
#------------------------------------------------------------------------------
if (is.null(metric)) {
  xaxis_flag <- NULL
  sep <- ""
  for(tempi in 1:length(xaxis_vars)){
    xaxis_flag <- paste(xaxis_flag, eval(parse(text=paste("datatable$",xaxis_vars[tempi],sep=""))), sep=sep)
  }
  output <- data.frame(xaxis_flag = xaxis_flag,
                       value1     = eval(parse(text=paste("datatable$",yaxis_vars,sep=""))))
  colnames(output) <- c("xaxis_flag", "value1")
  if (!is.null(grp_vars)) {
    grp_flag <- NULL
    sep <- ""
    for(tempi in 1:length(grp_vars)){
      grp_flag <- paste(grp_flag, eval(parse(text=paste("datatable$",grp_vars[tempi],sep=""))), sep=sep)
    }
    output <- cbind.data.frame(output, grp_flag = grp_flag)
  }
  if (stacked_vars != "") {
    stacked_flag <- eval(parse(text=paste("datatable$",stacked_vars,sep="")))
    output <- cbind.data.frame(output, stacked_flag = stacked_flag)
  }
  
  if(chart_type=="ac"){
    if(length(grp_vars)){ output$grp_flag[output$grp_flag==""]<-"NA"}
    index_NAN<-is.nan(output$value1)
    index_NA<-is.na(output$xaxis_flag)
    final_index   <-which(index_NA|index_NAN)
    if (length(final_index)!=0){
      output<-output[-final_index,]
    }
    write.csv(output,paste(output_path,"/column_chart.csv",sep=""),row.names=F,quote=F)
    
    xaxis_flag = unique(output$xaxis_flag)
    
    if(all.is.numeric(xaxis_flag)){
      xaxis_flag = sort(x=as.numeric(as.character(xaxis_flag)),decreasing=F)
    }else{
      xaxis_flag = sort(x=(xaxis_flag),decreasing=F)
    }
    
    
  
    write.csv(data.frame(xaxis_flag=xaxis_flag),paste(output_path,"/xaxis_variables.csv",sep=""),row.names=F,quote=F)
    if(!(all(grpby1_vars %in% ""))){
      output$grp_flag[output$grp_flag==""]<-"NA"
      write.csv(data.frame(grp_flag=unique(output$grp_flag)),paste(output_path,"/grp_values_list.csv",sep=""),row.names=F,quote=F)
    }
    if(!(all(grpby2_vars %in% ""))){
      write.csv(data.frame(NAME=unique(output$stacked_flag)),paste(output_path,"/stackedvalues_list.csv",sep=""),row.names=F,quote=F)
    }
  }
  
  warning("no metric. code ends.")
} else {
  #------------------------------------------------------------------------------
  # The necessary stuff / Aggregation
  #------------------------------------------------------------------------------
  if(chart_type=="bc"){
    j1      <- paste(rep(metric_start[1],times=1),rep(yaxis_vars[1],each=1),rep(metric_stop[1],times=1),sep="")
    j2      <- paste(rep(metric_start[2],times=1),rep(yaxis_vars[2],each=1),rep(metric_stop[2],times=1),sep="")
    j <- c(j1,j2)
  }else{
    j      <- paste(metric_start,yaxis_vars,metric_stop,sep="")
  }
  listj  <- paste("list(",paste(j,collapse=","),")",sep="")
  by     <- paste(unique(c(grpby1_vars,grpby2_vars,xaxis_vars)))
  by     <- by[by!=""]
  listby <- paste("by=list(",paste(by,collapse=","),")",sep="")
  text   <- paste("datatable[,",listj,",",listby,"]",sep="")
  
  output <- data.table(eval(parse(text=text)))
  #------------------------------------------------------------------------------
  
  
  
  #------------------------------------------------------------------------------
  # Making the CSV
  #------------------------------------------------------------------------------
  insidelist   <- NULL
  xaxis_flag   <- paste("paste(",paste(xaxis_vars,collapse=","),",sep='_')",sep="")
  xaxis_flag   <- paste("xaxis_flag = ",xaxis_flag,sep="")
  insidelist   <- paste(insidelist,xaxis_flag,sep="")
  
  grp_flag     <- NULL
  if(!(all(grpby1_vars %in% ""))){
    grp_flag     <- paste("paste(",paste(grpby1_vars,collapse=","),",sep='_')",sep="")
    grp_flag     <- paste("grp_flag = ",grp_flag,sep="")
    insidelist   <- paste(insidelist,grp_flag,sep=",")
  }
  
  stacked_flag <- NULL
  if(!(all(grpby2_vars %in% ""))){
    stacked_flag <- paste("stacked_flag = ",grpby2_vars,sep="")
    insidelist   <- paste(insidelist,stacked_flag,sep=",")
  }
  
  if(chart_type=="bc"){
    thenumber <- 2
  }else{
    thenumber    <- length(yaxis_vars)
  }
  valuei       <- paste(rep("value",times=thenumber),1:thenumber,rep("=",times=thenumber),rep("V",times=thenumber),1:thenumber,sep="")
  insidelist   <- paste(insidelist,",",paste(valuei,collapse=","))
  j            <- paste("list(",insidelist,")",sep="")
  text         <- paste("output[,",j,"]",sep="")
  output       <- eval(parse(text=text))
  
  if(!(all(grpby1_vars %in% ""))){
    output       <- output[order(output$grp_flag),]
  }
  
  if(chart_type=="ac"){
    if(length(grp_vars)){ output$grp_flag[output$grp_flag==""]<-"NA" }
    index_NAN<-is.nan(output$value1)
    index_NA<-is.na(output$xaxis_flag)
    final_index   <-which(index_NA|index_NAN)
    if (length(final_index)!=0){
      output<-output[-final_index,]
    }
    
    
    write.csv(output,paste(output_path,"/column_chart.csv",sep=""),row.names=F,quote=F)
    
    xaxis_flag = unique(output$xaxis_flag)
    
    if(all.is.numeric(xaxis_flag)){
      xaxis_flag = sort(x=as.numeric(xaxis_flag),decreasing=F)
    }else{
      xaxis_flag = sort(x=(xaxis_flag),decreasing=F)
    }
    write.csv(data.frame(xaxis_flag=xaxis_flag),paste(output_path,"/xaxis_variables.csv",sep=""),row.names=F,quote=F)
    
    if(!(all(grpby1_vars %in% ""))){
      output$grp_flag[output$grp_flag==""]<-"NA"
      write.csv(output[,list(grp_flag=unique(grp_flag))],paste(output_path,"/grp_values_list.csv",sep=""),row.names=F,quote=F)
    }
    if(!(all(grpby2_vars %in% ""))){
      write.csv(output[,list(NAME=unique(stacked_flag))],paste(output_path,"/stackedvalues_list.csv",sep=""),row.names=F,quote=F)
    }
  }
  
  if(chart_type=="pc"){
    
    setnames(output,c("xaxis_flag","value1"),c("COLORED_FLAG","VALUE"))
    index_NAN<-is.nan(output$VALUE)
    index_NA<-is.na(output$COLORED_FLAG)
    final_index   <-which(index_NA|index_NAN)
    if (length(final_index)!=0){
      output<-output[-final_index,]
    }
    write.csv(format(output[,list(xaxis_flag=unique(COLORED_FLAG))],scientific=FALSE),paste(output_path,"/xaxis_variables.csv",sep=""),row.names=F,quote=F)
    if(!(all(grpby1_vars %in% ""))){
      output$grp_flag[output$grp_flag==""]<-"NA"
      setnames(output,c("grp_flag"),c("GRP_FLAG"))
      write.csv(output[,list(GRP_FLAG=unique(GRP_FLAG))],paste(output_path,"/grp_values_list.csv",sep=""),row.names=F,quote=F)
    }
    if(length(grp_vars))
    { 
      output$GRP_FLAG[output$grp_flag==""]<-"NA" 
    }
    
    write.csv(output,paste(output_path,"/column_chart.csv",sep=""),row.names=F,quote=F)
  }
  
  if(chart_type=="bc"){
    setnames(output,"value2","metric_S")
    if(length(grp_vars)){ output$grp_flag[output$grp_flag==""]<-"NA"} 
    index_NAN_1<-is.nan(output$value1)
    index_NAN_2<-is.nan(output$metric_S)
    index_NA<-is.na(output$xaxis_flag)
    final_index   <-which(index_NA|index_NAN_1|index_NAN_2)
    if (length(final_index)!=0){
      output<-output[-final_index,]
    }
    write.csv(output,paste(output_path,"/column_chart.csv",sep=""),row.names=F,quote=F)
    write.csv(output[,list(xaxis_flag=unique(xaxis_flag))],paste(output_path,"/xaxis_variables.csv",sep=""),row.names=F,quote=F)
    if(!(all(grpby1_vars %in% ""))){
      output$grp_flag[output$grp_flag==""]<-"NA"
      write.csv(output[,list(grp_flag=unique(grp_flag))],paste(output_path,"/grp_values_list.csv",sep=""),row.names=F,quote=F)
    }
  }
  #------------------------------------------------------------------------------
}

#------------------------------------------------------------------------------
# Completed.txt
#------------------------------------------------------------------------------
write("Visualizations Advanced Complete",file=paste(output_path,"/CHART_COMPLETED.txt",sep=""))
#------------------------------------------------------------------------------