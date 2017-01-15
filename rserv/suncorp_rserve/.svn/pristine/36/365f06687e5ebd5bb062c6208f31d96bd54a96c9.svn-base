#-------------------------------------------------------------------------------
# parameters required
#-------------------------------------------------------------------------------
# rm(list = ls())
# rcodePath                        <- "D:/SVN New/Suncorp 8.7.2 Flex/src/com/musigma/reusablemodules/serverRCodes"
# source(paste(rcodePath, "/common/functions.R", sep=""))
# c_path_in                        <- c('D:/data')
# c_path_out                       <- c('D:/temp')
# 
# groupBy_var                      <- c('geography', 'Date')
# groupBy_option                   <- c('', 'Monthly')
# 
# aggregation_var                  <- c('ACV','Store_Format', 'Store_Format','Store_Format','Store_Format','Store_Format','Store_Format')
# aggregation_level                <- c('', '', 'Food/Drug Combo','Super Combo','Supercenter','Supermarket','Superstore')
# aggregation_newVar               <- c('ACV_','Store_Format','Store_Format_Food/Drug Combo','Store_Format_Super Combo','Store_Format_Supercenter','Store_Format_Supermarket','Store_Format_Superstore')
# aggregation_aggregation          <- c('SUM','COUNT','PERCENT','PERCENT','PERCENT','COUNT','COUNT')
# 
# c_dataset_new                    <- c('R')
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
aggregation_newVar               <- gsub(pattern = "[^a-zA-Z0-9_]",
                                         replacement = "_",
                                         x = aggregation_newVar)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries required
#-------------------------------------------------------------------------------
library(data.table)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : muRx_aggregation
#-------------------------------------------------------------------------------
muRx_sum                         <- function(x, na.rm = TRUE) {
  sum(as.numeric(x), na.rm = na.rm)
}

muRx_mean                        <- function (x, na.rm = TRUE) {
  mean(as.numeric(x), na.rm = na.rm)
}

muRx_min                         <- function (x, na.rm = TRUE) {
  ret                            <- min(x, na.rm = na.rm)
  if (ret == Inf) {
    ret                          <- NA
  }
  return(ret)
}

muRx_max                         <- function (x, na.rm = TRUE) {
  ret                            <- min(x, na.rm = na.rm)
  if (ret == -Inf) {
    ret                          <- NA
  }
  return(ret)
}

muRx_count                       <- function (x, na.rm = TRUE) {
  n_index                        <- x %in% ""
  x_temp                         <- is.na(x)
  n_index                        <- which(!(n_index | x_temp))
  ret                            <- length(n_index)
  
  return(ret)
}

muRx_uniqueCount                 <- function (x, na.rm = TRUE) {
  x                              <- unique(x)
  ret                            <- muRx_count(x = x, na.rm = na.rm)
  
  return(ret)
}

muRx_percent                     <- function (x, na.rm = TRUE) {
  ret                            <- (x / muRx_sum(x = x, na.rm = na.rm)) * 100
  
  return(ret)
}

