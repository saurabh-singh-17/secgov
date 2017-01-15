# -*- coding: utf-8 -*-
"""
Created on Wed Jul  8 03:01:44 2015

@author: svs
"""

import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
import operator
import numpy as np
import pandas as pd
import metaclassifier.mcServicesAPI as mcapi
from metaclassifier.metaclassifier_utils import computeFeatures, makeSKFormat

import_file_with_path="/home/nkoka/projects/mcSurveyAnalysis/data/sessiondump.json"
export_path="home/ss018a/mcSurveyAnalysis/scripts"
export_file_name="features_customer_chat.csv"
final_export_path = "/".join((export_path,export_file_name))
serviceNames=["sentiment","problemDetection"]
reqServices = mcapi._getServicesConfig(serviceNames)

f=open(import_file_with_path)
data=json.load(f)
f.close()

allFeatures = set()
for service in reqServices:
    for serRes in service[mcapi.MCCFG_RESOURCES]:
        allFeatures = allFeatures.union(serRes[mcapi.MCKEY_FEATURES])
featureArray=np.array([])
sentenceArray=np.array([])

for lines in data:    
    procTxt=mcapi._mcNLPipeline(lines["IAX"]["CustText"])
    sprocTxts = mcapi.sentenceSplitProcTxts(procTxt)
    for sentence in sprocTxts:
        features = computeFeatures(sentence,mcapi.__MC_PROD_HR__[0],allFeatures,False)  
        bases = {}
        for feature in allFeatures:
            bases.update(features[feature])
    
        bases_new,names=makeSKFormat([bases],True)    
        if featureArray.shape[0] == 0:
            featureArray=np.array(bases_new)
            sentenceArray=np.array([str(sentence["sentences"][0])[2:-1]])
        else:
            featureArray=np.row_stack((featureArray,bases_new))
            sentenceArray=np.row_stack((sentenceArray,[str(sentence["sentences"][0])[2:-1]]))

sorted_names=sorted(names.items(),key=operator.itemgetter(1))   
colnames=[x[0] for x in sorted_name]

featureDataFrame = pd.DataFrame(featureArray,columns=colnames)
sentenceDataFrame = pd.DataFrame(sentenceArray,columns=["sentence"])
sentenceDataFrame = pd.concat([sentenceDataFrame,featureDataFrame],axis=1)
featureDataFrame.to_csv(final_export_path,sep="|",index=False)