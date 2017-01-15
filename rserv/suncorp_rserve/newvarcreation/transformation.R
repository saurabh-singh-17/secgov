#-------------------------------------------------------------------------------
# function : cumulative sum
#-------------------------------------------------------------------------------
muRx_cumulative_sum              <- function(x,
                                             type) {
  if (substr(type, 1, 1) == "p") {
    x                            <- (x / sum(x, na.rm=TRUE)) * 100
  }
  return(Reduce(f=function(x1, x2) {sum(x1, x2, na.rm=TRUE)},
                x=x,
                accumulate=TRUE))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : move (for lag/lead)
#-------------------------------------------------------------------------------
muRx_move                        <- function(x,
                                             direction,
                                             n) {
  
  if (!(class(x) == "numeric" | class(x) == "integer")) {
    stop("ERROR : class(x) has to be numeric or integer",
         call.=TRUE)
  }
  if (missing(direction)) {
    stop("ERROR : direction needs to be specified.",
         call.=TRUE)
  }
  if (missing(n)) {
    stop("ERROR : n needs to be specified.",
         call.=TRUE)
  }
  if (missing(x)) {
    stop("ERROR : x needs to be specified.",
         call.=TRUE)
  }
  
  if (n < length(x)) {
    if (direction == "forward") {
      x                          <- c(rep(NA,
                                          n),
                                      x[1:(length(x) - n)])
    }
    if (direction == "backward") {
      x                          <- c(x[(n + 1):length(x)],
                                      rep(NA,
                                          n))
    }
  } else {
    x                            <- rep(NA,
                                        length(x))
  }

  return(x)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : moving average
#-------------------------------------------------------------------------------
muRx_moving_average              <- function(x,
                                             direction,
                                             n) {
  if (!(class(x) == "numeric" | class(x) == "integer")) {
    stop("ERROR : class(x) has to be numeric or integer",
         call.=TRUE)
  }
  if (missing(direction)) {
    stop("ERROR : direction needs to be specified.",
         call.=TRUE)
  }
  if (missing(n)) {
    stop("ERROR : n needs to be specified.",
         call.=TRUE)
  }
  if (missing(x)) {
    stop("ERROR : x needs to be specified.",
         call.=TRUE)
  }

  if (direction == "backward") {
    n_backward                   <- 0
    n_forward                    <- n - 1
  } else if (direction == "forward") {
    n_backward                   <- n - 1
    n_forward                    <- 0
  } else if (direction == "mid") {
    n_backward                   <- floor(n / 2)
    n_forward                    <- ceiling((n / 2) - 1)
  }
  
  list_temp                      <- list(x)
  for (n_tempi in n_backward:1) {
    if (n_tempi == 0) break
    x_temp                       <- length(list_temp) + 1
    list_temp[[x_temp]]          <- muRx_move(x=x,
                                              direction="backward",
                                              n=n_tempi)
  }
  for (n_tempi in n_forward:1) {
    if (n_tempi == 0) break
    x_temp                       <- length(list_temp) + 1
    list_temp[[x_temp]]          <- muRx_move(x=x,
                                              direction="forward",
                                              n=n_tempi)
  }
  df_temp                        <- data.frame(list_temp)
  rm(list=c("list_temp"))
  
  return(rowMeans(x=df_temp, na.rm=TRUE))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# b_cos                           <- c(0)
# b_exponent                      <- c(0)
# b_lag                           <- c(0)
# b_lead                          <- c(0)
# b_log                           <- c(0)
# b_ma                            <- c(0)
# b_meancenter                    <- c(0)
# b_normalize                     <- c(0)
# b_onebyx                        <- c(0)
# b_onebyxcube                    <- c(0)
# b_onebyxsquare                  <- c(0)
# b_rounddown                     <- c(0)
# b_roundup                       <- c(0)
# b_sine                          <- c(1)
# c_path_in                       <- c('D:/data')
# c_path_out                      <- c('D:/temp')
# c_prefix                        <- c('acdc')
# c_type_ma                       <- c('Forward')
# c_var_in_date                   <- c('Date')
# c_var_in_transformation         <- c('sales')
# n_lag                           <- c(4)
# n_lead                          <- c(4)
# n_ma                            <- c(4)
# n_panel                         <- c(0)

# initialise
b_cos                            <- grepl(pattern="(^|!!)Cosine($|!!)",
                                          x=tranz)
b_cs                             <- grepl(pattern="(^|!!)CumSum($|!!)",
                                          x=tranz)
b_exponent                       <- grepl(pattern="(^|!!)exponential($|!!)",
                                          x=tranz)
b_lag                            <- grepl(pattern="(^|!!)Lag($|!!)",
                                          x=tranz)
b_lead                           <- grepl(pattern="(^|!!)lead($|!!)",
                                          x=tranz)
b_log                            <- grepl(pattern="(^|!!)Log($|!!)",
                                          x=tranz)
b_ma                             <- grepl(pattern="(^|!!)movingavg($|!!)",
                                          x=tranz)
b_meancenter                     <- grepl(pattern="(^|!!)meanCenter($|!!)",
                                          x=tranz)
b_normalize                      <- grepl(pattern="(^|!!)Normalize($|!!)",
                                          x=tranz)
b_onebyx                         <- grepl(pattern="(^|!!)Reciprocal($|!!)",
                                          x=tranz)
b_onebyxcube                     <- grepl(pattern="(^|!!)RecCube($|!!)",
                                          x=tranz)
b_onebyxsquare                   <- grepl(pattern="(^|!!)RecSquare($|!!)",
                                          x=tranz)
b_rounddown                      <- grepl(pattern="(^|!!)roundDown($|!!)",
                                          x=tranz)
b_roundup                        <- grepl(pattern="(^|!!)roundUp($|!!)",
                                          x=tranz)
b_sine                           <- grepl(pattern="(^|!!)Sine($|!!)",
                                          x=tranz)
c_path_in                        <- inputPath
c_path_out                       <- outputPath
c_prefix                         <- prefix
c_type_cs                        <- CumSumType
c_type_ma                        <- avgType
c_var_in_date                    <- dateVarName
c_var_in_transformation          <- varList
n_lag                            <- lag
n_lead                           <- lead
n_ma                             <- moveavg
n_panel                          <- grp_no
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# making "" NULL
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
# typecasting
b_cos                            <- as.integer(b_cos)
b_cs                             <- as.integer(b_cs)
b_exponent                       <- as.integer(b_exponent)
b_lag                            <- as.integer(b_lag)
b_lead                           <- as.integer(b_lead)
b_log                            <- as.integer(b_log)
b_ma                             <- as.integer(b_ma)
b_meancenter                     <- as.integer(b_meancenter)
b_normalize                      <- as.integer(b_normalize)
b_onebyx                         <- as.integer(b_onebyx)
b_onebyxcube                     <- as.integer(b_onebyxcube)
b_onebyxsquare                   <- as.integer(b_onebyxsquare)
b_rounddown                      <- as.integer(b_rounddown)
b_roundup                        <- as.integer(b_roundup)
b_sine                           <- as.integer(b_sine)
n_lag                            <- as.integer(n_lag)
n_lead                           <- as.integer(n_lead)
n_ma                             <- as.integer(n_ma)
n_panel                          <- as.integer(n_panel)

# initialising
c_csv_newvar                     <- c('transformations_output')
c_data_in                        <- c('dataworking')
c_data_newvar                    <- c('murx_newvar')
c_prefix_cos                     <- c('cos_')
c_prefix_cs                      <- NULL
c_prefix_exponent                <- c('exp_')
c_prefix_lag                     <- NULL
c_prefix_lead                    <- NULL
c_prefix_ma                      <- NULL
c_prefix_log                     <- c('log_')
c_prefix_meancenter              <- c('mean_')
c_prefix_normalize               <- c('normal_')
c_prefix_onebyx                  <- c('rec_')
c_prefix_onebyxcube              <- c('reccub_')
c_prefix_onebyxsquare            <- c('recsqr_')
c_prefix_rounddown               <- c('rnddn_')
c_prefix_roundup                 <- c('rndup_')
c_prefix_sine                    <- c('sin_')
c_txt_completed                  <- c('NEWVAR_TRANSFORMATION_COMPLETED')
c_txt_error                      <- c('error')
c_txt_warning                    <- c('warning')
c_var_key                        <- c('primary_key_1644')
c_var_panel                      <- NULL
c_file_delete                    <-  c(paste(c_path_out, '/', c_txt_completed, '.txt', sep=""),
                                       paste(c_path_out,  '/', c_txt_error,     '.txt', sep=""),
                                       paste(c_path_out,  '/', c_txt_warning,   '.txt', sep=""),
                                       paste(c_path_out,  '/', c_csv_newvar,    '.csv', sep=""))

# check and change
if (b_lag)
  c_prefix_lag                   <- paste('lag', n_lag, '_', sep='')
if (b_lead)
  c_prefix_lead                  <- paste('ld', n_lead, '_', sep='')
if (b_cs) {
  if (c_type_cs == "absolute")
    c_prefix_cs                <- "csa_"
  if (c_type_cs == "percentage")
    c_prefix_cs                <- "csp_"
}
if (b_ma) {
  c_type_ma                      <- gsub(pattern="bw",
                                         replacement="backward",
                                         x=c_type_ma)
  c_type_ma                      <- gsub(pattern="fw",
                                         replacement="forward",
                                         x=c_type_ma)
  if (c_type_ma == "forward")
    c_prefix_ma                  <- paste('ma', n_ma, 'fw_',  sep="")
  if (c_type_ma == 'backward')
    c_prefix_ma                  <- paste('ma', n_ma, 'bw_',  sep="")
  if (c_type_ma == 'mid')
    c_prefix_ma                  <- paste('ma', n_ma, 'mid_', sep="")
}
if (n_panel)
  c_var_panel                    <- paste("grp", n_panel, "_flag", sep="")
c_var_keep                       <- unique(c(c_var_in_transformation, c_var_in_date,
                                             c_var_key, c_var_panel))
c_prefix                         <- paste(c_prefix, "_", sep="")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# delete file
#-------------------------------------------------------------------------------
for (tempi in c_file_delete) {
  unlink(x=tempi)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# prepare the input data
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
df_data_newvar <- subset(x=dataworking, subset=TRUE, select=c_var_keep)
rm("dataworking")
df_data_newvar[c_var_in_transformation] <- data.frame(sapply(df_data_newvar[c_var_in_transformation], FUN=as.numeric))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# newvarcreation
#-------------------------------------------------------------------------------
c_var_new <- NULL

# sort the dataset by the date variable for time series transformations
if (length(c_var_in_date) | length(c_var_panel)) {
  c_text                         <- "order("
  c_sep                          <- ""
  if (length(c_var_panel)) {
    c_text                       <- paste(c_text,
                                          c_sep,
                                          "df_data_newvar[, c_var_panel]",
                                          sep="")
    c_sep                        <- ","
  }
  if (length(c_var_in_date)) {
    c_text                       <- paste(c_text,
                                          c_sep,
                                          "df_data_newvar[, c_var_in_date]",
                                          sep="")
  }
  c_text                         <- paste(c_text,
                                          ")",
                                          sep="")
  df_data_newvar                 <- df_data_newvar[eval(parse(text=c_text)), ]
}

# cumulative sum
if (b_cs) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_cs,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    for (n_tempi in 1:length(c_var_new_temp)) {
      c_var_new_now <- c_var_new_temp[n_tempi]
      c_var_trn_now <- c_var_in_transformation[n_tempi]
      df_data_newvar[c_var_new_now] <- muRx_cumulative_sum(x=df_data_newvar[, c_var_trn_now],
                                                            type=c_type_cs)
    }
    
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=FALSE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      for (n_tempi in 1:length(c_var_new_temp)) {
        c_var_new_now <- c_var_new_temp[n_tempi]
        c_var_trn_now <- c_var_in_transformation[n_tempi]
        df_data_newvar[l_index, c_var_new_now] <- muRx_cumulative_sum(x=df_data_newvar[l_index, c_var_trn_now],
                                                             type=c_type_cs)
      }
    }
  }
}
if (b_lag) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_lag,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    for (n_tempi in 1:length(c_var_new_temp)) {
      c_var_new_now <- c_var_new_temp[n_tempi]
      c_var_trn_now <- c_var_in_transformation[n_tempi]
      df_data_newvar[, c_var_new_now] <- muRx_move(x=df_data_newvar[, c_var_trn_now],
                                                          direction="forward",
                                                          n=n_lag)
    }
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=FALSE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      for (n_tempi in 1:length(c_var_new_temp)) {
        c_var_new_now <- c_var_new_temp[n_tempi]
        c_var_trn_now <- c_var_in_transformation[n_tempi]
        df_data_newvar[l_index, c_var_new_now] <- muRx_move(x=df_data_newvar[l_index, c_var_trn_now],
                                                            direction="forward",
                                                            n=n_lag)
      }
    }
  }
}
if (b_lead) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_lead,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    for (n_tempi in 1:length(c_var_new_temp)) {
      c_var_new_now <- c_var_new_temp[n_tempi]
      c_var_trn_now <- c_var_in_transformation[n_tempi]
      df_data_newvar[, c_var_new_now] <- muRx_move(x=df_data_newvar[, c_var_trn_now],
                                                          direction="backward",
                                                          n=n_lead)
    }
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=FALSE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      for (n_tempi in 1:length(c_var_new_temp)) {
        c_var_new_now <- c_var_new_temp[n_tempi]
        c_var_trn_now <- c_var_in_transformation[n_tempi]
        df_data_newvar[l_index, c_var_new_now] <- muRx_move(x=df_data_newvar[l_index, c_var_trn_now],
                                                            direction="backward",
                                                            n=n_lead)
      }
    }
  }
}
if (b_ma) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_ma,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    for (n_tempi in 1:length(c_var_new_temp)) {
      c_var_new_now <- c_var_new_temp[n_tempi]
      c_var_trn_now <- c_var_in_transformation[n_tempi]
      df_data_newvar[, c_var_new_now] <- muRx_moving_average(x=df_data_newvar[, c_var_trn_now],
                                                                    direction=c_type_ma,
                                                                    n=n_ma)
    }
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=FALSE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      for (n_tempi in 1:length(c_var_new_temp)) {
        c_var_new_now <- c_var_new_temp[n_tempi]
        c_var_trn_now <- c_var_in_transformation[n_tempi]
        df_data_newvar[l_index, c_var_new_now] <- muRx_moving_average(x=df_data_newvar[l_index, c_var_trn_now],
                                                                      direction=c_type_ma,
                                                                      n=n_ma)
      }
    }
  }
}
if (b_meancenter) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_meancenter,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    df_data_newvar[c_var_new_temp] <- scale(x=df_data_newvar[, c_var_in_transformation],
                                           scale=FALSE)
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=TRUE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      df_data_newvar[l_index, c_var_new_temp] <- scale(x=df_data_newvar[l_index, c_var_in_transformation],
                                                      scale=FALSE)
    }
  }
}
if (b_normalize) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_normalize,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  if (is.null(c_var_panel)) {
    df_data_newvar[c_var_new_temp] <- scale(x=df_data_newvar[, c_var_in_transformation])
  } else {
    df_data_newvar[c_var_new_temp] <- df_data_newvar[c_var_in_transformation]
    df_unique <- unique(df_data_newvar[c_var_panel])
    
    for (tempi in 1:nrow(df_unique)) {
      df_temp <- merge(x=df_data_newvar[c(c_var_panel, c_var_key)],
                       y=subset(x=df_unique, subset=1:nrow(df_unique) == tempi),
                       by=c_var_panel,
                       all=TRUE)
      l_index <- df_data_newvar[, c_var_key] %in% df_temp[, c_var_key]
      df_data_newvar[l_index, c_var_new_temp] <- scale(x=df_data_newvar[l_index, c_var_in_transformation])
    }
  }
}
if (b_sine) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_sine,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- sin(df_data_newvar[c_var_in_transformation])
}
if (b_cos) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_cos,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- cos(df_data_newvar[c_var_in_transformation])
}
if (b_onebyx) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_onebyx,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- 1 / df_data_newvar[c_var_in_transformation]
}
if (b_onebyxsquare) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_onebyxsquare,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- 1 / (df_data_newvar[c_var_in_transformation]^2)
}
if (b_onebyxcube) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_onebyxcube,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- 1 / (df_data_newvar[c_var_in_transformation]^3)
}
if (b_roundup) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_roundup,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- ceiling(df_data_newvar[c_var_in_transformation])
}
if (b_rounddown) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_rounddown,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- floor(df_data_newvar[c_var_in_transformation])
}
if (b_log) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_log,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- log(df_data_newvar[c_var_in_transformation])
}
if (b_exponent) {
  c_var_new_temp <- paste(c_prefix,
                         c_prefix_exponent,
                         substr(x=c_var_in_transformation, start=1, stop=17),
                         sep="")
  c_var_new     <- c(c_var_new, c_var_new_temp)
  
  df_data_newvar[c_var_new_temp] <- exp(df_data_newvar[c_var_in_transformation])
}

df_data_newvar <- subset(x=df_data_newvar, select=c(c_var_new, c_var_key))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# adding new variables to dataworking
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
dataworking <- merge(x=dataworking,
                     y=df_data_newvar,
                     by=c_var_key,
                     all.x=TRUE)
save(dataworking, file=paste(c_path_in, "/dataworking.RData", sep=""))
df_data_newvar <- subset(x=df_data_newvar, select=c(c_var_new))
rm("dataworking")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# 6000 check
#-------------------------------------------------------------------------------
if (nrow(df_data_newvar) > 6000) {
  x_temp                       <- sample(x=nrow(df_data_newvar),
                                         size=6000,
                                         replace=FALSE)
  df_data_newvar               <- df_data_newvar[x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : unnecessary nonsense
#-------------------------------------------------------------------------------
write.csv(as.data.frame(c_var_new),
          paste(outputPath,"newVar_transformation.csv",sep="/"),
          row.names=FALSE,quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : newvar csv
#-------------------------------------------------------------------------------
write.csv(df_data_newvar, paste(c_path_out, "/", c_csv_newvar, ".csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# update the dataset properties
#-------------------------------------------------------------------------------
source(paste(genericCode_path,"datasetprop_update.R",sep="/"))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------
