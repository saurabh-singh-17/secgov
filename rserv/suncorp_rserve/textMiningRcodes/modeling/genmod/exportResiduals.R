#export files at a given location#

residualStatistics <- read.csv(paste(inputPath,"/ActualvsPredicted.csv",sep=""))
write.csv(residualStatistics,paste(outputPath,"/residuals.csv",sep=""),quote=FALSE,row.names=FALSE)
write.table("Export Residuals Complete",paste(outputPath,"/EXPORT_RESIDUALS_COMPLETED.txt",sep="/"),quote=F,row.names=F,col.names=F)