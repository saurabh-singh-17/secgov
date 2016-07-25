
#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Text_Categorization_1.0                                                      --#
#-- Description  :  Some functions to  build text classifiers                                        --#
#-- Return type  :  Creates model and result on validation set                                       --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#



#Parameters required
#-----------------------------------------------------------------
#input_path <- "E:/MRx/Text Mining/Text Mining Sample datasets/"
#indVarName <- "CONTENT"
#depVarName <-"M_SENTIMENT"
#modelLoc <-"E:/MRx/Text Mining/Text Mining Sample datasets/"
#matrixName <- "sample_matrix"
#modelName <- "sample_model"
#modelStatsLoc <- "E:/MRx/Text Mining/Text Mining Sample datasets/mstat.csv" 
#docSummaryReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/ds.csv"
#lblSummaryReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/ls.csv"
#algoSummaryReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/algo.csv"
#predActReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/predAct.csv"
#predReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/pred.csv"
#actualReport <- "E:/MRx/Text Mining/Text Mining Sample datasets/acReport.csv"
#isInSampleValid <- "false"
#isOutSampleValid <- "false"
#outSampleLoc <-""
#trainRatio = 80
#isSVM = "true" 
#isRF = "true"
#isMAXENT = "true" 
#isGLM = "true"
#minWordLen = 3
#minDocumentFreq = 3 
#ifTf = "true"
#ifTfIdf = "false"
#removePunctuations = "true"
#removeNumber = "true"
#stripWhitespaces = "false" 
#stemDoc = "false"
#isLower = "false"
#remStopwords = "false"



#Libraries required
#-----------------------------------------------------------------
library(RTextTools)
library(tm)
library(tau)

#Reading the dataworking.csv  
#-----------------------------------------------------------------
# dataworking=read.csv(paste(input_path,"/dataworking.csv",sep=""),header=T)
load(paste(input_path,"/dataworking.RData",sep=""))

index<-which(is.na(dataworking[,depVarName]))
if(length(index)){
  dataworking<-dataworking[-c(index),]
}

#changing the encoding of data for further processing
index_true<-which(is.locale(as.character(dataworking[,indVarName])) == "FALSE")
if(length(index_true))
{
  dataworking[index_true,indVarName]<-iconv(as.character(dataworking[index_true,indVarName]),from="latin1" ,to = "UTF-8")
}


#if(grp_no!=0){
#  dataworking=subset.data.frame(dataworking,eval(parse(text=paste("grp_",grp_no,"_flag==",grp_flag,sep=""))))
#}


# Defining some custom functions
#-----------------------------------------------------------------


recallAccuracy <-function (true_labels, predicted_labels) 
{
  accuracy <- length(which(as.vector(true_labels)==as.vector(predicted_labels))==TRUE)/length(as.vector(predicted_labels))
  return(round(accuracy,3))
}

