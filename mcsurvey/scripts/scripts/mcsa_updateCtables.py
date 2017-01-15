# -*- coding: utf-8 -*-
"""
Created on Wed Sep  9 01:59:16 2015

@author: user
"""

import os, sys
import csv, json, time
home = os.path.dirname(os.path.abspath(__file__))
os.sys.path.append(home)

import mcsa_phase2 as mcsa_ph2
import metaclassifier.mcServicesAPI as mcapi

#path of the dataset
dataset_fname="/home/user/Desktop/mcSurveyAnalysis/tmp/dil_verbatims.txt"

#defining the variables
dataset_name = 'DIL'
docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
txt_cols = ['SRV_Q21A_ISSUE_VERBATIM', 'SRV_Q21B_RESOLVE_VERBATIM'] 
dnames = ['DIL-ISSUE', 'DIL-RESOLVE']


#defining the variables
dataset_name = 'MCV'
docid_cols = ['RowID'] 
txt_cols = ['Verbatim'] 
dnames = ['MCV-verbatim']

#path where verbatims needs to  be created
data_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"          
tmp_home = data_home
dhome = os.path.join(tmp_home, dataset_name)
data_home = os.path.join(data_home, dataset_name)


import os
import matplotlib.pyplot as plt
from mcsa_w2v import mcW2V
from mcsa_clusters import mcClusters

for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    mcres_fname = dbase + '.mcres.csv'
    ctable_fname = dbase + '.ctable.csv'
    w2v_fname = dbase + '.w2vm'
    verb_noun_pickle_path = dbase + 'Coloc_verb_noun.pickle'
    adj_noun_pickle_path = dbase + 'Coloc_adj_noun.pickle'
    
    #itoks, cnts = getEntities(mcres_fname, th=102, top=None)
    itoks, cnts = getEntities(mcres_fname, th=None, top=20)
    #itoks, cnts = getAVRToks(mcres_fname, th=600)
    w2vm= mcW2V()
    w2vm = w2vm.build(mcres_fname,baseModel = basemodel_path, saveas = w2v_fname)
    #w2vm = w2vm.build(mcres_fname,baseModel = None, saveas = w2v_fname)
    w2vm = mcW2V(w2v_fname)
    #mcc = mcClusters(w2vm) #create mcClusters object.
    #mcc.makeClusters(itoks, cnts,saveSimMat=".".join((dbase,"SimMat.csv")))
    #mcc.plot(pname=dname) #visualize
    #mcc.save(open(ctable_fname, 'wb').write)
        
    #making of adjective and noun similarity graph
    #loading the file for adj and noun co-loc matrix
    ctableAdjNoun(pickle_path=adj_noun_pickle_path,ctable_fname=ctable_fname,file_name=dbase + 'ctable_noun_adj.csv',count=3,itoks=itoks,cnts=cnts,polarity="negative",polarityDict=mcapi.__MC_PROD_HR__[0].getResource("polar_adjs_dict"))  
    mccnew = mcClusters(w2vm) #create mcClusters object.
    mccnew.load(dbase + 'ctable_noun_adj.csv')    
    mccnew.plot(pname=dname)
