#---------------------------------------------------------------------------------------#
#-- Modified on 16Jan2013 1024 by Vasanth M M & Payal Gupta                           --#
#---------------------------------------------------------------------------------------#



#---------------------------------------------------------------------------------------#
#--                                                                                   --#
#--  Project Name:   Text Mining                                                      --#
#--  Task :          Task 1: Relationship Analysis                                     --#
#--  Sub-Task:       1.1 Create frequency reports                                     --#
#--  Sub-Task:       1.2 Create word association reports                              --#
#--  version :       1.0 date: 15/03/2012 author: Gaurav Jain		          		        --#
#---------------------------------------------------------------------------------------#



#---------------------------------------------------------------------------------------
# Defining some custom functions
#---------------------------------------------------------------------------------------
# 1. To install required packages
# 2. To split text into tokens based on whitespaces
# 3. To Extract parts of speech
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# Parameters needed
#---------------------------------------------------------------------------------------
#-- Path where the dataworking.csv is located
# input_path      <- "D:/"
#-- Path where the output files are to be generated
# output_path     <- "D:/output"
#-- This will contain the list of columns for which a frequency report is to be generated
# varName         <- c("")

#-- Flag : If True, then we have to calculate frequency report, if False, then we have to calculate Word Association
# ifFrequency     <- "TRUE/FALSE"

#-- These parameters below are used only when ifFrequency <- "TRUE"
#-- Flags : Only one of them can be true in one parameter file
# ifEntireComment <- "TRUE/FALSE" 
# ifVerb          <- "TRUE/FALSE" 
# ifNoun          <- "TRUE/FALSE"
# ifAdj           <- "TRUE/FALSE"
#-- At any given time, only one of findFreqTerms and findTopTerms can be TRUE. Both cannot be TRUE at the same time. But both can be FALSE at the same time.
# findFreqTerms   <- "TRUE/FALSE"
# minimumFreq     <- '3'
# maximumFreq     <- '23'
# findTopTerms    <- "TRUE/FALSE"
# numTerms        <-  '15'

#-- The two parameters below are used only if ifFrequency <- 'FALSE'
#-- The keywords selected for which Word Association is to be calculated
# keyword         <- c("")
#-- The name of the relationship report
# reportName      <- 'myreport'
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# # Function to install required packages
# #---------------------------------------------------------------------------------------
# is.installed <- function(pkg){ is.element(pkg, installed.packages()[,1])}
# #---------------------------------------------------------------------------------------
# #Configurations to load rJava library
# #====================================
# 
# #Reading java path from the system paths
# #---------------------------------------
# jPath <- readChar(jpath.location, file.info(jpath.location)$size)
# 
# #Adding client to JPath as jvm.dll exists inside that folder is used to load rJava
# #---------------------------------------------------------------------------------
# jPath.client=paste(jPath,'\\client',sep='')
# 
# #Checking for jre client or jre server
# #-------------------------------------
# if(file.exists(jPath.client)){
#   jPath <- jPath.client
# }else{
#   jPath <- paste(jPath,'\\server',sep='')
# }
# 
# #Setting temporary java client/server path
# #-----------------------------------------
# try(Sys.setenv('path'=paste(Sys.getenv('path'),jPath,sep=';')),silent=TRUE)



#---------------------------------------------------------------------------------------
# Libraries required
#---------------------------------------------------------------------------------------
# if(!is.installed('openNLP')){
#   install.packages('openNLP',repo="http://lib.stat.cmu.edu/R/CRAN")
#   library(openNLP)
# }
# if(!is.installed('openNLPmodels.en')){
#   install.packages('openNLPmodels.en',repo="http://lib.stat.cmu.edu/R/CRAN")
#   library(openNLPmodels.en)
# }
# if(!is.installed('RTextTools')){
# install.packages('RTextTools',repo="http://lib.stat.cmu.edu/R/CRAN")
#   library(RTextTools)
# }
# if(!is.installed('stringr')){
#   install.packages('stringr',repo="http://lib.stat.cmu.edu/R/CRAN")
#   library(stringr)
# }

library(stringr)
library(SnowballC)
library(tm)
library(openNLP)
library(openNLPmodels.en)
library(lda)
library(XML)
library(slam)
library(stringr)
library(wordcloud)
library(RColorBrewer)
library(rJava)
library(RTextTools)
library(Snowball)
library(NLP)
#---------------------------------------------------------------------------------------


