#-------------------------------------------------------------------------------
# notes
#-------------------------------------------------------------------------------
# Fully done
#---------
# fixed effects
# actvspred
# model stats

# Partially done
#---------
# random effects - stderror, DF, t value and p value pending
# type1 & 3 tests for fixed effects - type 1 & 3 chisq & pvalue pending

# Yet to be done
#---------
# lsmeans
# diff matrix
# covariance parameter estimates???
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# sample : parameters required
#-------------------------------------------------------------------------------
# inputPath <- 'C:/Users/vasanth.mm/MRx/r/mixed2-23-Oct-2013-11-17-07/2'
# outputPath <- 'C:/Users/vasanth.mm/MRx/r/mixed2-23-Oct-2013-11-17-07/2/0/1_1_1/MIXED/1/1'
# groupPath <- 'C:/Users/vasanth.mm/MRx/r/mixed2-23-Oct-2013-11-17-07/2/0/1_1_1'
# shouldPreModelRun <- 'false'
# shouldModelRun <- 'true'
# operation <- 'MixedModel'
# datasetName <- 'group.bygroupdata'
# grpFlag <- '1_1_1'
# grpNo <- '0'
# byGroupUpdate <- 'false'
# validationType <- ''
# flagVif <- 'false'
# validationVar <- ''
# dependentVariable <- 'sales'
# flagMissingPerc <- 'false'
# independentVariables <- c('ACV','black_hispanic')
# independentTransformation <- c('none','none')
# dependentTransformation <- 'none'
# classVariables <- c('channel_1','geography')
# lsMeansVariables <- c()
# vifVariables <- c('ACV','black_hispanic')
# modelOptions <- 'e solution  htype = 1,2,3'
# maxfunc <- '150'
# randomVariables <- c('channel_1')
# randomOptions <- 'type=UN Solution '
# lsMeansOptions <- ''
# subject <- 'geography'
# actual <- 'dependentVariable'
# repeated_variable <- ''
# repeated_subject <- ''
# repeated_type <- ''
# method <- 'REML'
# maxiter <- '150'
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries : load
#-------------------------------------------------------------------------------
library(AICcmodavg)  # For AICc()
library(nlme)  # For nlme()
library(car)  # For vif()
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


dependentTransformation<-"none"
#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
c.path.input                 <- inputPath
c.path.output                <- outputPath
c.path.group                 <- groupPath
c.level.group                <- grpFlag
c.type.validation            <- validationType
c.transformation.dependent   <- dependentTransformation
c.transformation.independent <- independentTransformation
c.var.class                  <- classVariables
c.var.lsmeans                <- lsMeansVariables
c.var.vif                    <- vifVariables
c.var.validation             <- validationVar
c.var.dependent              <- dependentVariable
c.var.independent            <- independentVariables
c.var.random                 <- randomVariables
c.options.model              <- modelOptions
c.options.random             <- randomOptions
c.options.lsmeans            <- lsMeansOptions
c.var.subject                <- subject
c.method                     <- method

l.missing.percentage         <- as.logical(flagMissingPerc)
l.vif                        <- as.logical(flagVif)
l.bygroupupdate              <- as.logical(byGroupUpdate)
l.premodel                   <- as.logical(shouldPreModelRun)
l.model                      <- as.logical(shouldModelRun)

n.max.func                   <- as.numeric(maxfunc)
n.max.iter                   <- as.numeric(maxiter)
n.group                      <- as.numeric(grpNo)

# if (length(c.var.subject)) {
#   n.index <- which(c.var.class %in% c.var.subject)
#   if (length(n.index)) {
#     c.var.class <- c.var.class[-n.index]
#   }
# }

