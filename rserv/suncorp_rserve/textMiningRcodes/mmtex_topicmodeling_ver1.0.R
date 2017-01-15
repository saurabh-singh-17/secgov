#---------------------------------------------------------------------------------------#
#--                                                                                   --#
#--  Project Name:   Text Mining                                                      --#
#--  Task :          Task 1: Topic Modeling                             	      	  --#
#--  Sub-Task:       1.1 Create topic modeling xml                                    --#
#--  Sub-Task:       1.2 Create topic report                                          --#
#--  version :       1.0 date: 03/04/2012 author: Gaurav Jain/Shankar Jha		          		  --#
#---------------------------------------------------------------------------------------#


# Defining some custom functions
# 1. To install required packages
# 2. To find top words for a topic along with associated score
# 3. To sort the top words based on decreasing order of scores
#---------------------------------------------------------------------------------------

is.installed <- function(pkg){ is.element(pkg, installed.packages()[,1])}


posTagger <- function(filePath, fileName, varName,
                      extractVerbs = TRUE,
                      extractNouns = TRUE,
                      extractAdjectives = TRUE) {


if(!is.installed('RTextTools')){
  install.packages('RTextTools',repo="http://lib.stat.cmu.edu/R/CRAN")
  library('RTextTools')
}
if(!is.installed('openNLP')){
  install.packages('openNLP',repo="http://lib.stat.cmu.edu/R/CRAN")
  library('openNLP')
}
if(!is.installed('openNLPmodels.en')){
  install.packages('openNLPmodels.en',repo="http://lib.stat.cmu.edu/R/CRAN")
  library('openNLPmodels.en')
}

  require('RTextTools')
  require('openNLP')
  require('openNLPmodels.en')

  # To read data from a single csv file and create a dataset of required column
  #----------------------------------------------------------------------------

  # fileLoc <- paste(filePath,fileName,sep="\\")

  # tmDataSet <- read_data(fileLoc,type="csv")

  load(paste(filePath,fileName,sep="/"))
  tmDataSet <- dataworking
  rm("dataworking")

  dataSize <- nrow(tmDataSet)

  varIndex <- which(colnames(tmDataSet)==varName)

  dataList <- as.vector(tmDataSet[,varIndex])

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

  tmDataSetNew <- cbind(tmDataSet)

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
    scores <- apply(as.matrix(normalized.topics), 2, function(x) x * (log(x + 1e-05) - sum(log(x + 1e-05))/length(x)))
    ret1 <- apply(as.matrix(scores),1,sortOnX,env)
    ret2 <- apply(as.matrix(scores),1,sortOnX,env,FALSE)

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



topicModeling <- function(filePath, fileName, varName,
                          ifEntireComment = TRUE,
                          ifVerbs = FALSE, ifNouns = FALSE, ifAdj = FALSE,
                          ifManual = FALSE, ifAuto = FALSE,
                          numTopics = 5, numKeys = 10, numIterations = 10,
                          reportLoc, topicDistLoc, xmlLoc) {

  if(!is.installed('RTextTools')){
    install.packages('RTextTools',repo="http://lib.stat.cmu.edu/R/CRAN")
    library('RTextTools')
  }
  if(!is.installed('lda')){
    install.packages('lda',repo="http://lib.stat.cmu.edu/R/CRAN")
    library('lda')
  }
  if(!is.installed('XML')){
    install.packages('XML',repo="http://lib.stat.cmu.edu/R/CRAN")
   library('XML')
  }
  if(!is.installed('slam')){
    install.packages('slam',repo="http://lib.stat.cmu.edu/R/CRAN")
    library('slam')
  }

  require('RTextTools')
  require('lda')
  require('XML')
  require('slam')

  # To read data from a csv file and create a dataset from required column(s)
  #---------------------------------------------------------------------------------

  #fileLoc <- paste(filePath,fileName,sep="/")

  #tmDataSet <- read_data(fileLoc,type="csv")
   tmDataSet <-  tmDataSet<-posTagger(filePath, fileName, varName,
                      extractVerbs = TRUE,
                      extractNouns = TRUE,
                      extractAdjectives = TRUE)	

  corpus = ""

  if(ifEntireComment) {
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


  tmDataSetNew <- cbind(tmDataSet,topicPerDoc)
  tmDataSetNew=tmDataSetNew[,-which(colnames(tmDataSetNew)%in% c("nounPOS","verbPOS","adjPOS"))]	

  write.csv(tmDataSetNew, file = reportLoc, append = FALSE, col.names = TRUE,
            row.names = FALSE)

  Topic <- topicPerDoc # renaming the column as 'topic'

  Topic <- table(Topic) # creating a frequency report

  write.csv(Topic, file = topicDistLoc, append = FALSE, col.names = TRUE,
            row.names = FALSE) # creating a csv file for frequency report

  # To write the topic xml in a file
  #----------------------------------------------------------------------------

  resultXML <- newXMLNode("Map")
  numOfGroups <- ncol(word.list)

  for(i in 1:ncol(word.list)) {

    nodeName <- newXMLNode("Topic",attrs=c(type = "package",name=i),parent = resultXML)

    for(j in 1:nrow(word.list)){
      newXMLNode("node",attrs=c(type="class", label=as.character(word.list[j,i]), size = score.list[j,i]),parent=nodeName)
    }

  }

  resultXML <- saveXML(resultXML, indent=TRUE)
  #resultXML <- as.character(resultXML)

  write(resultXML, file = xmlLoc)


  # To clear all variable used
  #----------------------------------------------------------------------------

  rm(list=c("filePath","fileName","fileLoc","varName","corpus","reportLoc",
            "varIndex","tmDataSet","tmDataSetNew","word.list","score.list",
            "topicPerDoc","topic.proportions","result","top.words","nTopics",
            "resultXML","nodeName","numOfGroups"))

}