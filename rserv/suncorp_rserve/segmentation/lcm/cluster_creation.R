#-------------------------------------------------------------------------------
# info : parameters needed
#-------------------------------------------------------------------------------
# /../<dataset>/segmentation/lcm/<number>/<number>/param_cluster_creation.R
# b_missing_exclude                : should the missing values be excluded?
# c_path_in                        : path of input dataset(dataworking.RData)
# c_path_out                       : path of the output from this code
# c_var_in_dependent               : dependent variable
# c_var_in_id                      : id variable
# c_var_in_independent             : independent variable
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
# c_var_in_dependent               <- c("sales")
# c_var_in_id                      <- c("ACV")
# c_var_in_independent             <- c("ACV", "black_hispanic")
# c_val_panel                      <- c()
# n_cluster                        <- c("5")
# n_converge                       <- c("0.05")
# n_max_iter                       <- c("25")
# n_panel                          <- c("0")
# n_rerun                          <- c("1")
# n_seed                           <- c("0435")

b_missing_exclude                <- c("1")
c_file_txt_error                 <- "error.txt"
c_path_in                        <- input_path
c_path_out                       <- output_path
c_var_in_dependent               <- dependent_var
c_var_in_id                      <- id_var
c_var_in_independent             <- independent_var
c_val_panel                      <- grp_flag
n_cluster                        <- nofclusters
n_converge                       <- converge
n_max_iter                       <- maxiter
n_panel                          <- grp_no
n_rerun                          <- rerun
n_seed                           <- seed
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing : delete outputs if present
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
c_var_cluster                    <- "murx_n_cluster"
c_var_panel                      <- NULL
c_var_key                        <- "primary_key_1644"
if (is.null(c_var_in_id)) {
  c_var_in_id                    <- c_var_key
}
if (is.null(n_converge)) {
  n_converge                     <- 1e-06
}
if (n_panel) {
  c_var_panel                    <- paste("grp", n_panel, "_flag", sep="")
}
if (is.null(n_seed)) {
  n_seed                         <- sample(x=1000, size=1)
}
c_var_keep                       <- unique(c(c_var_in_dependent,
                                             c_var_in_independent,
                                             c_var_in_id,
                                             c_var_key))
c_formula                        <- paste(paste(c_var_in_dependent,
                                                collapse=","),
                                          " ~ ",
                                          paste(c_var_in_independent,
                                                collapse=" + "),
                                          "|",
                                          c_var_in_id,
                                          sep="")

# libraries required
library(flexmix)  # flexmix
library(reshape)  # cast melt
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# loading the data
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))
subset                           <- TRUE
if (n_panel) {
  subset                         <- dataworking[, c_var_panel] == c_val_panel
}
dataworking                      <- dataworking[subset, c_var_keep, drop=FALSE]
dataworking                      <- na.omit(dataworking)
n_key                            <- dataworking[, c_var_key]
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# initial prob
#-------------------------------------------------------------------------------
set.seed(n_seed)
x_temp                           <- length(unique(dataworking[, c_var_in_id]))
df_initial_prob                  <- matrix(data=runif(n_cluster * x_temp),
                                           nrow=x_temp,
                                           ncol=n_cluster)
df_initial_prob                  <- df_initial_prob/rowSums(df_initial_prob)
x_temp                           <- unique(dataworking[c_var_in_id])
df_initial_prob                  <- cbind.data.frame(x_temp,
                                                     df_initial_prob,
                                                     stringsAsFactors=FALSE)
x_temp                           <- cbind.data.frame(n_key,
                                                     dataworking[c_var_in_id])
m_initial_prob                   <- merge(x=df_initial_prob,
                                          y=x_temp,
                                          by=c_var_in_id,
                                          all.y=TRUE)
x_temp                           <- order(m_initial_prob[, "n_key"])
m_initial_prob                   <- m_initial_prob[x_temp,
                                                   as.character(1:n_cluster)]