#-------------------------------------------------------------------------------
# Im thinking of creating the below parameter for all the modules
# It lists all the variables that are in the parameter
# We can take only these variables from the dataset
#-------------------------------------------------------------------------------
c.temp             <- ls(pattern="c\\.var\\.")
c.temp             <- paste("c(",paste(c.temp,collapse=","),")",sep="")
c.var.all          <- eval(parse(text=c.temp))
c.var.all          <- unique(c.var.all)
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
#-------------------------------------------------------------------------------
# code composition
#-------------------------------------------------------------------------------
# notes
# sample : parameters required
# libraries : load
# making the '' parameters NULL
# parameter play
# data : load
# data : take only what is needed
# check : > 0 observations
# check : >= min no.of observations - not implemented
# BEGINNING : mixed modeling
# check : > 1 level in the class variables
# output : VIF
# check : if Only VIF option is selected stop the code
# mixed modeling : create the text of the fixed part of the formula
# mixed modeling : create the text of the random part of the formula
# mixed modeling : converting class variables into factor
# mixed modeling : run mixed model
# check : has the model run successfully ?
# output : actual predicted residual
# output : fixed effects
# output : random effects
# output : type 1 & 3 tests for fixed effects
# output : model stats
# END : mixed modeling
# indicating completion
#-------------------------------------------------------------------------------

# notes
# sample : parameters required
# libraries : load
# making the '' parameters NULL
# parameter play
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# data : load
#-------------------------------------------------------------------------------
if (n.group) {
  load(paste(c.path.group, "/bygroupdata.RData", sep=""))
  df.data <- bygroupdata
  rm("bygroupdata")
} else {
  load(paste(c.path.input, "/dataworking.RData", sep=""))
  df.data <- dataworking
  rm("dataworking")
}
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# data : check for validation variable
#-------------------------------------------------------------------------------

if(!is.null(c.var.validation))
{
  if (c.type.validation=="build")
  {
    col_num<-which(names(df.data)==c.var.validation)
    df.data<-df.data[which(df.data[col_num]==1),]
  }
  if (c.type.validation=="validation")
  {
    col_num<-which(names(df.data)==c.var.validation)
    df.data<-df.data[c(which(df.data[col_num]==0)),]
  }
}


