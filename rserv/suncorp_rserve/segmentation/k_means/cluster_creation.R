#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# b_drift                         <- '0'
# b_nomiss                        <- '0'
# b_impute                        <- '0'
# c_path_in                       <- c("D:/data")
# c_path_out                      <- c("D:/temp")
# c_path_seed                     <- ''
# c_seed_replace_method           <- 'Full'
# c_seed_source_type              <- 'current'
# c_val_subset_panel              <- '1_1_1'
# c_var_in_cluster                <- c("black_hispanic", "sales")
# n_converge                      <- ''
# n_maxcluster                    <- '7'
# n_maxiter                       <- '10'
# n_panel                         <- '0'
# n_radius                        <- ''
# n_seed                          <- '12111'
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()

for (c.tempi in a.all) {
  
  x_tempi <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) != 1) next
  if (is.null(x_tempi)) next
  if (x_tempi != "") next
  
  assign(x=c.tempi, value=NULL)
  print(c.tempi)
  
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
# parameters
b_normalize        <- as.integer(b_normalize)
n_panel            <- as.integer(n_panel)
n_maxcluster       <- as.integer(n_maxcluster)
n_maxiter          <- as.integer(n_maxiter)

# hardcoding
c_var_cluster       <- "murx_n_cluster"
c_var_key           <- "primary_key_1644"
c_var_subset_panel  <- NULL
c_csv_model_stats   <- "model_stats"
c_csv_clus_mean     <- "ClusterMeans"
c_csv_clus_mean_bf  <- "ClusterMeans_BasicProf"
c_csv_clus_summ     <- "cluster_summary"
c_csv_data_cluster  <- "datasetview"
c_csv_initial_seed  <- "InitialSeeds"
c_csv_var_stats     <- "VariableStats"
c_rdata_cluster     <- "df_cluster"
c_txt_completed     <- "completed"
c_txt_initial_kmeans_key <- "initial_kmeans_key"

# check and change
if(n_panel) c_var_subset_panel <- paste("grp", n_panel, "_flag", sep="")
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
# function definitions
#-------------------------------------------------------------------------------
sum_of_squares <- function(x) {
  if (class(x) == "data.frame") {
    sum_of_squares <- 0
    for(tempi in 1:ncol(x)) {
      x_temp         <- sum(scale(x=x[, tempi], center=TRUE, scale=FALSE)^2, na.rm=TRUE)
      sum_of_squares <- sum_of_squares + x_temp
    }
  } else {
    sum_of_squares <- sum(scale(x=x, center=TRUE, scale=FALSE)^2, na.rm=TRUE)
  }
  
  return(sum_of_squares)
}

