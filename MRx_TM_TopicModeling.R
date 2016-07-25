#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_TopicModeling_1.0                                                            --#
#-- Description  :  Contains some functions to  enable Topic Modeling in Text Mining module of MRx   --#
#-- Return type  :  Generates xmls and csv at output location                            --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#


#Parameters required
#-----------------------------------------------------------------
# input_path="C:/Documents and Settings/shankar.jha/Desktop/Text mining r codes/"
# varName=c("CONTENT","COMMENTS")
# ifEntireComment = "true"
# ifVerbs = "false" 
# ifNouns = "false"
# ifAdj = "false"
# ifManual = "true"
# ifAuto = "false"
# numTopics = 5
# numKeys = 10
# numIterations = 10
# reportLoc="C:/Documents and Settings/shankar.jha/Desktop/Text mining r codes/"
#Configurations to load rJava library
#====================================

#Reading java path from the system paths
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


#Libraries required
#-----------------------------------------------------------------
library('SnowballC')
library('tm')
library('openNLP')
library('openNLPmodels.en')
library('lda')
library('XML')
library('slam')
library('stringr')
library('wordcloud')
library('RColorBrewer')
library('rJava')
library('RTextTools')
library('Snowball')
library('NLP')


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

#Reading the dataworking.csv  
#-----------------------------------------------------------------
# dataworking=read.csv(paste(input_path,"/dataworking.csv",sep=""),header=T)
load(paste(input_path,"/dataworking.RData",sep=""))
dataworking<-na.omit(dataworking)
#if(grp_no!=0){
#  dataworking=subset.data.frame(dataworking,eval(parse(text=paste("grp_",grp_no,"_flag==",grp_flag,sep=""))))
#}


# Defining some custom functions
# 1. To Extract POS if required
# 2. To find top words for a topic along with associated score
# 3. To sort the top words based on decreasing order of scores
# 4. Main function to perform topic modeling using above function
#---------------------------------------------------------------------------------------

#is.installed <- function(pkg){ is.element(pkg, installed.packages()[,1])}

posTagger <- function(varName,
                      extractVerbs = TRUE,
                      extractNouns = TRUE,
                      extractAdjectives = TRUE) {
  
  #dataSize <- nrow(tmDataSet)
  
  varIndex <- which(colnames(dataworking)==varName)
  
  dataList <- as.vector(dataworking[,varIndex])
  
  # To remove punctuations from dataset
  #----------------------------------------------------------------------------
  
  dataList <- removePunctuation(dataList, preserve_intra_word_dashes = FALSE)
  
  # POS-tag the dataset
  #----------------------------------------------------------------------------
  
  dataList <- tagPOS(dataList, language = "en")
  
  nounPOS = c()
  verbPOS = c()
  adjPOS = c()
  
  # Extracting nouns, verbs and adjectives from the tagged data
  #----------------------------------------------------------------------------
  
  for(i in 1:length(dataList)) {
    
    wordlist <- unlist(strsplit(dataList[i], " ", fixed=TRUE))
    splitVars <- sapply(wordlist, function(str){strsplit(str, "/", fixed=TRUE)},
                        simplify = TRUE, USE.NAMES = FALSE)
    
    splitMat <- as.data.frame(t(data.frame(splitVars)))
    
    words = as.character(splitMat$V1)
    postags = as.vector(splitMat$V2)
    
    noun = ""
    verb = ""
    adj = ""
    
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
    adjPOS = c(adjPOS,adj)
    
  }
  
  verbPOS = tolower(verbPOS)
  nounPOS = tolower(nounPOS)
  adjPOS = tolower(adjPOS)
  
  tmDataSetNew <- cbind(dataworking)
  
  # Adding POS entity data to the original dataset
  #----------------------------------------------------------------------------
  
  if(extractVerbs) {
    tmDataSetNew <- cbind(tmDataSetNew,verbPOS)
  }
  
  if(extractNouns) {
    tmDataSetNew <- cbind(tmDataSetNew,nounPOS)
  }
  
  if(extractAdjectives) {
    tmDataSetNew <- cbind(tmDataSetNew,adjPOS)
  }
  
  return(tmDataSetNew)
}


