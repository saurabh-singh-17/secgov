# -*- coding: utf-8 -*-
"""
Created on Tue Mar 29 11:01:06 2016

@author: u472290
"""



import os
import zipfile
import pandas as pd
#import urllib
from bs4 import BeautifulSoup
import datetime
import math
import shutil
import urllib2

folderPath="C:\\Users\\u472290\\workfolder\\Project 10_k\\previous_forms"
writeBasePath="C:\\Users\\u472290\\workfolder\\Project 10_k\\previous_forms"
collatedFormsPath=os.path.join(folderPath,"collatedForms")
tempFolderPath=os.path.join(folderPath,"temp")
parsedXbrlFilesPath=os.path.join(folderPath,"parsedInfo")
try:
    os.mkdir(collatedFormsPath)
    os.mkdir(tempFolderPath)
    os.mkdir(parsedXbrlFilesPath)
except:
    "folder already exists"     

listOfFiles=os.listdir(folderPath)
pathOfZips=[os.path.join(folderPath,files) for files in listOfFiles if files.find(".zip") > 0]
nameOfFiles=[files for files in listOfFiles if files.find(".zip") > 0]


#function for parsing the facts and other information from an XBRL xml file and return as a dataframe
def xbrlParser(path):
    processedXbrl = pd.DataFrame()
    soup=BeautifulSoup(open(path),'xml')
    allTags=soup.findAll()
    allTags=allTags[1:]
    counter=0
    for ind,currentTag in enumerate(allTags):
        attributes=currentTag.attrs
        if attributes.has_key("contextRef"):
            elementId="_".join((currentTag.prefix,currentTag.name)) 
            if attributes.has_key("contextRef"):
                contextId=attributes["contextRef"]
            else:
                contextId=""
            if attributes.has_key("unitRef"):
                unitId=attributes["unitRef"]
            else:
                unitId=""
            try:
                fact=currentTag.contents[0]
            except:
                fact=""
            if attributes.has_key("decimals"):
                decimals=attributes["decimals"]
            else:
                decimals=""        
            if attributes.has_key("scale"):
                scale=attributes["scale"]
            else:
                scale="" 
            if attributes.has_key("sign"):
                decimals=attributes["sign"]
            else:
                sign=""             
            if attributes.has_key("id"):
                factId=attributes["id"]
            else:
                factId="" 
            ns=currentTag.namespace    
            #adding all the data to the processedXbrl dataframe
            if counter==0:
                processedXbrl=pd.DataFrame({"elementId":pd.Series(elementId),"contextId":pd.Series(contextId),"unitId":pd.Series(unitId),"fact":pd.Series(fact),"decimals":pd.Series(decimals),"scale":pd.Series(scale),"sign":pd.Series(sign),"factId":pd.Series(factId),"ns":ns})
                counter=1
            else:
                processedXbrl.ix[ind,"elementId"] = elementId
                processedXbrl.ix[ind,"contextId"] = contextId
                processedXbrl.ix[ind,"unitId"] = unitId
                processedXbrl.ix[ind,"fact"] = fact
                processedXbrl.ix[ind,"decimals"] = decimals
                processedXbrl.ix[ind,"scale"] = scale
                processedXbrl.ix[ind,"sign"] = sign
                processedXbrl.ix[ind,"factId"] = factId
                processedXbrl.ix[ind,"ns"] = ns
       
    processedXbrl["fact"] = processedXbrl.fact.apply(lambda x:x.encode('ascii', 'ignore'))
    #adding Path, Company_Name, CIK, form_type, Date.Filed, qtr
    processedXbrl["Path"]  = "RSS-Feed"
    processedXbrl["Company_Name"]  = processedXbrl[processedXbrl.elementId == "dei_EntityRegistrantName"].fact.values[0]
    processedXbrl["CIK"]  = processedXbrl[processedXbrl.elementId == "dei_EntityCentralIndexKey"].fact.values[0]   
    processedXbrl["form_type"]  = processedXbrl[processedXbrl.elementId == "dei_DocumentType"].fact.values[0]   
    processedXbrl["Date.Filed"] = datetime.datetime.now().strftime("%Y-%m-%d")
    date1  = datetime.datetime.strptime(str(processedXbrl[processedXbrl.elementId == "dei_DocumentPeriodEndDate"].fact.values[0]),"%Y-%m-%d")
    year=date1.strftime("%y")
    qtr=int(math.ceil(int(date1.strftime("%m"))/3))
    date = "-".join((str(year),str(qtr)))
    processedXbrl["qtr"] = date
    processedXbrl = processedXbrl.reindex_axis(['elementId','contextId', 'unitId', 'fact', 'decimals','scale', 'sign', 'factId', 'ns','Path', 'Company_Name', 'CIK', 'form_type', 'Date.Filed', 'qtr'],axis=1)
    return processedXbrl       


