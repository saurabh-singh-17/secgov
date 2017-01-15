# -*- coding: utf-8 -*-
"""
Created on 3rd August 2015

@author:svs
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

import csv, json, time
from itertools import islice
from joblib import Parallel, delayed
import metaclassifier.mcServicesAPI as mcapi
import mcsa_word_relationships as mcwr
import numpy as np
import cPickle as pickle
csv.field_size_limit(sys.maxsize)

def getAllVerbs(hr):
    allVerbs=list(hr.resources["soft_verbs"]) + list(hr.resources["not_hapenning_verbs"]) + list(hr.resources["polar_verbs_dict"].keys())
    return allVerbs

def callMC(line, docid_idxs, txtcol_idx, serializer = json.dumps):   
    docid = [line[idx] for idx in docid_idxs]
    txt = line[txtcol_idx]
    res ={}
    #rv = [serializer(docid), serializer([{}])] 
    if txt: 
        res = mcapi._mcNLPipeline(txt) #, ['sentiment', 'entitySentiment'])
        #rv[-1] = serializer(res)
            
    return res

def _mc_CSVPBSW(func, ifname, docid_cols, txtcol, rfname, dbase, serializer = json.dumps):
    '''
    CSV parallel batch processing and serialized writer 
    ''' 
    
    with open(ifname) as dfile:
        ipreader = csv.reader(dfile, delimiter='|')
        
        #header parse and find indices.
        header = ipreader.next()
        docid_idxs = [header.index(dc) for dc in docid_cols]
        txtcol_idx = header.index(txtcol) 
        ##print docid_idxs, txtcol_idx
        
        part = 0
        ink=0
        while True:
            ink+=1
            
            n_lines = list(islice(ipreader, 1000))
            if not n_lines:
                break      
            resps = [callMC(line, docid_idxs, txtcol_idx) for line in n_lines] #if "439293759" in line[docid_idxs[0]]         
            st = time.time()
            makeCoLocation(resps)
            print(collocation_matrix.shape)
            #print(collocation_matrix.shape)
            #print '%3d %4d %4.3f' % (part, len(n_lines), time.time() - st)
            if part == 30:
                break
            part += 1  
    coloc_verb_noun=VerbNounColocMatrix()
    pickle.dump(coloc_verb_noun,open(dbase+"Coloc_verb_noun.pickle","wb"))                
    collocation_result=VerbGivenNounSimilarityMatrix(weighing="tfidf")
    writerColl(collocation_result,dbase)
    pickle.dump(collocation_result,open(dbase+"all_verb_given_noun.pickle","wb"))
                        
nounTags=['N','S','Z','^']
nounList = []
verbList = []
collocation_matrix=np.zeros([1,1])
assocNoun=0
def makeCoLocation(res):
    allVerbs=getAllVerbs(mcapi.__MC_PROD_HR__[0])
    global collocation_matrix
    for text in res:
        if(len(text)==0):
            continue
        result=mcwr.findNounrelatedKeyVerbs(text)
        if result.keys().__len__(): 
            for key in result.keys():
                current_noun = key
                for value in result[key]:
                    presence_N=-1
                    presence_V=-1
                    if(value not in verbList):
                        verbList.append(value)
                    else:
                        presence_V=verbList.index(value)
                
                    if current_noun not in nounList:
                        nounList.append(current_noun) 
                    else:
                        presence_N=nounList.index(current_noun)
                    
                    if((len(verbList)==1) and (len(nounList)==1)):
                        collocation_matrix[0][0]=1
                    else:
                        if((presence_N!=-1) and (presence_V!=-1)):
                            collocation_matrix[presence_N][presence_V]+=1
                        elif((presence_N==-1) and (presence_V==-1)):
                            seq=np.array([0 for k in xrange(collocation_matrix.shape[1])])
                            collocation_matrix=np.vstack((collocation_matrix,seq))
                            seq=np.array([0 for k in xrange(collocation_matrix.shape[0])])
                            seq[-1]=1
                            collocation_matrix=np.column_stack((collocation_matrix,seq))
                        elif((presence_N!=-1) and (presence_V==-1)): 
                            seq=np.array([0 for k in xrange(collocation_matrix.shape[0])])
                            collocation_matrix=np.column_stack((collocation_matrix,seq))
                            collocation_matrix[presence_N][-1]=1
                        elif((presence_N==-1) and (presence_V!=-1)):     
                            seq=np.array([0 for k in xrange(collocation_matrix.shape[1])])
                            collocation_matrix=np.vstack((collocation_matrix,seq))        
                            collocation_matrix[-1][presence_V]=1
                                        
def top_members_extract(collocation_matrix, rev=0):
    collocation_result={}
    if(rev==0):
        for j in xrange(collocation_matrix.shape[0]):
            ind_non_zero=sorted(collocation_matrix[j],reverse=True).index(0)
            noun_max = sorted(collocation_matrix[j],reverse=True)[0:ind_non_zero]
            noun_index=np.argsort(collocation_matrix[j])[-ind_non_zero:]
            noun_index=list(noun_index)
            noun_index.reverse()
            noun_names=[nounList[m] for m in noun_index]
            collocation_result[verbList[j]]=[noun_names,noun_max]
    else:
        for j in xrange(collocation_matrix.shape[0]):
            ind_non_zero=sorted(collocation_matrix[j],reverse=True).index(0)
            verb_max = sorted(collocation_matrix[j],reverse=True)[0:ind_non_zero]
            verb_index=np.argsort(collocation_matrix[j])[-ind_non_zero:]
            verb_index=list(verb_index)
            verb_index.reverse()
            verb_names=[verbList[m] for m in verb_index]
            collocation_result[nounList[j]]=[verb_names,verb_max]
    return collocation_result
            
#calculates the conditional probability of a noun given verb            
def NounGivenVerbSimilarityMatrix():
    #calculating sum of the matrix
    sum_of_adj=collocation_matrix.sum(0)
    sum_of_array=sum(sum_of_adj)
    #normalizing the array
    collocation_matrix1=collocation_matrix/sum_of_array
    sum_normal_adj=collocation_matrix1.sum(0)
    collocation_matrix1 = collocation_matrix1.transpose()
    
    for i in xrange(collocation_matrix1.shape[0]):
        collocation_matrix1[i] = collocation_matrix1[i]/sum_normal_adj[i]
    collocation_result =top_members_extract(collocation_matrix1, rev=0)
    return collocation_result
   
#calculates the conditional probability of an verb given noun               
def VerbGivenNounSimilarityMatrix(weighing=None):
    
    #weighing tf-idf  
    if weighing == "tfidf":
        collocation_matrix1 = collocation_matrix.transpose()
        for i in xrange(collocation_matrix1.shape[0]):
            collocation_matrix1[i] = collocation_matrix1[i]*np.log(collocation_matrix1.shape[1]/collocation_matrix1[i][collocation_matrix1[i] > 0].__len__())
        collocation_matrix1 = collocation_matrix1.transpose()
    
    #calculating sum of the matrix
    sum_of_adj=collocation_matrix1.sum(0)
    sum_of_array=sum(sum_of_adj)
    collocation_matrix1=collocation_matrix1/sum_of_array
    #normalizing the array
    sum_normal_noun=collocation_matrix1.sum(1)
    for i in xrange(collocation_matrix1.shape[0]):
        collocation_matrix1[i] = collocation_matrix1[i]/sum_normal_noun[i]
    collocation_result =top_members_extract(collocation_matrix1, rev=1)
    return collocation_result

       
def VerbNounColocMatrix():
    collocation_result =top_members_extract(collocation_matrix.copy(), rev=1)
    return collocation_result    
    
    
def writerColl(write_dictionary,dbase):
    tmp=open(dbase+"noun_all_verb.txt","wb")
    logger = tmp.write
    for k in write_dictionary:
        logger("%s|%s|%s\n" %(k,"--".join(write_dictionary[k][0]),write_dictionary[k][1]))
    
    tmp.close()
        
        

def makeMCRes(ifname, docid_cols, txtcol, rfname, dbase, serializer = json.dumps):
    _mc_CSVPBSW(callMC, ifname, docid_cols, txtcol, rfname, dbase, serializer = json.dumps)
                                                 
if __name__ == "__main__":
    import time, os
    import csv

    
    dataset_name = 'DIL'
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM'] 
    tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"          
    dhome = os.path.join(tmp_home, dataset_name)

    for col in txt_cols:
        dbase = os.path.join(dhome, col, col)
        ifname = dbase + '.verbatims'
        rfname = dbase + '.mcres.csv'
        #print 'Extracting Surface Properties & Polarities'
        makeMCRes(ifname, docid_cols, col, rfname, dbase, serializer = json.dumps)
        #print(collocation_matrix.shape())
