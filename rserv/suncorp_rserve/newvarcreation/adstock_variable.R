#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# c_path_in          <- 'D:/data'
# c_path_out         <- "D:/temp"
# 
# n_panel            <- '0'
# 
# c_mode             <- 'check'
# 
# c_var_in_adstock   <- c('ACV', "black_hispanic")
# c_var_in_date      <- 'Date'
# c_var_in_dependent <- 'sales'
# 
# n_decay            <- '0.1!!0.4!!0.5'
# n_gamma            <- NULL
# c_type_eqn         <- 'log'
# c_type_trn         <- NULL
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()

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
# parameter play
#-------------------------------------------------------------------------------
n_panel <- as.integer(n_panel)
n_lambda <- as.numeric(unlist(strsplit(x=n_decay, split="!!", fixed=TRUE)))
if (c_type_eqn == "exponential") {
  n_gamma <- as.numeric(unlist(strsplit(x=n_gamma, split="!!", fixed=TRUE)))
  if(is.null(c_type_trn)) c_type_trn <- "simple"
} else {
  n_gamma <- 1
}
c_var_in_by <- NULL
if (n_panel) c_var_in_by <- paste("grp", n_panel, "_flag", sep="")

#hardcoding
c_csv_corr_table  <- "correlation_table"
c_csv_newvar      <- "adstockVarCreation_viewPane"
c_rdata_forcreate <- "adstock"
c_var_key         <- "primary_key_1644"
c_txt_completed   <- "completed"
c_txt_error       <- "error"
c_txt_warning     <- "warning"
c_file_delete     <- c(paste(c_path_out, "/", c_csv_newvar, ".csv", sep=""),
                       paste(c_path_out, "/", c_csv_corr_table, ".csv", sep=""),
                       paste(c_path_out, "/", c_txt_completed, ".txt", sep=""),
                       paste(c_path_out, "/", c_txt_error, ".txt", sep=""),
                       paste(c_path_out, "/", c_txt_warning, ".txt", sep=""))
#-------------------------------------------------------------------------------



if(c_mode == "confirm") {
  #-------------------------------------------------------------------------------
  # delete file
  #-------------------------------------------------------------------------------
  for (tempi in c_file_delete) {
    unlink(x=tempi)
  }
  #-------------------------------------------------------------------------------
  
  #-------------------------------------------------------------------------------
  # read dataworking and add the selected new variables to dataworking
  #-------------------------------------------------------------------------------
  load(paste(c_path_in,"/dataworking.RData",sep=""))
  load(paste(c_path_in,"/", c_rdata_forcreate, ".RData",sep=""))
  df_newvar <- df_newvar[c_var_in_selected]
  #-------------------------------------------------------------------------------
  
  #-------------------------------------------------------------------------------
  # output : dataworking
  #-------------------------------------------------------------------------------
  dataworking <- cbind.data.frame(dataworking, df_newvar)
  save(dataworking, file=paste(c_path_in,"/dataworking.RData",sep=""))
  #-------------------------------------------------------------------------------

  #-------------------------------------------------------------------------------
  # 6000 check
  #-------------------------------------------------------------------------------
  if (nrow(df_newvar) > 6000) {
    x_temp                       <- sample(x=nrow(df_newvar),
                                           size=6000,
                                           replace=FALSE)
    df_newvar                    <- df_newvar[x_temp, , drop=FALSE]
  }
  #-------------------------------------------------------------------------------
  
  #-------------------------------------------------------------------------------
  # output : new variables
  #-------------------------------------------------------------------------------
  write.csv(df_newvar,
            paste(c_path_out, "/", c_csv_newvar, ".csv", sep=""),
            row.names=FALSE, quote=FALSE)
  #-------------------------------------------------------------------------------

  #-------------------------------------------------------------------------------
  # update the dataset properties
  #-------------------------------------------------------------------------------
  source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
  #-------------------------------------------------------------------------------
  
  #-------------------------------------------------------------------------------
  # output : completed
  #-------------------------------------------------------------------------------
  write(x=c_txt_completed,
        file=paste(c_path_out,
                   "/",
                   c_txt_completed,
                   ".txt",
                   sep=""))
  #-------------------------------------------------------------------------------
}


