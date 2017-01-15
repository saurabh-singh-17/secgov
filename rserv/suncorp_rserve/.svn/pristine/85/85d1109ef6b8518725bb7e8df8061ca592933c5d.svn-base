#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# c_path_in          <- "D:/data"
# c_path_out         <- "D:/temp"
# 
# n_panel            <- 0
# c_val_subset_panel <- "1_1_1"
# 
# c_var_in_cluster   <- c("Total_Selling_Area", "sales")
# c_var_in_id        <- c("Date")
# 
# c_clus_method      <- c("average")
# # "ward", "single", "complete", "average", "mcquitty", "median" or "centroid"
# b_dendrogram       <- 0
# b_nosquare         <- 1
# b_standardize      <- 1
# l_run_cluster      <- "true"
# 
# n_cluster          <- 4
# n_last             <- 15
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Making the "" parameters NULL
#-------------------------------------------------------------------------------
a.all <- ls()

for (c.tempi in a.all) {
  
  x_tempi <- eval(parse(text=c.tempi))
  
  if (class(x_tempi) != "character") next  
  if (length(x_tempi) > 1) next
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
b_dendrogram       <- as.integer(b_dendrogram)
b_nosquare         <- as.integer(b_nosquare)
b_standardize      <- as.integer(b_standardize)
l_run_cluster      <- as.logical(l_run_cluster)
n_cluster          <- as.integer(n_cluster)
n_panel            <- as.integer(n_panel)

# hardcoding
c_dist_method       <- "euclidean"
# "euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski"
c_var_key           <- "primary_key_1644"
c_var_cluster       <- "murx_n_cluster"
c_var_subset_panel  <- NULL
c_jpeg_dendrogram   <- "tree"
n_width_dendrogram  <- 1000
n_height_dendrogram <- 1000
c_xlab_dendrogram   <- "Name of Observation or Cluster"
c_ylab_dendrogram   <- "Distance"
c_csv_clus_hist     <- "ClusterHistory"
c_csv_clus_mean     <- "ClusterMeans"
c_csv_clus_summ     <- "cluster_summary"
c_csv_var_stats     <- "VariableStats"
c_csv_ccc           <- "ccc"
c_rdata_cluster     <- "df_cluster"
c_csv_pseudot2      <- "PseudoTSq"
c_txt_completed     <- "completed"

if (n_panel) c_var_subset_panel <- paste("grp", n_panel, "_flag", sep="")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function : to calculate mean, sd, skewness, kurtosis & bimodality
#-------------------------------------------------------------------------------
muRx_stats <- function(x, weight=NULL) {
  # skewness & kurtosis formula taken from http://support.sas.com/documentation/cdl/en/procstat/63104/HTML/default/viewer.htm#procstat_univariate_sect026.htm
  # bimodality formula taken from http://support.sas.com/documentation/cdl/en/statug/63347/HTML/default/viewer.htm#statug_cluster_sect013.htm
  n <- length(which(!is.na(x)))
  
  if (n == 0) {
    stop("0 non missing values")
  }
  
  if(!is.null(weight) & (length(weight) != length(x))) {
    stop("weight & x should be vectors of same length")
  }
  
  term1 <- (n * (n + 1)) / ((n - 1) * (n - 2) * (n - 3))
  term2 <- ((3 * (n - 1)^2) / ((n - 2) * (n - 3)))
  mean  <- mean(x, na.rm=TRUE)
  sd    <- sd(x, na.rm=TRUE)
  
  if (is.null(weight)) {
    skewness <- (n * sum(((x - mean) / sd)^3,na.rm=TRUE)) / ((n - 1) * (n - 2))
    kurtosis <- term1 * sum(((x - mean) / sd)^4,na.rm=TRUE) - term2
  } else {
    skewness <- (n * sum(weight^(3/2) * ((x - mean) / sd)^3,na.rm=TRUE)) / ((n - 1) * (n - 2))
    kurtosis <- term1 * sum(weight^2 * ((x - mean) / sd)^4,na.rm=TRUE) - term2
  }
  bimodality <- (skewness^2 + 1) / (kurtosis + term2)
  
  return(c(mean=mean, sd=sd, skewness=skewness, kurtosis=kurtosis,
           bimodality=bimodality))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries required
#-------------------------------------------------------------------------------
library(reshape)  # melt() cast()
library(NbClust)  # NbClust()
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# delete unwanted files
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  c_path_file_unwanted <- list.files(path=c_path_out, full.names=TRUE, all.files=TRUE,
                                     recursive=TRUE, include.dirs=FALSE)
  c_file_wanted        <- c("param_cluster_creation.R", "code_cluster_creation.R")
  c_path_file_wanted   <- paste(c_path_out, "/", c_file_wanted, sep="")
  l_path_file_unwanted <- !(c_path_file_unwanted %in% c_path_file_wanted)
  c_path_file_unwanted <- c_path_file_unwanted[l_path_file_unwanted]
  
  if(length(c_path_file_unwanted)) unlink(x=c_path_file_unwanted)
} else {
  c_path_file_unwanted <- c(paste(c_path_out,"/", c_csv_clus_mean, ".csv",sep=""),
                            paste(c_path_out, "/", c_rdata_cluster, ".RData", sep=""),
                            paste(c_path_out,"/", c_csv_clus_summ, ".csv",sep=""),
                            paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
  
  if(length(c_path_file_unwanted)) unlink(x=c_path_file_unwanted)
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
df_data <- subset(x=dataworking, subset=subset, select=c(c_var_in_cluster))
n_key   <- dataworking[subset, c_var_key]

c_val_id <- NULL
if(!is.null(c_var_in_id)) {
  c_val_id <- as.character(dataworking[subset, c_var_in_id])
  if (length(c_val_id) != length(unique(c_val_id))) {
    c_error <- "The ID variable does not have unique values"
    
    cat(c_status, c_error, sep="\n", append=T,
        file=paste(c_path_out, "/error.txt", sep=""))
    stop(c_error)
  }
}

# Checking whether any cluster variable is having all values as missing
error_var_final <- NULL
n_obs_dataworking <- nrow(dataworking)

for (i in 1:length(c_var_in_cluster)) {
  n_index <- dataworking[, c_var_in_cluster[i]] == ""
  x_temp  <- is.na(dataworking[,c_var_in_cluster[i]])
  n_index <- which(n_index | x_temp)
  n_invalid_obs <- length(n_index)
  
  if (n_invalid_obs == n_obs_dataworking) {
    error_var_final <- c(error_var_final, c_var_in_cluster[i])
  }
}

if (length(error_var_final)){
  error_text <- paste("The variable(s) ", 
                      paste(error_var_final,
                            collapse= ", "),
                      " have all values missing. Please deselect them.",
                      sep="")
  write(error_text, paste(c_path_out,"/error.txt",sep=""))
  stop(error_text)
}

rm("dataworking")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# error check
#-------------------------------------------------------------------------------
if(nrow(df_data) < 2 | nrow(df_data) > 65535) {
  c_error <- paste("The number of observations(N) is ",
                   nrow(df_data),
                   ". Hence cannot perform clustering. Expecting 2 <= N <= 65535.",
                   sep="")
  cat(c_error, sep="\n", append=T,
      file=paste(c_path_out, "/error.txt", sep=""))
  stop(c_error)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# clustering the observations (or) reusing it
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  # calculating the distance
  if(b_standardize) {
    for(tempi in 1:ncol(df_data)) {
      df_data[, tempi] <- scale(x=df_data[, tempi])
    }
  }
  
  if (!is.null(c_var_in_id)) {
    rownames(df_data) <- c_val_id
  }
  
  dist_dist <- dist(x=df_data, method=c_dist_method)
  
  if(!b_nosquare) {
    dist_dist <- dist_dist^2
  }
  
  # clustering the observations
  hclust_clus <- try(hclust(d=dist_dist, method=c_clus_method),silent=TRUE)
  if(class(hclust_clus)=="try-error")
  {
    c_message <- as.character(hclust_clus)
    if(grepl(pattern = "NA/NaN/Inf in foreign function call (arg 11)",
             x = c_message,
             fixed = TRUE))
    {
      c_message <- "Distance between certain observations cannot be calculated. Treat the missing values in the selected variables and then continue."
      write(c_message,file=paste(c_path_out, "/error.txt", sep=""))
      stop(c_message)
    } else {
      write(c_message,file=paste(c_path_out, "/error.txt", sep=""))
      stop(c_message)
    }
  }
  save(hclust_clus, file=paste(c_path_out, "/hclust_clus.RData", sep=""))
} else {
  load(file=paste(c_path_out, "/hclust_clus.RData", sep=""))
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# if the data has been standardized, load the original data
#-------------------------------------------------------------------------------
if (b_standardize) {
  load(file=paste(c_path_in, "/dataworking.RData", sep=""))
  
  subset <- TRUE
  if(n_panel) {
    subset <- dataworking[, c_var_subset_panel] == c_val_subset_panel
  }
  df_data <- subset(x=dataworking, subset=subset, select=c(c_var_in_cluster))
  rm("dataworking")
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 1 : dendrogram
#-------------------------------------------------------------------------------
if (b_dendrogram) {
  jpeg(filename=paste(c_path_out, "/", c_jpeg_dendrogram, ".jpeg", sep=""),
       width=n_width_dendrogram,
       height=n_height_dendrogram)
  plot(x=hclust_clus,
       hang=-1,
       xlab=c_xlab_dendrogram,
       ylab=c_ylab_dendrogram)
  dev.off()
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 2 : cluster history
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  f <- function(x) {
    n_index_neg                  <- which(x < 0)
    n_index_pos                  <- which(x > 0)
    if (length(n_index_neg)) {
      if (!is.null(c_var_in_id)) {
        x_temp                   <- -1 * x[n_index_neg]
        x_temp                   <- hclust_clus$labels[x_temp]
      } else {
        x_temp                   <- as.numeric(x[n_index_neg])
        x_temp                   <- paste("OB",
                                          as.character(-1 * x_temp),
                                          sep="")
      }
      x[n_index_neg]             <- x_temp
    }
    if (length(n_index_pos)) {
      x_temp                     <- as.numeric(x[n_index_pos])
      x_temp                     <- paste("CL",
                                          as.character(length(x) + 1 - x_temp),
                                          sep="")
      x[n_index_pos]             <- x_temp
    }
    return(x)
  }
  
  x_temp                         <- as.data.frame(hclust_clus$merge)
  f2                             <- function(x_temp) {
    freq                           <- NULL
    for(tempi in 1:nrow(x_temp)) {
      n_value_current              <- as.numeric(x_temp[tempi, ])
      n_temp                       <- 0
      for(tempj in 1:2) {
        if(n_value_current[tempj] < 0) {
          n_temp                   <- n_temp + 1
        } else {
          n_temp                   <- n_temp + freq[n_value_current[tempj]]
        }
      }
      freq                         <- c(freq, n_temp)
    }
    return(freq)
  }
  
  freq                           <- f2(x_temp)
  x_temp                         <- sapply(x_temp, f)
  colnames(x_temp)               <- c("ID1", "ID2")
  df_clus_hist                   <- data.frame(NumberOfClusters=(nrow(x_temp):1),
                                               x_temp,
                                               FreqOfNewCluster=freq,
                                               Distance=hclust_clus$height)
  
  write.csv(df_clus_hist,
            paste(c_path_out,"/", c_csv_clus_hist, ".csv",sep=""),
            row.names=FALSE, quote=FALSE)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 3 : cluster means
#-------------------------------------------------------------------------------
df_data$murx_cluster <- cutree(tree=hclust_clus, k=n_cluster)

c_fun        <- c("length", "mean", "sd", "min", "max")
c_name_col   <- c("N", "Mean", "Std_Dev", "Minimum", "Maximum")
df_clus_mean <- NULL

for(tempi in 1:length(c_fun)) {
  if (c_fun[tempi]=="length") {
    x_temp <- aggregate(x=df_data[c_var_in_cluster],
                        by=list(df_data$murx_cluster),
                        FUN=c_fun[tempi])
  } else {
    x_temp <- aggregate(x=df_data[c_var_in_cluster],
                        by=list(df_data$murx_cluster),
                        FUN=c_fun[tempi],na.rm=TRUE)
  }
  x_temp$murx_name_col <- c_name_col[tempi]
  df_clus_mean <- rbind(df_clus_mean, x_temp)
}
colnames(df_clus_mean)[1] <- "cluster"

df_clus_mean <- melt(data=df_clus_mean, id.vars=c("cluster", "murx_name_col"))
x_temp <- which(sapply(df_clus_mean, class) == "factor")
if (length(x_temp)) {
  for (i in x_temp) {
    df_clus_mean[, i] <- as.character(df_clus_mean[, i])
  }
}

df_clus_mean <- cast(data=df_clus_mean, formula=cluster + variable ~ murx_name_col)
df_clus_mean <- df_clus_mean[, c("variable", "cluster", "N", "Mean","Std_Dev",
                                 "Minimum", "Maximum")]

write.csv(df_clus_mean,
          paste(c_path_out,"/", c_csv_clus_mean, ".csv",sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : saving the cluster variable
#-------------------------------------------------------------------------------
df_cluster <- data.frame(df_data$murx_cluster, n_key)
colnames(df_cluster) <- c(c_var_cluster, c_var_key)

save(df_cluster,
     file=paste(c_path_out, "/", c_rdata_cluster, ".RData", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 4 : cluster summary
#-------------------------------------------------------------------------------
df_clus_summ <- as.data.frame(table(df_data$murx_cluster))
colnames(df_clus_summ) <- c("CLUSTER", "Frequency")
df_clus_summ$Percent <- (df_clus_summ$Frequency / sum(df_clus_summ$Frequency)) * 100
df_clus_summ$CumFrequency <- Reduce(f=sum, x=df_clus_summ$Frequency, accumulate=T)
df_clus_summ$CumPercent <- Reduce(f=sum, x=df_clus_summ$Percent, accumulate=T)

write.csv(df_clus_summ,
          paste(c_path_out,"/", c_csv_clus_summ, ".csv",sep=""),
          quote=FALSE, row.names=FALSE)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 5 : variable statistics
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  df_var_stats                   <- sapply(X=df_data[c_var_in_cluster],
                                           FUN=muRx_stats)
  df_var_stats                   <- data.frame(t(df_var_stats))
  colnames(df_var_stats)         <- c("Mean", "StdDev", "Skewness", "Kurtosis",
                                      "Bimodality")
  df_var_stats$Variable          <- rownames(df_var_stats)
  
  write.csv(df_var_stats,
            paste(c_path_out,"/", c_csv_var_stats, ".csv",sep=""),
            quote=FALSE, row.names=FALSE)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 6 : ccc
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  nbclust_ccc      <- try(NbClust(data=df_data[c_var_in_cluster],
                                  distance=c_dist_method,
                                  method=c_clus_method,
                                  index="ccc"),
                          silent=TRUE)
  
  if(class(nbclust_ccc) == "try-error") {
    c_warning <- as.character(nbclust_ccc)
    c_status  <- "Error in calculating ccc."
    cat(c_status, c_warning, sep="\n", append=T,
        file=paste(c_path_out, "/warning.txt", sep=""))
  } else {
    df_ccc           <- nbclust_ccc$All.index
    colnames(df_ccc) <- c("NumberOfClusters", "CubicClusCrit")
    
    write.csv(df_ccc,
              paste(c_path_out,"/", c_csv_ccc, ".csv",sep=""),
              quote=FALSE, row.names=FALSE)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output 7 : pseudo t squared
#-------------------------------------------------------------------------------
if (l_run_cluster) {
  nbclust_pseudot2      <- try(NbClust(data=df_data[c_var_in_cluster],
                                       distance=c_dist_method,
                                       method=c_clus_method,
                                       index="pseudot2"),
                               silent=TRUE)
  
  if(class(nbclust_pseudot2) == "try-error") {
    c_warning <- as.character(nbclust_pseudot2)
    c_status  <- "Error in calculating pseudo t squared."
    cat(c_status, c_warning, sep="\n", append=T,
        file=paste(c_path_out, "/warning.txt", sep=""))
  } else {
    df_pseudot2           <- nbclust_pseudot2$All.index
    colnames(df_pseudot2) <- c("NumberOfClusters","PseudoTSq")
    
    write.csv(df_pseudot2,
              paste(c_path_out,"/", c_csv_pseudot2, ".csv",sep=""),
              quote=FALSE, row.names=FALSE)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# completed txt
#-------------------------------------------------------------------------------
write(x=c_txt_completed,
      file=paste(c_path_out, "/", c_txt_completed, ".txt", sep=""))
#-------------------------------------------------------------------------------