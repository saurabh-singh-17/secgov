# -*- coding: utf-8 -*-
"""
Created on Tue Jun 30 09:35:47 2015

@author: svs
"""

import os, sys
import csv, json, time
home = os.path.dirname(os.path.abspath(__file__))
os.sys.path.append(home)

#surveyCorpus.py 
import surveyCorpus as survCorp
import mcsa_phase1 as mcsa_ph1
import mcsa_phase2 as mcsa_ph2
import mcsa_phase3 as mcsa_ph3
import mcsa_3NF as mcsa_3nf
import mcsa_pf as mc_pf

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
#making verbatims
dhome = os.path.join(tmp_home, dataset_name)
data_home = os.path.join(data_home, dataset_name)
#corpus = survCorp.mcCorpus(dataset_fname, delimiter='|', dtype=str)
#corpus.extractTxtCols(txt_cols, docid_cols, data_home)


#running  phase 1 of survey analysis 
'''
it is making of the mcres which is the result of mcRunServices or
result of the metaClassifier package
'''
        

for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    ifname = dbase + '.verbatims'
    rfname = dbase + '.mcres.csv'
    print 'Extracting Surface Properties & Polarities'
    mcsa_ph1.makeMCRes(ifname, docid_cols, col, rfname, serializer = json.dumps)
    
    
print "phase 1 complete"    

#running phase 2 of survey analysis
'''
reads the mcres file made in phase 1 and runs the clustering algorithm on it.
Clustering is done using affinity propagation on the wordtoVec models
It also saves the similarity matrix for the used entities
'''

basemodel_path="/home/user/Desktop/mcSurveyAnalysis/tmp/volte/SRV_Q1B_WTR_WHY/SRV_Q1B_WTR_WHY.w2vm"
dresult= tmp_home

import matplotlib.pyplot as plt
from mcsa_w2v import mcW2V
from mcsa_clusters import mcClusters
for ind,col in enumerate(txt_cols):
        dbase = os.path.join(dhome, col, col)
        mcres_fname = dbase + '.mcres.csv'
        ctable_fname = dbase + '.ctable.csv'
        w2v_fname = dbase + '.w2vm'
        resbase = dresult + '__'.join([dataset_name, col]) 
        
        itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=20)
        #itoks, cnts = getAVRToks(mcres_fname, th=600)
        w2vm= mcW2V()
        w2vm = w2vm.build(mcres_fname,baseModel = basemodel_path, saveas = w2v_fname)
        #w2vm = w2vm.build(mcres_fname,baseModel = None, saveas = w2v_fname)
        w2vm = mcW2V(w2v_fname)
        mcc = mcClusters(w2vm) #create mcClusters object.
        mcc.makeClusters(itoks, cnts,saveSimMat=".".join((dbase,"SimMat.csv")))
        mcc.plot(pname=dnames[ind]) #visualize
        mcc.save(open(ctable_fname, 'wb').write)
        
        
print "phase 2 complete"        

#running phase 3 of the survey analysis
'''
using the wordtoVec model it creates the 2 dimensional spatial representation 
using PCA algorithm. it then computes the global and local representations
using clusters from ctable
'''
    
from mc_categories2 import mcCategories, mcSpatialRep
from collections import defaultdict
from itertools import islice

for k in txt_cols:
    print(k)
    col=k
    dhome = os.path.join(tmp_home, dataset_name)
    bname = os.path.join(dhome, col, col)
    w2vmod_fname = bname + '.w2vm'
    ctable_fname = bname + '.ctable.csv'
    mcres_fname = os.path.join(dhome, col, col + '.mcres.csv')
    catmodel = mcCategories(w2vmod_fname, ctable_fname, False)
    print 'done catmodel'
    srepmodel = mcSpatialRep(w2vmod_fname, ctable_fname, 2, False)

    print 'Phase 3'
    print 'Inferring Categories & Spatial Representations'
    with open(mcres_fname+'.3', 'wb') as ofile:
            writer = csv.writer(ofile, delimiter='|')
            with open(mcres_fname) as f:
                ipreader = csv.reader(f, delimiter='|')
                part = 0
                while True:
                    n_lines = list(islice(ipreader, 1000))
                    if not n_lines:
                        break
                    resps = [mcsa_ph3.mcPhase3(line, catmodel, srepmodel) for line in n_lines]
                    #resps = [mcPhase3(line) for line in n_lines]
                    writer.writerows(resps)
                    sys.stdout.write('%s ' % '.')
                    if (part+1) % 10 == 0:
                        sys.stdout.write(' %d \n' % (part+1))
                    part += 1


    sys.stdout.write('\n')
    
    
print "phase 3 complete"    

#running the 3NF (normalized form) for consumption
for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    rfname = dbase + '.mcres.csv'
    cfname = dbase + '.ctable.csv'
    wfname = dbase + '.w2vm'
    ofname = os.path.join(dbase + '_2.csv')

    mcsa_3nf.mc3NFizer(rfname+'.3', ofname)

        
print "phase 3NF complete"        
        

   
#pivot table generation
    
from mc_categories2 import mcCategories    
for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    ifname = dbase + '.verbatims'
    rfname = dbase + '.pivot.csv'       
    w2vmod_fname = dbase + '.w2vm'
    ctable_fname = dbase + '.ctable.csv'
    mcres_fname = dbase + '.mcres.csv'
    lemma_pickle_path = dbase + "lemma.pickle"
    catmodel = mcCategories(w2vmod_fname, ctable_fname, False)
    mc_pf.pivotcsv(ifname,rfname,docid_cols,col,catmodel,lemma_pickle_path)  







