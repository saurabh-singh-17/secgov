#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Frequency_Analysis_1.0                                                       --#
#-- Description  :  Some functions to  generate frequency reports(unigram analysis)                  --#
#-- Return type  :  generates CSV report and word cloud                                              --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#

#Parameters required
#-----------------------------------------------------------------
# input_path<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
# varName<-c("CONTENT")
# ifVerbs <-"true"
# ifNouns <-"true"
# ifAdj <-"true"
# reportLoc<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
# freqCloudLoc<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
# topCloudLoc<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
# minWordLen <-3 
# minDocFreq <-1
# findFreqTerms<-"false"
# findTopTerms <-"true"
# minimumFreq<-""
# maximumFreq <-"" 
# numTerms<-"25"
# output_path<-"E:/MRx/Text Mining/Text Mining Sample datasets/"

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

#---------------------------------------------------------------------------------------
# Loading the data
#---------------------------------------------------------------------------------------
load(paste(input_path,"/dataworking.RData",sep=""))
grp_no <- as.numeric(grp_no)
if (grp_no != 0) {
  index <- which(dataworking[, paste("grp", grp_no, "_flag", sep="")] == grp_flag)
  dataworking <- dataworking[index, ]
}
#---------------------------------------------------------------------------------------



# Defining some custom functions
#-----------------------------------------------------------------
posTagger <- function(varName,
                      extractVerbs = TRUE,
                      extractNouns = TRUE,
                      extractAdjectives = TRUE) {
  
  
  
  
  
  dataSize <- nrow(dataworking)
  
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



strsplit_space_tokenizer <- function(x) unlist(strsplit(x, "[[:space:]]+"))

freqAnalysis <- function(varName,
                         ifVerbs = FALSE, ifNouns = FALSE, ifAdj = FALSE,
                         reportLoc, freqCloudLoc, topCloudLoc,
                         minWordLen = 3, minDocFreq = 1,
                         findFreqTerms = FALSE, findTopTerms = FALSE,
                         minimumFreq = 1, maximumFreq = Inf, numTerms = 25) {
  extractVerbs = TRUE
  extractNouns = TRUE
  extractAdjectives = TRUE
  tmDataSet <- posTagger(varName,TRUE,TRUE,TRUE)	
  corpus = ""
  
  if(!ifVerbs & !ifNouns & !ifAdj) {
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
  
  # To convert dataset into Plain text document
  #----------------------------------------------------------------------------
  
  doc <- PlainTextDocument(corpus)
  
  # To remove punctuations from dataset
  #----------------------------------------------------------------------------
  
  doc <- removePunctuation(doc, preserve_intra_word_dashes = TRUE)
  
  # To remove leading and trailing whitespaces
  #----------------------------------------------------------------------------
  
  doc = sub("^[[:space:]]*(.*?)[[:space:]]*$", "\\1", doc, perl=TRUE)
  
  # Frequency calculation and sorting data based on count in descending order
  # -------------------------------------------------------------------------
  
  freqList <- termFreq(doc,
                       control = list(tokenize = strsplit_space_tokenizer,
                                      wordLengths = c(minWordLen, Inf)))
  
  word = names(freqList)
  freq <- as.numeric(freqList)
  
  ap.d <- data.frame(word,freq)
  
  ap.d.sorted <- ap.d[order(-freq,word),]
  
  comment.count = nrow(tmDataSet)
  unique.word.count = nrow(ap.d.sorted)
  total.word.count = sum(ap.d.sorted$freq)
  
  dir.create(path=paste(reportLoc,varName,sep="/"),recursive=T)
  
  #-------------------------------------------------------------------------------
  # Finding terms between the specified term & document frequency range
  #-------------------------------------------------------------------------------
  if(findFreqTerms) {
    
    # term frequency range subsetting
    subset        <- ap.d.sorted$freq >= minimumFreq & ap.d.sorted$freq <= maximumFreq
    
    freqTermsList <- subset(x=ap.d.sorted, subset=subset)
    
    if(nrow(freqTermsList) == 0) {
      c_error <- "term frequency range subsetting gave 0 terms"
      write(x=c_error, file=paste(output_path, "/error.txt", sep=""))
      stop(c_error)
    }
    
    f <- function(x) {
      length(grep(pattern=paste("\\b", x, "\\b", sep=""), x=doc))
    }
    
    # column 3 : freqShare
    # column 4 : commentsPresent
    # column 5 : commentShare
    n_c3 <- round(x=(freqTermsList$freq / total.word.count) * 100, digits=2)
    n_c4 <- sapply(X=freqTermsList$word, FUN=f)
    n_c5 <- round(x=(n_c4 / comment.count) * 100, digits=2)
    
    freqTermsList <- cbind.data.frame(freqTermsList,
                                      freqShare=n_c3,
                                      commentsPresent=n_c4,
                                      commentShare=n_c5)
    
    # document frequency range subsetting
    subset        <- freqTermsList$commentsPresent >= minDocFreq
    
    freqTermsList <- subset(x=freqTermsList, subset=subset)
    
    if(nrow(freqTermsList) == 0) {
      c_error <- "document frequency range subsetting gave 0 terms"
      write(x=c_error, file=paste(output_path, "/error.txt", sep=""))
      stop(c_error)
    }
    
    # output
    write.csv(freqTermsList,
              file=paste(reportLoc, varName, "/termsList.csv", sep=""),
              row.names=FALSE , quote=FALSE)
    #-------------------------------------------------------------------------------
    
    
    # Settings for word cloud image creation
    # Creates a png in the specified directory
    #---------------------------------------------------------------------------------------
    
    pal2 <- brewer.pal(8,"Dark2")
    
    png(paste(reportLoc,varName,"topCloud.png",sep="/"), width=800, height=600)
    
    wordcloud(freqTermsList$word, freqTermsList$freq, scale=c(8,.2), min.freq=1, max.words=Inf,random.order=FALSE,rot.per=.15, colors=pal2)
    
    #---------------------------------------------------------------------------------------
    # Closing time!
    #---------------------------------------------------------------------------------------
    
    dev.off()
    
  }
  
  # Finding topmost frequent terms
  # -------------------------------------------------------------------------
  
  if(findTopTerms) {
    
    # numTerms = number of top terms
    # -------------------------------
    
    topTermsList <- ap.d.sorted[1:numTerms,]
    
    topTermsList$freqShare <- round((topTermsList$freq/total.word.count)*100,
                                    digits=2)
    
    x <- sapply(topTermsList$word, function(str)
    {str=paste(str," ",sep="")
     length(subset(corpus, grepl(str, corpus)))},
                simplify = TRUE, USE.NAMES = FALSE)
    
    y <- sapply(topTermsList$word, function(str)
    {str=paste(" ",str,"$",sep="")
     length(subset(corpus, grepl(str, corpus)))},
                simplify = TRUE, USE.NAMES = FALSE)
    
    topTermsList$commentsPresent <- x + y
    
    topTermsList$commentShare <- round((topTermsList$commentsPresent/comment.count)*100,
                                       digits=2)
    
    topTermsList <- subset(topTermsList, topTermsList$commentsPresent >= minDocFreq)
    
    # To write the frequency report in a csv
    #----------------------------------------------------------------------------
    
    write.csv(topTermsList, file = paste(reportLoc,varName,"termsList.csv",sep="/"), append = FALSE, col.names = TRUE,
              row.names = FALSE, quote=FALSE)
    
    # Settings for word cloud image creation
    # Creates a png in the specified directory
    #---------------------------------------------------------------------------------------
    
    pal2 <- brewer.pal(8,"Dark2")
    
    png(paste(topCloudLoc,varName,"topCloud.png",sep="/"), width=800, height=600)
    #print(topTermsList$word)
    #print(topTermsList$freq)
    
    wordcloud(topTermsList$word, topTermsList$freq, scale=c(8,.2), min.freq=1, max.words=Inf,random.order=FALSE,rot.per=.15, colors=pal2)
    
    #---------------------------------------------------------------------------------------
    # Closing time!
    #---------------------------------------------------------------------------------------
    
    dev.off()
    
  }
  
  returnStr <- paste(comment.count,total.word.count,unique.word.count,sep=",")
  return(returnStr)
}


for (i in 1:length(varName)) {
  freqAnalysis (varName[i],
                as.logical(ifVerbs), as.logical(ifNouns), as.logical(ifAdj),
                reportLoc, freqCloudLoc, topCloudLoc,
                as.numeric(minWordLen), as.numeric(minDocFreq),
                as.logical(findFreqTerms),as.logical(findTopTerms),
                as.numeric(minimumFreq), as.numeric(maximumFreq), as.numeric(numTerms))
  
}


#Completed text
#-------------------------------------------
write("FREQUENCY_ANALYSIS", file = paste(output_path, "FREQUENCY_ANALYSIS_COMPLETED.TXT", sep="/"))


# To clear all variable used
#----------------------------------------------------------------------------
