# -*- coding: utf-8 -*-
"""
Created on Thu Mar 03 11:23:04 2016

@author: u472290
"""

import os
import re
import pandas as pd
from bs4 import BeautifulSoup
import nltk
import string
import datetime
import pyodbc
import sqlalchemy


#input parameters
#gathering information for manipulating the search
number="1"   #the number can be integers between 0 to 99.
 
#please list the folder path here if the result needs to be written as a text file
folderPath="C:\Users\u472290\workfolder\Project 10_k\\test"
writeBasePath="C:\Users\u472290\workfolder\Project 10_k\\test"
writeBasePath=""
fileName="results_CIK_10K.txt"
financialsFileName="financial_CIK.txt"
allFinancialsFileName="allFinancials.txt"

delimToRead="|"
delimToWrite="|"

#please provide the Database information if the results needs to be written in a DB
#The result in the DB will be available in the table name 10_K_results
insertInDB=False
DRIVER="SQL Server"
SERVER="RDVWA4002"
DATABASE="EGS_EDA"
UID="tableau_dev"
PWD="SS2012sp1"
tableName="results_CIK_10K"
financialsTableName="financial_CIK"
allFinancialsTableName="allFinancials"

updateLocalFilesToServer=False

#writing a text file for scheduler
fo = open(os.path.join(folderPath,"counter.txt"), "wb")
fo.write( "Scoring algorithm is currenlty running.\n No need to run again\n");
fo.close()


#making basic operations function for sql
def getColumnsFromSqlServer(name,cursor):
    rows=[]
    for row in cursor.columns(table=name):
        rows.append(row.column_name)
    return rows    
        
def getNumberOfRows(name,cursor):
    count = cursor.execute("select count(*) from " + name).fetchone()[0]
    return format(count)
    
def getListOfTables(cursor):
    listOfTables=[]
    for i in cursor.tables():
        listOfTables.append(i[2])    
    return listOfTables
    
## function to compare the texts with the regular expression. It also cleans the text
## and splits them into sentences
def compareRegexWithText(text):
    text=re.sub( r'([a-zA-Z()%,])([0-9])', r'\1 \2', text)
    text=re.sub( r'([0-9()%,])([a-zA-Z])', r'\1 \2', text)
    text=re.sub(r'([a-zA-Z()])(\.)([$()a-zA-Z0-9])',r'\1\2 \3',text)
    text=re.sub(r'([a-zA-Z0-9()%])(\.)([()a-zA-Z])',r'\1\2 \3',text)
    sentences=nltk.sent_tokenize(filter(lambda x: x in string.printable, text))
    validLines=[]
    for lines in sentences:
        check=finalre.search(" "+lines.lower()+" ")
        if check:
            validLines.append(lines)
    returnLines="  :  ".join(validLines)        
    return returnLines

if type(number) == "str":
    number=str(number)

if insertInDB:
    connectionString="DRIVER={"+DRIVER+"};SERVER="+SERVER+";DATABASE="+DATABASE+";UID="+UID+";PWD="+PWD
    sqlalchemyConnectionString="mssql+pyodbc://"+UID+":"+PWD+"@"+SERVER+"/"+DATABASE+"?driver="+DRIVER
    cnxn = pyodbc.connect(connectionString)
    cursor = cnxn.cursor()
    engine = sqlalchemy.create_engine(sqlalchemyConnectionString)



if updateLocalFilesToServer and insertInDB:
    if fileName in os.listdir(folderPath) and tableName:
        tables=getListOfTables(cursor)
        if tableName in tables:
            sql1="drop table "+ tableName
            cursor.execute(sql1)
            cnxn.commit()
        localResult=pd.read_csv(os.path.join(folderPath,fileName),sep=delimToWrite)
        localResult.to_sql(tableName,engine,index=False)
        
    if financialsFileName in os.listdir(folderPath) and financialsTableName:
        tables=getListOfTables(cursor)
        if financialsTableName in tables:
            sql1="drop table "+ financialsTableName
            cursor.execute(sql1)
            cnxn.commit()        
        localResult=pd.read_csv(os.path.join(folderPath,financialsFileName),sep=delimToWrite)
        localResult.to_sql(financialsTableName,engine,index=False) 
        
