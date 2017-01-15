#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# rm(list=ls())
# c_path_in       <- 'C:/Users/vasanth.mm/MRx/r/vasanth_testing-5-Jun-2014-11-18-45/1'
# c_path_out      <- 'C:/Users/vasanth.mm/MRx/r/vasanth_testing-5-Jun-2014-11-18-45/1/NewVariable/CategoricalCascading/9'
# c_path_in_xml   <- 'C:/Users/vasanth.mm/MRx/r/vasanth_testing-5-Jun-2014-11-18-45/1/NewVariable/CategoricalCascading/9/CascadedGroupsInput.xml'
# c_var_in_new    <- 'cc3 cc4 cc5 cc6 '
# c_delimiter     <- 'No Delimiter|/|_|No Delimiter'
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries required
#-------------------------------------------------------------------------------
library(XML)
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
c_path_in       <- input_path
c_path_out      <- output_path
c_path_in_xml   <- input_xml_path
c_var_in_new    <- newvar_list
c_delimiter     <- delimiter

# hardcoding
c_csv_newvar          <- c('categoricalCascading_viewPane')
c_delimiter           <- unlist(strsplit(x=c_delimiter, split="|", fixed=TRUE))
n_index               <- which(c_delimiter == "No Delimiter")
if (length(n_index)) {
  c_delimiter[n_index] <- ""
}
c_var_in_cc           <- unlist(xmlToList(c_path_in_xml))
c_var_in_cc           <- strsplit(x=c_var_in_cc,  split=" ", fixed=TRUE)
c_var_in_new          <- unlist(strsplit(x=c_var_in_new, split=" ", fixed=TRUE))
c_txt_completed       <- c('CATEGORICAL_CASCADING_COMPLETED')
c_txt_error           <- c('error')
c_txt_warning         <- c('warning')
c_var_key             <- c('primary_key_1644')


c_file_delete <-  c(paste(c_path_out, '/', c_txt_completed, '.txt', sep=""),
                    paste(c_path_out,  '/', c_txt_error,     '.txt', sep=""),
                    paste(c_path_out,  '/', c_txt_warning,   '.txt', sep=""),
                    paste(c_path_out,  '/', c_csv_newvar,    '.csv', sep=""))
c_var_keep    <-  unique(unlist(c_var_in_cc))
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
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# newvarcreation
#-------------------------------------------------------------------------------
c_var_new <- c_var_in_new

for (tempi in 1:length(c_var_in_cc)) {
  c_var_in_new_now <- c_var_in_new[tempi]
  c_var_in_cc_now  <- c_var_in_cc[[tempi]]
  c_delimiter_now  <- c_delimiter[tempi]
  
  df_data_newvar[c_var_in_new_now] <- apply(X=df_data_newvar[c_var_in_cc_now],
                                            MARGIN=1,
                                            FUN=paste,
                                            collapse=c_delimiter_now)
}

df_data_newvar <- subset(x=df_data_newvar, select=c_var_new)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# adding new variables to dataworking
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
dataworking <- cbind.data.frame(dataworking, df_data_newvar)
save(dataworking, file=paste(c_path_in, "/dataworking.RData", sep=""))
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