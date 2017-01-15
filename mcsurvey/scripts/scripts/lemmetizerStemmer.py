# -*- coding: utf-8 -*-
"""
Created on Tue Aug  4 01:33:52 2015

@author: user
"""
import cPickle as pickle
import pandas as pd
import math
import numpy as np
from sklearn.cluster import AffinityPropagation
import gensim
import gensim.matutils as ma
import mcsa_phase2 as mcsa_ph2
import cPickle as pickle
import os, sys
import csv, json, time


def writeLemmas(lemmaDict,path,lemma_pickle_path=None):
    tmp=open(path,"wb")
    logger = tmp.write
    logger("Group_no|Lemma|Words|Sim_value|Closest_group\n")
    for k in lemmaDict.keys():
        logger("%s|%s|%s|%s|%s\n" %(str(k),lemmaDict[k]["lemma"]," ".join((lemmaDict[k]["words"])),str(lemmaDict[k]["sim_value"]),str(lemmaDict[k]["close_group"])))
    tmp.close()
    if lemma_pickle_path:
        pickle.dump(lemmaDict,open(lemma_pickle_path,"wb"))
        
def formLemmaAlgo(mcres_fname,affmat,pref=None,thr=0.1):
    lemma_dict = {}
    itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=10)
    if pref:
        lemma_c=formLemma(affmat,pref[0])
        lemma_c,lemma_c_ws=verifyLemma(lemma_c,affmat,th=thr)
        if lemma_c_ws:
            group=max(lemma_c_ws.keys())+1
        for t in pref[1:]:
            lemma_d=formLemma(affmat,t)
            lemma_d,lemma_d_ws=verifyLemma(lemma_d,affmat,th=0)    
            if lemma_c and lemma_d:
                for lem_c in lemma_c_ws:
                    for lem_d in lemma_d_ws:
                        count=set(lemma_c_ws[lem_c]["words"]).intersection(lemma_d_ws[lem_d]["words"]).__len__()
                        if count and lemma_c_ws[lem_c]["sim_value"] > thr and lemma_d_ws[lem_d]["sim_value"] > thr and lemma_d.has_key(lem_d):
                            combined_list=lemma_c_ws[lem_c]["words"] + lemma_d_ws[lem_d]["words"]
                            lemma_c[lem_c]=list(set(combined_list))
                            lemma_d.pop(lem_d)
                            break 
                for lem_d in lemma_d:    
                    lemma_d_ws[lem_d]["sim_value"] > thr
                    lemma_c[group] = lemma_d_ws[lem_d]["words"]
                    group +=1
                lemma_c,lemma_c_ws=verifyLemma(lemma_c,affmat,th=thr)
            else:
                lemma_c = lemma_d.copy()
                lemma_c_ws = lemma_d_ws.copy()
                if lemma_c_ws:
                    group=max(lemma_c_ws.keys())+1
            print (t,"completed")  
            print lemma_c.keys()
        lemma_c,lemma_c_ws=verifyLemma(lemma_c,affmat,th=thr)
    else:
        lemma_c=formLemma(affmat)
        lemma_c,lemma_c_ws=verifyLemma(lemma_c,affmat,th=thr)
    
    lemma_final={}
    num=0    
    for lem in lemma_c:
        temp=[]
        key=[]
        for lem2 in lemma_c_ws:
            comm=set(lemma_c[lem]).intersection(lemma_c_ws[lem2]["words"])
            if comm:
               temp=list(set(temp + lemma_c_ws[lem2]["words"])) 
               key=key + [lem2]
        if temp:       
            lemma_final[num]=temp
            num +=1
        for i in key:
            lemma_c_ws.pop(i)
    lemma_final,lemma_final_ws=verifyLemma(lemma_final,affmat,th=thr)
    
    #finding the lemma as most frequent word
    for lem in lemma_final_ws:
        lemma = []
        for words in lemma_final_ws[lem]["words"]:
            if (words in itoks) and (lemma == []):
                lemma=words
            elif words in itoks:
                if cnts[itoks.index(words)] > cnts[itoks.index(lemma)]:
                    lemma = words
        if lemma:            
            lemma_final_ws[lem]["lemma"]=lemma             
        else:
            lemma_final_ws[lem]["lemma"]= lemma_final_ws[lem]["words"][0]            

    #finding the next closest group:
    for lem in lemma_final_ws:
        cl_grp=[]
        cl_lemma=[]
        cl_value=[]
        for lem2 in lemma_final_ws:
            if cl_grp == [] and lem != lem2:
                cl_grp=lem2
                cl_lemma=lemma_final_ws[lem2]["lemma"]
                cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
            elif lem != lem2:
                if cl_value < calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat):
                    cl_grp=lem2
                    cl_lemma=lemma_final_ws[lem2]["lemma"]
                    cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
        lemma_final_ws[lem]["close_group"]=":".join((str(cl_grp),cl_lemma,str(cl_value)))
        
    return lemma_final,lemma_final_ws    

