
# c_path_in   <-  'C:/Users/Jerin.Sam/MRx/r/jer_PGD1-24-Jun-2014-15-12-22/1' 
# c_path_out  <-  'C:/Users/Jerin.Sam/MRx/r/jer_PGD1-24-Jun-2014-15-12-22/1/univariateAnalysis/1'
# c_var_in    <-  c("ACV","channel_1")
# n_var_id_in <-  c(1,2)
# 

load(paste(c_path_in,"/dataworking.RData",sep=""))
count_data<- t(data.frame(lapply(c_var_in,function(x)nrow(unique(dataworking[x])))))
result <- cbind.data.frame(variable=c_var_in,var_id=n_var_id_in,distinct_count=count_data)

write.csv(result,file=paste(c_path_out,"/distinct_count.csv",sep=""),quote = F, row.names = F)
