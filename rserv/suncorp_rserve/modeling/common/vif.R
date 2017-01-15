# Author: saurabh vikash singh

if(exists("outputPath")){outputpath<-outputPath}
if(exists("operation"))
{
if(operation == "GeneralisedLinearModel")
{
library(car)
#formula creation for model---------------------------------------------------------------
no_intercept_model="false"
modelOptions=""
if(grepl("noint",modelOptions))
{
  formulaobj=paste(dependentVariable,"~",paste("0",paste(vifVariables,collapse="+"),sep="+"))
}else{formulaobj=paste(dependentVariable,"~",paste(vifVariables,collapse="+"))
}

#linear regression-------------------------------------------------------------------------
lmobj <- try(lm(formulaobj,data=bygroupdata),silent=T)

if(class(lmobj) == "try-error")
{
  errorText <- "Cannot build the model with the current selection"
  write(errorText,file=paste(output_path,"/error.txt",sep=""),append=T)
  stop("Cannot build the model with the current selection")
}


lmtable<-coef(summary(lmobj))


if(any(rownames(as.data.frame(lmtable)) == "(Intercept)") && (nrow(as.data.frame(lmtable)) == 1))
{
  write("Model cannot be built with currrent selection",file=paste(output_path,"/error.txt",sep=""))
  stop("Model cannot be built with current selection")
}
independent_variables2<-vifVariables
vif1<-data.frame(rep("NA",nrow(lmtable)))
if(length(which(is.na(coefficients(lmobj)))) == 0)
{
  try(vif1<-vif(lmobj),silent=TRUE)
}else{
  
  independent_variables2<-row.names(lmtable)
  #formula creation for model---------------------------------------------------------------
  if(no_intercept_model=="true"){
    formulaobj=paste(dependentVariable,"~",paste("0",paste(independent_variables2,collapse="+"),sep="+"))
  }else{
    independent_variables2<-independent_variables2[-1]
    formulaobj=paste(dependentVariable,"~",paste(independent_variables2,collapse="+"))
  }
  #linear regression-------------------------------------------------------------------------
  lmobj2 <- lm(formulaobj,data=bygroupdata)
  if(length(independent_variables2) != 1)
  {
    vif1<-vif(lmobj2)
  }else{
    vif1<-NA
  }
}

vif1<-cbind.data.frame(names(vif1),vif1)
colnames(vif1)<-c("Variable","VIF")

write.csv(vif1,file=paste(outputpath,"model.csv",sep="/"),quote=FALSE,row.names=FALSE)
}
}
write.csv("vif_COMPLETED",paste(outputpath,"vif_COMPLETED.txt",sep="/"))