def combineLemmaDict(mcres_fname,dict1,dict2,affmat,thr=0.1):
    itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=10)
    lemma_final={}
    num=0 
    for lem in dict1:
        temp=dict1[lem]["words"]
        key=[]
        for lem2 in dict2:
            comm=set(dict1[lem]["words"]).intersection(dict2[lem2]["words"])
            if comm:
               temp=list(set(temp + dict2[lem2]["words"])) 
               key=key + [lem2]
        if temp:       
            lemma_final[num]=temp
            num +=1
        for i in key:
            dict2.pop(i)
    for lem2 in dict2:
        lemma_final[num] = dict2[lem2]["words"]
        num +=1
    lemma_final,lemma_final_ws=verifyLemma(lemma_final,affmat,th=thr)
    
    #finding the lemma as most frequent word
    for lem in lemma_final_ws:
        lemma = []
        for words in lemma_final_ws[lem]["words"]:
            if (words in itoks) and (lemma == []):
                lemma=words
            elif words in itoks:
                if cnts[itoks.index(words)] > cnts[itoks.index(lemma)]:
                    lemma = words
        if lemma:            
            lemma_final_ws[lem]["lemma"]=lemma             
        else:
            lemma_final_ws[lem]["lemma"]= lemma_final_ws[lem]["words"][0]            

    #finding the next closest group:
    for lem in lemma_final_ws:
        cl_grp=[]
        cl_lemma=[]
        cl_value=[]
        for lem2 in lemma_final_ws:
            if cl_grp == [] and lem != lem2:
                cl_grp=lem2
                cl_lemma=lemma_final_ws[lem2]["lemma"]
                cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
            elif lem != lem2:
                if cl_value < calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat):
                    cl_grp=lem2
                    cl_lemma=lemma_final_ws[lem2]["lemma"]
                    cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
        lemma_final_ws[lem]["close_group"]=":".join((str(cl_grp),cl_lemma,str(cl_value)))
        
    return lemma_final,lemma_final_ws    

def calculateSim(lem1,lem2,affmat):
    sim_value=0
    for word1 in lem1:
        sim_value=sim_value+sum([affmat.ix[word1,word2] for word2 in lem2])
    sim_value=sim_value/(lem1.__len__()*lem2.__len__())
    return sim_value
    
def verifyLemma(lemmas,affmat,th=0.1):
    lemma_with_avg_sim = {}
    for lemma in lemmas.keys():
        sim_value=0
        if lemmas[lemma].__len__() > 1:
            for ind,words in enumerate(lemmas[lemma]):
                sim_value=sim_value+sum([affmat.ix[words,word] for word in lemmas[lemma][ind+1:]])
            sim_value=sim_value/(lemmas[lemma].__len__()*(lemmas[lemma].__len__()-1)/2)
        else:
            sim_value=1
        if(sim_value > th):
            lemma_with_avg_sim[lemma] = {}
            lemma_with_avg_sim[lemma]["words"] = lemmas[lemma]
            lemma_with_avg_sim[lemma]["sim_value"] = sim_value
        else:    
            lemmas.pop(lemma)
    return lemmas,lemma_with_avg_sim