top.topic.words.custom <- function(topics, num.words = 20, by.score = FALSE) {
  if(by.score){
    rm(list = c('env'))
    env <- new.env(parent = globalenv())
    env$num.words <- num.words
    env$topics <- topics
    normalized.topics <- topics/(rowSums(topics) + 1e-05)
    nTopics<-nrow(topics)
    if(nTopics > 1) { 
      scores <- apply(as.matrix(normalized.topics), 2, function(x) x * (log(x + 1e-05) - sum(log(x + 1e-05))/length(x)))
    } else {
      scores<-as.matrix(normalized.topics)
    }
    ret1 <- apply(as.matrix(scores),1,sortOnX,env)
    ret2 <- apply(as.matrix(scores),1,sortOnX,env,FALSE)
    if((nTopics > 1)==FALSE)
    {
      row.names(ret2)<-NULL 
    }
    
  } else {
    ret1 <- apply(as.matrix(topics),1,sortOnX,env)
    ret2 <- apply(as.matrix(topics),1,sortOnX,env,FALSE)
  }
  
  rm(list = c('env'))
  return(list(ret1,ret2))
}

sortOnX <- function(x,env,retNames = TRUE) {
  if(retNames) {
    retVec <- colnames(env$topics)
  } else {
    retVec <- x
  }
  retVec[order(x,decreasing = TRUE)[1:env$num.words]]
}



