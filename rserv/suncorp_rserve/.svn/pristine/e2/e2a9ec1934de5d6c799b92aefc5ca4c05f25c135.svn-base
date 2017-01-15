#------------------------------------------------------------------------------------------------------#
#--                                                                                                  --#   
#-- Project Name :  MRx_Aggregated_Binning_1.0                                                        --#
#-- Description :-
#--   2.The below Script is divided into six parts :-
#--     1. Loading Libraries
#--     2. Data loading
#--     3. Function to create binned variables if script is ran from bivariate Analyis
#--     4. Understanding the bins
#--     5. Binning all the variables
#--     6. Writing the report CSVs and updating dataworking
#-- Return type  :  Creates CSVs at a location according to given inputs                            --#
#-- Author       :  Shankar Kumar Jha                                                                --#                 
#------------------------------------------------------------------------------------------------------#



#-------------------------------------------------------------------------------
#PART 1 : Libraries required
#-------------------------------------------------------------------------------
require(XML)
require(data.table)
require(Hmisc)
require(stringr)
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#PART 2 : Loading the Data  
#-------------------------------------------------------------------------------
load(paste(input_path,"dataworking.RData",sep="/"))
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#PART 4 : Understanding the bins through XML  
#-------------------------------------------------------------------------------
input_xml <- xmlTreeParse(input_xml)
xmldata <- xmlToList(input_xml)
xmldata=as.data.frame(matrix(unlist(xmldata),ncol = 2,byrow = T))[1]
colnames(xmldata)<-c("bincol")
#-------------------------------------------------------------------------------
if(var_type != "CATEGORICAL")
{
  bivarCol<-read.csv(paste(bivariate_report_path,"bindata.csv",sep="/"))[paste("bin_",var_list,sep="")]
}else{
  bivarCol<-read.csv(paste(bivariate_report_path,"bindata.csv",sep="/"))[var_list]  
}
bivarCol[,1]<-as.character(bivarCol[,1])
bivarCol[,1][is.na(bivarCol[,1])] <- "NA"

for(i in 1:nrow(xmldata))
{
  if(var_type == "NUMERIC")
  {
    
    lista<-unlist(str_split(xmldata[i,1],","))
    for(j in 1:length(lista))
      {
        new1<-str_split(gsub("[^[:digit:] ]","",lista[j])," ")
        min_val<-as.numeric(unlist(new1)[!is.na(as.numeric(unlist(new1)))][2])
        max_val<-as.numeric(unlist(new1)[!is.na(as.numeric(unlist(new1)))][3])
        if(j == 1) replace_val<-paste(min_val,max_val,sep=" - ")
        else replace_val<-paste(replace_val,paste(min_val,max_val,sep=" - "),sep=" | ")
      }
    search_var<-paste(paste("bivarCol[,1] == '",lista,"'",sep=""),collapse = " | ")
    bivarCol[which(eval(parse(text=search_var))),] = replace_val
    
  }else{
    
    lista<-unlist(str_split(xmldata[i,1],","))
    if(length(lista) > 1)
    {  
      replace_val<-paste(lista,collapse = " | ")
      search_var<-paste(paste("bivarCol[,1] == '",lista,"'",sep=""),collapse = " | ")
      bivarCol[which(eval(parse(text=search_var))),] = replace_val
    }
    
  }
}

colnames(bivarCol) <- paste(prefix,gsub('bin_','',var_list,fixed=TRUE), sep='_')
#-----------------------------------------------------------------
#PART 6 : Updating the dataworking and writing report csvs
#-----------------------------------------------------------------
dataworking <- cbind.data.frame(dataworking, bivarCol)
save(dataworking, file = paste(input_path,"dataworking.RData",sep="/"))
# ======================================================
# code for updating the dataset properties information
# ====================================================== 

source(paste(genericCode_path,"datasetprop_update.R",sep="/"))

# ------------------------------------------------------

write.csv(bivarCol,paste(output_path,"MultiAggrBinning_viewPane.csv",sep="/"),row.names=FALSE, quote=FALSE )

write.table("MULTIPLE_AGGREGATION_BINNING_COMPLETED",paste(output_path,"MULTIPLE_AGGREGATION_BINNING_COMPLETED.txt",sep="/"),sep="/t",quote=F)
