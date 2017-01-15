#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_BivariateAnalysis_1.0                                                        --#
#-- Description :-
#--   1.All the Continuous variables are binned using binner method defined below
#--   2.The Scriptis divided into five parts :-
#--     1. Function defination(s)
#--     2. Data loading
#--     3. When dependent variable is binary 
#--     4. When dependent variable is categorical
#--     5. When dependent variable is continuous
#-- Return type  :  Creates CSV's at a location according to given inputs                            --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#



#-------------------
#Parameters required
#-------------------
# flag_dep_bivariate=false;
# event=0;
# input_path=C:\MRx\lineardemo-13-Sep-2012-16-27-25\1;
# output_path=C:\MRx\lineardemo-13-Sep-2012-16-27-25\BivariateAnalysis\rep1;
# dependent_variable=channel_1;
# vars_cont=ACV;
# vars_cat=;
# groups=10;
# flag_categorical=true;
# type_group=percentile;
# grp_flag="1_1_1";
# grp_no=0;

if (file.exists(paste(output_path,"/error.txt",sep=""))){
  file.remove(paste(output_path,"/error.txt",sep=""))
}

#-------------------
#Libraries required
#-------------------
library(data.table)
library(Hmisc)


#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()
allvars<-c()
for (c.tempi in a.all) {
  
  x_tempi <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi) | x_tempi != "") next
  
  assign(x=c.tempi, value=NULL)
  print(c.tempi)
  
}

#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Function to create the binned variable
#-------------------------------------------------------------------------------
untitled <- function(x,
                     c.type.bin,  # datasetorder, percentile, equalrange, custom
                     n.bins=NULL,
                     n.cutpoints=NULL,
                     l.namethebins=F){
  original_length<- length(x)
  if (c.type.bin == "percentile" | c.type.bin == "datasetorder") {
    #     n.obs.in.bin <- diff(floor(seq(from=0, to=length(x), by=length(x) / n.bins)))
    #     n.newvar     <- rep(x=1:n.bins, times=n.obs.in.bin)
    #     if (c.type.bin == "percentile") {
    #       key      <- 1:length(x)
    #       key      <- key[order(x)]  
    #       n.newvar <- n.newvar[order(key)]
    #     }
    n.newvar<-as.numeric(cut2(x,g=n.bins))
  }
  if (c.type.bin == "equalrange" | c.type.bin == "custom") {
    if (c.type.bin == "equalrange") {
      if (min(x, na.rm = TRUE) == max(x, na.rm = TRUE)) {
        n.cutpoints <- rep(min(x, na.rm = TRUE), times=2)
        n.bins = 1
      } else {
        n.cutpoints <- seq(from=min(x, na.rm = TRUE), to=max(x, na.rm = TRUE),
                           by=(max(x, na.rm = TRUE) - min(x, na.rm = TRUE)) / n.bins)
      }
    }
    n.newvar <- rep(x=NA, times=length(x))
    for (tempi in 1:n.bins) {
      index <- which(x >= n.cutpoints[tempi] & x < n.cutpoints[tempi + 1])
      if (tempi == n.bins) {
        index <- c(index, which(x == n.cutpoints[tempi + 1]))
      }
      if (length(index)) {
        n.newvar[index] <- tempi
      }
    }
  }
  
  if (l.namethebins) {
    if (c.type.bin == "percentile" | c.type.bin == "datasetorder") {
      c.b4bin <- "bin "
      c.a4bin <- ""
      c.b4min <- " (min : "
      c.a4min <- ";"
      c.b4max <- " max : "
      c.a4max <- ")"
      sep     <- ""
    } else {
      c.b4bin <- "bin "
      c.a4bin <- ""
      c.b4min <- " ["
      c.a4min <- ";"
      c.b4max <- " "
      c.a4max <- ")"
      sep     <- ""
    }
    
    if (c.type.bin == "equalrange") {
      n.min       <- n.cutpoints[1:n.bins]
      n.min       <- data.frame(Group.1=1:n.bins, x=n.min)
      n.max       <- n.cutpoints[2:(n.bins + 1)]
      n.max       <- data.frame(Group.1=1:n.bins, x=n.max)
    } else {
      n.min       <- aggregate(x=x, by=list(n.newvar), FUN=min, na.rm=TRUE)
      n.max       <- aggregate(x=x, by=list(n.newvar), FUN=max, na.rm=TRUE)
    }
    c.bin.names  <- paste(c.b4bin, sprintf("%02d", n.min$Group.1), c.a4bin, c.b4min, n.min$x, c.a4min, c.b4max, n.max$x, c.a4max, sep=sep)
    c.newvar     <- rep(x=NA, times=length(x))
    for (tempi in unique(n.newvar)) {
      if(is.na(tempi)) next
      index           <- which(n.newvar == tempi)
      c.newvar[index] <- c.bin.names[tempi]
    }
    if (c.type.bin == "equalrange" | c.type.bin == "custom") {
      index <- which(n.newvar == n.bins)
      c.newvar[index] <- gsub(pattern="\\)", replacement="]", x=c.newvar[index])
    }

    return(c.newvar)
  } else {
    return(n.newvar)
  }
}
#-------------------------------------------------------------------------------



