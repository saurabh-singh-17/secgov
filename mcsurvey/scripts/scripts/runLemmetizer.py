# -*- coding: utf-8 -*-
"""
Created on Mon Aug 17 10:21:18 2015

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
import colocationMatrix as colocMatAdj
import colocationMatrixNounVerb as colocMatVerb
import lemmetizerStemmer as lemStem
import pandas as pd
import mcsa_pf as mc_pf

#path of the dataset
dataset_fname="/home/user/Desktop/mcSurveyAnalysis/tmp/dil_verbatims.txt"

#defining the variables
dataset_name = 'DIL'
docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
txt_cols = ['SRV_Q21A_ISSUE_VERBATIM'] #SRV_Q21B_RESOLVE_VERBATIM 
dnames = ['DIL-ISSUE'] #'DIL-RESOLVE'

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
dnames = ['DIL-ISSUE']
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
        #mcc.plot(pname=dnames[ind]) #visualize
        itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=200)
        mcc = mcClusters(w2vm) #create mcClusters object.
        mcc.makeClusters(itoks, cnts)
        mcc.save(open(ctable_fname, 'wb').write)
        
        
print "phase 2 complete"   


'''
running collocation matrix for noun adjective relationship
the result will be made with extension "all_adj_given_noun.pickle"
'''
for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    ifname = dbase + '.verbatims'
    rfname = dbase + '.mcres.csv'
    #print 'Extracting Surface Properties & Polarities'
    colocMatAdj.makeMCRes(ifname, docid_cols, col, rfname, dbase, serializer = json.dumps)





'''
running collocation matrix for noun verb relationship
the result will be made with extension "all_verb_given_noun.pickle"
'''


for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    ifname = dbase + '.verbatims'
    rfname = dbase + '.mcres.csv'
    #print 'Extracting Surface Properties & Polarities'
    colocMatVerb.makeMCRes(ifname, docid_cols, col, rfname, dbase, serializer = json.dumps)
    
    
    
    
#running lemmetizer
'''    
running the lemmetizer code to form the lemmas, the lemmas will be written
in a file    
'''
#defining paths
for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    verb_noun_pickle_path = dbase + 'all_verb_given_noun.pickle'
    adj_noun_pickle_path = dbase + 'all_adj_given_noun.pickle'
    w2vm_sim_mat_path = dbase + ".SimMat.csv"
    mcres_fname = dbase + '.mcres.csv'
    lemma_path=dbase + "lemma.csv"
    lemma_pickle_path = dbase + "lemma.pickle"
    topKeyWordsWritePath = dbase + "KeyWords.csv"
    
    #calling lemmetizer
    #lemStem.lemmetizer(verb_noun_pickle_path,adj_noun_pickle_path,None,15,dbase)
    
    #importing results of lemmetizer and pickles
    verb_dict_path=dbase+"verb_sim_mat.csv"
    verb_dict=pd.read_csv(verb_dict_path,sep="|",index_col=0)
    
    adj_dict_path=dbase+"adj_sim_mat.csv"
    adj_dict=pd.read_csv(adj_dict_path,sep="|",index_col=0)
    
    w2vm_dict=pd.read_csv(w2vm_sim_mat_path,sep="|",index_col=0)
    
    print "forming lemmas"
    #formLemmaAlgo
    lemma_verb,lemma_verb_ws=lemStem.formLemmaAlgo(mcres_fname,verb_dict,[0.8,0.7,0.6,0.5,0.4],0.45)
    print "completed verb lemma"
    lemma_w2vm,lemma_w2vm_ws=lemStem.formLemmaAlgo(mcres_fname,w2vm_dict,None,0.7)
    print "completed w2vm lemma"
    lemma_adj,lemma_adj_ws=lemStem.formLemmaAlgo(mcres_fname,adj_dict,[0.9,0.8,0.7],0.5)
    print "completed adj lemma"
        
    lemStem.mostFrequentWords(mcres_fname,None,200,topKeyWordsWritePath)        
        
    #combined lemma
    comb_dict=w2vm_dict.add(verb_dict,fill_value=0)
    comb_dict.fillna(value=0,inplace=True)
    comb_index=set(verb_dict.index.tolist()).intersection(w2vm_dict.index.tolist())
    comb_dict.ix[comb_index,comb_index]=comb_dict.ix[comb_index,comb_index]/2
    lemma_comb,lemma_comb_ws=lemStem.combineLemmaDict(mcres_fname,lemma_verb_ws.copy(),lemma_w2vm_ws.copy(),comb_dict,0.1)     
    
    lemStem.writeLemmas(lemma_comb_ws,lemma_path,lemma_pickle_path)
   
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
    #mc_pf.pivotcsv(ifname,rfname,docid_cols,col,catmodel,lemma_pickle_path)      