tagPOS <- function(corpus, language = "en"){
  
  sent_token_annotator  <- Maxent_Sent_Token_Annotator()
  word_token_annotator  <- Maxent_Word_Token_Annotator()
  pos_tag_annotator     <- Maxent_POS_Tag_Annotator()
  
  corpus.set.to.return  <- NULL 
  for(i in 1:length(corpus)){
    corpus.element.annotated <- annotate(corpus[i], 
                                         list(sent_token_annotator,
                                              word_token_annotator))
    
    
    
    pos.tagged <- annotate(corpus[i], pos_tag_annotator, 
                           corpus.element.annotated)
    pos.tagged.word <- subset(pos.tagged, type == "word")
    
    tags <- sapply(pos.tagged.word$features, `[[`, "POS")
    
    
    sent.tagged <-  paste(apply(cbind(pos.tagged.word$start,pos.tagged.word$end, tags),1,
                                function(word.terms, sent){return(paste(substr(sent,word.terms[1],word.terms[2]),word.terms[3],sep="/"))},
                                sent=corpus[i]),collapse=" ")
    
    corpus.set.to.return[i] <- sent.tagged
    
  }
  return(corpus.set.to.return)
}



#---------------------------------------------------------------------------------------
# Function to split text into tokens based on whitespaces
#---------------------------------------------------------------------------------------
strsplit_space_tokenizer <- function(x) unlist(strsplit(x, "[[:space:]]+"))
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# Function to extract parts of speech
#---------------------------------------------------------------------------------------
posTagger <- function(input_path, fileName, varName) {
  
  # To read data from a single csv file and create a dataset of required column
  #----------------------------------------------------------------------------
  # fileLoc   <- paste(input_path,fileName,sep="\\")
  # tmDataSet <- read_data(fileLoc,type="csv")
  load(paste(input_path,fileName,sep="/"))
  tmDataSet <- dataworking
  rm("dataworking")
  varIndex  <- which(colnames(tmDataSet)==varName)
  dataList  <- as.vector(tmDataSet[,varIndex])
  
  # To remove punctuations from dataset
  #----------------------------------------------------------------------------
  dataList <- removePunctuation(dataList, preserve_intra_word_dashes = FALSE)
  
  # POS-tag the dataset
  #----------------------------------------------------------------------------
  dataList <- tagPOS(dataList, language = "en")
  
  nounPOS = c()
  verbPOS = c()
  adjPOS  = c()
  
  # Extracting nouns, verbs and adjectives from the tagged data
  #----------------------------------------------------------------------------
  for(i in 1:length(dataList)) {
    
    wordlist  <- unlist(strsplit(dataList[i], " ", fixed=TRUE))
    splitVars <- sapply(wordlist, function(str){strsplit(str, "/", fixed=TRUE)}, simplify = TRUE, USE.NAMES = FALSE)
    splitMat  <- as.data.frame(t(data.frame(splitVars)))
    words     <- as.character(splitMat$V1)
    postags   <- as.vector(splitMat$V2)
    
    noun  = ""
    verb  = ""
    adj   = ""
    
    for(j in 1:length(words)) {
      
      tag2 = substr(postags[j],1,2)
      
      if(length(tag2)==0){
        print(tag2)
      }
      else{
        if(tag2 == 'NN') {
          noun = paste(noun,words[j],sep=" ")
        }
        if(tag2 == 'VB') {
          verb = paste(verb,words[j],sep=" ")
        }
        if(tag2 == 'JJ') {
          adj = paste(adj,words[j],sep=" ")
        }
      }
    }
    
    nounPOS = c(nounPOS,noun)
    verbPOS = c(verbPOS,verb)
    adjPOS  = c(adjPOS,adj)
    
  }
  
  verbPOS = tolower(verbPOS)
  nounPOS = tolower(nounPOS)
  adjPOS  = tolower(adjPOS)
  
  tmDataSetNew <- cbind(tmDataSet)
  
  # Adding POS entity data to the original dataset
  #----------------------------------------------------------------------------
  tmDataSetNew <- cbind(tmDataSetNew,verbPOS,nounPOS,adjPOS)
  
  return(tmDataSetNew)
  
}
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# Function to generate the frequency report
#---------------------------------------------------------------------------------------
genFreqReports <- function(input_path, fileName, varName, ifEntireComment, ifNoun, ifVerb, ifAdj, output_path) {
  
  # Using posTagger function to get the verbs, nouns & adjectives in the varName column
  #---------------------------------------------------------------------------------
  tmDataSet <- posTagger(input_path, fileName, varName)
  
  corpus = ""
  
  varIndexE <- which(colnames(tmDataSet)==varName)
  varIndexN <- which(colnames(tmDataSet)=='nounPOS')
  varIndexV <- which(colnames(tmDataSet)=='verbPOS')
  varIndexA <- which(colnames(tmDataSet)=='adjPOS')
  
  if(ifEntireComment) {
    corpus <- tolower(tmDataSet[,varIndexE])
    #     dropDown='entire'
  } else if(ifNoun & ifVerb & ifAdj) {
    corpus <- paste(tolower(tmDataSet[,varIndexN]),tolower(tmDataSet[,varIndexV]),tolower(tmDataSet[,varIndexA]),sep=" ")
    #     dropDown='adjnounverb'
  } else if(ifNoun & ifVerb) {
    corpus <- paste(tolower(tmDataSet[,varIndexN]),tolower(tmDataSet[,varIndexV]),sep=" ")
    #     dropDown='nounverb'
  } else if(ifNoun & ifAdj) {
    corpus <- paste(tolower(tmDataSet[,varIndexN]),tolower(tmDataSet[,varIndexA]),sep=" ")
    #     dropDown='adjnoun'
  } else if(ifVerb & ifAdj) {
    corpus <- paste(tolower(tmDataSet[,varIndexV]),tolower(tmDataSet[,varIndexA]),sep=" ")
    #     dropDown='adjverb'
  } else if(ifNoun) {
    corpus <- tolower(tmDataSet[,varIndexN])
    #     dropDown='noun'
  } else if(ifVerb) {
    corpus <- tolower(tmDataSet[,varIndexV])
    #     dropDown='verb'
  } else if(ifAdj) {
    corpus <- tolower(tmDataSet[,varIndexA])
    #     dropDown='adj'
  }
  
  # To convert dataset into Plain text document
  #----------------------------------------------------------------------------
  doc <- PlainTextDocument(corpus)
  
  # To remove punctuations from dataset
  #----------------------------------------------------------------------------
  doc <- removePunctuation(doc, preserve_intra_word_dashes = TRUE)
  doc <- str_replace_all(doc, "[^[:alnum:]]", " ")
  
  # To remove leading and trailing whitespaces
  #----------------------------------------------------------------------------
  doc = sub("^[[:space:]]*(.*?)[[:space:]]*$", "\\1", doc, perl=TRUE)
  
  # Frequency calculation and sorting data based on count in descending order
  #----------------------------------------------------------------------------
  freqList <- termFreq(doc, control = list(tokenize = strsplit_space_tokenizer, wordLengths = c(3, Inf)))
  
  # Creating word and frequency columns
  #----------------------------------------------------------------------------
  word <- names(freqList)
  freq <- as.numeric(freqList)
  
  # Creating a dataset with the above two columns
  #----------------------------------------------------------------------------
  ap.d <- data.frame(word,freq)
  ap.d.sorted <- ap.d[order(-freq,word),]
  
  # findFreqTerms findTopTerms
  #----------------------------------------------------------------------------
  if(findFreqTerms){
    indx <- which(ap.d.sorted[,'freq']>=as.numeric(minimumFreq) & ap.d.sorted[,'freq']<=as.numeric(maximumFreq))
    ap.d.sorted <- ap.d.sorted[indx,]
  }
  if(findTopTerms){
    ap.d.sorted <- ap.d.sorted[1:as.numeric(numTerms),]
  }
  
  # To write the frequency report in a csv
  #----------------------------------------------------------------------------
  dir.create(output_path)
  dir.create(paste(output_path,"relationship analysis",sep="/"))
  dir.create(paste(output_path,"relationship analysis","frequency report",sep="/"))
  dir.create(paste(output_path,"relationship analysis","frequency report",varName,sep="/"))
  #   dir.create(paste(output_path,"relationship analysis","frequency report",varName,dropDown,sep="/"))
  #Location of the output file
  #----------------------------------------------------------------------------
  location <- paste(output_path,"relationship analysis","frequency report",varName,"frequency.csv",sep="/")
  #Writing the CSV
  #----------------------------------------------------------------------------
  write.csv(ap.d.sorted, file = location, append = FALSE, col.names = TRUE, row.names = FALSE,quote=F)
  
  # To clear all variable used
  #----------------------------------------------------------------------------
  #   rm(list=c("input_path","fileName","fileLoc","varName","corpus","doc","freq","word",
  #             "freqList","output_path","varIndexA","varIndexE","varIndexN","varIndexV",
  #             "ap.d","ap.d.sorted","tmDataSet","strsplit_space_tokenizer"))
  
}
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# Function to generate the association report
#---------------------------------------------------------------------------------------
genWordAssocReports <- function(input_path, fileName, varName, keyword, output_path) {
  
  # To read data from a csv file and create a dataset from required column(s)
  #---------------------------------------------------------------------------------
  #fileLoc   <- paste(input_path,fileName,sep="/")
  #tmDataSet <- read_data(fileLoc,type="csv")
  load(paste(input_path,fileName,sep="/"))
  tmDataSet <- dataworking
  rm("dataworking")
  varIndex  <- which(colnames(tmDataSet)==varName)
  corpus    <- tolower(tmDataSet[,varIndex])
  #-- #~!@#1052,15mar2013,vasanth#
  corpus    <- corpus[grep(pattern=keyword,x=corpus)]
  #-- #~!@#1052,15mar2013,vasanth#
  corpus <- str_replace_all(corpus, "[^[:alnum:]]", " ")
  
  # To create a document term matrix from the dataset
  #----------------------------------------------------------------------------
  dtmatrix <- create_matrix(corpus,language="english",
                            minWordLength = 3,minDocFreq = 1,ngramLength = 0,
                            removeNumbers = FALSE,stemWords = FALSE,
                            removePunctuation = FALSE,stripWhitespace = FALSE,
                            toLower = TRUE,removeStopwords = FALSE,
                            weighting = weightTf)
  
  rm("corpus","tmDataSet")
  gc(reset=TRUE)
  
  # To find associations for a given keyword and sort the results in descending order of scores
  #--------------------------------------------------------------------------------------------
  associationList <- findAssocs(dtmatrix, keyword, 0.0)
  
  rm("dtmatrix")
  # Creating word and frequency columns
  #----------------------------------------------------------------------------
  word        <- names(associationList)
  assocScore  <- as.numeric(associationList)
  
  # Creating a dataset with the above two columns
  #----------------------------------------------------------------------------
  ap.d <- data.frame(word,assocScore)
  ap.d.sorted <- ap.d[order(-assocScore,word),]
  
  # To remove the analyzed keyword from the association list
  #---------------------------------------------------------
  if(ap.d.sorted$word[1]==keyword) {
    ap.d.sorted = ap.d.sorted[2:nrow(ap.d.sorted),]
  }
  
  # To write the association report in a csv
  #----------------------------------------------------------------------------
  
  dir.create(paste(output_path,"relationship analysis","relationship report",reportName,varName,keyword,sep="/"),recursive=T)
#   dir.create(output_path)
#   dir.create(paste(output_path,"relationship analysis",sep="/"))
#   dir.create(paste(output_path,"relationship analysis","relationship report",sep="/"))
#   dir.create(paste(output_path,"relationship analysis","relationship report",reportName,sep="/"))
#   dir.create(paste(output_path,"relationship analysis","relationship report",reportName,varName,sep="/"))
#   dir.create(paste(output_path,"relationship analysis","relationship report",reportName,varName,keyword,sep="/"))
#   # Location of the output file
  #----------------------------------------------------------------------------
  location <- paste(output_path,"relationship analysis","relationship report",reportName,varName,keyword,"relationship.csv",sep="/")
  # Writing the CSV
  #----------------------------------------------------------------------------
  write.csv(ap.d.sorted, file = location, append = FALSE, col.names = TRUE, row.names = FALSE, quote=F)
  
  # To clear all variable used
  #----------------------------------------------------------------------------
  rm(list=c("input_path","fileName","fileLoc","varName","corpus","word",
            "output_path","varIndex","assocScore","associationList",
            "ap.d","ap.d.sorted","tmDataSet","dtmatrix","keyword"))
  
}
#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------
# Calling the functions
#---------------------------------------------------------------------------------------
if(as.logical(ifFrequency)){
  for(i in 1:length(varName)){
    check <- try(genFreqReports(input_path, 'dataworking.RData', varName[i], as.logical(ifEntireComment), 
                                as.logical(ifNoun), as.logical(ifVerb), as.logical(ifAdj),output_path),silent=T)
    if(!class(check)=='try-error'){
      write.table("Frequency Report successfully generated",paste(output_path,"relationship analysis","frequency report","FREQUENCY_REPORT_COMPLETED.txt",sep="/"),quote=FALSE,row.names=F,col.names=F)
    }
  }
}

if(!as.logical(ifFrequency)){
  for( i in 1:length(keyword)){
    check <- try(genWordAssocReports(input_path, 'dataworking.RData', varName, keyword[i], output_path),silent=T)
    if(!class(check)=='try-error'){
      write.table("Relationship Report successfully generated",paste(output_path,"relationship analysis","relationship report",reportName,"RELATIONSHIP_REPORT_COMPLETED.txt",sep="/"),quote=FALSE,row.names=F,col.names=F)
    }
  }
}
#---------------------------------------------------------------------------------------