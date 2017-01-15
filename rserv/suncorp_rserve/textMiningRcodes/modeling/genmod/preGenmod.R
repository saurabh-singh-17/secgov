
#If dependent is in events/trials form, create new variable 
#and set "actual" as that
  
#reading the dataset----------------------------------------------------------------

if(formEventsTrials=="true")
{
  newcol<-unlist(strsplit(dependentVariable,"/",fixed=TRUE))
  bygroupdata$actual<-as.matrix(bygroupdata[,newcol[1]]/bygroupdata[,newcol[2]])
  dependentVariable="actual"
}