#-----------------------------------------------------------------
#PART 2 : Loading the Data  
#-----------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))

if(grp_no!=0){
  dataworking=eval(parse(text=paste("subset.data.frame(dataworking, grp",grp_no,"_flag=='",grp_flag,"')",sep="")))
}

error_var_final <- NULL
vars_check <- c(vars_cat,vars_cont,dependent_variable)
n_obs_dataworking <- nrow(dataworking)

for (i in 1:length(vars_check)) {
  n_index <- dataworking[, vars_check[i]] == ""
  x_temp  <- is.na(dataworking[,vars_check[i]])
  n_index <- which(n_index | x_temp)
  n_invalid_obs <- length(n_index)
  
  if (n_invalid_obs == n_obs_dataworking) {
    error_var_final <- c(error_var_final, vars_check[i])
  }
}
  
if (length(error_var_final)){
  error_text <- paste("The variable(s) ", 
                      paste(error_var_final,
                            collapse= ", "),
                      " have all values missing. Please deselect them.",
                      sep="")
  write(error_text, paste(output_path,"/error.txt",sep=""))
  stop(error_text)
}

# Binning the continuous variables (if any)
if (length(vars_cont)) {
  c.type.bin <- type_group
  n.bins <- as.numeric(groups)
  temp.var.continuous <- vars_cont
  if(c.type.bin == "equal range") c.type.bin = "equalrange"
  
  
  for (tempi in 1:length(temp.var.continuous)) {
    temp.newvar.name <- paste('bin', temp.var.continuous[tempi], sep="_")
    dataworking[, temp.newvar.name] <- untitled(x=dataworking[, temp.var.continuous[tempi]],
                                                c.type.bin=c.type.bin,
                                                n.bins=n.bins,
                                                l.namethebins=TRUE)
  }
}

