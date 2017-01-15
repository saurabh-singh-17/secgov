#-------------------------------------------------------------------------------
# info : parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/segmentation/lca/<number>/param_cluster_creation.R
# b_missing_exclude                : should the missing values be excluded?
# c_path_in                        : path of input dataset(dataworking.RData)
# c_path_out                       : path of the output from this code
# c_var_in_lca                     : variable for the subsetted data
# c_val_panel                      : values of the selected panel levels
# n_cluster                        : no of clusters
# n_converge                       : convergence criterion
# n_max_iter                       : no of max iterations
# n_panel                          : number of the selected panel
# n_rerun                          : no of reruns
# n_seed                           : seed to randomly select
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# info : sample parameters
#-------------------------------------------------------------------------------
# b_missing_exclude                <- c("1")
# c_path_in                        <- c("D:/data")
# c_path_out                       <- c("D:/temp")
# c_var_in_lca                     <- c("geography", "channel_1", "Store_Format")
# c_val_panel                      <- c()
# n_cluster                        <- c("5")
# n_converge                       <- c("0.05")
# n_max_iter                       <- c("25")
# n_panel                          <- c("0")
# n_rerun                          <- c("1")
# n_seed                           <- c()

b_missing_exclude                <- c("1")
c_path_in                        <- input_path
c_path_out                       <- output_path
c_var_in_lca                     <- var_lca
c_val_panel                      <- grp_flag
n_cluster                        <- nofclusters
n_converge                       <- converge
n_max_iter                       <- maxiter
n_panel                          <- grp_no
n_rerun                          <- rerun
n_seed                           <- seed
c_txt_error                      <- "error"
c_txt_warning                    <- "warning"
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# delete unwanted files
#-------------------------------------------------------------------------------
c_path_file_unwanted <- list.files(path=c_path_out, full.names=TRUE, all.files=TRUE,
                                   recursive=TRUE, include.dirs=FALSE)
c_file_wanted        <- c("param_cluster_creation.R", "code_cluster_creation.R")
c_path_file_wanted   <- paste(c_path_out, "/", c_file_wanted, sep="")
l_path_file_unwanted <- !(c_path_file_unwanted %in% c_path_file_wanted)
c_path_file_unwanted <- c_path_file_unwanted[l_path_file_unwanted]

if(length(c_path_file_unwanted)) unlink(x=c_path_file_unwanted)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing : ""  --> NULL
#-------------------------------------------------------------------------------
a.all                            <- ls()
for (c.tempi in a.all) {
  x_tempi                        <- eval(parse(text=c.tempi))
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi) | x_tempi != "") next
  assign(x=c.tempi, value=NULL)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing : as.numeric for n_: and b_: parameters
