#---------------------------------------------------------------------------------------
# Sample Parameters
#---------------------------------------------------------------------------------------
# inputPath <- 'C:/Users/nida.arif/Desktop/abc/textmining'
# c_grp <- c('0','0','0')
# c_grp_flag <- c('1_1_1','1_1_1','1_1_1')
# variables <- c('Verbatim','Verbatim','Verbatim')
# c_report_id <- '1'
# words <- c('Desktop   ',' prov ','  I bet  not  ')
# ifNGram <- 'true'

#---------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------
# Libraries
#---------------------------------------------------------------------------------------
library(lsa)
library(muPreProcessing)
library(tau)
#---------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------
# Function: to generate word association
#---------------------------------------------------------------------------------------

# Custom Function: To find words similar to the given term
termAssociationLSA <- function(matrixLSA,term) {
  
  compareTermsTable<-round(as.data.frame(associate(matrixLSA, term, measure = "cosine", threshold = 0.1)),2)
  compareTermsTable <- cbind(word=row.names(compareTermsTable),compareTermsTable)
  colnames(compareTermsTable)[2]= "score"
  row.names(compareTermsTable) <- NULL
  return(compareTermsTable)
}


# Custom Function: To call the LSA function
CreateLSAMatrix<-function(text){
  splt<-strsplit(text," ")  
  dtm1<-Corpus(VectorSource(splt), readerControl = list(language="en")) #specifies the exact folder where my text file(s) is for analysis with tm.
  ctrl <- list(wordLengths = c(2, Inf))
  dtm2<-t(as.DocumentTermMatrix(DocumentTermMatrix(dtm1,control = ctrl)))
  dtm2<-as.textmatrix(as.matrix(dtm2))
  myMatrix = lw_logtf(dtm2) * gw_idf(dtm2)
  return(lsa(myMatrix, dims=dimcalc_share(share = .8)))
  
}

# Custom Function: To generate the relationship report for the given term
genWordAssocReports<-function(inputPath,data,varName,keyword,output_path) {
  
  # To write the association report in a csv
  #----------------------------------------------------------------------------
  dir.create(paste(output_path,"relationship analysis","relationship report",c_report_id,varName,dirName,sep="/"),recursive=T)
  
  data    <- as.character(data[grep(pattern=paste("\\b",keyword,"\\b",sep = ""),x=data,ignore.case = TRUE)])
  if(length(data)==1){
    data <- c(data,"")
  }
  if(length(data) == 0){
    write(paste("No such phrase/keyword: ",keyword," was found in the variable: ",varName," and panel: ",grp_no," level: ",grp_flag,sep=""),
          file=paste(output_path,"relationship analysis","relationship report",c_report_id,"error.txt",sep="/"))
    stop
  }
  myMatrix <- as.textmatrix(CreateLSAMatrix(data))
  associationTable <- termAssociationLSA(myMatrix,keyword)
  
  # Location of the output file
  #----------------------------------------------------------------------------
  location <- paste(output_path,"relationship analysis","relationship report",c_report_id,varName,dirName,"relationship.csv",sep="/")
  
  # Writing the CSV
  #----------------------------------------------------------------------------
  
  write.csv(associationTable, file = location, append = FALSE, col.names = TRUE, row.names = FALSE, quote=FALSE)
  
  # To clear all variable used
  #----------------------------------------------------------------------------
  rm(list=c("varName","output_path","associationTable","compare","keyword"))
  
}

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

load(paste(inputPath,"/dataworking.RData",sep=""))


for( i in 1:length(variables)){
  
  grp_no <- as.numeric(c_grp[i])
  grp_flag <- c_grp_flag[i]
  output_path <- paste(inputPath,grp_no,grp_flag,"text mining",sep = "/")
  
  file.remove(paste(output_path,"relationship analysis","relationship report",c_report_id,"RELATIONSHIP_REPORT_COMPLETED.txt",sep="/"))
  file.remove(paste(output_path,"relationship analysis","relationship report",c_report_id,"error.txt",sep="/"))
  
  
  if (grp_no != 0) {
    index <- which(dataworking[, paste("grp", grp_no, "_flag", sep="")] == grp_flag)
    dataworking_use <- dataworking[index, ]
  } else {
    dataworking_use <- dataworking
  }
  
  keyword<-trim(words[i])
  dirName <- keyword
  if(as.logical(ifNGram)){
    words[i]<-stripWhitespace(keyword)
    if(grepl(pattern = " ",x = words[i])){  
      keyword<-gsub(pattern = " ",replacement = "",x = words[i])
    }
    keyword<-tolower(keyword)
  }
  
  varName <- variables[i]
  #changing the encoding of data for further processing
  index_true<-which(is.locale(as.character(dataworking_use[,varName])) == "FALSE")
  if(length(index_true))
  {
    dataworking_use[index_true,varName]<-iconv(as.character(dataworking_use[index_true,varName]),from="latin1" ,to = "UTF-8")
  }
  data <- dataworking_use[,varName]
  data <- removeURL(data)
  data <- removeEmailIds(data)
  data <- removeUsernames(data)
  data <- expandContractions(data)
  data <- compressRepetition(data)
  data <- removeControlChars(data)
  data <- data[which (data!="")]
  data <- removeContent(data,c(" "))
  data <- gsub(pattern = "[^[:alnum:] ]",replacement = "", data)
  if(as.logical(ifNGram) & grepl(pattern = " ",x = words[i])){
    data <- gsub(pattern=words[i],replacement = keyword,x=data,ignore.case = TRUE)
  }
  stopWrds<-stopwords()
  if(length(which(stopWrds==keyword))>0)
  {
    stopWrds<-stopWrds[-which(stopWrds==keyword)]
  }
  data <- removeContent(data,stopWrds)
  
  check <- try(genWordAssocReports(inputPath, data, varName, keyword, output_path),silent=T)
  if(!class(check)=='try-error'){
    write.table("Relationship Report successfully generated",paste(output_path,"relationship analysis","relationship report",c_report_id,"RELATIONSHIP_REPORT_COMPLETED.txt",sep="/"),quote=FALSE,row.names=F,col.names=F)
  }   
}

