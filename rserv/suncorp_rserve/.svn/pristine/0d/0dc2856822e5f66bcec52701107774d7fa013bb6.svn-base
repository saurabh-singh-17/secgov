#-------------------------------------------------------------------------------
# parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/dataset_manipuation/subset/<number>/param_subset.R
# c_path_in                      : path of input dataset(dataworking.RData)
# c_path_out                     : path of the output from this code
# c_var_in                       : variable for the subsetted data

# c_type_subset                  : type of subsetting

# c_path_param_filter            : path of parameter for filter
# c_path_code_filter             : path of code for filter

# n_panel                        : number of the selected panel
# c_val_panel                    : values of the selected panel levels

# c_ran_seq                      : random/sequential
# b_n_obs                        : is number of observations selected?
# b_p_obs                        : is percentage of observations selected?
# n_obs_from                     : number of observations
# n_obs_to                       : number of observations
# n_p_obs                        : percentage of observations
# c_bottom_top                   : bottom/top for percentage of observations
# n_obs_random                   : number of observations to randomly select
# n_seed                         : seed to randomly select
# n_p_obs_random                 : percentage of observations to randomly select

# c_data_subset                  : name for the subsetted data
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# c_path_in                      <- /../<dataset>/
# c_path_out                     <- /../<dataset>/dataset_manipuation/subset/<number>/
# c_var_in                       <- <variable>
# 
# c_type_subset                  <- Filter Scenario|Panel Selection|Dataset Order Subset
# 
# c_path_param_filter            <- /../<dataset>/project_setup/sort_and_filter/<scenario>/
# c_path_code_filter             <- /../project_setup/sort_and_filter/sort_and_filter.R
# 
# n_panel                        <- <number>
# c_val_panel                    <- <string>
# 
# c_ran_seq                      <- Random|Sequential
# b_n_obs                        <- 0|1
# b_p_obs                        <- 0|1
# n_obs_from                     <- <number>
# n_obs_to                       <- <number>
# n_p_obs                        <- <number>
# c_bottom_top                   <- bottom|top
# n_obs_random                   <- <number>
# n_seed                         <- <number>
# n_p_obs_random                 <- <number>
# 
# c_data_subset                  <- <string>



# c_path_in                      <- c("D:/data")
# c_path_out                     <- c("D:/temp")
# c_var_in                       <- c("ACV", "sales", "geography")
# 
# c_type_subset                  <- c("ranseq")
# 
# c_path_param_filter            <- c("D:/temp/param_filter.R")
# c_path_code_filter             <- c("D:/code/future - filtering.R")
# 
# n_panel                        <- c()
# c_val_panel                    <- c()
# 
# c_ran_seq                      <- c("ran")
# b_n_obs                        <- c()
# b_p_obs                        <- c()
# n_obs_from                     <- c()
# n_obs_to                       <- c()
# n_p_obs                        <- c()
# c_bottom_top                   <- c()
# n_obs_random                   <- c()
# n_seed                         <- c("45")
# n_p_obs_random                 <- c("50")
# 
# c_data_subset                  <- c("ab")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
if (c_type_subset == 'Filter Scenario') {
  source(file=c_path_param_filter)
  source(file=c_path_code_filter)
}

# as.numeric for n_: and b_: parameters
x_temp                         <- ls(pattern="^(n|b)_")
if (length(x_temp)) {
  for (n_i_temp in 1:length(x_temp)) {
    x_temp_now                 <- x_temp[n_i_temp]
    n_temp                     <- as.numeric(eval(parse(text=x_temp_now)))
    if (length(n_temp) == 0) next
    if (all(is.na(n_temp))) next
    assign(x=x_temp_now, value=n_temp)
  }
}

# Making the "" parameters NULL
a.all <- ls()

for (c.tempi in a.all) {
  
  if (!length(grep(pattern="^(c|n|b|l|x)_", x=c.tempi))) next
  
  x_tempi                      <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi) | x_tempi != "") next
  
  assign(x=c.tempi, value=NULL)
  print(c.tempi)
  
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the dataset
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# subset : filter and sort the dataset
#-------------------------------------------------------------------------------
if (c_type_subset == "Filter Scenario") {
  c_var_keep                     <- c_var_in
  
  dataworking                    <- muRx_filter_sort(df_x=dataworking,
                                                     c_text_filter_dc=c_text_filter_dc,
                                                     c_text_filter_vs=c_text_filter_vs,
                                                     c_text_sort=c_text_sort,
                                                     c_var_date_sort_filter=c_var_date_sort_filter,
                                                     c_var_required=c_var_keep)
  dataworking                    <- dataworking[, c_var_keep, drop=FALSE]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# subset : panel
#-------------------------------------------------------------------------------
if (c_type_subset == "Panel Selection") {
  c_var_panel                  <- paste("grp", n_panel, "_flag", sep="")
  l_index                      <- dataworking[, c_var_panel] %in% c_val_panel
  dataworking                  <- dataworking[l_index, c_var_in, drop=FALSE]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# subset : random
#-------------------------------------------------------------------------------
if (c_type_subset == "Dataset Order Subset") {
  if (c_ran_seq == "Random") {
    if (is.null(n_obs_random)) {
      n_obs_random               <- n_p_obs_random / 100 * nrow(dataworking)
    }
    set.seed(seed=n_seed)
    n_index                      <- sample(x=nrow(dataworking),
                                           size=n_obs_random)
    dataworking                  <- dataworking[n_index, c_var_in, drop=FALSE]
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# subset : sequential
#-------------------------------------------------------------------------------
if (c_type_subset == "Dataset Order Subset") {
  if (c_ran_seq == "Sequential") {
    if (is.null(n_obs_from)) {
      if (c_bottom_top == "Bottom") {
        n_p_obs_from             <- 100 - n_p_obs
        n_p_obs_to               <- 100
      } else if (c_bottom_top == "Top") {
        n_p_obs_from             <- 0
        n_p_obs_to               <- n_p_obs
      }
      n_obs_from                 <- (n_p_obs_from / 100 * nrow(dataworking)) + 1
      n_obs_to                   <- n_p_obs_to / 100 * nrow(dataworking)
    }
    n_index                      <- n_obs_from:n_obs_to
    dataworking                  <- dataworking[n_index, c_var_in, drop=FALSE]
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# formatting the output
#-------------------------------------------------------------------------------
dataworking <- useDateFormat(c_path_in = c_path_in,
                             x = dataworking)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : <dataset>
#-------------------------------------------------------------------------------
write.csv(dataworking,
          paste(c_path_out, "/", c_data_subset, ".csv", sep=""),
          row.names=FALSE, quote=TRUE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="subset completed.txt",
      file=paste(c_path_out, "/completed.txt", sep=""))
#-------------------------------------------------------------------------------