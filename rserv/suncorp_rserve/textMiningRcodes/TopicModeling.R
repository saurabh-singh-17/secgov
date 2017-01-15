#-------------------------------------------------------------------------------
# sample parameters
#-------------------------------------------------------------------------------
# inputPath        <- 'C:/Users/Anvita.srivastava/MRx/r/logisticDrop-4-Nov-2014-14-47-06/2/'
# c_var_in         <- c('Verbatim')
# ifManual         <- 'false'
# ifAuto           <- 'true'
# numTopics        <- '6'
# numKeys          <- '4'
# numIterations    <- '3'
# n_grp            <- c(1)
# c_grp_flag       <- c("2_1_1")
# n_report_id      <- 'r5'
# c_entity         <- c()
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# libraries required
#-------------------------------------------------------------------------------
library(muPreProcessing)
library(lda)
library(RTextTools)
library(slam)
library(glmnet)
library(NLP)
library(openNLPmodels.en)
library(tau)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function definitions
#-------------------------------------------------------------------------------
tagPOS <- function(corpus,language="en"){
  
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
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Loading the data
#-------------------------------------------------------------------------------
load(paste(inputPath,"/dataworking.RData",sep=""))
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Looping for different levels of panel
#-------------------------------------------------------------------------------
for(i in 1:length(n_grp)) {
  n_grp_now       <- n_grp[i]
  c_grp_flag_now  <- c_grp_flag[i]
  
  if(n_grp_now != 0) {
    index         <- which(dataworking[, paste("grp", n_grp_now, "_flag", sep="")] == c_grp_flag_now)
    data          <- dataworking[index, ]
  } else {
    data          <- dataworking
  }
  
  output_path     <- paste(inputPath,"/",n_grp_now,"/",c_grp_flag_now,"/text mining/topic modeling/"
                           ,n_report_id,sep="")
  
  for (j in 1:length(c_var_in)) {
    # output path for outputs corresponding to this variable
    var_output_path        <- paste(output_path,"/",c_var_in[j],sep="")
    
    # changing the encoding of data for further processing
    index_true<-which(is.locale(as.character(data[,c_var_in[j]])) == "FALSE")
    if(length(index_true))
    {
      data[index_true,c_var_in[j]]<-iconv(as.character(data[index_true,c_var_in[j]]),from="latin1" ,to = "UTF-8")
    }
    
    # initialising analysisData to be the variable selected
    analysisData         <- as.character(data[,c_var_in[j]])
    
    # index of "^$"|"^\\s*$" and NA in analysisData
    index_remove <- grepl(pattern = "(^$)|(^\\s*$)", x = analysisData)
    index_remove <- index_remove | is.na(analysisData)
    
    # remove "^$"|"^\\s*$" and NA from analysisData
    analysisData <- analysisData[!index_remove]
    
    # dataset row index of the elements that are going to be used
    dataset_index_used <- !index_remove
    
    # error check if there are 0 elements
    if (length(analysisData) == 0) {
      write(x="No data to analyse",
            file=paste(var_output_path, "/error.txt", sep=""))
      next
    }
    
    # Extraction of Noun, Verb and Adjective
    if(!is.null(c_entity))
    {
      dataList<-tagPOS(corpus = analysisData, language = "en")
      for(k in 1:length(c_entity)){
        if(k==1)
          POSextract<-paste("[[:punct:]]*/",c_entity[k],".?",sep="")
        else
          POSextract<-paste(POSextract,"|[[:punct:]]*/",c_entity[k],".?",sep="")
      }
      dataList<-sapply(strsplit(dataList,POSextract),function(x) {res = sub("(^.*\\s)(\\w+$)", "\\2", x); res[!grepl("\\s",res)]} )
      dataList<-lapply(dataList,paste,collapse=" ")
      analysisData<-unlist(dataList)
      
      # index of "^$"|"^\\s*$" and NA in analysisData
      index_remove <- grepl(pattern = "(^$)|(^\\s*$)", x = analysisData)
      index_remove <- index_remove | is.na(analysisData)
      
      # remove "^$"|"^\\s*$" and NA from analysisData
      analysisData <- analysisData[!index_remove]
      
      # dataset row index of the elements that are going to be used
      dataset_index_used[dataset_index_used] <- !index_remove
      
      # error check if there are 0 elements
      if (length(analysisData) == 0) {
        write(x="No data to analyse",
              file=paste(var_output_path, "/error.txt", sep=""))
        next
      }
    }
    
    # clean analysisData
    analysisData           <- apply(as.data.frame(analysisData),2,removeURL)
    analysisData           <- apply(analysisData,2,removeNonAlphabetChars)
    analysisData           <- apply(analysisData,2,removeEmailIds)
    analysisData           <- apply(analysisData,2,removeDigits)
    analysisData           <- apply(analysisData,2,compressWhiteSpaces)
    analysisData           <- tolower(analysisData)
    analysisData           <- str_trim(analysisData,side="both")
    
    # error check if there are 0 elements
    if (length(analysisData) == 0) {
      write(x="No data to analyse",
            file=paste(var_output_path, "/error.txt", sep=""))
      next
    }
    
    # number of topics
    if(ifManual) {
      nTopics            <- numTopics
    } else {
      numKeys            <- 5
      numIterations      <- 20
      dtm                <- create_matrix(analysisData,language="english",
                                          minWordLength = 3,minDocFreq = 1,
                                          stripWhitespace = TRUE,
                                          toLower = TRUE,weighting = weightTf)
      
      term_tfidf         <- tapply(dtm$v/row_sums(dtm)[dtm$i], dtm$j, mean) *
        log2(nDocs(dtm)/col_sums(dtm > 0))
      
      dtm                <- dtm[,term_tfidf >= round(summary(term_tfidf)[[3]],digits = 1)]
      dtm                <- dtm[row_sums(dtm) > 0,]
      
      numRow             <- nrow(dtm)
      numCol             <- ncol(dtm)
      
      nonZeroEntries     <- nnzero(dtm)
      
      if(nonZeroEntries == 0) {
        nonZeroEntries   <- 1
      }
      
      nTopics            <- round((numRow * numCol)/(nonZeroEntries))
    }
    
    # find the topics, keywords & probabilities
    analysisData         <- lexicalize(analysisData, lower=TRUE)
    result               <- lda.collapsed.gibbs.sampler(analysisData$documents, nTopics,
                                                        analysisData$vocab, numIterations,
                                                        0.1, 0.1, compute.log.likelihood=TRUE)
    top.words            <- top.topic.words.custom(result$topics, numKeys, by.score=TRUE)
    topic.proportions    <- t(result$document_sums) / colSums(result$document_sums)
    topicPerDoc          <- max.col(topic.proportions, ties.method=c("random", "first", "last"))
    
    # output : the topics and the keywords and their probabilities
    wordProb             <- data.frame(rep(1:nTopics,each=numKeys),
                                       as.character(top.words[[1]]),
                                       as.numeric(top.words[[2]]))
    wordProb             <- na.omit(wordProb)
    colnames(wordProb)   <- c("Topic","Word","Prob")
    
    # output : frequency of the topics
    topicChart           <- data.frame(table(topicPerDoc))
    colnames(topicChart) <- c("Topic", "Freq")
    topicChart           <- topicChart[order(topicChart[,"Topic"]), ]
    
    # output : topic for each of the rows of the variable
    topicModel           <- data.frame(data[c_var_in[j]])
    topicModel[dataset_index_used, "topicPerDoc"] <- topicPerDoc
    colnames(topicModel) <- c("analysisData","topicPerDoc")
    
    # if no rows are assigned to some topics
    #   it will result in topic numbers that are not continuous
    #   and wordProb will have the keywords & probabilities for the missing topics
    # so,
    # removing the keywords & probabilities for the missing topics from wordProb
    # making the topic numbers continuous in topicChart, topicModel & wordProb
    n_uniqueTopics <- sort(topicChart[, "Topic"])
    if (length(n_uniqueTopics) < nTopics) {
      # keeping the keywords & probabilities for only the existing topics
      x_temp   <- wordProb[, "Topic"] %in% n_uniqueTopics
      wordProb <- wordProb[x_temp, ]
      
      # making the topic numbers continuous
      topicChart[, "Topic"]       <- match(x = topicChart[, "Topic"],
                                           table = n_uniqueTopics)
      topicModel[, "topicPerDoc"] <- match(x = topicModel[, "topicPerDoc"],
                                           table = n_uniqueTopics)
      wordProb[, "Topic"]         <- match(x = wordProb[, "Topic"],
                                           table = n_uniqueTopics)
    }
    
    write.csv(wordProb,file=paste(var_output_path, "/wordProb.csv", sep=""),
              row.names=FALSE , quote=FALSE)
    
    write.csv(topicModel,file=paste(var_output_path, "/topicModel.csv", sep=""),
              row.names=FALSE , quote=FALSE)
    
    write.csv(topicChart,file=paste(var_output_path, "/topicChart.csv", sep=""),
              row.names=FALSE , quote=FALSE)
  }
  
  write("TOPIC_MODELING", file = paste(output_path, "TOPIC_MODELING_COMPLETED.TXT", sep="/"))
}
#-------------------------------------------------------------------------------
