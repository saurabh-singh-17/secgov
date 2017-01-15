#------------------------------------------------------------------------------
# function : getDateFormat
# author   : Vasanth MM
#------------------------------------------------------------------------------
getDateFormat <- function (c_path_in, c_var_in) {
  x_temp <- paste(c_path_in, "/df_dateFormat.RData", sep = "")
  if (!file.exists(x_temp)) {
    return("unknown")
  }
  load(paste(c_path_in, "/df_dateFormat.RData", sep = ""))
  n_index <- which(df_dateFormat$variable == c_var_in)
  if (length(n_index) == 1) {
    return(df_dateFormat[n_index, "dateFormat"])
  }
  return("unknown")
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : setDateFormat
# author   : Shanti Jha
#------------------------------------------------------------------------------
setDateFormat <- function(c_path_in, c_var_in, dateFormat)
{  
  if(file.exists(paste(c_path_in,"/df_dateFormat.RData",sep=""))){
    load(paste(c_path_in,"/df_dateFormat.RData",sep=""))
  } else {
    df_dateFormat <- NULL
  }
  
  dateFormat      <- updateDateFormat(dateFormat)
  df_dateFormat   <- rbind.data.frame(df_dateFormat,
                                      data.frame(variable = c_var_in,
                                                 dateFormat,
                                                 stringsAsFactors=FALSE))
  
  save(df_dateFormat, file=paste(c_path_in, "/df_dateFormat.RData", sep=""))
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : updateDateFormat
# author   : Tushar Gupta
#------------------------------------------------------------------------------
updateDateFormat <- function(dateFormat) {
  if (dateFormat == "unknown") {
    return("unknown")
  }
  
  pattern <- c("%Y/%m/%d","%Y/%d/%m","%d/%m/%y","%d/%m/%y","%d/%m/%Y","%m/%d/%Y",
               "%Y-%m-%d","%Y-%d-%m","%d-%m-%y","%d-%m-%y","%d-%m-%Y","%m-%d-%Y")
  for (i in 1:length(pattern)){
    if (grepl(pattern = pattern[i], x = dateFormat)){
      return(pattern[i])
    }
  }
  return("unknown")
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : useDateFormat
# author   : Vasanth MM
#------------------------------------------------------------------------------
useDateFormat <- function(c_path_in,
                          x) {
  for (i in names(x)) {
    for (j in c_path_in) {
      format <- getDateFormat(c_path_in = j,
                              c_var_in = i)
      if (format != "unknown") {
        x[[i]] <- format(x = x[[i]], format = format)
        next
      }
    }
  }
  return(x)
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : dateformat
# author   : Saurabh Vikash Singh
#------------------------------------------------------------------------------
dateformat<-function(date){
  date <- gsub(pattern = " ", replacement = "", x = date)
  index <- which(date == "")
  index<-c(index,which(is.na(date)))
  if(length(index)){
    date <- date[-index]
  }
  form<-NULL
  temp<-as.character(na.omit(date)[1])
  
  
  if(grepl("[a-zA-Z ]",temp)){
    date<-apply(as.data.frame(date),1,function(x){strsplit(as.character(x),"[a-zA-Z ]")[[1]][1]})
  }
  if(any(grepl("[[:alpha:]]",date) == "TRUE") || all(date == ""))
  {
    return("unknown")
  }
  date<-as.character(date)
  if (is.null(date))
    return("unknown")  
  if(is.na(mean(as.numeric(date),na.rm=T)) == "FALSE")    
  {
    return("unknown")
  }
  if(any(apply(as.data.frame(date),1,function(x){length(unlist(strsplit(x,"")))}) < 6))
  {
    return("unknown")
  }
  if((length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("/","",date,fixed=T))) == FALSE)))   &
       (length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == TRUE)) > length(which(is.na(as.numeric(gsub("-","",date,fixed=T))) == FALSE))))
    return("unknown")
  if (all(is.na(date))) 
    return(NA)
  val<-length(date)
