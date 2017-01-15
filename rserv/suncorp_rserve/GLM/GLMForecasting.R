# input_path <- 'C:/Users/Senjuti.Bhattacharyy/MRx/r/pjt1-24-Jul-2013-18-08-40/1'
# output_path <- 'C:/Users/Senjuti.Bhattacharyy/MRx/r/pjt1-24-Jul-2013-18-08-40/1/0/1_1_1/GLM/1/1/forecast'
# group_path <- 'C:/Users/Senjuti.Bhattacharyy/MRx/r/pjt1-24-Jul-2013-18-08-40/1/0/1_1_1'
# dependent_variable <- 'sales'
# validation_var <- 'XXX1'

# dataworking<-read.csv(paste(input_path,"dataworking.csv",sep="/"))
load(paste(input_path,"/dataworking.RData",sep=""))
load(file=paste(input_path,"/glmobj.RData",sep=""))
# bygroupdata <- read.csv(paste(group_path, "bygroupdata.csv", sep="/"))
load(paste(group_path,"/bygroupdata.RData",sep=""))
# Code for part one -- Not forecast
subset <- subset(x=bygroupdata,subset=(bygroupdata[,validation_var]!=2))
Nobs <- 1:nrow(subset)
actual <- subset[,dependent_variable]
pred <- predict(glmobj, type="response")[Nobs]
Forecast <- rep(NA,nrow(subset))

partoneDF <- cbind(Nobs,actual,pred,Forecast)

# Code for part two -- Forecast
subset <- subset(x=bygroupdata,subset=(bygroupdata[,validation_var]==2))
Nobs <- (length(Nobs)+1):(length(Nobs)+nrow(subset))
actual <- rep(NA,nrow(subset))
pred <- rep(NA,nrow(subset))
Forecast <- predict(glmobj, type="response")[Nobs]

parttwoDF <- cbind(Nobs,actual,pred,Forecast)

forecastDF <- as.data.frame(rbind(partoneDF,parttwoDF))

#Writing the csv
write.csv(forecastDF, file=paste(output_path,"Forecast.csv",sep="/"), quote=FALSE,row.names=FALSE)

#Completed.txt
write("GLM FORECASTING IS COMPLETED",paste(output_path,"GLM_FORECAST_COMPLETED.txt",sep="/"))