# -*- coding: utf-8 -*-
"""
Created on Fri Jun 19 10:01:15 2015

@author: user
"""

import csv, sys, json, operator
from collections import defaultdict
import pandas as pd
import os
import matplotlib.pyplot as plt
from mcsa_w2v import mcW2V
from mcsa_clusters import mcClusters


dbase="/home/user/Desktop/"
dname=["Managed","Hosting"]

#ctable_names=["Purchase", "Primary Reason Customer", "Primary Reason Prospect", 
#              "Why not accomplish", "OE_Accomplish", "OE_Improve or positive aspect", 
#              "Navigation", "OE_Navigation", "Technical Difficulties", "Call Shed", "Search"]

#dbase="/home/user/Desktop/mcSurveyAnalysis/tmp/DIL/SRV_Q21A_ISSUE_VERBATIM/"
#dname = 'DIL'
#ctable_names=["ISSUE"]
#table_name="SRV_Q21A_ISSUE_VERBATIMctable_noun_adj.csv"
#ctable_add=dbase+table_name
ctable_names=["Overall Comments.Managed","Overall Comments.Hosting"]

for i,k in enumerate(ctable_names):
    mccnew = mcClusters(None) #create mcClusters object.
    mccnew.load(dbase+k+".ctable.csv")    
    mccnew.plot(pname=dname[i])