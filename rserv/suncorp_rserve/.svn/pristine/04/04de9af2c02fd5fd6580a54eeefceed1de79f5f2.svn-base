#-------------------------------------------------------------------------------
# parameters required
#-------------------------------------------------------------------------------
# csvname       <- c("geography")
# var_order     <- c("south","north")
# column_name   <- c("level")
# input_path    <- c("C:/Users/payal.gupta/Mrx/r/pg_test-10-Oct-2013-14-20-24/1")
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# do whatever
#-------------------------------------------------------------------------------
data               <- read.csv(paste(input_path, "/", csvname, ".csv", sep=""))
index              <- NULL
for(i in 1:length(var_order))
{
  index            <- c(index, which(data[, column_name] %in% var_order[i]))
}
data               <- data[index, , drop = FALSE]

write.csv(data, file = paste(input_path,"/",csvname,".csv",sep=""),
          row.names=FALSE, quote=FALSE)
#-------------------------------------------------------------------------------