#extracting path of all the csvs here
listOfFiles=os.listdir(folderPath)
pathOfCsv=[os.path.join(folderPath,files) for files in listOfFiles if files.find(".csv") > 0]
nameOfFiles=[files for files in listOfFiles if files.find(".csv") > 0]
pathOfCsvForSaving=[os.path.join(writeBasePath,"results",files[0:files.find(".csv")]+"new.txt") for files in listOfFiles if files.find(".csv") > 0]


#making the regular expression and the soup object
if number.__len__() == 2:
    numMatchText="".join(("(?=.*[a-zA-Z ]([",number[0],"][",number[1],"-9]|[",str(int(number[0])+1),"-9][0-9]?[0]?)\.?\d* *(%|percent))"))
else:
    numMatchText="".join(("(?=.*[a-zA-Z ]([0]?[",number[0],"-9]|[1-9][0-9]?[0]?)\.?\d* *(%|percent))"))
    
finaltext="".join(("((?=.*(accounted|represented|attributed|sales to|derived|contributed))",numMatchText,"(?=.*(gross| net|total))(?=.*(sales|revenue|income|receivables))(^((?! no | none |segment|region|geograph|operation|tax|financial|stock|equity|loan|share|asset|debt|nosingle|nodirect|noone|nocustomer|noindividual|no single|no direct|no customer|no individual|nopaid|notenants|country|countries|property|properties|liability|project|expense|pay|commission|did not|royalty|fair value|fairvalue|import).)*$))"))
finalre=re.compile(finaltext)


#finalre=re.compile("((?=.*approximately)(?=.*\d* *(%|percent))(?=.*(gross|net|total))(?=.*(sales|revenue))(^((?! no | none ).)*$))")
soup = lambda x: BeautifulSoup(str(x)).get_text(strip=True).replace("\t", " ").replace("\r", " ").replace("\n", " ").strip('\t\r\n')


#please mention the delimiter of the csv

finaldata=pd.DataFrame()
# extracting and saving the pattern matched with regular expression and saving 
# the results in a single file
for ind,files in enumerate(pathOfCsv):
    print str(ind)+"/"+str(pathOfCsv.__len__())
    print "start time " + str(datetime.datetime.now().time())
    try:
        data=pd.read_csv(files,sep=delimToRead,index_col=False,  error_bad_lines=False)
        data=data[data['elementId'].str.contains("TextBlock")]
        #data=data[data.form_type == "10-K"]
        data['text']=data.fact.apply(soup)
        data["extractedLines"]=data.text.apply(compareRegexWithText)
        del data["text"]
        del data["fact"]
        #data.to_csv(pathOfCsvForSaving[ind],sep=delimToWrite, index=False)
        data["filename"] = nameOfFiles[ind]
        #making all positive cases in a single file
        if ind:
            finaldata = finaldata.append(data[data.extractedLines != ""] )
        else:
            finaldata = data[data.extractedLines != ""]
        print "end time " + str(datetime.datetime.now().time())
    except:
        print "can not read file " + str(nameOfFiles[ind])

if finaldata.empty == False:
    finaldata=finaldata[["CIK","elementId","form_type","qtr","extractedLines"]]
    finaldata=finaldata.groupby(["CIK","elementId","form_type","qtr"])
    combinedExtract=finaldata.extractedLines.apply(lambda x: " . ".join((x)))
    finaldata = pd.DataFrame(combinedExtract)
    finaldata.to_csv(os.path.join(folderPath,"result.txt"),sep=delimToWrite)
    finaldata=pd.read_csv(os.path.join(folderPath,"result.txt"),sep=delimToWrite)
    os.remove(os.path.join(folderPath,"result.txt")) 

#extracting fresh financial figures
financialData=pd.DataFrame()

for ind,files in enumerate(pathOfCsv):
    print str(ind)+"/"+str(pathOfCsv.__len__())
    print "start time " + str(datetime.datetime.now().time())
    try:
        data=pd.read_csv(files,sep=delimToRead,index_col=False,  error_bad_lines=False)
        data=data[data['elementId'].str.contains("us-gaap_Revenues") | data['elementId'].str.contains("us-gaap_OperatingLeasesIncomeStatementLeaseRevenue") | data['elementId'].str.contains("us-gaap_RevenueFromRelatedParties") | data['elementId'].str.contains("us-gaap_SalesRevenueNet")]
        data["filename"] = nameOfFiles[ind]
        financialData = financialData.append(data)
        print "end time " + str(datetime.datetime.now().time())
    except:
        print "can not read file " + str(nameOfFiles[ind])
        