mlTrainValidate <- function(input_path, indVarName, depVarName,
                            modelLoc, matrixName, modelName,
                            modelStatsLoc, docSummaryReport, lblSummaryReport, algoSummaryReport, predActReport,
                            predReport, actualReport, isInSampleValid = FALSE, isOutSampleValid = FALSE,
                            outSampleLoc, trainRatio = 80, isSVM = FALSE, isRF = FALSE, isMAXENT = FALSE, isGLM = FALSE,
                            minWordLen = 3, minDocumentFreq = 1, ifTf = FALSE, ifTfIdf = FALSE,
                            removePunctuations = FALSE, removeNumber = FALSE,
                            stripWhitespaces = FALSE, stemDoc = FALSE, isLower = FALSE,
                            remStopwords = FALSE){
  
  
  
  
  # Create a dataset of required column
  #----------------------------------------------------------------------------
  varIndexInd <- which(colnames(dataworking)==indVarName)
  varIndexDep <- which(colnames(dataworking)==depVarName)
  
  
  # To create training and validation sets
  #----------------------------------------------------------------------------
  
  dataSize <- nrow(dataworking)
  
  if(isInSampleValid) {
    trainingSize = round((trainRatio/100)*dataSize)
    validationSize = dataSize - trainingSize
    
    data_training <- dataworking[sample(1:dataSize,size=trainingSize,replace=FALSE),]
    
    rowIndex <- row.names(data_training)
    delRowIndex <- which(row.names(dataworking) %in% rowIndex)
    data_validation <- dataworking[-delRowIndex,]
    
    trainValidData <- rbind(data_training,data_validation)
    
    indData <- trainValidData[,varIndexInd]
    depData <- trainValidData[,varIndexDep]
    
  }
  
  # To create a matrix from the dataset
  #----------------------------------------------------------------------------
  
  if(ifTf) {
    weighting = weightTf
  } else if(ifTfIdf) {
    weighting = weightTfIdf
  }
  
  matrix <- create_matrix(indData,language="english",
                          minWordLength = minWordLen,minDocFreq = minDocumentFreq,ngramLength = 0,
                          removeNumbers = removeNumber,stemWords = stemDoc,
                          removePunctuation = removePunctuations,stripWhitespace = stripWhitespaces,
                          toLower = isLower,removeStopwords = remStopwords,
                          weighting,removeSparseTerms = .998)
  matrix<-weightSMART(matrix,spec="ntn")    
  
  
  # sorts a sparse matrix in triplet format (i,j,v) first by i, then by j.
  #----------------------------------------------------------------------------
  
  ResortDtm <- function(working.dtm) {
    working.df <- data.frame(i = working.dtm$i, j = working.dtm$j, v = working.dtm$v)  # create a data frame comprised of i,j,v values from the sparse matrix passed in.
    working.df <- working.df[order(working.df$i, working.df$j), ] # sort the data frame first by i, then by j.
    working.dtm$i <- working.df$i  # reassign the sparse matrix' i values with the i values from the sorted data frame.
    working.dtm$j <- working.df$j  # ditto for j values.
    working.dtm$v <- working.df$v  # ditto for v values.
    return(working.dtm) 
  } 
  
  matrix <- ResortDtm(matrix)
  
  # To create a corpus of independent and dependent data
  #----------------------------------------------------------------------------
  
  corpus <- create_container(matrix,depData,trainSize=1:trainingSize,
                             testSize=(trainingSize+1):dataSize,virgin=FALSE)
  
  
  # To train on selected algorithms
  #----------------------------------------------------------------------------
  
  algorithms = NULL
  
  if(isSVM) {
    algorithms="SVM"
  }
  if(isRF) {
    algorithms = c(algorithms, "RF")
  }
  if(isMAXENT) {
    algorithms = c(algorithms, "MAXENT")
  }
  if(isGLM) {
    algorithms = c(algorithms, "GLMNET")
  }
  
  models <- train_models(corpus, algorithms)
  
  
  # To save generated matrix and model
  #----------------------------------------------------------------------------
  
  matrixPath <- paste(modelLoc,matrixName,sep="/")
  modelPath <- paste(modelLoc,modelName,sep="/")
  
  save(matrix,file=matrixPath)
  save(models,file=modelPath)
  
  
  # To create analytics reports
  #----------------------------------------------------------------------------
  
  results <- classify_models(corpus, models)
  
  analytics <- create_analytics(corpus, results)
  
  Statistic = c()
  Value = c()
  
  Statistic = c(Statistic, "Consensus Accuracy")
  Value = c(Value, recallAccuracy(analytics@document_summary$MANUAL_CODE,
                                  analytics@document_summary$CONSENSUS_CODE))
  
  if(isSVM) {
    Statistic = c(Statistic, "SVM Accuracy")
    Value = c(Value, recallAccuracy(analytics@document_summary$MANUAL_CODE,
                                    analytics@document_summary$SVM_LABEL))
  }
  if(isRF) {
    Statistic = c(Statistic, "Random Forest Accuracy")
    Value = c(Value, recallAccuracy(analytics@document_summary$MANUAL_CODE,
                                    analytics@document_summary$FORESTS_LABEL))
  }
  if(isMAXENT) {
    Statistic = c(Statistic, "Maximum Entropy Accuracy")
    Value = c(Value, recallAccuracy(analytics@document_summary$MANUAL_CODE,
                                    analytics@document_summary$MAXENTROPY_LABEL))
  }
  if(isGLM) {
    Statistic = c(Statistic, "GLMNET Accuracy")
    Value = c(Value, recallAccuracy(analytics@document_summary$MANUAL_CODE,
                                    analytics@document_summary$GLMNET_LABEL))
  }
  
  ModelStats = data.frame(Statistic,Value)
  
  # To write the model stats summary report in a csv
  #----------------------------------------------------------------------------
  
  write.csv(ModelStats, file = modelStatsLoc, append = FALSE, col.names = TRUE,
            row.names = FALSE, quote=FALSE)
  
  
  # To write the model stats detailed reports in csvs
  #----------------------------------------------------------------------------
  
  write.csv(analytics@label_summary, lblSummaryReport,row.names = FALSE,quote=FALSE)
  write.csv(analytics@algorithm_summary, algoSummaryReport,row.names = FALSE,quote=FALSE)
  
  Data_Validation = data.frame(data_validation[,varIndexInd])
  colnames(Data_Validation) = "Data_Validation"
  
  write.csv(cbind(Data_Validation, analytics@document_summary),
            docSummaryReport,row.names = FALSE,quote=FALSE)
  
  
  # To calculate the % category share
  #----------------------------------------------------------------------------
  
  predicted_Category <- analytics@document_summary$CONSENSUS_CODE
  actual_Category <- analytics@document_summary$MANUAL_CODE
  
  predTable = table(predicted_Category)
  predTable = (predTable/sum(predTable))*100
  
  actualTable = table(actual_Category)
  actualTable = (actualTable/sum(actualTable))*100
  
  write.csv(predTable, file = predReport, append = FALSE, col.names = TRUE,
            row.names = FALSE,quote=FALSE)
  write.csv(actualTable, file = actualReport, append = FALSE, col.names = TRUE,
            row.names = FALSE,quote=FALSE)
  
  
  # To write the predicted vs actual report in a csv
  #----------------------------------------------------------------------------
  
  write.csv(cbind(Data_Validation,analytics@document_summary$CONSENSUS_CODE,
                  analytics@document_summary$MANUAL_CODE),predActReport,row.names = FALSE,quote=FALSE)
  
  
  # To clear all variable used
  #----------------------------------------------------------------------------
  
  rm(list=c("input_path","varIndexInd","varIndexDep",
            "indData","depData","algorithms","matrixLoc","modelLoc",
            "matrix","corpus","models","traininig_size","predicted_Category","actual_Category",
            "predTable","actualTable","ModelStats","results","analytics","Statistic","Value"))
  
}


mlTrainValidate(input_path, indVarName, depVarName, modelLoc, matrixName, modelName,
                modelStatsLoc, docSummaryReport, lblSummaryReport, algoSummaryReport, predActReport,
                predReport, actualReport, as.logical(isInSampleValid), as.logical(isOutSampleValid),
                outSampleLoc, as.numeric(trainRatio), as.logical(isSVM), as.logical(isRF), as.logical(isMAXENT), 
                as.logical(isGLM), as.numeric(minWordLen), as.numeric(minDocumentFreq), as.logical(ifTf), as.logical(ifTfIdf),
                as.logical(removePunctuations), as.logical(removeNumber),as.logical(stripWhitespaces), 
                as.logical(stemDoc), as.logical(isLower), as.logical(remStopwords ))


write("CLASSIFIER MODEL CREATED", file = paste(modelLoc, "TEXT_CATEGORIZATION_COMPLETED.txt", sep="/"))

