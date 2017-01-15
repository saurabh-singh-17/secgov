#============================================================================ 
# parameters required for the code
#============================================================================ 
#output_path <- 
#============================================================================ 
month      <-toupper(months(x=Sys.Date()))
date       <- unlist(strsplit(as.character(Sys.Date()),split="-",fixed=TRUE))
day        <- date[3]
year       <- date[1]
time       <- unlist(strsplit(as.character(Sys.time()),split=" ",
                        fixed=TRUE))[2]

time_stamp <- paste(day,month,year,":", time,sep="")
write(time_stamp,file=paste(output_path,"/DATETIMESTAMP.TXT",sep=""))

#============================================================================ 