muRx_aggregation                 <- function (x, level, aggregation, na.rm = TRUE) {
  if (level != "") {
    x                            <- x[x == level]
  }
  if (!length(x)) {
    ret                          <- 0
  } else if (aggregation == "SUM") {
    ret                          <- muRx_sum(x, na.rm)
  } else if (aggregation == "AVG") {
    ret                          <- muRx_mean(x, na.rm)
  } else if (aggregation == "MIN") {
    ret                          <- muRx_min(x, na.rm)
  } else if (aggregation == "MAX") {
    ret                          <- muRx_max(x, na.rm)
  } else if (aggregation == "COUNT" | aggregation == "PERCENT") {
    ret                          <- muRx_count(x, na.rm)
  } else if (aggregation == "UNIQUE COUNT") {
    ret                          <- muRx_uniqueCount(x, na.rm)
  }
  
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : muRx_dateLevel
#-------------------------------------------------------------------------------
muRx_dateLevel                   <- function (x, level) {
  # what is a week? starts with sunday/monday?
  # what is the first week of a month/year? is the first 7 days of the month/year?
  if (level == "Week of Month") {
    x_temp                       <- as.Date(paste(year(x), month(x), "01", sep="-"))
    x_temp                       <- as.integer(format(x = x_temp, format = "%W"))
    ret                          <- as.integer(format(x = x, format = "%W")) - x_temp + 1
  } else if (level == "Week of Year") {
    ret                          <- as.integer(format(x = x, format = "%W"))
  } else if (level == "Monthly") {
    ret                          <- month(x = x)
  } else if (level == "Quarterly") {
    ret                          <- quarters(x = x)
  } else if (level == "Yearly") {
    ret                          <- year(x = x)
  } else {
    ret                          <- x
  }
  
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# load the dataset
#-------------------------------------------------------------------------------
load(paste(c_path_in, "/dataworking.RData", sep=""))
dataworking                      <- subset(x = dataworking,
                                           select = unique(c(groupBy_var,
                                                             aggregation_var)))
dataworking                      <- data.table(dataworking)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# rolling up the dataset
#-------------------------------------------------------------------------------
groupBy_text                     <- "list("
sep                              <- ""
for (i in 1:length(groupBy_var)) {
  groupBy_var_now                <- groupBy_var[i]
  groupBy_option_now             <- groupBy_option[i]
  
  x_temp                         <- paste(groupBy_var_now,
                                          " = muRx_dateLevel(x = ",
                                          groupBy_var_now,
                                          ", level = '",
                                          groupBy_option_now,
                                          "')",
                                          sep="")
  groupBy_text                   <- paste(groupBy_text,
                                          x_temp,
                                          sep = sep)
  sep                            <- ", "
}
groupBy_text                     <- paste(groupBy_text,
                                          ")",
                                          sep="")

aggregation_text                 <- "list("
sep                              <- ""
for (i in 1:length(aggregation_var)) {
  aggregation_var_now            <- aggregation_var[i]
  aggregation_level_now          <- aggregation_level[i]
  aggregation_newVar_now         <- aggregation_newVar[i]
  aggregation_aggregation_now    <- aggregation_aggregation[i]
  
  x_temp                         <- paste(aggregation_newVar_now,
                                          " = muRx_aggregation(x = ",
                                          aggregation_var_now,
                                          ", aggregation = '",
                                          aggregation_aggregation_now,
                                          "', level = '",
                                          aggregation_level_now,
                                          "')",
                                          sep="")
  aggregation_text               <- paste(aggregation_text,
                                          x_temp,
                                          sep = sep)
  sep                            <- ", "
}
aggregation_text                 <- paste(aggregation_text,
                                          ")",
                                          sep="")

x_temp                           <- paste("dataworking[, ",
                                          aggregation_text,
                                          ", ",
                                          groupBy_text,
                                          "]",
                                          sep="")
df_rolledUp                      <- eval(parse(text = x_temp))

n_index                          <- which(aggregation_aggregation == "PERCENT")
if (length(n_index)) {
  percent_text                   <- "list("
  sep                            <- ""
  for (i in n_index) {
    aggregation_newVar_now       <- aggregation_newVar[i]
    
    x_temp                       <- paste("muRx_percent(x = ",
                                          aggregation_newVar_now,
                                          ")",
                                          sep = "")
    percent_text                 <- paste(percent_text,
                                          x_temp,
                                          sep = sep)
    sep                          <- ", "
  }
  percent_text                   <- paste(percent_text,
                                          ")",
                                          sep = "")
  
  df_rolledUp                    <- eval(parse(text = paste("df_rolledUp[, c('",
                                                            paste(aggregation_newVar[n_index],
                                                                  collapse = "', '"),
                                                            "') := ",
                                                            percent_text,
                                                            "]",
                                                            sep = "")))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#calls the useDateFunction to format date variables into the original format 
#------------------------------------------------------------------------------- 
df_rolledUp                       <- useDateFormat(c_path_in = c_path_in,
                                                   x = df_rolledUp)
#------------------------------------------------------------------------------- 



#-------------------------------------------------------------------------------
# write the output csv
#-------------------------------------------------------------------------------
write.csv(df_rolledUp,
          paste(c_path_out, "/", c_dataset_new, ".csv", sep=""),
          row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# some change for job automation
#-------------------------------------------------------------------------------
dataset_name                   <- c_dataset_new
input_path                     <- c_path_out
output_path                    <- c_path_out

source(paste(rcodePath, "/application_setup/datasetProperties.R", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x = "ROLLUP_COMPLETED",
      file = paste(c_path_out, "/ROLLUP_COMPLETED.txt", sep=""))
#-------------------------------------------------------------------------------
