x_temp                           <- unlist(strsplit(c_path_muRxDataset, split = "/"))
c_path_out                       <- paste(x_temp[-length(x_temp)], collapse = "/")
file.remove(paste(c_path_out, "/completed.txt", sep = ""))

#-------------------------------------------------------------------------------
# parameters required
#-------------------------------------------------------------------------------
# rm(list = ls())
# c_path_newDataset                <- c("D:/temp/newDataset.RData")
# c_path_muRxDataset               <- c("D:/temp/muRxDataset.RData")
# c_var_key_newDataset             <- c("key")
# c_var_key_muRxDataset            <- c("keey")
# c_var_new                        <- c("newVar")
#-------------------------------------------------------------------------------

c_var_key_newDataset               <- unlist(strsplit(c_var_key_newDataset, split = ","))
c_var_key_muRxDataset              <- unlist(strsplit(c_var_key_muRxDataset, split = ","))
c_var_new                          <- unlist(strsplit(c_var_new, split = ","))

#-------------------------------------------------------------------------------
# input validation
#-------------------------------------------------------------------------------
stopifnot(class(c_path_newDataset) == "character")

stopifnot(class(c_path_muRxDataset) == "character")
stopifnot(class(c_var_key_newDataset) == "character")
stopifnot(class(c_var_key_muRxDataset) == "character")
stopifnot(class(c_var_new) == "character")

stopifnot(length(c_path_newDataset) == 1)
stopifnot(length(c_path_muRxDataset) == 1)
# stopifnot(length(c_var_key_newDataset) >= 1)
# stopifnot(length(c_var_key_muRxDataset) >= 1)
stopifnot(length(c_var_new) >= 1)

stopifnot(file.exists(c_path_newDataset))
stopifnot(file.exists(c_path_muRxDataset))
stopifnot(length(c_var_key_newDataset) == length(c_var_key_muRxDataset))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function     : muRx_readTsv
# description  : read a .tsv file
# purpose      : to be used in muRx_read function
#
# README
# file extension is not case-sensitive
# file extension should be .tsv
# .tsv file should contain headers
#
# INPUT
# file         : character : path of the file which should be read
#
# OUTPUT
# ret          : data.frame : dataset represented by the file which is read
#-------------------------------------------------------------------------------
muRx_readTsv <- function (file) {
  ret <- read.table(file=file,
                    header=TRUE,
                    sep="\t",
                    check.names=TRUE,
                    comment.char="",
                    fill=TRUE,
                    stringsAsFactors=FALSE)
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function     : muRx_readCsv
# description  : read a .csv file
# purpose      : to be used in muRx_read function
#
# README
# file extension is not case-sensitive
# file extension should be .csv
# .csv file should contain headers
#
# INPUT
# file         : character : path of the file which should be read
#
# OUTPUT
# ret          : data.frame : dataset represented by the file which is read
#-------------------------------------------------------------------------------
muRx_readCsv <- function (file) {
  ret <- read.table(file=file,
                    header=TRUE,
                    sep=",",
                    check.names=TRUE,
                    comment.char="",
                    fill=TRUE,
                    stringsAsFactors=FALSE)
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function     : muRx_readRData
# description  : read a .RData file
# purpose      : to be used in muRx_read function
#
# README
# file extension is not case-sensitive
# file extension should be .RData
# .Rdata file should contain only 1 object of class data.frame
#
# INPUT
# file         : character : path of the file which should be read
#
# OUTPUT
# ret          : data.frame : dataset represented by the file which is read
#-------------------------------------------------------------------------------
muRx_readRData <- function (file) {
  envir                 <- new.env()
  ret                   <- load(file = file, envir = envir)
  if (length(ret) != 1 || (length(ret) == 1 && class(get(x = ret, envir = envir)) != "data.frame")) {
    c_message           <- paste("The file ",
                                 file,
                                 " should have ",
                                 "only 1 object of class data.frame.",
                                 sep="")
    stop(c_message, call.=TRUE)
  }
  ret                   <- get(x = ret, envir = envir)
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function     : muRx_read
# description  : read a file
# purpose      : to be used for all file reading in muRx R codes
#
# README
# file extension is not case-sensitive
# file extension should be one of .csv / .rdata / .tsv
# .Rdata file should contain only 1 object of class data.frame
# .csv / .tsv file should contain headers
#
# INPUT
# file         : character : path of the file which should be read
#
# OUTPUT
# ret          : data.frame : contents of the file which is read
#-------------------------------------------------------------------------------
muRx_read                        <- function(file) {
  # check if the file exists
  if (!file.exists(file)) {
    c_message                    <- paste("The file ",
                                          file,
                                          " does not exist.",
                                          sep="")
    stop(c_message, call.=TRUE)
  }
  
  # find the file extension
  c_extension                    <- unlist(x=strsplit(x=file,
                                                      split="\\."))
  c_extension                    <- c_extension[length(c_extension)]
  
  # check if the file extension is supported
  if (!(tolower(c_extension) %in% c("csv", "tsv", "txt", "rdata"))) {
    c_message                    <- paste("The file extension",
                                          c_extension,
                                          " is not supported.",
                                          sep="")
    stop(c_message, call.=TRUE)
  }
  
  # read data from the file based on the file extension
  switch(EXPR=tolower(c_extension),
         csv = {
           ret                   <- muRx_readCsv(file = file)
         },
         rdata = {
           ret                   <- muRx_readRData(file = file)
         },
         tsv = {
           ret                   <- muRx_readTsv(file = file)
         })
  
  # return the data
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# read the two datasets
#-------------------------------------------------------------------------------
df_muRxDataset                   <- muRx_read(file = c_path_muRxDataset)
df_newDataset                    <- muRx_read(file = c_path_newDataset)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# input validation
#-------------------------------------------------------------------------------
stopifnot(!(c_var_new %in% colnames(df_muRxDataset)))
stopifnot(c_var_new %in% colnames(df_newDataset))
if (!(length(c_var_key_muRxDataset) == 0 & length(c_var_key_newDataset) == 0)) {
  stopifnot(all(c_var_key_newDataset %in% colnames(df_newDataset)))
  stopifnot(all(c_var_key_muRxDataset %in% colnames(df_muRxDataset)))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# merge the two datasets
#-------------------------------------------------------------------------------
if (length(c_var_key_muRxDataset) != 0 & length(c_var_key_newDataset) != 0) {
  df_muRxDataset                 <- merge(x = df_muRxDataset,
                                          y = df_newDataset,
                                          by.x = c_var_key_muRxDataset,
                                          by.y = c_var_key_newDataset,
                                          all.x = TRUE)
} else {
  df_muRxDataset                 <- data.frame(df_muRxDataset,
                                               subset(x = df_newDataset,
                                                      select = c_var_new),
                                               stringsAsFactors = FALSE)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# save the muRx dataset
#-------------------------------------------------------------------------------
dataworking                      <- df_muRxDataset
save(dataworking,
     file = c_path_muRxDataset)
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# call datasetProperties.R on the new dataset to get the variable properties
#-------------------------------------------------------------------------------
input_path                       <- c_path_out
output_path                      <- c_path_out
dataset_name                     <- "dataworking"
c_extension                      <- "RData"

source(paste(rcodePath, "/application_setup/datasetProperties.R", sep = ""))

#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x = "completed",
      file = paste(c_path_out, "/completed.txt", sep = ""))
#-------------------------------------------------------------------------------
