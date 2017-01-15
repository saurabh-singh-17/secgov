#=================================================================================
#Sample Parameters 
#=================================================================================
# nrow <- '524'
# outputpath <- 'C:/Users/nida.arif/MRx/r/sampling_check-2-Sep-2014-15-36-00/1/randomSampling'
# power <- '0.8'
# meandiff <- '10744825'
# stddev <- '19744825.307919'
# significance <- '0.05'
# sampling_type<-'one sample test'


#=================================================================================
#parameter play
#=================================================================================
c_path_out <- output_path
n_power    <- as.numeric(power)
n_sig      <- as.numeric(significance)
n_Meandiff <- as.numeric(meandiff)
n_std      <- as.numeric(stddev)
# n_row      <- as.numeric(nrow)
flag_createSample <- 1
c_var_grp          <- paste("grp", n_grp, "_flag", sep="")
c_grp_flag         <- grp_flag
n_grp           <- as.numeric(n_grp)

if (file.exists(paste(c_path_out, "/samplesize.csv", sep="")))
{
  file.remove((paste(c_path_out, "/samplesize.csv", sep="")))
}

if (file.exists(paste(c_path_out, "/samplesize_completed.txt", sep="")))
{
  file.remove((paste(c_path_out, "/samplesize_completed.txt", sep="")))
}


library(pwr)

#========= Sample Size Calculation=====================================================
test_result             <- NULL
load(paste(input_path,"/dataworking.RData",sep=""))
subset <- TRUE
if(n_grp) {
  subset <- dataworking[,c_var_grp] == c_grp_flag
}
dataworking <- subset(x=dataworking, subset=subset)
n_row<-nrow(dataworking)

if(sampling_type == "One Sample Test") {
  test_result             <- try({pwr.t.test(d=n_Meandiff/n_std,sig.level=n_sig,
                                             power=n_power,type="one.sample")},silent=T)  
} else {
  test_result             <- try({pwr.t.test(d=n_Meandiff/n_std,sig.level=n_sig,
                                             power=n_power,type="two.sample")},silent=T)    
  
}


if(class(test_result)=="try-error")
{
  errorText <- paste("Mean Difference for the suggested standard deviation is too low or too high ",sep="")
  write(errorText,file=paste(c_path_out,"/error.txt",sep=""))
  stop()
}
n_sample_size           <- as.data.frame(ceiling(test_result$n))
colnames(n_sample_size) <- "NTotal"
#===================================================================================

if(n_sample_size[1,"NTotal"]>n_row)
{
  errorText <- paste("Sample size is greater than population size",sep="")
  write(errorText,file=paste(c_path_out,"/error.txt",sep=""))
  stop(errorText)
}
if(!is.na(flag_createSample))
{
  Sample_Size           <- n_sample_size
  write.csv(Sample_Size, paste(c_path_out, "/samplesize.csv", sep=""),
            row.names=F, quote=F)
}

#==================================================================================
# completed txt
#==================================================================================
write("completed", file=paste(c_path_out, "/samplesize_completed", ".txt", sep=""))
#==================================================================================