topicModeling <- function(varName,
                          ifEntireComment = TRUE,
                          ifVerbs = FALSE, ifNouns = FALSE, ifAdj = FALSE,
                          ifManual = FALSE, ifAuto = FALSE,
                          numTopics = 5, numKeys = 10, numIterations = 10,
                          reportLoc, topicDistLoc, xmlLoc) {
  
  tmDataSet <-  tmDataSet<-posTagger(varName,
                                     extractVerbs = TRUE,
                                     extractNouns = TRUE,
                                     extractAdjectives = TRUE)  
  
  corpus = ""
  
  if(as.logical(ifEntireComment)) {
    varIndex <- which(colnames(tmDataSet)==varName)
    corpus <- tolower(tmDataSet[,varIndex])
  } else {
    if(ifVerbs) {
      varIndex <- which(colnames(tmDataSet)=='verbPOS')
      corpus <- tolower(tmDataSet[,varIndex])
    }
    if(ifNouns) {
      varIndex <- which(colnames(tmDataSet)=='nounPOS')
      corpus <- paste(corpus,tolower(tmDataSet[,varIndex]),sep=" ")
    }
    if(ifAdj) {
      varIndex <- which(colnames(tmDataSet)=='adjPOS')
      corpus <- paste(corpus,tolower(tmDataSet[,varIndex]),sep=" ")
    }
  }
  
  # Check for number of topics and subsequent calculation of optimum number of topics
  # ---------------------------------------------------------------------------------
  
  if(ifManual) {
    nTopics <- numTopics
  } else if(ifAuto) {
    dtm <- create_matrix(corpus,language="english",
                         minWordLength = 3,minDocFreq = 2,
                         stripWhitespace = TRUE,
                         toLower = TRUE,weighting = weightTf)
    
    term_tfidf <- tapply(dtm$v/row_sums(dtm)[dtm$i], dtm$j, mean) *
      log2(nDocs(dtm)/col_sums(dtm > 0))
    
    dtm <- dtm[,term_tfidf >= round(summary(term_tfidf)[[3]],digits = 1)]
    dtm <- dtm[row_sums(dtm) > 0,]
    
    numRow <- nrow(dtm)
    numCol <- ncol(dtm)
    
    nonZeroEntries = nnzero(dtm)
    
    if(nonZeroEntries == 0) {
      nonZeroEntries = 1
    }
    
    nTopics <- (numRow * numCol)/(nonZeroEntries)
    nTopics = round(nTopics)
    
  }
  
  # Topic extraction and most likely topic per document
  # -------------------------------------------------------------------------
  
  len <- length(corpus)
  
  if(len > 0) {
    corpus <- str_trim(corpus,side="both")
    corpus <- lexicalize(corpus, lower=TRUE)
    result <- lda.collapsed.gibbs.sampler(corpus$documents, nTopics,
                                          corpus$vocab, numIterations,
                                          0.1, 0.1, compute.log.likelihood=TRUE)
    top.words <- top.topic.words.custom(result$topics, numKeys, by.score=TRUE)
    
    word.list <- top.words[[1]]
    score.list <- top.words[[2]]
    word.list <- as.data.frame(word.list)
    score.list <- as.data.frame(score.list)
    
    topic.proportions <- t(result$document_sums) / colSums(result$document_sums)
    topicPerDoc <- max.col(topic.proportions, ties.method=c("random", "first", "last"))
    
  } else {
    word.list <- as.data.frame('Insufficient data')
    score.list <- as.data.frame('1')
    
  }
  
  # To write the topic allocation and distribution reports in csvs
  #----------------------------------------------------------------------------
  dir.create(path=paste(reportLoc,varName,sep="/"),recursive=T)
  
  tmDataSetNew <- cbind(tmDataSet,topicPerDoc)
  tmDataSetNew=tmDataSetNew[,-which(colnames(tmDataSetNew)%in% c("nounPOS","verbPOS","adjPOS"))]	
  
  write.csv(tmDataSetNew, file = paste(reportLoc,varName,"topicmodel.csv",sep="/"), append = FALSE, col.names = TRUE, quote=FALSE,
            row.names = FALSE)
  
  Topic <- topicPerDoc # renaming the column as 'topic'
  
  Topic <- table(Topic) # creating a frequency report
  
  write.csv(Topic, file = paste(reportLoc,varName,"topicchart.csv",sep="/"), append = FALSE, col.names = TRUE, quote=FALSE,
            row.names = FALSE) # creating a csv file for frequency report
  
  # To write the topic xml in a file
  #----------------------------------------------------------------------------
  
  resultXML <- newXMLNode("Map")
  numOfGroups <- ncol(word.list)
  
  if(length(which(word.list==""))>0)
  {
    score.list<-as.data.frame(score.list[-as.numeric(c(which(word.list=="")%%nrow(word.list))),])
    row.names(score.list)<-NULL
    word.list<-as.data.frame(word.list[-as.numeric(c(which(word.list=="")%%nrow(word.list))),])
    row.names(word.list)<-NULL
    
  }
  
  
  for(i in 1:ncol(word.list)) {
    
    nodeName <- newXMLNode("Topic",attrs=c(type = "package",name=i),parent = resultXML)
    
    for(j in 1:nrow(word.list)){
      newXMLNode("node",attrs=c(type="class", label=as.character(word.list[j,i]), size = score.list[j,i]),parent=nodeName)
    }
    
  }
  
  resultXML <- saveXML(resultXML, indent=TRUE)
  #resultXML <- as.character(resultXML)
  
  write(resultXML, file = paste(reportLoc,varName,"topicxml.xml",sep="/"))
}



for(i in 1:length(varName)){
  topicModeling(varName[i],ifEntireComment,
                ifVerbs, ifNouns, ifAdj,
                ifManual, ifAuto,
                numTopics, numKeys, numIterations,
                reportLoc)
  
}

#completed.text
write("TOPIC_MODELING", file = paste(reportLoc, "TOPIC_MODELING_COMPLETED.TXT", sep="/"))


# To clear all variable used
#----------------------------------------------------------------------------