btw_sum_of_squares <- function(x, groups){
  
  size <- as.integer(table(groups))
  
  total_ss    <- sum_of_squares(x)
  within_ss   <- aggregate(x=x, by=list(groups), FUN=sum_of_squares)
  if (ncol(within_ss) > 2) {
    within_ss[, "x"] <- apply(X=within_ss[2:ncol(within_ss)], MARGIN=1, FUN=sum,
                              na.rm=TRUE)
    within_ss <- within_ss[, c(1, ncol(within_ss))]
  }
  between_ss  <- total_ss - sum(within_ss$x)
  
  total_var   <- total_ss / (sum(size) - 1)
  within_var  <- within_ss$x / (size - 1)
  between_var <- abs(total_var - sum(within_var))
  
  total_sd    <- sqrt(total_var)
  within_sd   <- sqrt(within_var)
  between_sd  <- abs(total_sd - sum(within_sd))
  
  ret         <- list(total_ss=total_ss, within_ss=within_ss$x,
                      between_ss=between_ss, total_var=total_var, 
                      within_var=within_var, between_var=between_var, 
                      total_sd=total_sd, within_sd=within_sd, between_sd=between_sd,
                      group=within_ss$Group.1, size=size)
  
  return(ret)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# preparing the data
#-------------------------------------------------------------------------------
load(file=paste(c_path_in, "/dataworking.RData", sep=""))

subset <- TRUE
if(n_panel) {
  subset <- dataworking[, c_var_subset_panel] == c_val_subset_panel
}
df_data   <- subset(x=dataworking, subset=subset, select=c(c_var_in_cluster, c_var_key))
if(b_normalize) {
  for(tempi in 1:length(c_var_in_cluster)) {
    c_var_in_cluster_now         <- c_var_in_cluster[tempi]
    df_data[, c_var_in_cluster_now] <- scale(x=df_data[, c_var_in_cluster_now])
  }
}
df_data   <- na.omit(df_data)
n_var_key <- df_data[, c_var_key]
df_data   <- df_data[, c_var_in_cluster]
rm("dataworking")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# error check
#-------------------------------------------------------------------------------
if(nrow(df_data) < n_maxcluster) {
  c_error  <- paste("Number of observations in the dataset is ", nrow(df_data), 
                    ". Number of observations should be >= ",
                    n_maxcluster, ".", sep="")
  c_status <- "Error check."
  
  cat(c_error, sep="\n", append=T,
      file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_error)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# generating the initial K Means
#-------------------------------------------------------------------------------
if (c_seed_source_type == "current") {
  df_seed                        <- df_data
} else if (c_seed_source_type == "different") {
  load(paste(c_path_seed,
             "/dataworking.RData",
             sep=""))
  df_seed                        <- dataworking
  rm("dataworking")
} else if (c_seed_source_type == "kmeans") {
  load(paste(c_path_seed,
             "/df_initial_kmeans.RData",
             sep=""))
  df_seed                       <- df_initial_kmeans
  rm("df_initial_kmeans")
} else if (c_seed_source_type == "agglomerative") {
  library(reshape)
  df_seed                        <- read.csv(paste(c_path_seed,
                                                   "/ClusterMeans.csv",
                                                   sep=""),
                                             stringsAsFactors=FALSE)
  df_seed                        <- df_seed[, c("variable", "cluster", "Mean")]
  df_seed                        <- cast(data=df_seed,
                                         formula="cluster ~ variable",
                                         value="Mean")
}

x_temp                           <- which(!(c_var_in_cluster %in% colnames(df_seed)))
if (length(x_temp)) {
  if (length(x_temp) > 1) {
    c_error  <- paste("The variables ",
                      paste(c_var_in_cluster[x_temp],
                            collapse=", "),
                      " are not present in the seed dataset.",
                      sep="")
  } else {
    c_error  <- paste("The variable ",
                      c_var_in_cluster[x_temp],
                      " is not present in the seed dataset.",
                      sep="")
  }
  
  c_status <- "Error check."
  
  cat(c_error, sep="\n", append=T,
      file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_error)
}

df_seed                          <- na.omit(df_seed[, c_var_in_cluster])
if(nrow(df_seed) < n_maxcluster) {
  c_error  <- paste("Number of observations in the seed dataset is ",
                    nrow(df_seed), ". Number of observations should be >= ",
                    n_maxcluster, ".", sep="")
  c_status <- "Error check."
  
  cat(c_error, sep="\n", append=T,
      file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_error)
}

if(length(n_seed)) set.seed(n_seed)
x_temp                           <- sample(x=1:nrow(df_seed),
                                           size=n_maxcluster,
                                           replace=FALSE)
df_initial_kmeans                <- df_seed[x_temp, ]
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# error check
#-------------------------------------------------------------------------------
if(nrow(df_initial_kmeans) > nrow(unique(df_initial_kmeans))) {
  c_error  <- "Initial cluster seeds are not distinct"
  c_status <- "Error check."
  
  cat(c_error, sep="\n", append=T,
      file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_error)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# clustering the observations
#-------------------------------------------------------------------------------
kmeans_clus <- kmeans(x=df_data,
                      centers=df_initial_kmeans,
                      iter.max=n_maxiter)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# saving the cluster variable
#-------------------------------------------------------------------------------
df_cluster <- data.frame(kmeans_clus$cluster, n_var_key)
colnames(df_cluster) <- c(c_var_cluster, c_var_key)

save(df_cluster,
     file=paste(c_path_out, "/", c_rdata_cluster, ".RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : initial kmeans 
#-------------------------------------------------------------------------------
save(df_initial_kmeans,
     file=paste(c_path_out, "/df_initial_kmeans.RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : cluster means
#-------------------------------------------------------------------------------
x_temp       <- as.data.frame(kmeans_clus$centers)
df_clus_mean <- cbind.data.frame(Cluster=rownames(x_temp), x_temp)

write.csv(df_clus_mean,
          paste(c_path_out,"/", c_csv_clus_mean, ".csv",sep=""),
          quote=FALSE, row.names=FALSE)
write.csv(df_clus_mean,
          paste(c_path_out,"/", c_csv_clus_mean_bf, ".csv",sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : cluster summary
#-------------------------------------------------------------------------------
df_clus_summ <- data.frame(Cluster=1:n_maxcluster,
                           Freq=kmeans_clus$size)
df_clus_summ["cumulative_frequency"] <- Reduce(f=sum, x=df_clus_summ[, "Freq"],
                                               accumulate=TRUE)

write.csv(df_clus_summ,
          paste(c_path_out,"/", c_csv_clus_summ, ".csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : initial seed
#-------------------------------------------------------------------------------
df_initial_seed <- data.frame(Clusters=1:n_maxcluster,
                              df_initial_kmeans)

write.csv(df_initial_seed,
          paste(c_path_out,"/", c_csv_initial_seed, ".csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : variable stats & model stats
#-------------------------------------------------------------------------------
sum_of_squares                   <- function(x) {
  sum(scale(x, scale = FALSE)^2)
}
n_var_frequency                  <- sapply(X=df_data,
                                           FUN=length)
n_ss                             <- sapply(X=df_data,
                                           FUN=sum_of_squares)
n_var                            <- n_ss / (n_var_frequency - 1)
n_sd                             <- sqrt(n_var)
n_wc_ss                          <- aggregate(x=df_data,
                                              by=list(kmeans_clus$cluster),
                                              FUN=sum_of_squares)
n_wc_ss                          <- as.list(n_wc_ss[2:ncol(n_wc_ss)])
n_cluster_frequency              <- as.integer(table(kmeans_clus$cluster))
n_wc_var                         <- lapply(X=n_wc_ss,
                                           FUN=function(x) x / (n_cluster_frequency - 1))
n_wc_sd                          <- lapply(X=n_wc_var,
                                           FUN=sqrt)
n_pwc_var                        <- sapply(X=n_wc_var,
                                           FUN=weighted.mean,
                                           w=n_cluster_frequency,na.rm=TRUE)
n_pwc_sd                         <- sqrt(n_pwc_var)
n_rsq                            <- NULL
n_rsq_ratio                      <- NULL

for (tempi in 1:length(c_var_in_cluster)) {
  c_var_in_cluster_now           <- c_var_in_cluster[tempi]
  x_temp                         <- 1 - (sum(n_wc_ss[[c_var_in_cluster_now]]) / n_ss[tempi])
  n_rsq                          <- c(n_rsq, x_temp)
  n_rsq_ratio                    <- c(n_rsq_ratio, (x_temp / (1 - x_temp)))
}

n_wmean_var                      <- weighted.mean(x=n_var,
                                                  w=n_var_frequency)
n_wmean_pwc_var                  <- sqrt(weighted.mean(x=n_pwc_var,
                                                       w=n_var_frequency))
n_wmean_sd                       <- sqrt(n_wmean_var)
n_wmean_pwc_sd                   <- sqrt(n_wmean_pwc_var)
n_wmean_rsq                      <- weighted.mean(x=n_rsq,
                                                  w=n_var_frequency,na.rm=TRUE)
n_wmean_rsq_ratio                <- weighted.mean(x=n_rsq_ratio,
                                                  w=n_var_frequency,na.rm=TRUE)

df_var_stats                     <- data.frame(Variable=c(c_var_in_cluster,
                                                          "OVER-ALL"),
                                               TotStd=c(n_sd,
                                                        n_wmean_sd),
                                               WithinStd=c(n_pwc_sd,
                                                           n_wmean_pwc_sd),
                                               RSquare=c(n_rsq,
                                                         n_wmean_rsq),
                                               RSqRatio=c(n_rsq_ratio,
                                                          n_wmean_rsq_ratio),
                                               stringsAsFactors=FALSE)

df_model_stats                   <- data.frame(Label=c("Minimum Distance Between Initial Seeds",
                                                       "Total STD",
                                                       "Within STD",
                                                       "R-Square",
                                                       "RSQ/(1-RSQ)",
                                                       "Total_variance",
                                                       "Within_variance"),
                                               Value=c(min(dist(x=df_initial_kmeans)),
                                                       n_wmean_sd,
                                                       n_wmean_pwc_sd,
                                                       n_wmean_rsq,
                                                       n_wmean_rsq_ratio,
                                                       n_wmean_var,
                                                       n_wmean_pwc_var),
                                               stringsAsFactors=FALSE)

write.csv(df_model_stats,
          paste(c_path_out,"/", c_csv_model_stats, ".csv",sep=""),
          quote=FALSE, row.names=FALSE)

write.csv(df_var_stats,
          paste(c_path_out,"/", c_csv_var_stats, ".csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : data cluster (for cluster means chart)
#-------------------------------------------------------------------------------
x_temp <- ls(pattern="^df_")
x_temp <- x_temp[-which(x_temp %in% c("df_cluster"))]
rm(list=x_temp)

load(file=paste(c_path_in, "/dataworking.RData", sep=""))
colnames(df_cluster)[1] <- "cluster_variable"
df_data_cluster <- merge(x=dataworking, y=df_cluster, by=c_var_key, all.x=TRUE)

write.csv(df_data_cluster,
          paste(c_path_out,"/", c_csv_data_cluster, ".csv", sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------
