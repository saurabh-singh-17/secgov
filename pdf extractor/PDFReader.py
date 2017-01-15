# -*- coding: utf-8 -*-
"""
Created on Thu Aug 18 14:27:07 2016

@author: u472290
"""

import PyPDF2
import string
import nltk
import re
import os

'''
Function definition:

Name: extractPDF
Purpose: Converts PDFs into text file for further use
Parameters:
        pathPDF :  input can be a single string path or a list of paths for extrtaction
        pathFolder: input can be a path of a folder containing single or multiple PDFs.
                    All the PDSs in the folder are converted into txt files
                    
Output: writes txt files in the same folder with the same name as the PDF file

Note: Atleast one input is required, either pathPDF or pathFolder                    

Keywords used for extraction

    -Affiliate
    -Guarantee
    -Exclusivity(Non-Exclusive; Conflicts)
    -Minimum Purchase
    -WF Assignment(Assignment)
    -Vendor Assignment
    -Insolvency
    -Change of Control
    -Termination
    -Divestiture(Divestiture/Business Downturn)



'''
keywords=["affiliate","guarantee","exclusivity","minimum purchase","assignment","vendor assignment","insolvency","change of control","termination","divestiture"]

    


def extractPDF(pathPDF=None,pathFolder=None):
    if type(pathPDF) == str:
        pathPDF = os.path.join("/".join(string.split(pathPDF,"/")[:string.split(pathPDF,"/").__len__()-1]),string.split(pathPDF,"/")[-1])
        pathPDF=[pathPDF]
    if pathFolder != None:
        listOfFiles=os.listdir(pathFolder)
        pathPDF=[os.path.join(pathFolder,files) for files in listOfFiles if files.find(".pdf") > 0]   
    writeExtractsPath =  os.path.join(string.split(pathPDF[0],"\\")[0],"PDFextracts.csv")
    csvWriteObj=open(writeExtractsPath,"wb")
    csvWriteObj.write("FileName|AgreementNo|Keyword|PageNo|ExratcedTexts\n")
    for pathOfPDF in pathPDF: 
        print pathOfPDF
        nameOfPDF = string.split(pathOfPDF,"\\")[1]
        agreementNo = string.strip(string.split(pathOfPDF,"\\")[1].split("-")[0])
        pdfFileObj = open(pathOfPDF, 'rb')
        pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
        numPage=pdfReader.numPages
        writeFilePath = string.join((pathOfPDF[0:pathOfPDF.__len__()-3],"txt"),"")
        writeObj=open(writeFilePath,"wb")
        for ite in xrange(numPage):
            print ite
            pageObj=pdfReader.getPage(ite)
            text=pageObj.extractText()
            text = re.sub("\s"," ",text)
            textClean = nltk.sent_tokenize(filter(lambda x: x in string.printable, text))
            for items in keywords:
                for lines in textClean:
                    if string.lower(lines).find(items) > 0:
                        csvWriteObj.write("%s|%s|%s|%d|%s\n"%(nameOfPDF,agreementNo,items,ite+1,lines))
            textClean=string.join(textClean,"\n")
            writeObj.write("\n \n Page %d \n \n"%(ite+1))
            writeObj.write(textClean)
        writeObj.close()
    csvWriteObj.close()
    
if __name__ == "__main__":
    pathPDF = 'C:/Users/u472290/workfolder/pdfReader/188467- DeloitteConsultingLLP-SOW-FE.pdf'
    extractPDF(pathPDF)         
    