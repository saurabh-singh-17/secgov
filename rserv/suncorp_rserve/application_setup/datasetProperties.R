#-------------------------------------------------------------------------------
# comments
#-------------------------------------------------------------------------------
# define size/ncol/nobs/variables OfTheDataset
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/param_datasetProperties.R
# b_clean                        : should the dataset be cleaned
# c_path_in                      : path of input dataset to be added
# c_path_out                     : path of the output from this code
# c_data                         : name of input dataset to be added
# c_extension                    : extension of input dataset to be added
#-------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# parameters required
#------------------------------------------------------------------------------
# b_clean                        : <0 | 1>
# c_path_in                      : <string>
# c_path_out                     : /../<dataset>
# c_data                         : <string>
# c_extension                    : <file_extension>

# b_clean                        <- c("0")
# c_path_in                      <- c("D:/data")
# c_path_out                     <- c("D:/temp")
# c_data                         <- c("dataworking")
# c_extension                    <- c("csv")

if (!exists("b_clean")) {
  b_clean                        <- 0
}
b_clean                          <- as.integer(b_clean)
c_path_in                        <- input_path
c_path_out                       <- output_path
c_data                           <- dataset_name
if (!exists("c_extension")) {
  c_extension                    <- c("csv")
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# parameter play
#------------------------------------------------------------------------------
c_path_file_in_data              <- paste(c_path_in,
                                          "/",
                                          c_data,
                                          ".",
                                          c_extension,
                                          sep="")
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Read the data depending on the file extension
#------------------------------------------------------------------------------
switch(tolower(c_extension),
       tsv = {
         dataworking             <- read.table(file=c_path_file_in_data,
                                               header=TRUE,
                                               sep="\t",
                                               check.names=TRUE,
                                               fill=TRUE,
                                               stringsAsFactors=FALSE)
       },
       csv = {
         dataworking             <- read.csv(file=c_path_file_in_data,
                                             header=TRUE,
                                             stringsAsFactors=FALSE)
       },
       rdata = {
         currentname             <- load(c_path_file_in_data)
         load(c_path_file_in_data)
         eval(parse(text=paste("dataworking <-", currentname)))
         if(currentname != "dataworking") {
           eval(parse(text=paste("rm(",currentname,")",sep="")))
         }
       })
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Keep only alphanumeric characters and _ in the column names
#------------------------------------------------------------------------------
colnames(dataworking)            <- gsub(pattern="[^[:alnum:]_]",
                                         replacement="_",
                                         x=colnames(dataworking),
                                         ignore.case=TRUE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Getting the class of all variables
# Separating them into numeric, string & date 
#------------------------------------------------------------------------------
c_numeric_string                 <- as.character(sapply(dataworking,class))
c_numeric_string                 <- gsub(pattern="logical",
                                         replacement="numeric",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="integer",
                                         replacement="numeric",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="factor",
                                         replacement="string",
                                         x=c_numeric_string)
c_numeric_string                 <- gsub(pattern="character",
                                         replacement="string",
                                         x=c_numeric_string)

n_index_string                   <- which(c_numeric_string == "string")
if (length(n_index_string)) {
  if (b_clean) {
    dataworking[, n_index_string]  <- lapply(dataworking[,
                                                         n_index_string,
                                                         drop = FALSE],
                                             gsub,
                                             pattern = "[,\n\'\"\r]",
                                             replacement = " ")
  }
  x_temp                         <- dataworking[, n_index_string, drop=FALSE]
  x_temp                         <- sapply(x_temp, dateformat)
  n_index_date                   <- which(x_temp != "unknown")
  c_dateFormat                   <- x_temp[n_index_date]
  if (length(n_index_date)) {
    n_index_date                   <- n_index_string[n_index_date]
    c_numeric_string[n_index_date] <- "date"
    if (c_extension != "RData") {
      # saving the date formats for later use
      for (i in names(c_dateFormat)) {
        dataworking[, i]             <- as.Date(x = dataworking[, i],
                                                format = c_dateFormat[i])
        setDateFormat(c_path_out, i, c_dateFormat[i])
      }
    }
  }
}
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Getting the length of all the variable names in the dataset
#------------------------------------------------------------------------------
var_len                          <- sapply(names(dataworking), nchar)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Categorical/Continuous
#------------------------------------------------------------------------------
c_continuous_categorical         <- c_numeric_string
c_continuous_categorical         <- gsub(pattern="numeric",
                                         replacement="continuous",
                                         x=c_continuous_categorical)
c_continuous_categorical         <- gsub(pattern="date",
                                         replacement="continuous",
                                         x=c_continuous_categorical)
c_continuous_categorical         <- gsub(pattern="string",
                                         replacement="categorical",
                                         x=c_continuous_categorical)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Create variable_categorization.csv
#------------------------------------------------------------------------------
df_var_cat                       <- data.frame(colnames(dataworking),
                                               c_continuous_categorical,
                                               0,
                                               c_numeric_string,
                                               0,
                                               "",
                                               stringsAsFactors=FALSE)
colnames(df_var_cat)             <- c("variable",
                                      "variable_type",
                                      "distinctvalues",
                                      "num_str",
                                      "var_len",
                                      "label")

write.csv(df_var_cat,
          paste(c_path_out,
                "/variable_categorization.csv",
                sep=""),
          row.names=FALSE,
          quote=FALSE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Adding row numbers as a column with the name primary_key_1644
#------------------------------------------------------------------------------
dataworking$primary_key_1644     <- 1:nrow(dataworking)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Saving the dataset as dataworking.RData
#------------------------------------------------------------------------------
save(dataworking,
     file=paste(c_path_out,
                "/dataworking.RData",
                sep=""))
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# Creating a dataset with dataset properties
#------------------------------------------------------------------------------
n_file_size                      <- file.info(paste(c_path_out,"/dataworking.RData",sep=""))$size
n_file_size                      <- round(x=n_file_size/1048576, digits=2)

dataset_properties               <- data.frame(file_name=c_data,
                                               no_of_obs=nrow(dataworking),
                                               no_of_vars=ncol(dataworking) - 1,
                                               file_size=n_file_size)
write.csv(dataset_properties,
          file=paste(c_path_out,
                     "/dataset_properties.csv",
                     sep=""),
          quote=FALSE,
          row.names=FALSE)
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# The completed.txt file
#------------------------------------------------------------------------------
write("variable categorization",
      file=paste(c_path_out,
                 "/categorical_gof_completed.txt",
                 sep=""))
#------------------------------------------------------------------------------
