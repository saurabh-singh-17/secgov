# -*- coding: utf-8 -*-
"""
Created on Thu Jul  9 12:10:46 2015

@author: user
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
export_file_name="features_customer_chat.txt"
final_export_path = "/".join((export_path,export_file_name))
serviceNames=["sentiment","problemDetection"]
reqServices = mcapi._getServicesConfig(serviceNames)

f=open(import_file_with_path)
data=json.load(f)
f.close()
op=open(final_export_path,"wb")
logger=op.write
#logger("Sentence|Problem|Context\n")




allFeatures = set()
for service in reqServices:
    for serRes in service[mcapi.MCCFG_RESOURCES]:
        allFeatures = allFeatures.union(serRes[mcapi.MCKEY_FEATURES])

counter=0
for lines in data:    
    procTxt=mcapi._mcNLPipeline(lines)
    sprocTxts = mcapi.sentenceSplitProcTxts(procTxt)
    for sentence in sprocTxts:
        features = computeFeatures(sentence,mcapi.__MC_PROD_HR__[0],allFeatures,False)  
        bases = {}
        for feature in allFeatures:
            bases.update(features[feature])
    
        bases_new,names=makeSKFormat([bases],True)    
        if(counter == 0):        
            sorted_names=sorted(names.items(),key=operator.itemgetter(1))   
            colnames=[x[0] for x in sorted_names]
            colnamesfinal="|".join(("sentence","|".join(colnames)))
            logger("%s\n"%(str(colnamesfinal)))
            print colnamesfinal
        bases_str=[str(x) for x in bases_new[0]]    
        bases_strfinal="|".join((str(sentence["sentences"][0])[2:-1],"|".join(bases_str)))
        logger("%s\n"%(str(bases_strfinal)))
        counter=1
        print bases_strfinal

op.close()