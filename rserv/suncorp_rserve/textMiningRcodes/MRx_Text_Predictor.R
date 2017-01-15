#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Text_Predictor_1.0                                                           --#
#-- Description  :  Some functions to  build text classifiers                                        --#
#-- Return type  :  Classifies the new set based on the classifier selected                          --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#


#Parameters required
#-----------------------------------------------------------------
# input_path <- 'C:/MRx/r/Testing_LOpa-11-Dec-2012-14-47-57/3'
# output_path <- 'C:/MRx/r/Testing_LOpa-11-Dec-2012-14-47-57/3/0/1_1_1/text mining/model building/M_SENTIMENT/13/Model'
# varName <- 'CONTENT'
# uniqueLabels <- '1,0'
# modelLoc <- 'C:/MRx/r/Testing_LOpa-11-Dec-2012-14-47-57/3/0/1_1_1/text mining/model building/M_SENTIMENT/13/Model/SampleModel.Rd'
# matrixLoc <- 'C:/MRx/r/Testing_LOpa-11-Dec-2012-14-47-57/3/0/1_1_1/text mining/model building/M_SENTIMENT/13/Model/SampleMatrix.Rd'
# ifGenerateReport <- 'true'
# reportLoc <- 'C:/Documents and Settings/lopamudra.senapati/Desktop'
# predReport <- 'C:/MRx/r/Testing_LOpa-11-Dec-2012-14-47-57/3/0/1_1_1/text mining/model building/M_SENTIMENT/13/Reports/PredictReport.csv'
# minWordLen <- '3'
# minDocumentFreq <- '1'
# ifTf <- 'true'
# ifTfIdf <- 'false'
# removePunctuations <- 'true'
# removeNumber <- 'true'
# stripWhitespaces <- 'true'
# stemDoc <- 'true'
# isLower <- 'true'
# remStopwords <- 'true'



#Libraries required
#-----------------------------------------------------------------
library(RTextTools)
library(tm)
library(tau)

#Reading the dataworking.csv  
#-----------------------------------------------------------------
# dataworking=read.csv(paste(input_path,"/dataworking.csv",sep=""),header=T)
load(paste(input_path,"/dataworking.RData",sep=""))

#changing the encoding of data for further processing
index_true<-which(is.locale(as.character(dataworking[,varName])) == "FALSE")
if(length(index_true))
{
  dataworking[index_true,varName]<-iconv(as.character(dataworking[index_true,varName]),from="latin1" ,to = "UTF-8")
}

#if(grp_no!=0){
#  dataworking=subset.data.frame(dataworking,eval(parse(text=paste("grp_",grp_no,"_flag==",grp_flag,sep=""))))
#}

mlPredict <- function( varName, uniqueLabels, modelLoc, matrixLoc, reportLoc, predReport,
                       minWordLen = 3, minDocumentFreq = 1, ifTf = FALSE, ifTfIdf = FALSE,
                       removePunctuations = FALSE, removeNumber = FALSE,
                       stripWhitespaces = FALSE, stemDoc = FALSE, isLower = FALSE,
                       remStopwords = FALSE, ifGenerateReport = FALSE){
  
  
  # To read data from a single csv file and create a dataset of required column
  #----------------------------------------------------------------------------
  varIndex <- which(colnames(dataworking)==varName)
  corpus <- tolower(dataworking[,varIndex])
  
  
  # To load saved model
  #----------------------------------------------------------------------------
  
  load(matrixLoc)
  load(modelLoc)
  
  # To create a matrix from the dataset
  #----------------------------------------------------------------------------
  
  if(ifTf) {
    weighting = weightTf
  } else if(ifTfIdf) {
    weighting = weightTfIdf
  }
  
  matrix_new <- create_matrix(corpus,language="english",
                              minWordLength = minWordLen,minDocFreq = minDocumentFreq,ngramLength = 0,
                              removeNumbers = removeNumber,stemWords = stemDoc,
                              removePunctuation = removePunctuations,stripWhitespace = stripWhitespaces,
                              toLower = isLower,removeStopwords = remStopwords,
                              weightTf,removeSparseTerms = .998,originalMatrix = matrix)
  
  if(ifTfIdf) {
    matrix_new = weightSMART(matrix_new,"ntn")
  }
  
  
  # To create a label list and corpus of independent and dependent data
  #----------------------------------------------------------------------------
  
  data_size <- nrow(dataworking)
  label_list <- unlist(strsplit(uniqueLabels, ",", fixed=TRUE))
  indexNA <-which(label_list == "NA")
  if(length(indexNA))
  { 
    label_list<-label_list[-c(indexNA)]
  }
  label <- sample(as.numeric(label_list),data_size,replace=TRUE)
  
  corpus_new <- create_container(matrix_new,label,testSize=1:data_size,virgin=TRUE)
  
  
  # To classify new data and create analytics report
  #----------------------------------------------------------------------------
  
  results_new <- classify_models(corpus_new, models)
  analytics_new <- create_analytics(corpus_new, results_new)
  
  
  # To generate onscreen results
  #----------------------------------------------------------------------------
  
  predicted_Category <- analytics_new@document_summary$CONSENSUS_CODE
  predTable = table(predicted_Category)
  predTable = (predTable/sum(predTable))*100
  
  dir.create(output_path)

  write.csv(predTable, file = predReport, append = FALSE, col.names = TRUE,
            row.names = FALSE, quote=FALSE)
  
  
  # To save analytics reports
  #----------------------------------------------------------------------------
  
  if(ifGenerateReport) {
    write.csv(analytics_new@label_summary, paste(reportLoc,"LabelSummary.csv",sep="/"),row.names=FALSE, quote=FALSE)
    
    write.csv(cbind(corpus, analytics_new@document_summary),
              paste(reportLoc,"DocumentSummary.csv",sep="/"),row.names=FALSE, quote=FALSE)
  }
  
  
}

mlPredict(varName, uniqueLabels, modelLoc, matrixLoc, reportLoc, predReport,
          minWordLen, minDocumentFreq, as.logical(ifTf), as.logical(ifTfIdf),
          as.logical(removePunctuations), as.logical(removeNumber),as.logical(stripWhitespaces), 
          as.logical(stemDoc), as.logical(isLower), as.logical(remStopwords), as.logical(ifGenerateReport))


#Completed text
#-------------------------------------------
write("TEXT_PREDICTOR", file = paste(output_path, "TEXT_PREDICTION_COMPLETED.TXT", sep="/"))


# To clear all variable used
#----------------------------------------------------------------------------
rm(list = ls())