def formLemma(affmat,pref=None):
    af = AffinityPropagation(preference=pref,affinity = 'precomputed').fit(affmat)
    no_of_clusters = len(af.cluster_centers_indices_)
    indices=affmat.index.tolist()
    lemma_dict={}
    for n in xrange(no_of_clusters):
        index = [item for item in range(len(list(af.labels_))) if list(af.labels_)[item] == n]
        if index.__len__() > 1:
            lemma_dict[n]=[indices[ind] for ind in index]
    return lemma_dict        

def lemmetizer(verb_path=None,adj_path=None,w2vm_path=None,th=1,dbase=None):
    lemme_dict={}
    if verb_path == None and adj_path == None and  w2vm_path == None:
        return lemme_dict
    
    if verb_path:
        verb_noun_pickle=pickle.load(open(verb_path))
        if th > 1:
            for words in verb_noun_pickle.keys():
                if verb_noun_pickle[words][0].__len__() < th:
                    verb_noun_pickle.pop(words)
        print "dimension" 
        print verb_noun_pickle.keys().__len__()
        verb_dict=pd.DataFrame(index=verb_noun_pickle.keys(),columns=verb_noun_pickle.keys())
        for indn,noun in enumerate(verb_noun_pickle.keys()):
            print indn
            for indcn in xrange(indn,verb_noun_pickle.keys().__len__()-1):
                compare_noun=verb_noun_pickle.keys()[indcn]
                if noun == compare_noun:
                    verb_dict.ix[noun,compare_noun]=1
                    continue
                common_verbs=list(set(verb_noun_pickle[noun][0][:100]).intersection(verb_noun_pickle[compare_noun][0][:100]))
                len_noun=verb_noun_pickle[noun][0].__len__()
                if len_noun > 100:
                    len_noun = 100
                len_compare_noun=verb_noun_pickle[compare_noun][0].__len__()
                if len_compare_noun > 100:
                    len_compare_noun = 100
                len_common_verbs=common_verbs.__len__()
                noun_add=0
                compare_noun_add=0
                sim_value=0
                if common_verbs:
                    noun_add = sum([verb_noun_pickle[noun][1][verb_noun_pickle[noun][0].index(nn)] for nn in common_verbs])
                    noun_weight=sum([len_noun - verb_noun_pickle[noun][0].index(nn) for nn in common_verbs])/(float(len_common_verbs*len_noun))
                    compare_noun_add = sum([verb_noun_pickle[compare_noun][1][verb_noun_pickle[compare_noun][0].index(nn)] for nn in common_verbs])
                    compare_noun_weight=sum([len_compare_noun - verb_noun_pickle[compare_noun][0].index(nn) for nn in common_verbs])/(float(len_common_verbs*len_compare_noun))
                    noun_add=noun_add+((1-noun_add)*len_common_verbs/len_compare_noun*noun_weight)
                    compare_noun_add=compare_noun_add+((1-compare_noun_add)*len_common_verbs/len_noun*compare_noun_weight)
                    sim_value=math.sqrt(noun_add*compare_noun_add)
                verb_dict.ix[noun,compare_noun]=sim_value    
                verb_dict.ix[compare_noun,noun]=sim_value  
        verb_dict.fillna(value=0,inplace=True)         
        verb_dict.to_csv((dbase + "verb_sim_mat.csv"),sep="|")       


    if adj_path:
        print "running adjectives"
        adj_noun_pickle=pickle.load(open(adj_path))
        if th > 1:
            for words in adj_noun_pickle.keys():
                if adj_noun_pickle[words][0].__len__() < th:
                    adj_noun_pickle.pop(words)
        print "dimension" 
        print adj_noun_pickle.keys().__len__()
        
        adj_dict=pd.DataFrame(index=adj_noun_pickle.keys(),columns=adj_noun_pickle.keys())
        for indn,noun in enumerate(adj_noun_pickle.keys()):
            print indn
            for indcn in xrange(indn,adj_noun_pickle.keys().__len__()-1):
                compare_noun=adj_noun_pickle.keys()[indcn]
                if noun == compare_noun:
                    adj_dict.ix[noun,compare_noun]=1
                    continue
                common_adj=list(set(adj_noun_pickle[noun][0]).intersection(adj_noun_pickle[compare_noun][0]))
                len_noun=adj_noun_pickle[noun][0].__len__()
                len_compare_noun=adj_noun_pickle[compare_noun][0].__len__()
                len_common_adj=common_adj.__len__()
                noun_add=0
                compare_noun_add=0
                sim_value=0
                if common_adj:
                    noun_add = sum([adj_noun_pickle[noun][1][adj_noun_pickle[noun][0].index(nn)] for nn in common_adj])
                    noun_weight=sum([len_noun - adj_noun_pickle[noun][0].index(nn) for nn in common_adj])/(float(len_common_adj*len_noun))
                    compare_noun_add = sum([adj_noun_pickle[compare_noun][1][adj_noun_pickle[compare_noun][0].index(nn)] for nn in common_adj])
                    compare_noun_weight=sum([len_compare_noun - adj_noun_pickle[compare_noun][0].index(nn) for nn in common_adj])/(float(len_common_adj*len_compare_noun))
                    noun_add=noun_add+((1-noun_add)*len_common_adj/len_compare_noun*noun_weight)
                    compare_noun_add=compare_noun_add+((1-compare_noun_add)*len_common_adj/len_noun*compare_noun_weight)
                    #sim_value=((noun_add+compare_noun_add)/2)*(len_commom_adj/math.sqrt(len_noun*len_compare_noun))
                    sim_value=math.sqrt(noun_add*compare_noun_add)
                adj_dict.ix[noun,compare_noun]=sim_value    
                adj_dict.ix[compare_noun,noun]=sim_value
        adj_dict.fillna(value=0,inplace=True)        
        adj_dict.to_csv((dbase + "adj_sim_mat.csv"),sep="|")         
        
    if w2vm_path:
        w2vm_dict=pd.read_csv(w2vm_sim_mat_path,sep="|",index_col=0)