for ind,zips in enumerate(pathOfZips):
    print "processing file " + str(ind+1) +" of " + str(len(pathOfZips))
    fh = open(zips, 'rb')
    z=zipfile.ZipFile(fh)
    files=z.extract(z.namelist()[0], collatedFormsPath)
    z.close()
    fh.close()
    
    readIdx=open(files)
    writeFile=open(os.path.join(writeBasePath,".".join((nameOfFiles[ind].split(".")[0],"csv"))),"wb")
    for lines in readIdx:
        if lines.find("|") >= 0:
            writeFile.write(lines)
    readIdx.close()
    writeFile.close()
    os.remove(files)
        
    data=pd.read_csv(os.path.join(writeBasePath,".".join((nameOfFiles[ind].split(".")[0],"csv"))),sep="|")
    data["xbrlFilePath"]=data.Filename.apply(lambda x:"".join(("ftp://ftp.sec.gov/",x.replace("-","").replace(".txt",""),"/",x.split("/")[x.split("/").__len__()-1].replace(".txt","-xbrl.zip"))))
    del data["Filename"]
    data.to_csv(os.path.join(writeBasePath,".".join((nameOfFiles[ind].split(".")[0],"csv"))),sep="|",index=False)
    tempDownloadPath=os.path.join(tempFolderPath,"xbrl.zip")
    xbrlFinal=pd.DataFrame()
    for inds,paths in enumerate(data.xbrlFilePath):
        print "processing xmls " + str(inds+1) +" of " + str(len(data.xbrlFilePath))
        print "start time " + str(datetime.datetime.now().time())
        response = urllib2.urlopen(paths)
        zipcontent= response.read()
        with open(tempDownloadPath, 'wb') as f:
            f.write(zipcontent)
        f.close()
        
        fh=open(tempDownloadPath,'rb')
        z=zipfile.ZipFile(fh)
        files=z.extract(z.namelist()[0], tempFolderPath)
        z.close()
        fh.close()
        try:
            parsedXbrl=xbrlParser(files)
        except:
            print "unsuccessful attempt" 
            os.remove(files)
            os.chmod(tempDownloadPath,666)
            os.remove(tempDownloadPath)
            continue
        shutil.copyfile(files,os.path.join(collatedFormsPath,files.split("\\")[files.split("\\").__len__()-1]))
        os.remove(files)
        os.chmod(tempDownloadPath,666)
        os.remove(tempDownloadPath)
        xbrlFinal.append(parsedXbrl)
        if inds % 300 == 0 and inds != 0:
            xbrlFinal.to_csv(os.path.join(parsedXbrlFilesPath,"".join((nameOfFiles[ind].split(".")[0],"_",inds,".csv"))),sep="|")
            xbrlFinal=pd.DataFrame()
        
        if inds == len(data.xbrlFilePath) -1:
            xbrlFinal.to_csv(os.path.join(parsedXbrlFilesPath,"".join((nameOfFiles[ind].split(".")[0],"_",inds,".csv"))),sep="|")
            xbrlFinal=pd.DataFrame()
        print "end time " + str(datetime.datetime.now().time())