#extracting the non textblock data for all financials
allFinancials =pd.DataFrame()
for ind,files in enumerate(pathOfCsv):
    print str(ind)+"/"+str(pathOfCsv.__len__())
    print "start time " + str(datetime.datetime.now().time())
    try:
        data=pd.read_csv(files,sep=delimToRead,index_col=False,  error_bad_lines=False)
        data=data[data.elementId.str.contains("TextBlock") == False]
        data["filename"] = nameOfFiles[ind]
        allFinancials = allFinancials.append(data)
        print "end time " + str(datetime.datetime.now().time())
    except:
        print "can not read file " + str(nameOfFiles[ind])
        os.remove(files)

            
if financialData.empty == False:
    financialData=financialData[["CIK","Company_Name","unitId","fact"]]
    financialData=financialData.groupby(["CIK","Company_Name","unitId"])
    combinedFinancials=financialData.fact.apply(max)   
    financialData = pd.DataFrame(combinedFinancials)
    financialData.to_csv(os.path.join(folderPath,"financials.txt"),sep=delimToWrite)
    financialData=pd.read_csv(os.path.join(folderPath,"financials.txt"),sep=delimToWrite)
    os.remove(os.path.join(folderPath,"financials.txt")) 

#writing the new financials to the local file system if the paths are provided
if writeBasePath != "" and financialData.empty == False and financialsFileName != "":
    if financialsFileName in listOfFiles:
        previousFinancials=pd.read_csv(os.path.join(folderPath,financialsFileName),sep=delimToWrite)
        combinedFinancials=previousFinancials.append(financialData) 
        financial_CIK=combinedFinancials.groupby(["CIK","Company_Name","unitId"])
        financial_CIK = financial_CIK.fact.apply(max)
        combinedFinancials = pd.DataFrame(financial_CIK)
    combinedFinancials.to_csv(os.path.join(writeBasePath,financialsFileName),sep=delimToWrite) 
    combinedFinancials=pd.read_csv(os.path.join(writeBasePath,financialsFileName),sep=delimToWrite)
else:
    combinedFinancials=financialData


#merging the new results obtained to the financials data to get the revenue figures and units
finaldataLocal=pd.DataFrame()
if combinedFinancials.empty == False and finaldata.empty == False:
    finaldataLocal=finaldata.merge(combinedFinancials,on="CIK",how="left")

    
if finaldata.empty:
    print "No positive cases found in recent files. No data will be written"

#writing the results to the local file system if the paths are provided
if writeBasePath != "" and finaldataLocal.empty == False and fileName != "":
    if fileName in listOfFiles:
        previousResult=pd.read_csv(os.path.join(folderPath,fileName),sep=delimToWrite)
        combinedExtract=previousResult.append(finaldataLocal)    
        combinedExtract.to_csv(os.path.join(writeBasePath,fileName),sep=delimToWrite,index=False) 
    else:
        finaldataLocal.to_csv(os.path.join(writeBasePath,fileName),sep=delimToWrite,index=False) 


#writing the allFinancials to the local file system if the paths are provided
if writeBasePath != "" and allFinancials.empty == False and allFinancialsFileName != "":
    if allFinancialsFileName in listOfFiles:
        previousAllFinancials=pd.read_csv(os.path.join(folderPath,allFinancialsFileName),sep=delimToWrite)
        combinedAllFinancials=previousAllFinancials.append(allFinancials) 
        combinedAllFinancials.to_csv(os.path.join(writeBasePath,allFinancialsFileName),sep=delimToWrite,index=False) 
    else:
        allFinancials.to_csv(os.path.join(writeBasePath,allFinancialsFileName),sep=delimToWrite,index=False) 