#-------------------------------------------------------------------------------
x_temp                           <- ls(pattern="^(n|b)_")
if (length(x_temp)) {
  for (n_i_temp in 1:length(x_temp)) {
    x_temp_now                   <- x_temp[n_i_temp]
    n_temp                       <- as.numeric(eval(parse(text=x_temp_now)))
    if (length(n_temp) == 0) next
    assign(x=x_temp_now, value=n_temp)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing : parameter play
#-------------------------------------------------------------------------------
c_formula                        <- paste("cbind(",
                                          paste(c_var_in_lca,
                                                collapse=","),
                                          ")~1",
                                          sep="")
c_var_cluster                    <- "murx_n_cluster"
c_var_panel                      <- NULL
c_var_keep                       <- c(c_var_in_lca)
c_var_key                        <- "primary_key_1644"
if (is.null(n_converge)) {
  n_converge                     <- 1e-10
}
if (n_panel) {
  c_var_panel                    <- paste("grp", n_panel, "_flag", sep="")
}
if (is.null(n_seed)) {
  n_seed                         <- sample(x=1000, size=1)
}

# libraries required
library(poLCA)  # poLCA
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the data
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
subset                           <- TRUE
if (n_panel) {
  subset                         <- dataworking[, c_var_panel] == c_val_panel
}
n_key                            <- dataworking[subset, c_var_key]
dataworking                      <- dataworking[subset, c_var_keep, drop=FALSE]
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# recoding levels to 1:n
# initial probability
# check if any variable has only 1 level
#-------------------------------------------------------------------------------
b_error                          <- 0L
b_warning                        <- 0L
c_message                        <- NULL
c_var_in_lca_gt1                 <- NULL
c_var_in_lca_lteq1               <- NULL
list_prob_initial                <- NULL
list_unique                      <- NULL
x_temp                           <- length(c_var_in_lca)
set.seed(n_seed)

for (n_tempi in 1:x_temp) {
  c_var_in_lca_now               <- c_var_in_lca[n_tempi]
  x_temp_now                     <- c_var_in_lca_now
  
  # unique non missing levels of the variable now
  x_unique_now                   <- dataworking[, x_temp_now]
  x_unique_now                   <- na.omit(sort(unique(x_unique_now)))
  x_unique_now                   <- x_unique_now[x_unique_now != ""]
  n_unique_now                   <- length(x_unique_now)
  
  # check if any variable has only 1 level
  if (n_unique_now <= 1) {
    c_var_in_lca_lteq1           <- c(c_var_in_lca_lteq1,
                                      x_temp_now)
    next
  }
  c_var_in_lca_gt1               <- c(c_var_in_lca_gt1,
                                      x_temp_now)
  
  # recoding levels to 1:n
  dataworking[, x_temp_now]      <- match(x=dataworking[, x_temp_now],
                                          table=x_unique_now,
                                          nomatch=NA_integer_)

  # unique values
  list_unique[[x_temp_now]]      <- x_unique_now
  
  # initial probability
  list_prob_initial[[x_temp_now]]<- matrix(data=runif(n_cluster * n_unique_now),
                                           nrow=n_cluster,
                                           ncol=n_unique_now)
  list_prob_initial[[x_temp_now]]<- list_prob_initial[[x_temp_now]] / rowSums(list_prob_initial[[x_temp_now]])
}

if (!all(c_var_in_lca %in% c_var_in_lca_gt1)) {
  c_var_in_lca                   <- c_var_in_lca_gt1
  c_formula                      <- paste("cbind(",
                                          paste(c_var_in_lca,
                                                collapse=","),
                                          ")~1",
                                          sep="")
  dataworking                    <- dataworking[c_var_in_lca]
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# error check
#-------------------------------------------------------------------------------
if (length(c_var_in_lca_lteq1)) {
  b_warning                      <- 1L
  c_message                      <- paste("Eliminated variable(s) ",
                                          paste(c_var_in_lca_lteq1,
                                                collapse=", "),
                                          " with a single level.",
                                          sep="")
}

if (length(c_var_in_lca_gt1) <= 1) {
  b_error                        <- 1L
  c_message                      <- paste(c_message,
                                          "Insufficient variables to proceed.",
                                          sep=" ")
}

if (b_error) {
  write(x=c_message,
        file=paste(c_path_out, "/", c_txt_error, ".txt", sep=""))
  stop(c_message)
}

if (b_warning) {
  write(x=c_message,
        file=paste(c_path_out, "/", c_txt_warning, ".txt", sep=""))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# performing LCA
#-------------------------------------------------------------------------------
poLCA_model                      <- poLCA(formula=as.formula(c_formula),
                                          data=dataworking,
                                          nclass=n_cluster,
                                          maxiter=n_max_iter,
                                          graphs=FALSE,
                                          tol=n_converge,
                                          na.rm=as.logical(b_missing_exclude),
                                          probs.start=list_prob_initial,
                                          nrep=n_rerun,
                                          verbose=FALSE,
                                          calc.se=TRUE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# save : cluster variables
#-------------------------------------------------------------------------------
df_cluster                       <- data.frame(poLCA_model$predclass,
                                               n_key)
colnames(df_cluster)             <- c(c_var_cluster, c_var_key)

save(list=c("df_cluster"),
     file=paste(c_path_out,
                "/df_cluster.RData",
                sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : cluster summary
#-------------------------------------------------------------------------------
df_cluster_summary               <- data.frame(cluster=1:n_cluster)
x_temp                           <- as.data.frame(table(poLCA_model$predclass))
colnames(x_temp)                 <- c("cluster", "nobs")
df_cluster_summary               <- merge(x=df_cluster_summary,
                                          y=x_temp,
                                          all.x=TRUE,
                                          by="cluster")
x_temp                           <- which(is.na(df_cluster_summary$nobs))
if (length(x_temp)) {
  df_cluster_summary[x_temp, "nobs"] <- 0
}

write.csv(df_cluster_summary,
          paste(c_path_out, "/clustersummary.csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : initial seeds
#-------------------------------------------------------------------------------
df_initial_seeds                 <- lapply(X=poLCA_model$probs.start,
                                           FUN=t)
df_initial_seeds                 <- do.call(what=rbind.data.frame,
                                            args=df_initial_seeds)
colnames(df_initial_seeds)       <- paste("prob_cluster_",
                                          1:n_cluster,
                                          sep="")
x_temp                           <- rep(c_var_in_lca,
                                        times=sapply(X=list_unique,
                                                     FUN=length))
df_initial_seeds                 <- data.frame(variable=x_temp,
                                               value=do.call(what=c,
                                                              args=list_unique),
                                               df_initial_seeds,
                                               stringsAsFactors=FALSE)

write.csv(df_initial_seeds,
          paste(c_path_out, "/initialseeds.csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : final seeds
#-------------------------------------------------------------------------------
df_final_seeds                   <- lapply(X=poLCA_model$probs,
                                           FUN=t)
df_final_seeds                   <- do.call(what=rbind.data.frame,
                                            args=df_final_seeds)
colnames(df_final_seeds)         <- paste("prob_cluster_",
                                          1:n_cluster,
                                          sep="")
x_temp                           <- rep(c_var_in_lca,
                                        times=sapply(X=list_unique,
                                                     FUN=length))
df_final_seeds                   <- data.frame(variable=x_temp,
                                               value=do.call(what=c,
                                                             args=list_unique),
                                               df_final_seeds,
                                               stringsAsFactors=FALSE)

write.csv(df_final_seeds,
          paste(c_path_out, "/finalseeds.csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : model stats
#-------------------------------------------------------------------------------
df_model_stats                   <- data.frame(label=c("g_squared",
                                                       "chi_squared",
                                                       "DF",
#                                                        "pvalue_chisq",
                                                       "ll",
#                                                        "ll_difference",
                                                       "seed",
#                                                        "ll2",
                                                       "AIC",
                                                       "BIC",
                                                       "em_iterations",
#                                                        "converged",
                                                       "convergence_cutoff"),
                                               value=c(poLCA_model$Gsq,
                                                       poLCA_model$Chisq,
                                                       poLCA_model$resid.df,
#                                                        0,
                                                       poLCA_model$llik,
#                                                        0,
                                                       n_seed,
#                                                        0,
                                                       poLCA_model$aic,
                                                       poLCA_model$bic,
                                                       poLCA_model$numiter,
#                                                        0,
                                                       n_converge),
                                               stringsAsFactors=FALSE)

write.csv(df_model_stats,
          paste(c_path_out, "/modelstats.csv", sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="SEG>LCA completed",
      file=paste(c_path_out, "/LCA_COMPLETED.txt", sep=""),
      append=FALSE)
#-------------------------------------------------------------------------------
