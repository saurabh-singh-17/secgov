# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""


import os
import zipfile
import pandas as pd
import urllib

folderPath="C:\\Users\\saurabh\\Downloads\\xbrl"
writeBasePath="C:\\Users\\saurabh\\Downloads\\xbrl"
collatedFormsPath=os.path.join(folderPath,"collatedForms")
tempFolderPath=os.path.join(folderPath,"temp")
parsedXbrlFilesPath=os.path.join(folderPath,"parsedInfo")
try:
    os.mkdir(collatedFormsPath)
    os.mkdir(tempFolderPath)
except:
    "folder already exists"     

listOfFiles=os.listdir(folderPath)
pathOfZips=[os.path.join(folderPath,files) for files in listOfFiles if files.find(".zip") > 0]
nameOfFiles=[files for files in listOfFiles if files.find(".zip") > 0]

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
    data.to_csv(os.path.join(writeBasePath,".".join((nameOfFiles[ind].split(".")[0],"csv"))),sep="|")
    tempDownloadPath=os.path.join(tempFolderPath,"xbrl.zip")
    xbrlFinal=pd.DataFrame()
    for inds,paths in enumerate(data.xbrlFilePath):
        urllib.urlretrieve(paths,tempDownloadPath)
        fh=open(tempDownloadPath,'rb')
        z=zipfile.ZipFile(fh)
        files=z.extract(z.namelist()[0], tempFolderPath)
        z.close()
        fh.close()
        parsedXbrl=xbrlParser(files)
        os.remove(files)
        os.chomd(tempDownloadPath,666)
        os.remove(tempDownloadPath)
        xbrlFinal.append(parsedXbrl)
        if inds % 300 == 0 and inds != 0:
            xbrlFinal.to_csv(os.path.join(parsedXbrlFilesPath,"".join((nameOfFiles[ind].split(".")[1],"_",inds,".csv"))),sep="|")
            xbrlFinal=pd.DataFrame()
        
        
        
        
        
        
        
        