#writing the results to the database if the option has been selected
if insertInDB and financialData.empty == False:
    listOfTables=[]
    for i in cursor.tables():
        listOfTables.append(i[2])
    print listOfTables[0:10]
    if financialsTableName in listOfTables:
        count = cursor.execute("select count(*) from " + financialsTableName).fetchone()[0]
        print('{} financial_CIK'.format(count))
        print financialsTableName+ " already exists. Appending current financials to "+financialsTableName
        financialData.to_sql("current_financials_10K",engine,index=False)
        sqlquery="SELECT x.* INTO appended_financials FROM (SELECT * FROM "+financialsTableName+" UNION SELECT * FROM current_financials_10K) x"
        cursor.execute(sqlquery)
        cnxn.commit()
        sqlquery2="drop table current_financials_10K"
        cursor.execute(sqlquery2)
        cnxn.commit()
        sqlquery3="select x.* into updated_financials from (select CIK ,Company_Name, unitId, max(fact) as fact from appended_financials group by CIK ,Company_Name, unitId) x"
        cursor.execute(sqlquery3)
        cnxn.commit()
        sqlquery4="drop table appended_financials"
        cursor.execute(sqlquery4)
        cnxn.commit()
        sqlquery5="drop table "+ financialsTableName
        cursor.execute(sqlquery5)
        cnxn.commit()
        sqlquery6="select x.* into "+financialsTableName+ " from (select * from updated_financials) x"
        cursor.execute(sqlquery6)
        cnxn.commit()
        sqlquery6="drop table updated_financials"
        cursor.execute(sqlquery6)
        cnxn.commit()
    else:
        print tableName + " does not exist. Creating " + financialsTableName
        financialData.to_sql(financialsTableName,engine)




if insertInDB and finaldata.empty == False:
    listOfTables=[]
    for i in cursor.tables():
        listOfTables.append(i[2])
    if tableName in listOfTables:
        count = cursor.execute("select count(*) from " + tableName).fetchone()[0]
        print('{} result'.format(count))
        print tableName+ " already exists. Appending current result to "+tableName
        finaldata.to_sql("current_10K",engine,index=False)
        sqlquery1="select x.* into res_10k_merged from (select a.*,b.Company_Name,b.unitId,b.fact from current_10K as a left join " +financialsTableName+ " as b on a.CIK = b.CIK) x"
        cursor.execute(sqlquery1)
        cnxn.commit()
        sqlquery2="SELECT x.* INTO appended_results FROM (SELECT * FROM "+tableName+" UNION SELECT * FROM res_10k_merged) x"
        cursor.execute(sqlquery2)
        cnxn.commit()
        sqlquery3="drop table current_10K"
        cursor.execute(sqlquery3)
        cnxn.commit()
        sqlquery4="drop table res_10k_merged"
        cursor.execute(sqlquery4)
        cnxn.commit()
        sqlquery5="drop table "+ tableName
        cursor.execute(sqlquery5)
        cnxn.commit()    
        sqlquery6="select x.* into "+tableName+ " from (select * from appended_results) x"
        cursor.execute(sqlquery6)
        cnxn.commit()
        sqlquery7="drop table appended_results"
        cursor.execute(sqlquery7)
        cnxn.commit()
 
        cnxn.close()
    else:
        print tableName + " does not exist. Creating " + tableName
        finaldata.to_sql(tableName,engine)
        cnxn.close()
        
        
        
        
#writing the results to the database if the option has been selected
if insertInDB and allFinancials.empty == False:
    listOfTables=[]
    for i in cursor.tables():
        listOfTables.append(i[2])
    print listOfTables[0:10]
    if allFinancialsTableName in listOfTables:
        count = cursor.execute("select count(*) from " + allFinancialsTableName).fetchone()[0]
        print('{} allFinancials'.format(count))
        print allFinancialsTableName+ " already exists. Appending current financials to "+allFinancialsTableName
        allFinancials.to_sql("current_allFinancials_10K",engine,index=False)
        sqlquery="SELECT x.* INTO appended_allFinancials FROM (SELECT * FROM "+allFinancialsTableName+" UNION SELECT * FROM current_allFinancials_10K) x"
        cursor.execute(sqlquery)
        cnxn.commit()
        sqlquery2="drop table current_allFinancials_10K"
        cursor.execute(sqlquery2)
        cnxn.commit()
        sqlquery5="drop table "+ allFinancialsTableName
        cursor.execute(sqlquery5)
        cnxn.commit()
        sqlquery6="select x.* into "+financialsTableName+ " from (select * from appended_allFinancials) x"
        cursor.execute(sqlquery6)
        cnxn.commit()
        sqlquery6="drop table appended_allFinancials"
        cursor.execute(sqlquery6)
        cnxn.commit()
      
    else:
        print tableName + " does not exist. Creating " + financialsTableName
        allFinancials.to_sql(allFinancialsTableName,engine)
        
        
#deleting the text file from the location for the scheduler
os.remove(os.path.join(folderPath,"counter.txt"))