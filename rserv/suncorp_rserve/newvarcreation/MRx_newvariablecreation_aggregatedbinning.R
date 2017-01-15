#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Aggregated_Binning_1.0                                                        --#
#-- Description :-
#--   2.The below Script is divided into six parts :-
#--     1. Loading Libraries
#--     2. Data loading
#--     3. Function to create binned variables if script is ran from bivariate Analyis
#--     4. Understanding the bins
#--     5. Binning all the variables
#--     6. Writing the report CSVs and updating dataworking
#-- Return type  :  Creates CSVs at a location according to given inputs                            --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------
#PART 1 : Libraries required
#-------------------------------------------------------------------------------
require(XML)
require(data.table)
require(Hmisc)
require(stringr)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#PART 2 : Loading the Data  
#-------------------------------------------------------------------------------
load(paste(input_path,"dataworking.RData",sep="/"))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Function to create the binned variable
#-------------------------------------------------------------------------------
untitled <- function(x,
                     c.type.bin,  # datasetorder, percentile, equalrange, custom
                     n.bins=NULL,
                     n.cutpoints=NULL,
                     l.namethebins=F){
  if (c.type.bin == "percentile" | c.type.bin == "datasetorder") {
    n.obs.in.bin <- diff(floor(seq(from=0, to=length(x), by=length(x) / n.bins)))
    n.newvar     <- rep(x=1:n.bins, times=n.obs.in.bin)
    if (c.type.bin == "percentile") {
      key      <- 1:length(x)
      key      <- key[order(x)]  
      n.newvar <- n.newvar[order(key)]
    }
  }
  if (c.type.bin == "equalrange" | c.type.bin == "custom") {
    if (c.type.bin == "equalrange") {
      if (min(x) == max(x)) {
        n.cutpoints <- rep(min(x), times=2)
        n.bins = 1
      } else {
        n.cutpoints <- seq(from=min(x), to=max(x), by=(max(x) - min(x)) / n.bins)
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
      n.min       <- aggregate(x=x, by=list(n.newvar), FUN=min, na.rm=T)
      n.max       <- aggregate(x=x, by=list(n.newvar), FUN=max, na.rm=T)
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



#-------------------------------------------------------------------------------
# If from bivariate, create the binned variable first
#-------------------------------------------------------------------------------
if(as.logical(flag_bivariate)){
  
  c.type.bin <- bin_type
  n.bins <- as.numeric(bin)
  temp.var.continuous <- var_list
  if(c.type.bin == "equal range") c.type.bin = "equalrange"
  
  for (tempi in 1:length(temp.var.continuous)) {
    temp.newvar.name <- paste('bin', temp.var.continuous[tempi], sep="_")
    dataworking[, temp.newvar.name] <- untitled(x=dataworking[, temp.var.continuous[tempi]],
                                                c.type.bin=c.type.bin,
                                                n.bins=n.bins,
                                                l.namethebins=T)
  }
  var_list<-paste("bin_",var_list,sep="")
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#PART 4 : Understanding the bins through XML  
#-------------------------------------------------------------------------------
input_xml <- xmlTreeParse(input_xml)
xmldata <- xmlToList(input_xml)
xmldata=as.data.frame(xmldata)
#-------------------------------------------------------------------------------



#index <- grep(',',xmldata[1,],fixed=TRUE)
#xmldata <- xmldata[index]
data.result<-NULL

#-----------------------------------------------------------------
#PART 5 : Binning it for all the variables  
#-----------------------------------------------------------------
for(i in 1:length(var_list)){
  
  bin.info <- xmldata[which(colnames(xmldata)==gsub('bin_','',var_list[i],fixed=TRUE))]
  data <- as.character(dataworking[,var_list[i]])
  data <- str_trim(data,side="both")
  
  for(j in 1:ncol(bin.info)){
    
    ind.get <- function(x,y){
      return(unique(unlist(strsplit(x,split=',',fixed=TRUE)) %in% y ))
    }
    
    to.check <- unlist(strsplit(as.character(bin.info[1,j]),split=',',fixed=TRUE))
    index.to.rename <- which(apply(as.matrix(data),1,ind.get,y=to.check)==TRUE)
    index.to.rename <- data %in% to.check
    data[index.to.rename] <- as.character(bin.info[2,j])
  }
  
  if (type[i] == "categorical") {
    data <- as.character(data)
  } else if (type[i] == "numerical") {
    data <- as.numeric(data)
  }
  
  if (i == 1) {
    data.result <- data.frame(data,stringsAsFactors=F)
  } else {
    data.result <- cbind.data.frame(data.result, data)
  }
  
}

colnames(data.result) <- paste(prefix,gsub('bin_','',var_list,fixed=TRUE), sep='_')
#-----------------------------------------------------------------
#PART 6 : Updating the dataworking and writing report csvs
#-----------------------------------------------------------------
dataworking <- cbind.data.frame(dataworking, data.result)

#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(data.result) > 6000) {
  x_temp                       <- sample(x=nrow(data.result),
                                         size=6000,
                                         replace=FALSE)
  data.result                  <- data.result[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------
write.csv(data.result,paste(output_path,"MultiAggrBinning_viewPane.csv",sep="/"),row.names=FALSE, quote=FALSE )

save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))

#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------

write.table("MULTIPLE_AGGREGATION_BINNING_COMPLETED",paste(output_path,"MULTIPLE_AGGREGATION_BINNING_COMPLETED.txt",sep="/"),sep="/t",quote=F)