datatable <- data.table(dataworking)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#PART 3 : When dependent variable is binary
#-------------------------------------------------------------------------------
if(as.logical(flag_dep_bivariate)){ 
  if(length(vars_cat)){
    for(i in 1:length(vars_cat)){
      
      count.text <-paste('class_num_obs = length(',dependent_variable,')',sep="")
      data.result.text <- paste('datatable[,list(',count.text,'),by=',vars_cat[i],']',sep="")
      data.result <- as.data.frame(eval(parse(text=data.result.text)))
      data.result["class_per_obs"] <- (data.result$class_num_obs/sum(data.result$class_num_obs ))*100
      
      
      event.count.text<-paste('datatable[',dependent_variable,'==',"'",event,"'",',list(count=length(',dependent_variable,')),by=',vars_cat[i],']',sep="")
      event.count <- as.data.frame(eval(parse(text=event.count.text)))
      
      colnames(event.count)            <- c(colnames(event.count)[1],
                                            "num_event_class")
      data.result                      <- merge(x=data.result,
                                                y=event.count,
                                                by=vars_cat[i],
                                                all.x=TRUE)
      n_index                          <- which(is.na(data.result$num_event_class))
      if (length(n_index)) {
        0                              -> data.result$num_event_class[n_index]
      }
      
      data.result["num_nonevent_class"] <- data.result$class_num_obs - data.result$num_event_class
      
      data.result["class_noneventpercentage"] <- (data.result$num_nonevent_class/data.result$class_num_obs) * 100
      
      data.result["class_eventpercentage"] <- (data.result$num_event_class/data.result$class_num_obs) * 100
      
      data.result["global_eventpercentage"]=(data.result$num_event_class/sum(data.result$num_event_class))*100
      
      data.result["mean_eventpercentage"]=(sum(data.result$num_event_class)/nrow(datatable))*100
      
      data.result["plotvar"]=log(data.result$num_event_class/data.result$num_nonevent_class)
      
      colnames(data.result)[1] <- "level"
      data.result$level<-as.character(data.result$level)
      # data.result$level <- gsub(" ","",data.result$level)
      write.csv(data.result, paste(output_path,"/","Categorical","/",vars_cat[i],".csv",sep=""),row.names = FALSE,quote=F)
      allvars<-c(allvars,vars_cat[i])
    }
  }
  if(length(vars_cont)){
    for(i in 1:length(vars_cont)){
      
      #Error Check: NA will be omitted if only one exists
      #if(length(which(is.na(datatable[[paste('bin_',vars_cont[i],sep='')]])==TRUE))==1){datatable <- na.omit(datatable[,paste('bin_',vars_cont[i],sep=''),with=FALSE])}
      
      mean.text <- paste('mean_value = as.numeric(mean(',vars_cont[i],', na.rm=TRUE',' )),',sep="")
      min.text <-paste('min_value = as.numeric(min(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      max.text <- paste('max_value = as.numeric(max(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      count.text <-paste('class_num_obs = length(',vars_cont[i],'),',sep="")
      std.text <- paste('stddev = as.numeric(sd(',vars_cont[i],', na.rm=TRUE','))',sep="")
      
      
      data.result.text <- paste('datatable[,list(',mean.text,min.text,max.text, count.text,std.text,'),by=bin_',vars_cont[i],']',sep="")
      data.result <- as.data.frame(eval(parse(text=data.result.text)))
      data.result["class_per_obs"] <- (data.result$class_num_obs/sum(data.result$class_num_obs ))*100
      
      event.count.text<-paste('datatable[',dependent_variable,'==',"'",event,"'",',list(count=length(',dependent_variable,')),by=bin_',vars_cont[i],']',sep="")
      event.count <- as.data.frame(eval(parse(text=event.count.text)))
      
      colnames(event.count)            <- c(colnames(event.count)[1],
                                            "num_event_class")
      data.result                      <- merge(x=data.result,
                                                y=event.count,
                                                by=paste("bin_", vars_cont[i], sep=""),
                                                all.x=TRUE)
      n_index                          <- which(is.na(data.result$num_event_class))
      if (length(n_index)) {
        0                              -> data.result$num_event_class[n_index]
      }
      
      data.result["range"] <- data.result$max_value - data.result$min_value
      
      data.result["num_nonevent_class"] <- data.result$class_num_obs - data.result$num_event_class
      
      data.result["class_noneventpercentage"] <- (data.result$num_nonevent_class/data.result$class_num_obs) * 100
      
      data.result["class_eventpercentage"] <- (data.result$num_event_class/data.result$class_num_obs) * 100
      
      data.result["global_eventpercentage"]=(data.result$num_event_class/sum(data.result$num_event_class))*100
      
      data.result["mean_eventpercentage"]=(sum(data.result$num_event_class)/nrow(datatable))*100
      
      data.result["plotvar"]=log(data.result$num_event_class/data.result$num_nonevent_class)
      
      colnames(data.result)[1] <- "level"
      
      data.result<- data.result[order(data.result$level),]
      
      write.csv(data.result, paste(output_path,"/","Continuous","/",vars_cont[i],".csv",sep=""),row.names = FALSE,quote=F)
      allvars<-c(allvars,paste("bin_",vars_cont[i],sep=""))
    }
  }
  #-------------------------------------------------------------
  #PART 4 : When dependent variable is Categorical
  #-------------------------------------------------------------
  
}else if(as.logical(flag_categorical)){ #If dependent variable is Categorical
  
  if(length(vars_cat)){
    for(i in 1:length(vars_cat)){
      count.text <-paste('class_num_obs = length(',dependent_variable,')',sep="")
      data.result.text <- paste('datatable[,list(', count.text,'),by=',vars_cat[i],']',sep="")
      data.result <- as.data.frame(eval(parse(text=data.result.text)))
      data.result <- as.data.frame(data.result[order(data.result[,1]),])
      
      second.result <- as.data.frame.matrix(table(datatable[[vars_cat[i]]], datatable[[dependent_variable]],useNA='ifany'))
      
      colnames(second.result) <- paste("_", colnames(second.result), sep="")
      
      tab <- second.result
      #colnames(second.result)<-paste('No_',colnames(second.result),sep='')
      levels <- sort(unique(datatable[[dependent_variable]]), na.last = TRUE)
      
      second.result[paste('Perc',levels,sep='_')]<- apply(X=as.matrix(second.result),2,FUN=function(X,Y){(X/Y)*100},Y=data.result$class_num_obs)
      
      
      times <- nrow(data.result)
      
      global<-apply(as.data.frame.matrix(table(rep(1,length(datatable[[dependent_variable]])),datatable[[dependent_variable]], useNA='ifany')),2,rep,times=times)
      
      second.result[paste('Global',levels,sep='_')]<- global
      
      #second.result[paste('Global',levels,'Perc',sep='_')]<-t(apply(X=as.matrix(tab),1,FUN=function(X,Y){(X/Y)*100},Y=as.numeric(global[1,])))
      
      row.names(second.result)<-NULL
      data.result <- cbind.data.frame(data.result,second.result )
      colnames(data.result)[1]<-'level'
      colnames(data.result) <- gsub(pattern=' ', '_', colnames(data.result),fixed=TRUE)
      colnames(data.result) <- gsub(pattern='/', '_', colnames(data.result),fixed=TRUE)
      data.result$level<-as.character(data.result$level)
      # data.result$level <- gsub(" ","",data.result$level)
      write.csv(data.result,paste(output_path,"/","Categorical","/",vars_cat[i],".csv",sep=""),row.names = FALSE,quote=F)
      allvars<-c(allvars,vars_cat[i])
      
    }
  }
  if(length(vars_cont)){
    for(i in 1:length(vars_cont)){
      mean.text <- paste('mean_value = as.numeric(mean(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      min.text <-paste('min_value = as.numeric(min(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      max.text <- paste('max_value = as.numeric(max(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      count.text <-paste('class_num_obs = length(',vars_cont[i],'),',sep="")
      std.text <- paste('stddev = as.numeric(sd(',vars_cont[i],', na.rm=TRUE','))',sep="")
      
      
      data.result.text <- paste('datatable[,list(',mean.text,min.text,max.text, count.text,std.text,'),by=bin_',vars_cont[i],']',sep="")
      data.result <- as.data.frame(eval(parse(text=data.result.text)))
      text<-paste("bin_",vars_cont[i],sep = "" )
      index<-order(data.result[,text])
      data.result<-data.result[index,]
#       data.result <- data.result[order(data.result$min_value),]
      stddev.index <- which(colnames(data.result)=="stddev")
      data.result <- data.result[,-stddev.index]
      
      second.result <- as.data.frame.matrix(table(datatable[[paste('bin_',vars_cont[i],sep='')]], datatable[[dependent_variable]], useNA='ifany'))
      
      
      tab <- second.result
      colnames(second.result)<-paste('_',colnames(second.result),sep='')
      levels <- unique(datatable[[dependent_variable]])
      
      second.result[paste('Perc',levels,sep='_')]<- apply(X=as.matrix(second.result),2,FUN=function(X,Y){(X/Y)*100},Y=data.result$class_num_obs)
      
      times <- nrow(data.result)
      
      global<-as.matrix(apply(as.data.frame.matrix(table(rep(1,length(datatable[[dependent_variable]])),datatable[[dependent_variable]], useNA='ifany')),2,rep,times=times))
      
      second.result[paste('Global',levels,sep='_')]<- global
      
      unique.cnt.dep <- length(unique(datatable[[dependent_variable]]))
      
      if(unique.cnt.dep > 1){
        second.result[paste('Global',levels,'Perc',sep='_')]<-t(apply(X=as.matrix(tab),1,FUN=function(X,Y){(X/Y)*100},Y=as.numeric(global[1,])))
      }else{
        second.result[paste('Global',levels,'Perc',sep='_')]<-apply(X=as.matrix(tab),1,FUN=function(X,Y){(X/Y)*100},Y=as.numeric(global[1,]))
      }
      data.result <- cbind.data.frame(data.result,second.result )
      colnames(data.result)[1]<-'level'
      colnames(data.result) <- gsub(pattern=' ', '_', colnames(data.result),fixed=TRUE)
      colnames(data.result) <- gsub(pattern='/', '_', colnames(data.result),fixed=TRUE)
      data.result <- data.result[order(data.result$level), ]
      write.csv(data.result,paste(output_path,"/","Continuous","/",vars_cont[i],".csv",sep=""),row.names = FALSE,quote=F)
      allvars<-c(allvars,paste("bin_",vars_cont[i],sep=""))
      
    }  
  }
  #-------------------------------------------------------------
  #PART 5 : When dependent variable is Continuous
  #-------------------------------------------------------------
  
}else{
  if(length(vars_cat)){
    for(i in 1:length(vars_cat)){
      
      #index.text <- paste('unique = unique(',vars_cat[i],'),',sep="")
      mean.text <- paste('avg_dependent_variable = as.numeric(mean(',dependent_variable,', na.rm=TRUE))',sep="")
      #     min.text <-paste('min = min(',dependent_variable,', na.rm=TRUE),',sep="")
      #     max.text <- paste('max = max(',dependent_variable,', na.rm=TRUE),',sep="")
      count.text <-paste('class_num_obs = length(',dependent_variable,')',sep="")
      
      data.result.text <- paste('datatable[,list(', count.text, ",", mean.text, '),by=eval(vars_cat[i])]',sep="")
      data.result <- as.data.frame(eval(parse(text=data.result.text)))
      
      #-----------------------------------------
      #Creating data frame of all the statistics
      #-----------------------------------------
      #index <- unique(datatable[[vars_cat[i]]])
      total_num_obs <- rep(nrow(datatable),nrow(data.result))
      class_per_obs <-(data.result$class_num_obs/total_num_obs)*100
      index <- (data.result$avg_dependent_variable/mean(datatable[[dependent_variable]],na.rm=T))*100
      data.result <- cbind.data.frame(data.result, total_num_obs, class_per_obs, index )
      colnames(data.result)[1] <- 'level'
      data.result$level<-as.character(data.result$level)
      # data.result$level <- gsub(" ","",data.result$level)
      #-----------------------------------------
      #writing the result at the output location
      #-----------------------------------------
      write.csv(data.result,paste(output_path,"/","Categorical","/",vars_cat[i],".csv",sep=""),row.names=FALSE,quote=F)
      allvars<-c(allvars,vars_cat[i])
    }
  }
  if(length(vars_cont)){
    for(i in 1:length(vars_cont)){
      
      mean.text  <- paste('mean_indep = as.numeric(mean(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      min.text   <- paste('min = as.numeric(min(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      max.text   <- paste('max = as.numeric(max(',vars_cont[i],', na.rm=TRUE',')),',sep="")
      count.text <- paste('class_num_obs = length(',vars_cont[i],'),',sep="")
      mean.dep.text <- paste('mean_dep = as.numeric(mean(',dependent_variable,', na.rm=TRUE))',sep="")
      
      data.result.text <- paste('datatable[,list(',mean.text,min.text,max.text, count.text, mean.dep.text,'),by=bin_',vars_cont[i],']',sep="")
      data.result      <- as.data.frame(eval(parse(text=data.result.text)))
      total.Count=rep(nrow(datatable),nrow(data.result))
      class.per.obs=(data.result$class_num_obs/total.Count)*100
      index.Val=(data.result$mean_dep/mean(datatable[[dependent_variable]],na.rm=T))*100
      
      
      #-----------------------------------------
      #Creating data frame of all the statistics
      #-----------------------------------------
      data.result <- cbind.data.frame(data.result, total.Count, class.per.obs, index.Val)
      colnames(data.result) <- c("level", "mean_value", "min_value","max_value","class_num_obs","avg_dependent_variable","total_num_obs","class_per_obs","index")
      data.result <- data.result[order(data.result$level),]
      #-----------------------------------------
      #writing the result at the output location
      #-----------------------------------------
      write.csv(data.result,paste(output_path,"/","Continuous","/",vars_cont[i],".csv",sep=""),row.names = FALSE ,quote=F)
      
      #------------------------------------------------------------
      #Creating the binned column to be used for aggregated binning
      #------------------------------------------------------------
      allvars<-c(allvars,paste("bin_",vars_cont[i],sep=""))
      
    
    }
  }
}  
if(file.exists(paste(output_path,"/bindata.csv",sep="")))
{
BinData1<-read.csv(paste(output_path,"/bindata.csv",sep=""))
BinData2<-data.frame(datatable)[allvars]
BinData<-cbind(BinData1,BinData2)
}else{
BinData<-data.frame(datatable)[allvars]
}
write.csv(BinData,paste(output_path,"/bindata.csv",sep=""),row.names = FALSE ,quote=F)
#writing the completed text at the output location
#-----------------------------------------------------------------
write("BIVARIATE_ANALYSIS_COMPLETED", file = paste(output_path, "BIVARIATE_ANALYSIS_COMPLETED.txt", sep="/"))
