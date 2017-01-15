# -*- coding: utf-8 -*-
"""
Created on Mon Aug 31 05:43:17 2015

@author: user
"""
import mcsa_phase2 as mcsa_ph2
import lemmetizerStemmer as lemStem
import pandas as pd
import mcsa_pf as mc_pf
import os 


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
#defining paths
for col in txt_cols:
    dbase = os.path.join(dhome, col, col)
    verb_noun_pickle_path = dbase + 'all_verb_given_noun.pickle'
    adj_noun_pickle_path = dbase + 'all_adj_given_noun.pickle'
    w2vm_sim_mat_path = dbase + ".SimMat.csv"
    mcres_fname = dbase + '.mcres.csv'
    lemma_path=dbase + "lemma.csv"
    lemma_v_p = dbase + "vlemma.csv"
    lemma_w_p = dbase + "wlemma.csv"
    lemma_a_p = dbase + "alemma.csv"
    lemma_pickle_path = dbase + "lemma.pickle"
    topKeyWordsWritePath = dbase + "KeyWords1.csv"


    #importing results of lemmetizer and pickles
    verb_dict_path=dbase+"verb_sim_mat.csv"
    verb_dict=pd.read_csv(verb_dict_path,sep="|",index_col=0)
    
    adj_dict_path=dbase+"adj_sim_mat.csv"
    adj_dict=pd.read_csv(adj_dict_path,sep="|",index_col=0)
    
    w2vm_dict=pd.read_csv(w2vm_sim_mat_path,sep="|",index_col=0)

#write key words    
    seeds=lemStem.readSeeds(topKeyWordsWritePath)
    if seeds:
        lemma_verb,lemma_verb_ws=lemStem.seededLemmas(seeds,verb_dict,0.6,"verb")
        lemStem.writeLemmas(lemma_verb_ws,lemma_v_p)
        lemma_w2vm,lemma_w2vm_ws=lemStem.seededLemmas(seeds,w2vm_dict,0.8,"w2vm")
        lemStem.writeLemmas(lemma_w2vm_ws,lemma_w_p)
          

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