#   if(val > 100){val= 100}
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
  if(is.null(form))
  {
    return("unknown")
  }
  tempchar<-gsub(pattern = "[^[:alpha:] ]", "" ,temp)
  tempchar<-gsub("\\s*","",tempchar)
  separator<-" "
  if(!is.na(unlist(strsplit(tempchar,""))[1]))
  {
    separator<-unlist(strsplit(tempchar,""))[1] 
  }
  if(nchar(temp[1]) > 10 & nchar(temp[1]) <= 16){form<- paste(form,separator,"%H:%M",sep="")}
  if(nchar(temp[1]) > 16){form<- paste(form,separator,"%H:%M:%OS",sep="")}
  if(is.na(as.Date(temp[1],format=form))){
    return("unknown")
  }else{
    return(form)
  }
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : ppPlot
# author   : Vasanth MM
#------------------------------------------------------------------------------
ppPlot                           <- function(x,
                                             mean,
                                             sd,
                                             plot,
                                             xlab,
                                             ylab) {
  # PRE OPS
  # x should be of class numeric or integer
  if (class(x) != "numeric" & class(x) != "integer") {
    stop("x should be of class numeric or integer", call. = TRUE)
  }
  # x should have at least one non missing element
  if (length(x) < 1 | all(is.na(x))) {
    stop("x should have at least one non missing element", call. = TRUE)
  }
  # mean should be of class numeric or integer
  if (class(mean) != "numeric" & class(mean) != "integer") {
    stop("mean should be of class numeric or integer", call. = TRUE)
  }
  # mean should be of length 1
  if (length(mean) != 1) {
    stop("mean should be of length 1", call. = TRUE)
  }
  # mean should not be NA
  if (all(is.na(mean))) {
    stop("mean should not be NA", call. = TRUE)
  }
  # sd should be of class numeric or integer
  if (class(sd) != "numeric" & class(sd) != "integer") {
    stop("sd should be of class numeric or integer", call. = TRUE)
  }
  # sd should be of length 1
  if (length(sd) != 1) {
    stop("sd should be of length 1", call. = TRUE)
  }
  # sd should not be NA
  if (all(is.na(sd))) {
    stop("sd should not be NA", call. = TRUE)
  }
  # plot should be logical
  if (class(plot) != "logical") {
    stop("plot should be logical", call. = TRUE)
  }
  # plot should be of length 1
  if (length(plot) != 1) {
    stop("plot should be of length 1", call. = TRUE)
  }
  
  # OPS
  # calculating the probabilities
  x                              <- sort(na.omit(x))
  n_length                       <- length(x)
  x_temp                         <- 1:n_length
  n_empirical                    <- x_temp / n_length
  n_theoretical                  <- pnorm(q = x, mean = mean, sd = sd)
  
  # plot
  if (plot) {
    plot(x = n_theoretical,
         y = n_empirical,
         xlab = xlab,
         ylab = ylab,
         xlim = c(0, 1),
         ylim = c(0, 1))
    abline(a = c(0, 0), b = c(1, 1))
  }
  
  # POST OPS
  # return
  return(data.frame(n_empirical, n_theoretical))
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : extractHashTags
# author : Vasanth MM
#------------------------------------------------------------------------------
extractHashTags                  <- function(x) {
  x_temp                         <- gregexpr(pattern = "#[^#[:space:]]+",
                                             text = x)
  x_temp                         <- regmatches(x = x, m = x_temp)
  x_temp                         <- sapply(x_temp, paste, collapse = " ")
  x_temp                         <- gsub(pattern = "#",
                                         replacement = "",
                                         x = x_temp)
  return(x_temp)
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# function : extractPOS
# author : Vasanth MM
#------------------------------------------------------------------------------
extractPOS                       <- function(x, POS) {
  x_temp                         <- is.na(x)
  if (any(x_temp)) {
    x[x_temp]                    <- ""
  }
  x                              <- str_trim(string = x, side = "both")
  x                              <- removePunctuation(x = x,
                                                      preserve_intra_word_dashes = FALSE)
  x                              <- tagPOS(sentence = x, language = "en")
  requiredWords                  <- character(length = length(x))
  for (i in 1:length(x)) {
    x_temp                       <- x[i]
    
    if (x_temp == "") {
      next
    }
    
    x_temp                       <- unlist(strsplit(x = x_temp, split = " "))
    x_temp                       <- strsplit(x = x_temp, split = "/")
    words                        <- sapply(X = x_temp, FUN = "[", 1)
    postags                      <- sapply(X = x_temp, FUN = "[", 2)
    postags                      <- substr(x = postags, start = 1, stop = 2)
    n_index                      <- postags %in% POS
    
    if (!any(n_index)) {
      next
    }
    
    requiredWords[i]             <- paste(words[n_index], collapse = " ")
  }
  return(requiredWords)
}
#------------------------------------------------------------------------------