def mostFrequentWords(mcres_fname=None,th=100,top=100,writePath=None):
    if th:
        itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=th)
    elif top:
        itoks, cnts = mcsa_ph2.getEntities(mcres_fname, th=None, top=top)
    tmp=open(writePath,"wb")
    logger = tmp.write
    logger("Words|count|Seed\n")
    for k,toks in enumerate(itoks):
        logger("%s|%s|%s\n" %(toks,str(cnts[k]),"0"))
    tmp.close()

def readSeeds(readPath):
    seeds=pd.read_csv(readPath,sep="|",index_col=0)
    index=[]
    if any(seeds["Seed"] > 0):
        index=seeds[seeds["Seed"] > 0].index.tolist()
    return index    
    
 
def seededLemmas(seeds,affmat,th=0.4,types="verb"):
    lemma={}
    alllemma=[]
    for ind,seed in enumerate(seeds):
        completed=[]
        recursion = True
        clemma = []
        newseed=seed
        thr=th
        while recursion:
            nextSeeds = affmat[newseed][affmat[newseed] >= thr]
            nextSeeds = nextSeeds.index.tolist()[:nextSeeds.index.tolist().__len__()]
            clemma=clemma + nextSeeds
            completed = completed + [newseed]
            oldseed=newseed
            if types == "verb" or types == "adj":
                thr = th + 0.1
            elif types == "w2vm":
                thr = th + 0.2
            for word in clemma:
                if word not in completed:
                    newseed=word
                    print newseed
                    break
            if newseed == oldseed:
                recursion=False
        alllemma=alllemma + clemma
    alllemma = list(set(alllemma))    
        
    #assigning the alllemma list ot different lemma groups
    for word in alllemma:
        grp_no=np.argmax([affmat.ix[word,seed] for seed in seeds])
        if lemma.has_key(grp_no):
            lemma[grp_no] = lemma[grp_no] + [word]
        else:
            lemma[grp_no] = [word]
    
    lemma_final,lemma_final_ws=verifyLemma(lemma,affmat)
    
    #adding the lemma
    for key in lemma_final_ws.keys():
        lemma_final_ws[key]["lemma"] = seeds[key]
        
    #finding the next closest group:
    for lem in lemma_final_ws:
        cl_grp=[]
        cl_lemma=[]
        cl_value=[]
        for lem2 in lemma_final_ws:
            if cl_grp == [] and lem != lem2:
                cl_grp=lem2
                cl_lemma=lemma_final_ws[lem2]["lemma"]
                cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
            elif lem != lem2:
                if cl_value < calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat):
                    cl_grp=lem2
                    cl_lemma=lemma_final_ws[lem2]["lemma"]
                    cl_value=calculateSim(lemma_final_ws[lem]["words"],lemma_final_ws[lem2]["words"],affmat)
        lemma_final_ws[lem]["close_group"]=":".join((str(cl_grp),cl_lemma,str(cl_value)))
    
    return lemma_final,lemma_final_ws

   