if (c_mode == "check") {
  #-------------------------------------------------------------------------------
  # prepare the input data
  #-------------------------------------------------------------------------------
  load(paste(c_path_in,"/dataworking.RData",sep=""))
  
  select <- c(c_var_in_adstock, c_var_in_by, c_var_in_date, c_var_in_dependent, c_var_key)
  df_data <- subset(x=dataworking, subset=TRUE, select=select)
  rm("dataworking")
  
  df_data <- df_data[order(df_data[, c_var_in_date]), ]
  if (!n_panel) {
    c_var_in_by <- "murx_by"
    df_data[c_var_in_by] <- 0
  }
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # delete file
  #-------------------------------------------------------------------------------
  for (tempi in c_file_delete) {
    unlink(x=tempi)
  }
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # error check
  #-------------------------------------------------------------------------------
  if (c_type_eqn == "log") {
    
    errorText <- NULL
    x_temp <- length(which(df_data[, c_var_in_adstock] == 0))
    if (x_temp) {
      x_temp    <- paste("The variable ", c_var_in_adstock, " has ", x_temp,
                         " number of values as 0.", sep="")
      errorText <- c(x_temp, errorText)
    }
    
    x_temp <- length(which(df_data[, c_var_in_adstock] < 0))
    if (x_temp) {
      x_temp    <- paste("The variable ", c_var_in_adstock, " has ", x_temp,
                         " number of values as negative.", sep="")
      errorText <- c(x_temp, errorText)
    }
    
    x_temp <- length(which(is.na(df_data[, c_var_in_adstock])))
    if (x_temp) {
      x_temp    <- paste("The variable ", c_var_in_adstock, " has ", x_temp,
                         " number of values missing.", sep="")
      errorText <- c(x_temp, errorText)
    }
    
    if (length(errorText)) {
      write(x=errorText,
            file=paste(c_path_out, "/", c_txt_error, ".txt", sep=""),
            append=TRUE)
      stop(errorText)
    }
    
  }
  
  n_unique_count <- aggregate(x=df_data[, c_var_in_date],
                              by=list(df_data[, c_var_in_by]),
                              FUN=function(x) length(unique(x)))
  n_count        <- aggregate(x=df_data[, c_var_in_date],
                              by=list(df_data[, c_var_in_by]),
                              FUN=length)
  
  if (any(n_unique_count != n_count)) {
    c_warning <- "The date variable does not have unique values."
    write(x=c_warning,
          file=paste(c_path_out, "/", c_txt_warning, ".txt", sep=""),
          append=TRUE)
  }
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # creating the new variables
  #-------------------------------------------------------------------------------
  f <- function(x1, x2) {
    if (c_type_eqn == "log") {
      (log(x2) + (x1 * (1 - n_lambda_now)))^n_gamma_now
    } else {
      (x2 + (x1 * (1 - n_lambda_now)))^n_gamma_now
    }
  }
  
  c_letter1 <- "a"
  c_letter2 <- "d"
  c_letter3 <- "s"
  c_letter4 <- NULL
  
  if (n_panel)             c_letter2 <- "g"
  if (c_type_eqn == "log") c_letter3 <- "l"
  
  x_unique_by   <- unique(df_data[, c_var_in_by])
  c_4letterword <- paste(c_letter1, c_letter2, c_letter3, c_letter4, sep="")
  c_var_new     <- NULL
  df_corr_table <- NULL
  
  for (tempi in 1:length(c_var_in_adstock)) {
    c_var_in_adstock_now <- c_var_in_adstock[tempi]
    
    for (tempj in 1:length(n_lambda)) {
      n_lambda_now <- n_lambda[tempj]
      
      for (tempk in 1:length(n_gamma)) {
        n_gamma_now <- n_gamma[tempk]
        
        c_var_new_now <- paste(c_4letterword,
                               tempi,
                               "_",
                               substr(x=c_var_in_adstock_now, start=1, stop=10),
                               "_",
                               gsub(x=as.character(n_lambda_now),
                                    pattern=".",
                                    replacement="",
                                    fixed=TRUE),
                               sep="")
        
        c_var_new <- c(c_var_new, c_var_new_now)
        
        for(templ in 1:length(x_unique_by)) {
          x_unique_by_now <- x_unique_by[templ]
          n_index <- which(df_data[, c_var_in_by] == x_unique_by_now)
          
          df_data[n_index, c_var_new_now] <- Reduce(f=f,
                                                    x=df_data[n_index, c_var_in_adstock_now],
                                                    accumulate=TRUE)
        }
        
        x_temp <- data.frame(c_var_in_by=c_var_in_by,
                             c_type_eqn=c_type_eqn,
                             lambda=n_lambda_now,
                             gamma=n_gamma_now,
                             c_var_in_adstock=c_var_in_adstock_now,
                             correlation_with_dependent=cor(x=df_data[, c_var_new_now],
                                                            y=df_data[, c_var_in_dependent],
                                                            use="na.or.complete"),
                             c_var_new=c_var_new_now)
        df_corr_table <- rbind.data.frame(df_corr_table, x_temp)
      }
    }
  }
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # output : correlation table
  #-------------------------------------------------------------------------------
  for (tempi in 1:length(c_var_in_adstock)) {
    c_var_in_adstock_now <- c_var_in_adstock[tempi]
    
    x_temp <- data.frame(c_var_in_by=c_var_in_by,
                         c_type_eqn=c_type_eqn,
                         lambda=1,
                         gamma=1,
                         c_var_in_adstock=c_var_in_adstock_now,
                         correlation_with_dependent=cor(x=df_data[, c_var_in_adstock_now],
                                                        y=df_data[, c_var_in_dependent],
                                                        use="na.or.complete"),
                         c_var_new=c_var_in_adstock_now)
    df_corr_table <- rbind.data.frame(df_corr_table, x_temp)
  }
  
  df_corr_table <- df_corr_table[c("c_var_new", "correlation_with_dependent", "lambda")]
  colnames(df_corr_table) <- c("actual_name", "correlation", "decay")
  
  write.csv(df_corr_table,
            paste(c_path_out, "/", c_csv_corr_table, ".csv", sep=""),
            row.names=FALSE, quote=FALSE)
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # output : new variables
  #-------------------------------------------------------------------------------
  x_temp <- df_data[c(c_var_in_adstock, c_var_in_date, c_var_new)]
  x_temp <- x_temp[order(x_temp[, c_var_in_date]), ]
  
  #-------------------------------------------------------------------------------
  #calls the useDateFunction to format date variables into the original format 
  #------------------------------------------------------------------------------- 
  x_temp <- useDateFormat(c_path_in=c_path_in, x = x_temp)
  #------------------------------------------------------------------------------- 
  
  if (nrow(x_temp) > 6000) {
    x_temp                    <- x_temp[sample(x=nrow(x_temp),
                                               size=6000,
                                               replace=FALSE), , drop=FALSE]
  }
  
  write.csv(x_temp,
            paste(c_path_out, "/", c_csv_newvar, ".csv", sep=""),
            row.names=FALSE, quote=FALSE)
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # output : for create
  #-------------------------------------------------------------------------------
  df_newvar <- df_data[order(df_data[, c_var_key]), c(c_var_in_adstock,
                                                      c_var_new), drop=FALSE]
  
  save(df_newvar,
       file=paste(c_path_in, "/", c_rdata_forcreate, ".RData", sep=""))
  #-------------------------------------------------------------------------------
  
  
  
  #-------------------------------------------------------------------------------
  # output : completed
  #-------------------------------------------------------------------------------
  write(x=c_txt_completed,
        file=paste(c_path_out,
                   "/",
                   c_txt_completed,
                   ".txt",
                   sep=""))
  #-------------------------------------------------------------------------------
}

