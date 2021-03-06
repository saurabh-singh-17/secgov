#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_POS_TAGGER_1.0                                                               --#
#-- Description  :  Extracts POS from user selected variables                                        --#
#-- Return type  :  Adds POS column in the dataset                                                   --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#


#Parameters required
#-----------------------------------------------------------------
#input_path<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
#output_path<-"E:/MRx/Text Mining/Text Mining Sample datasets/"
#varName<-"CONTENT"
#extractVerbs <- "TRUE"
#extractNouns <- "TRUE"
#extractAdjectives <- "TRUE"


#Configurations to load rJava library
#====================================

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

#Reading the dataworking.csv  
#-----------------------------------------------------------------
# dataworking=read.csv(paste(input_path,"/dataworking.csv",sep=""),header=T)
load(paste(input_path,"/dataworking.RData",sep=""))
#if(grp_no!=0){
#  dataworking=subset.data.frame(dataworking,eval(parse(text=paste("grp_",grp_no,"_flag==",grp_flag,sep=""))))
#}


# Defining some custom functions
# 1. To install required packages
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

posTagger <- function(varName,
                      extractVerbs,
                      extractNouns,
                      extractAdjectives) {
  
  dataSize <- nrow(dataworking)
  
  varIndex <- which(colnames(dataworking)==varName)
  
  
  # To covert dataset into a Corpus; required for executing 'tm_map' functions
  #----------------------------------------------------------------------------
  
  dataList <- Corpus(VectorSource(dataworking[,varIndex]))
  
  
  # To remove punctuations from dataset
  #----------------------------------------------------------------------------
  
  dataList <- tm_map(dataList, removePunctuation, preserve_intra_word_dashes = TRUE)
  dataList <- unlist(dataList[1:dataSize])
  
  # POS-tag the dataset
  #----------------------------------------------------------------------------
  
  dataList <- tagPOS(dataList, language = "en")
  
  nounList = c()
  verbList = c()
  adjList = c()
  
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
    
    nounList = c(nounList,noun)
    verbList = c(verbList,verb)
    adjList = c(adjList,adj)
    
  }
  
  verbList = tolower(verbList)
  nounList = tolower(nounList)
  adjList = tolower(adjList)
  
  tmDataSetNew <- cbind(dataworking)
  
  # Adding POS entity data to the original dataset
  #----------------------------------------------------------------------------
  i=0
  col=NULL
  if(extractVerbs) {
    tmDataSetNew <- cbind(tmDataSetNew,verbList)
    col<-c(col,paste(varName,"_verbList",sep=""))
    i=i+1
  }
  
  if(extractNouns) {
    tmDataSetNew <- cbind(tmDataSetNew,nounList)
    col<-c(col,paste(varName,"_nounList",sep=""))
    i=i+1
  }
  
  if(extractAdjectives) {
    tmDataSetNew <- cbind(tmDataSetNew,adjList)
    col<-c(col,paste(varName,"_adjList",sep=""))
    i=i+1
  }
  
  if(extractVerbs | extractNouns | extractAdjectives){
    colnames(tmDataSetNew)[(length(tmDataSetNew)-(i-1)):length(tmDataSetNew)]<-col
  }
  
  
  
  dataworking <- tmDataSetNew
  save(dataworking,file=paste(input_path,"/dataworking.RData",sep=""))
  
  
  return(col)
}
colnm<- NULL

ev <- extractVerbs
en <- extractNouns
ea <- extractAdjectives
for (i in 1:length(varName)) {
  extractVerbs <- ev
  extractNouns <- en
  extractAdjectives <- ea
  v <- paste(varName[i],'verbList',sep="_")
  n <- paste(varName[i],'nounList',sep="_")
  a <- paste(varName[i],'adjList',sep="_")
  if(v %in% colnames(dataworking)) extractVerbs = FALSE
  if(n %in% colnames(dataworking)) extractNouns = FALSE
  if(a %in% colnames(dataworking)) extractAdjectives = FALSE
  colnm<-c(colnm, try(posTagger(varName[i], as.logical(extractVerbs), as.logical(extractNouns), as.logical(extractAdjectives)),silent=T))
}

#Completed text
#------------------------------------------------------------------------------
#colnm <- gsub(paste(colnm,collapse=" "),"\r","",fixed=TRUE)
#colnm <- gsub(colnm,"\n","",fixed=TRUE)
# colnm <- gsub(colnm,"Error in colnames(tmDataSetNew)[(length(tmDataSetNew) - (i - 1)):length(tmDataSetNew)] <- col : \n  replacement has length zero\n","")
write(colnm, file = paste(output_path, "POS_TAGGING_COMPLETED.TXT", sep="/"))


# To clear all variable used
#----------------------------------------------------------------------------
#rm(list = ls())