m_initial_prob                   <- as.matrix(m_initial_prob)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# performing LCM
#-------------------------------------------------------------------------------
try_flexmix <- try(expr={
flexmix_model                    <- flexmix(formula=as.formula(c_formula),
                                            data=dataworking,
                                            k=NULL,
                                            cluster=m_initial_prob,
                                            model=FLXMRglm(),
                                            concomitant=FLXPconstant(),
                                            control=list(iter=n_max_iter,
                                                         tol=n_converge),
                                            weights=NULL)
},
silent=TRUE)

if (class(try_flexmix) == "try-error") {
  c_message <- try_flexmix[1]
  l_condition <- grepl(pattern="Error in FLXfit",
                       x=c_message)
  l_condition <- l_condition & grepl(pattern="Log-likelihood:",
                                    x=c_message)
  if (l_condition) {
    c_message <- "Unable to calculate log likelihood for the current variable selection."
    write(x=c_message,
          file=paste(c_path_out, "/", c_file_txt_error, sep=""))
    stop(c_message)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# save : cluster variables
#-------------------------------------------------------------------------------
df_cluster                       <- data.frame(flexmix_model@cluster,
                                               n_key)
colnames(df_cluster)             <- c(c_var_cluster, c_var_key)

save(list=c("df_cluster"),
     file=paste(c_path_out,
                "/df_cluster.RData",
                sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : clustersummary.csv
# output : residual.csv
#-------------------------------------------------------------------------------
x_temp                           <- c("(Intercept)",
                                      c_var_in_independent)
x_temp                           <- paste("model.1_Comp.",
                                          rep(x=1:n_cluster,
                                              each=length(x_temp)),
                                          "_coef.",
                                          rep(x=x_temp,
                                              times=n_cluster),
                                          sep="")
df_cluster_summary               <- FLXgetParameters(object=flexmix_model)
x_temp                           <- names(df_cluster_summary) %in% x_temp
df_cluster_summary               <- as.numeric(df_cluster_summary[x_temp])
x_temp                           <- c("(Intercept)",
                                      c_var_in_independent)
df_cluster_summary               <- data.frame(cluster=rep(x=1:n_cluster,
                                                           each=length(x_temp)),
                                               variable=rep(x=x_temp,
                                                            times=n_cluster),
                                               Estimate=df_cluster_summary)
df_cluster_summary               <- melt(data=df_cluster_summary,
                                         variable_name="label",
                                         id.vars=c("cluster",
                                                   "variable"))
x_temp                           <- which(sapply(df_cluster_summary, class) == "factor")
if (length(x_temp)) {
  for (i in x_temp) {
    df_cluster_summary[, i]      <- as.character(df_cluster_summary[, i])
  }
}
df_cluster_summary               <- cast(data=df_cluster_summary,
                                         formula="label + variable ~ cluster")
df_cluster_summary[, "label"]    <- gsub(pattern="Estimate",
                                         replacement="Beta Estimate",
                                         x=df_cluster_summary[, "label"])
df_cluster_summary[, "label"]    <- gsub(pattern="Std. Error",
                                         replacement="Standard Error",
                                         x=df_cluster_summary[, "label"])
df_cluster_summary[, "label"]    <- paste(df_cluster_summary[, "label"],
                                          df_cluster_summary[, "variable"],
                                          sep=" of ")
df_cluster_summary[, "variable"] <- NULL
colnames(df_cluster_summary)     <- c("label",
                                      paste("cluster_",
                                            1:n_cluster,
                                            sep=""))
x_temp                           <- dataworking[unique(c(c_var_in_dependent,
                                                         c_var_in_id))]
df_residual                      <- data.frame(fitted(flexmix_model),
                                               x_temp,
                                               cluster=flexmix_model@cluster)
for (tempi in 1:n_cluster) {
  c_var_pred_now                 <- paste("Comp.",
                                          tempi,
                                          sep="")
  c_var_resid_now                <- paste("residual.",
                                          tempi,
                                          sep="")
  df_residual[c_var_resid_now]   <- df_residual[c_var_in_dependent] -df_residual[c_var_pred_now]
}
x_temp                           <- paste("residual.",
                                          1:n_cluster,
                                          sep="")
df_cluster_summary               <- rbind.data.frame(c("Number of Observations",
                                                       flexmix_model@size),
                                                     c("Percentage of Observations",
                                                       (flexmix_model@size / sum(flexmix_model@size)) * 100),
                                                     c("Mean of Residuals",
                                                       sapply(X=df_residual[x_temp],
                                                              FUN=mean,
                                                              na.rm=TRUE)),
                                                     c("Standard Deviation of Residuals",
                                                       sapply(X=df_residual[x_temp],
                                                              FUN=sd,
                                                              na.rm=TRUE)),
                                                     df_cluster_summary)
df_residual[, "predicted"]       <- NA
for (tempi in 1:n_cluster) {
  c_var_pred_now                 <- paste("Comp.",
                                          tempi,
                                          sep="")
  x_temp                         <- which(df_residual[, "cluster"] == tempi)
  if (length(x_temp)) {
    df_residual[x_temp, "predicted"] <- df_residual[x_temp, c_var_pred_now]
  }
}
df_residual                      <- df_residual[unique(c(c_var_in_dependent,
                                                         c_var_in_id,
                                                         "predicted",
                                                         "cluster"))]
df_residual[, "residual"]        <- df_residual[, c_var_in_dependent] - df_residual[, "predicted"]

write.csv(df_cluster_summary,
          paste(c_path_out, "/clustersummary.csv", sep=""),
          row.names=FALSE,
          quote=FALSE)
write.csv(df_residual,
          paste(c_path_out, "/residual.csv", sep=""),
          row.names=FALSE,
          quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : variablesummary.csv
#-------------------------------------------------------------------------------
df_variable_summary              <- data.frame(label="mean",
                                               aggregate(x=dataworking[c_var_in_independent],
                                                         by=list(cluster=flexmix_model@cluster),
                                                         FUN=mean,
                                                         na.rm=TRUE),
                                               stringsAsFactors=FALSE)
x_temp                           <- data.frame(label="std",
                                               aggregate(x=dataworking[c_var_in_independent],
                                                         by=list(cluster=flexmix_model@cluster),
                                                         FUN=sd,
                                                         na.rm=TRUE),
                                               stringsAsFactors=FALSE)
df_variable_summary              <- rbind.data.frame(df_variable_summary,
                                                     x_temp)
df_variable_summary              <- melt(data=df_variable_summary,
                                         id.vars=c("label", "cluster"))
df_variable_summary[,"murx_temp"]<- paste(df_variable_summary[, "label"],
                                          "_cluster_",
                                          df_variable_summary[, "cluster"],
                                          sep="")
df_variable_summary[, "label"]   <- NULL
df_variable_summary[, "cluster"] <- NULL
x_temp                           <- which(sapply(df_variable_summary, class) == "factor")
if (length(x_temp)) {
  for (i in x_temp) {
    df_variable_summary[, i]      <- as.character(df_variable_summary[, i])
  }
}
df_variable_summary              <- cast(data=df_variable_summary,
                                         formula=variable ~ murx_temp)

write.csv(df_variable_summary,
          paste(c_path_out, "/variablesummary.csv", sep=""),
          row.names=FALSE,
          quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : initialseeds.csv
#-------------------------------------------------------------------------------
colnames(df_initial_prob)        <- c("id",
                                      paste("prob_cluster_",
                                            1:n_cluster,
                                            sep=""))
write.csv(df_initial_prob,
          paste(c_path_out, "/initialseeds.csv", sep=""),
          row.names=FALSE,
          quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : modelstats.csv
#-------------------------------------------------------------------------------
x_temp                           <- summary(flexmix_model)
df_model_stats                   <- data.frame(label=c("AIC",
                                                       "BIC",
                                                       "Log Likelihood"),
                                               value=c(x_temp@AIC,
                                                       x_temp@BIC,
                                                       x_temp@logLik),
                                               stringsAsFactors=FALSE)

write.csv(df_model_stats,
          paste(c_path_out, "/modelstats.csv", sep=""),
          row.names=FALSE,
          quote=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x="SEG>LCM completed",
      file=paste(c_path_out, "/LCM_COMPLETED.txt", sep=""),
      append=FALSE)
#-------------------------------------------------------------------------------
