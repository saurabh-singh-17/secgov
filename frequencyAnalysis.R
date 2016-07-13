#-------------------------------------------------------------------------------
# TO - DO
#-------------------------------------------------------------------------------
# understand # changing the encoding of data for further processing
# 1:n_numTerms subsetting # i am not sure it is sorted
# shouldnt remove punctuations # should replace them with space
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# Parameters required
#-------------------------------------------------------------------------------
# inputPath <- 'C:/Users/Anvita.srivastava/MRx/r/logisticDrop-4-Nov-2014-14-47-06/2/'
# c_var_in <- c('v2')
# n_minWordLength <- 3
# n_minDocFrequency <- 1
# n_minFrequency <- 1
# n_maxFrequency <- Inf
# n_numTerms <- NULL
# n_grp <- c('0','1','1','2','2','2')
# c_grp_flag <- c('1_1_1','1_2_1','1_2_2','1_1_2','1_1_1','1_1_2')
# c_entity <- c()
# n_report_id <- '2'
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



#-------------------------------------------------------------------------------
# parameter play
#-------------------------------------------------------------------------------
n_minWordLength   <- as.numeric(n_minWordLength)
n_minDocFrequency <- as.numeric(n_minDocFrequency)
n_minFrequency    <- as.numeric(n_minFrequency)
n_maxFrequency    <- as.numeric(n_maxFrequency)
n_numTerms        <- as.numeric(n_numTerms)
n_report_id       <- as.numeric(n_report_id)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#Libraries required
#-------------------------------------------------------------------------------
library(muPreProcessing)
library(muFrequency)
library(NLP)
library(tau)
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function: tagPOS
#-------------------------------------------------------------------------------
tagPOS <- function (corpus,language="en") {
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
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
# function: analyseFrequency
# author : I & D
# edited by : Vasanth M M
#-------------------------------------------------------------------------------
analyseFrequency <- function (x,
                              minDocFrequency  = 1,  # minFrequencyInADoc
                              minTermFrequency = 0,  # minFrequencyInTheVar
                              maxTermFrequency = Inf,  # maxFrequencyInTheVar
                              minTermLength    = 1) {  
  # PRE - OP : INPUT VALIDATION
  # x should be of class character
  if (class(x) != "character") {
    stop("x should be of class character",
         call. = TRUE)
  }
  # minDocFrequency should be of class integer/numeric
  if (!(class(minDocFrequency) %in% c("integer", "numeric"))) {
    stop("minDocFrequency should be of class integer/numeric",
         call. = TRUE)
  }
  # minDocFrequency should be greater than or equal to 1
  if (minDocFrequency < 1) {
    stop("minDocFrequency should be greater than or equal to 1",
         call. = TRUE)
  }
  # minTermFrequency should be of class integer/numeric
  if (!(class(minTermFrequency) %in% c("integer", "numeric"))) {
    stop("minTermFrequency should be of class integer/numeric",
         call. = TRUE)
  }
  # minTermFrequency should be greater than or equal to 1
  if (minTermFrequency < 1) {
    stop("minTermFrequency should be greater than or equal to 1",
         call. = TRUE)
  }
  # maxTermFrequency should be of class integer/numeric
  if (!(class(maxTermFrequency) %in% c("integer", "numeric"))) {
    stop("maxTermFrequency should be of class integer/numeric",
         call. = TRUE)
  }
  # maxTermFrequency should be greater than or equal to minTermFrequency
  if (maxTermFrequency < minTermFrequency) {
    stop("maxTermFrequency should be greater than or equal to minTermFrequency",
         call. = TRUE)
  }
  # minTermLength should be of class integer/numeric
  if (!(class(minTermLength) %in% c("integer", "numeric"))) {
    stop("minTermLength should be of class integer/numeric",
         call. = TRUE)
  }
  # minTermLength should be greater than or equal to 1 and less than Inf
  if (minTermLength < 1 | minTermLength == Inf) {
    stop("minTermLength should be greater than or equal to 1 and less than Inf",
         call. = TRUE)
  }
  
  # PRE - OP : CLEAN THE INPUT
  # convert into lowercase
  x <- tolower(x)
  # remove punctuation characters
  x <- removePunctuation(x, preserve_intra_word_dashes = TRUE)
  # trim leading and trailing blanks
  x <- sub("^[[:space:]]*(.*?)[[:space:]]*$", "\\1", x, perl = TRUE)
  # remove blank documents
  x <- x[x != ""]
  # the function termFreq wont work with character. so...
  x <- PlainTextDocument(x)
  
  # PRE - OP : INPUT VALIDATION
  # x should have at least one valid document
  if (length(x) < 1) {
    stop("x should have at least one valid document",
         call. = TRUE)
  }
  
  # PRE - OP : INITIALIZATION
  # the data.frame that will be returned in all cases
  df_frequency <- data.frame(Term = character(0),
                             TermFrequency = integer(0),
                             TermFrequencyPercentage = numeric(0),
                             DocumentFrequency = integer(0),
                             DocumentFrequencyPercentage = numeric(0),
                             stringsAsFactors = FALSE)
  # function : to split the document into terms
  strsplit_space_tokenizer <- function(x) unlist(strsplit(x, "[[:space:]]+"))
  # function : customized : to find how many documents contain a term
  FUN <- function(term, document) {
    x_temp <- paste("(^|[[:space:]])", term, "([[:space:]]|$)", sep="")
    x_temp <- grep(pattern = x_temp,
                   x = document,
                   ignore.case = TRUE)
    x_temp <- length(x_temp)
    return(x_temp)
  }
  
  # OP : FIND TERM FREQUENCY ON A TERM LEVEL
  # get a vector of term frequencies whose names are the terms
  x_temp <- termFreq(x,
                     control = list(tokenize = strsplit_space_tokenizer, 
                                    wordLengths = c(minTermLength, Inf)))
  # extract terms from it
  Term <- names(x_temp)
  # extract term frequencies from it
  TermFrequency <- as.numeric(x_temp)
  
  # OP : SUBSET TERMS BASED ON MIN AND MAX FREQUENCIES INPUT
  # index of the required terms
  x_temp <- TermFrequency >= minTermFrequency & TermFrequency <= maxTermFrequency
  # if no valid terms are present, return default values
  if (!any(x_temp)) {
    return(df_frequency)
  }
  # if valid terms are present, keep only those
  Term <- Term[x_temp]
  TermFrequency <- TermFrequency[x_temp]
  
  # OP : FIND DOCUMENT FREQUENCY ON A TERM LEVEL
  DocumentFrequency <- sapply(X = Term, FUN = FUN, document = x)
  
  # OP : SUBSET TERMS BASED ON MIN DOCUMENT FREQUENCY INPUT
  # index of the required terms
  x_temp <- DocumentFrequency >= minDocFrequency
  # if no valid terms are present, return default values
  if (!any(x_temp)) {
    return(df_frequency)
  }
  # if valid terms are present, keep only those
  Term <- Term[x_temp]
  TermFrequency <- TermFrequency[x_temp]
  DocumentFrequency <- DocumentFrequency[x_temp]
  
  # OP : FIND TERM & DOCUMENT FREQUENCY PERCENTAGES ON A TERM LEVEL
  TermFrequencyPercentage <- TermFrequency / sum(TermFrequency) * 100
  TermFrequencyPercentage <- round(x = TermFrequencyPercentage, digits = 3)
  DocumentFrequencyPercentage <- DocumentFrequency / sum(DocumentFrequency) * 100
  DocumentFrequencyPercentage <- round(x = DocumentFrequencyPercentage, digits = 3)
  
  # OP : RETURN THE RESULTS
  df_frequency <- data.frame(Term,
                             TermFrequency,
                             TermFrequencyPercentage,
                             DocumentFrequency,
                             DocumentFrequencyPercentage,
                             row.names = NULL,
                             stringsAsFactors = FALSE)
  return(df_frequency)
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
for (i in 1:length(n_grp)) {
  n_grp_now            <- n_grp[i]
  c_grp_flag_now       <- c_grp_flag[i]
  
  if (n_grp_now != 0) {
    x_temp <- paste("grp", n_grp_now, "_flag", sep="")
    x_temp <- which(dataworking[, x_temp] == c_grp_flag_now)
    data   <- dataworking[x_temp, c_var_in, drop = FALSE]
  } else {
    data   <- dataworking[c_var_in]
  }
  
  for (j in 1:length(c_var_in)) {
    # the data to be analysed
    analysisData <- as.character(data[, c_var_in[j]])
    
    # changing the encoding of data for further processing
    x_temp <- which(is.locale(analysisData) == "FALSE")
    if (length(x_temp)) {
      analysisData <- iconv(analysisData, from = "latin1", to = "UTF-8")
    }
    
    # output path with some logic for checking if its freq or rel
    if (length(n_report_id)) {
      var_output_path <- paste(inputPath,"/",n_grp_now,"/",c_grp_flag_now,"/text mining/frequency analysis/"
                               ,n_report_id,"/",c_var_in[j],sep="")
    }else {
      var_output_path <- paste(inputPath,"/",n_grp_now,"/",c_grp_flag_now,"/",
                               "/text mining/relationship analysis/frequency report/",c_var_in[j],sep="")
    }
    
    # Remove blank rows
    analysisData <- analysisData[!grepl(pattern = "^[[:space:]]*$",
                                        x = analysisData)]
    
    # 
    if (!length(analysisData)) {
      write(x="No data to analyse",
            file=paste(var_output_path, "/warning.txt", sep=""))
      next
    }
    
    # Extraction of Noun, Verb and Adjective
    if (!is.null(c_entity)) {
      extractPos <- NULL
      for (k in 1:length(c_entity)) {
        x_temp     <- extractPOS(analysisData, c_entity[k])
        extractPos <- paste(extractPos, x_temp, sep=" ")
      }
      analysisData <- extractPos
    }
    
    # Remove blank rows
    analysisData <- analysisData[!grepl(pattern = "^[[:space:]]*$",
                                        x = analysisData)]
    
    # 
    if (!length(analysisData)) {
      write(x="No data to analyse",
            file=paste(var_output_path, "/warning.txt", sep=""))
      next
    }
    
    # get the frequency list
    freqList <- analyseFrequency(x                = analysisData,
                                 minDocFrequency  = n_minDocFrequency,
                                 minTermFrequency = as.numeric(n_minFrequency),
                                 maxTermFrequency = as.numeric(n_maxFrequency),
                                 minTermLength    = n_minWordLength)
    colnames(freqList) <- c("word", "freq", "freqShare", "commentsPresent", "commentShare")
    
    # 
    if (!nrow(freqList)) {
      write(x="Term frequency range subsetting gave 0 terms",
            file=paste(var_output_path, "/warning.txt", sep=""))
      next
    }
    
    # 
    if (length(n_numTerms)) {
      if (n_numTerms >= nrow(freqList)) {
        n_numTerms <- nrow(freqList)
      }
      freqList <- freqList[1:n_numTerms, ]
    }
    
    if(length(n_report_id)) {
      write.csv(freqList,file=paste(var_output_path, "/termsList.csv", sep=""),
                row.names=FALSE , quote=FALSE)
      # Settings for word cloud image creation
      # Creates a png in the specified directory
      pal2 <- brewer.pal(8,"Dark2")
      png(paste(var_output_path,"WordCloud.png",sep="/"), width=800, height=600)
      wordcloud(freqList$word, freqList$freq, scale=c(8,.2), min.freq=1, max.words=Inf,random.order=FALSE,rot.per=.15, colors=pal2)
      dev.off()
    }else{
      write.csv(freqList[c("word","freq")],file=paste(var_output_path, "/termsList.csv", sep=""),
                row.names=FALSE , quote=FALSE)
    }
  }
  
  # completed txt for this grp
  if (length(n_report_id)) {
    write("FREQUENCY_ANALYSIS", file = paste(inputPath,"/",n_grp_now,"/",c_grp_flag_now,"/text mining/frequency analysis/"
                                             ,n_report_id, "/", "FREQUENCY_ANALYSIS_COMPLETED.TXT", sep=""))
  } else {
    write("FREQUENCY_ANALYSIS", file = paste(inputPath,"/",n_grp_now,"/",c_grp_flag_now,"/text mining/relationship analysis/frequency report/"
                                             ,"FREQUENCY_ANALYSIS_COMPLETED.TXT", sep=""))  
  }
}