#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# data : load
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# data : take only what is needed
#-------------------------------------------------------------------------------
df.data     <- subset(x=df.data, select=c(c.var.all, "primary_key_1644"))
n.nrow.read <- nrow(df.data)
df.data     <- na.omit(df.data)
n.nrow.rem  <- nrow(df.data)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# data : take only what is needed
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# check : > 0 observations
#-------------------------------------------------------------------------------
if (!nrow(df.data)) {
  c.error <- "No valid observations"
  write(c.error, file=paste(c.path.output, "/error.txt", sep=""), append=T)
  stop(c.error, call.=T)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# check : > 0 observations
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# check : >= min no.of observations - not implemented
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# check : >= min no.of observations - not implemented
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# BEGINNING : mixed modeling
# check : > 1 level in the class variables
#-------------------------------------------------------------------------------
if (length(c.var.class)) {
  c.error <- NULL
  for (c.tempi in c.var.class) {
    if (length(unique(df.data[, c.tempi])) == 1) {
      c.error <- c(c.error, c.tempi)
    }
  }
  if (length(c.error)) {
    if (length(c.error) > 1) {
      c.error <- paste(c.error, collapse=" , ")
      c.error <- gsub(pattern="(.*),", replacement="\\1and", x=c.error)
      c.error <- paste("The class variables ", c.error,
                       " have only 1 unique level. Regression will not run.",
                       sep="")
    } else {
      c.error <- paste("The class variable ", c.error,
                       " has only 1 unique level. Regression will not run.",
                       sep="")
    }
    write(c.error, file=paste(c.path.output, "/error.txt", sep=""))
    stop(c.error, call.=T)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# BEGINNING : mixed modeling
# check : > 1 level in the class variables
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : VIF
#-------------------------------------------------------------------------------
if (l.vif) {
  c.formula.lm <- paste(c.var.dependent, " ~ ", paste(c.var.vif, collapse=" + "))
  obj.lm <- lm(formula=as.formula(c.formula.lm), data=df.data)
  n.vif <- vif(obj.lm)
  df.vif <- data.frame(Variable=names(n.vif), VIF=n.vif)
  
  write.csv(df.vif, paste(c.path.output, "/model.csv", sep=""),
            row.names=F, quote=F)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : VIF
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# check : if "Only VIF" option is selected stop the code
#-------------------------------------------------------------------------------
if (!l.model) {
  #-------------------------------------------------------------------------------
  # indicating completion
  #-------------------------------------------------------------------------------
  write("completed", file=paste(c.path.output, "/MIXED_COMPLETED.txt", sep=""))
  #-------------------------------------------------------------------------------
  
  stop("VIF calculated. Only VIF option selected. Completed. Code will stop here.")
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# check : if Only VIF option is selected stop the code
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# mixed modeling : create the text of the fixed part of the formula
#-------------------------------------------------------------------------------
c.fixed <- paste(c.var.dependent, paste(c.var.independent, collapse="+"),
                 sep="~")
if (length(grep(pattern="noint", x=c.options.model, ignore.case=T))) {
  c.fixed <- paste(c.fixed, " -1", sep="")
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# mixed modeling : create the text of the fixed part of the formula
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# mixed modeling : create the text of the random part of the formula
#-------------------------------------------------------------------------------
if (is.null(c.var.random) & is.null(c.var.subject)) {
  c.random <- NULL
}else{
  if (is.null(c.var.random)) {
    c.var.random <- "1"
  }
  if (is.null(c.var.subject)) {
    c.var.subject <- "1"
  }
  c.random <- paste(paste(c.var.random, collapse=" + "), " | ", c.var.subject,
                    sep="")
  if (length(grep(pattern="noint", x=c.options.random, ignore.case=T))) {
    c.random <-  paste("-1 + ", c.random, sep="")
  }
  c.random <- paste(" ~ ", c.random)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# mixed modeling : create the text of the random part of the formula
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# mixed modeling : convert class variables into factor
#-------------------------------------------------------------------------------
if (!is.null(c.var.class)) {
  for (c.tempi in c.var.class) {
    levels             <- sort(unique(df.data[, c.tempi]), decreasing=T)
    df.data[, c.tempi] <- factor(df.data[, c.tempi], levels=levels)
  }
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# mixed modeling : convert class variables into factor
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# mixed modeling : run mixed model
#-------------------------------------------------------------------------------
ctrl <- lmeControl(opt='optim',maxIter=n.max.iter,msMaxIter=n.max.func);

model.nlme <- try({
  lme(fixed     = as.formula(c.fixed),
      random    = as.formula(c.random),
      data      = df.data,
      method    = method,
      control   = ctrl,
      keep.data = F)
},
silent=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# mixed modeling : run mixed model
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# check : has the model run successfully ?
#-------------------------------------------------------------------------------
if(class(model.nlme) == "try-error"){
  c.error <- model.nlme
  write(x=c.error, file=paste(c.path.output, "/error.txt", sep=""))
  stop(c.error)
} else {
  summary.model.nlme <- summary(model.nlme)
}
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# check : has the model run successfully ?
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : actual predicted residual
#-------------------------------------------------------------------------------
df.avp <- data.frame(Actual=df.data[, c.var.dependent],
                     Predicted=fitted(model.nlme))
df.avp$Residual <- df.avp$Actual - df.avp$Predicted
df.avp$primary_key_1644 <- df.data$primary_key_1644

write.csv(df.avp, paste(c.path.output, "/normal_chart.csv", sep=""),
          row.names=F, quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : actual predicted residual
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : fixed effects
#-------------------------------------------------------------------------------
df.fe <- data.frame(summary(model.nlme)$tTable, stringsAsFactors=F)
df.fe <- data.frame(row.names(df.fe), df.fe, stringsAsFactors=F)
colnames(df.fe) <- c("Variable", "Estimate", "StandardError", "DF", "tValue",
                     "PValue")

# Replacing the class variables with class variables and an underscore
if (length(c.var.class)) {
  index <- which(c.var.class %in% c.var.independent)
  if(length(index)){
    for(n.tempi in index){
      df.fe$Variable  <- sub(pattern=paste("(^", c.var.class[n.tempi], ")", sep=""),
                             replacement="\\1_", x=df.fe$Variable)
    }
  }
}

write.csv(df.fe, paste(c.path.output, "/FixedEffect.csv", sep=""),
          row.names=F, quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : fixed effects
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : random effects
#-------------------------------------------------------------------------------
df.re <- data.frame(t(ranef(summary(model.nlme))), stringsAsFactors=F)
n.re <- NULL
for (n.tempi in 1:ncol(df.re)) {
  n.re <- c(n.re, df.re[, n.tempi])
}
df.re2 <- data.frame(Variable=rep(x=rownames(df.re), times=ncol(df.re)),
                     Estimate=n.re)
df.re2[, c.var.subject] <- rep(x=colnames(df.re), each=nrow(df.re))

write.csv(df.re2, paste(c.path.output, "/RandomEffect.csv", sep=""),
          row.names=F, quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : random effects
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : type 1 & 3 tests for fixed effects
#-------------------------------------------------------------------------------
df.type13fe           <- data.frame(anova.lme(object=model.nlme,
                                              type="sequential"),
                                    anova.lme(object=model.nlme,
                                              type="marginal"))
colnames(df.type13fe) <- c("type1NumDF", "type1DenDF", "type1FValue",
                           "type1PValueF", "type3NumDF", "type3DenDF", 
                           "type3FValue", "type3PValueF")
df.type13fe$Variable  <- row.names(df.type13fe)

if (l.vif) {
  df.type13fe <- merge(x=df.type13fe, y=df.vif, by="Variable", all.x=T)
}

write.csv(df.type13fe, paste(c.path.output, "/model.csv", sep=""),
          row.names=F, quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : type 1 & 3 tests for fixed effects
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# output : model stats
#-------------------------------------------------------------------------------
CalcMape <- function (actual, predicted) {
  index = (1:nrow(actual))[!is.na(actual)] 
  index = index[actual[index,1] != 0] 
  actual = actual[index,1] 
  predicted = predicted[index,1] 
  mape = mean(abs((actual - predicted)/actual))*100 
  return(mape)
}

c.lhs  <- NULL
c.rhs  <- NULL
c.type <- NULL
if (length(c.var.class)) {
  for (tempi in c.var.class) {
    c.temp <- paste(tempi, c("Levels", "Values"))
    c.lhs  <- c(c.lhs, c.temp)
    
    c.temp <- unique(df.data[, tempi])
    c.temp <- c(length(c.temp), paste(c.temp, collapse=" "))
    c.rhs  <- c(c.rhs, c.temp)
  }
  c.type <- rep(x="Statistics", times=length(c.rhs))
}


  
obj.htest <-try({chisq.test(x=abs(x=df.data[, c.var.dependent]),
                         p=abs(x=fitted(model.nlme) / sum(fitted(model.nlme))))},silent=T)

if(class(obj.htest) == "try-error")
{
  obj.htest <- as.data.frame(c())  
  obj.htest[1,"statistic"] <- 'NA'
  obj.htest[1,"parameter"] <- 'NA'
  obj.htest[1,"p.value"]   <- 'NA'
}

c.lhs <- c(c.lhs,
           "Number of Observations Read",
           "Number of Observations Used",
           "Number of Observations Not Used",
           "-2ResLogLikelihood",
           "AIC(smallerisbetter)",
           "AICC(smallerisbetter)",
           "BIC(smallerisbetter)",
           "MAPE",
           "ChiSq",
           "Degrees of Freedom",
           "ProbChiSq")
c.rhs <- c(c.rhs,
           n.nrow.read,
           n.nrow.rem,
           n.nrow.read - n.nrow.rem,
           -2 * summary.model.nlme$logLik,
           summary.model.nlme$AIC,
           AICc(mod=model.nlme, second.ord=T),
           summary.model.nlme$BIC,
           CalcMape(actual=as.data.frame(df.data[, c.var.dependent]),
                    predicted=as.data.frame(fitted(model.nlme))),
           obj.htest$statistic,
           obj.htest$parameter,
           obj.htest$p.value)
c.type <- c(c.type,
            "Statistics",
            "Statistics",
            "Statistics",
            "Statistics",
            "Statistics",
            "Statistics",
            "Statistics",
            "Statistics",
            "Likelihood Ratio Test",
            "Likelihood Ratio Test",
            "Likelihood Ratio Test")

df.modelstats <- data.frame(Statistics=c.lhs, Value=c.rhs, Type=c.type,
                            stringsAsFactors=F)

write.csv(df.modelstats, paste(c.path.output, "/ModelStats.csv", sep=""),
          row.names=F, quote=F)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# output : model stats
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# END : mixed modeling
# indicating completion
#-------------------------------------------------------------------------------
write("completed", file=paste(c.path.output, "/MIXED_COMPLETED.txt", sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# status
#-------------------------------------------------------------------------------
x <- "
# END : mixed modeling
# indicating completion
"
write(x=x, file=paste(c.path.output, "/status.txt", sep=""), append=T)
#-------------------------------------------------------------------------------