if __name__ == "__main__":
    
#path of the dataset
    dataset_fname="/home/user/Desktop/mcSurveyAnalysis/tmp/dil_verbatims.txt"
    
#defining the variables
    dataset_name = 'DIL'
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM'] #SRV_Q21B_RESOLVE_VERBATIM 
    dnames = ['DIL-ISSUE'] #'DIL-RESOLVE'

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
        topKeyWordsWritePath = dbase + "KeyWords.csv"

    #write key words    
        verb_dict_path=dbase+"verb_sim_mat.csv"
        verb_dict=pd.read_csv(verb_dict_path,sep="|",index_col=0)
        w2vm_dict=pd.read_csv(w2vm_sim_mat_path,sep="|",index_col=0)
        mostFrequentWords(mcres_fname,th=None,top=100,writePath=topKeyWordsWritePath)
        seeds=readSeeds(topKeyWordsWritePath)
        seeds=["rep/N","tower/N","bill/N","plan/N"]
        if seeds:
              lemma_verb,lemma_verb_ws=seededLemmas(seeds,verb_dict,0.5)
        '''
    #calling lemmetizer
        lemmetizer(verb_noun_pickle_path , adj_noun_pickle_path , None ,10,dbase)
    
    #importing results of lemmetizer and pickles
        verb_dict_path=dbase+"verb_sim_mat.csv"
        verb_dict=pd.read_csv(verb_dict_path,sep="|",index_col=0)
    
        adj_dict_path=dbase+"adj_sim_mat.csv"
        adj_dict=pd.read_csv(adj_dict_path,sep="|",index_col=0)
        
        w2vm_dict=pd.read_csv(w2vm_sim_mat_path,sep="|",index_col=0)
    
        print "forming lemmas"
        #formLemmaAlgo
        lemma_verb,lemma_verb_ws=formLemmaAlgo(mcres_fname,verb_dict,[0.8,0.7,0.6,0.5],0.4)
        writeLemmas(lemma_verb_ws,lemma_v_p)
        print "completed verb lemma"
        lemma_w2vm,lemma_w2vm_ws=formLemmaAlgo(mcres_fname,w2vm_dict,None,0.55)
        writeLemmas(lemma_w2vm_ws,lemma_w_p)
        print "completed w2vm lemma"
        
        lemma_adj,lemma_adj_ws=formLemmaAlgo(mcres_fname,adj_dict,[0.9,0.8,0.7],0.5)
        writeLemmas(lemma_adj_ws,lemma_a_p)
        print "completed adj lemma"
        
        #combined lemma
        comb_dict=w2vm_dict.add(verb_dict,fill_value=0)
        comb_dict.fillna(value=0,inplace=True)
        comb_index=set(verb_dict.index.tolist()).intersection(w2vm_dict.index.tolist())
        comb_dict.ix[comb_index,comb_index]=comb_dict.ix[comb_index,comb_index]/2
        lemma_comb,lemma_comb_ws=combineLemmaDict(mcres_fname,lemma_verb_ws.copy(),lemma_w2vm_ws.copy(),comb_dict,0.1)     
    
        writeLemmas(lemma_comb_ws,lemma_path,lemma_pickle_path)
        '''