#-------------------------------------------------------------------------------
# info : sample parameters
#-------------------------------------------------------------------------------
# input_path <- 'C:/Users/vasanth.mm/MRx/r/vasanth_newvarcreation-30-Oct-2014-14-59-34/3'
# output_path <- 'C:/Users/vasanth.mm/MRx/r/vasanth_newvarcreation-30-Oct-2014-14-59-34/DatasetManipulation/Transpose/1'
# dataset_name <- 'dataworking'
# unique_var <- 'Date'
# unique_level_flag  <- 'true'
# unique_level_vars <- c('Store_Format')
# var_list <- c('Total_Selling_Area')
# prefix <- 't1'
# new_var_name <- 't1'
# new_dataset <- 't1'

c_data_in                        <- dataset_name
c_data_new                       <- new_dataset
c_path_in                        <- input_path
c_path_out                       <- output_path
c_prefix                         <- prefix
c_var_in_by                      <- unique_level_vars
c_var_in_id                      <- unique_var
c_var_in_transpose               <- var_list
c_var_new_rownames               <- new_var_name
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
# libraries required
#-------------------------------------------------------------------------------
library(plyr)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the dataset
#-------------------------------------------------------------------------------
load(paste(c_path_in, "/dataworking.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : muRx_transpose
#-------------------------------------------------------------------------------
muRx_transpose                   <- function(df_data,
                                             c_var_by=NULL,
                                             c_var_id=NULL,
                                             c_var_rownames="muRx_rownames",
                                             c_var_transpose) {
  if (!is.null(c_var_id) & is.null(c_var_by)) {
    if (length(which(na.omit(df_data[,c_var_id]) != "")) != length(which(na.omit(unique(df_data[,c_var_id])) != ""))) {
      stop("ID variable is not unique")
    }
  }
  
  if (is.null(c_var_by)) {
    ret                          <- t(df_data[c_var_transpose])
    ret                          <- as.data.frame(ret, stringsAsFactors=FALSE)
    colnames(ret)                <- df_data[, c_var_id]
    ret[c_var_rownames]          <- c_var_transpose
    ret
    return(ret)
  }
  
  df_unique                      <- unique(dataworking[c_var_by])
  ret                            <- NULL
  for (i in 1:nrow(df_unique)) {
    x_temp                       <- merge(x=df_data,
                                          y=df_unique[i, , drop=FALSE])
    x_temp                       <- muRx_transpose(df_data=x_temp,
                                                   c_var_by=NULL,
                                                   c_var_id=c_var_id,
                                                   c_var_rownames=c_var_new_rownames,
                                                   c_var_transpose=c_var_transpose)
    x_temp                       <- cbind.data.frame(df_unique[rep(i,
                                                                   nrow(x_temp)),
                                                               ,
                                                               drop=FALSE],
                                                     x_temp)
    ret                          <- rbind.fill(ret, x_temp)
  }
  return(ret)  
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing the dataset
#-------------------------------------------------------------------------------
dataworking                      <- useDateFormat(c_path_in = c_path_in,
                                                  x = dataworking)
x_temp                           <- is.na(dataworking[, c_var_in_id]) | dataworking[, c_var_in_id] == ""
n_missing_id                     <- length(which(x_temp))
if (length(which(!x_temp))) {
  dataworking                    <- dataworking[!x_temp, , drop=FALSE]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# transposing the dataset
#-------------------------------------------------------------------------------
df_data_new                      <- muRx_transpose(df_data=dataworking,
                                                   c_var_by=c_var_in_by,
                                                   c_var_id=c_var_in_id,
                                                   c_var_rownames=c_var_new_rownames,
                                                   c_var_transpose=c_var_in_transpose)

x_temp                           <- !(colnames(df_data_new) %in% c(c_var_in_id,
                                                                   c_var_in_by,
                                                                   c_var_new_rownames))
colnames(df_data_new)[x_temp]    <- paste(c_prefix,
                                          "_",
                                          colnames(df_data_new)[x_temp],
                                          sep="")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : resultant dataset
#-------------------------------------------------------------------------------
write.csv(df_data_new,
          paste(c_path_out, "/", c_data_new, ".csv", sep=""),
          row.names=FALSE, quote=TRUE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : transpose properties
#-------------------------------------------------------------------------------
write.csv(data.frame(missing=n_missing_id),
          paste(c_path_out,"/transpose_properties.csv",sep=""),
          row.names = FALSE, quote = FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write("TRANSPOSE", file = paste(c_path_out, "TRANSPOSE_COMPLETED.txt", sep="/"))
#-------------------------------------------------------------------------------