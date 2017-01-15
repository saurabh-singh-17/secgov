# -*- coding: utf-8 -*-
"""
Created on Sun Apr 26 18:30:26 2015

@author: vh, shardul and svs
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

import csv, json, time
from itertools import islice
from joblib import Parallel, delayed
import metaclassifier.mcServicesAPI as mcapi
import numpy as np
import cPickle as pickle
csv.field_size_limit(sys.maxsize)

def callMC(line, docid_idxs, txtcol_idx, serializer = json.dumps):   
    docid = [line[idx] for idx in docid_idxs]
    txt = line[txtcol_idx]
    res ={}
    #rv = [serializer(docid), serializer([{}])] 
    if txt: 
        res = mcapi._mcNLPipeline(txt) #, ['sentiment', 'entitySentiment'])
        #rv[-1] = serializer(res)
            
    return res

def _mc_CSVPBSW(func, ifname, docid_cols, txtcol, rfname , dbase, serializer = json.dumps):
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

            part += 1  
    coloc_adj_noun=AdjNounColocMatrix()
    pickle.dump(coloc_adj_noun,open(dbase+"Coloc_adj_noun.pickle","wb"))                        
    colloation_result=adjectiveAndNounSimilarityMatrix()
    writerColl(colloation_result,dbase)
    pickle.dump(colloation_result,open(dbase+"all_adj_given_noun.pickle","wb"))
                            
nounTags=['N','S','Z','^']
adjectiveList = []
nounList = []
collocation_matrix=np.zeros([1,1])
def makeCoLocation(res):
    global collocation_matrix
    for text in res:
        if(len(text)==0):
            continue
        for chunkSentences in text["chunkedSentences"]:
            for indc,chunk in enumerate(chunkSentences):
                if chunk.chunkType in ["NP","ADJP"]:
                    for ind,tags in enumerate(chunk.tags):
                        if tags == "A":
                            #print(chunk)
                            presence_N=-1
                            presence_A=-1
                            assocNoun=-1
                            current_noun = []
                            for i in xrange(ind+1,chunk.tags.__len__()):
                                if chunk.tags[i] in nounTags:
                                    assocNoun=i
                                    current_noun="/".join((chunk.tokens[i],chunk.tags[i]))
                                elif chunk.tags[i] == "P":
                                    break
                            #print("0")    
                            if assocNoun == -1:
                                if indc >= 2:
                                     if ((chunkSentences[indc-1].chunkType == "VP") and (chunkSentences[indc-2].chunkType == "NP")):
                                         if  chunkSentences[indc-1].tprops[0].has_key("AUXVERB"):
                                             for j in xrange(chunkSentences[indc-2].tags.__len__()):
                                                if chunkSentences[indc-2].tags[j] in nounTags:
                                                    assocNoun=j
                                                    current_noun="/".join((chunkSentences[indc-2].tokens[j],chunkSentences[indc-2].tags[j]))
                                                elif chunkSentences[indc-2].tags[j] == "P":
                                                    break        
                            
                            if assocNoun  != -1: 
                                if("/".join((chunk.tokens[ind],chunk.tags[ind])) not in adjectiveList):
                                    adjectiveList.append("/".join((chunk.tokens[ind],chunk.tags[ind])))
                                else:
                                    presence_A=adjectiveList.index("/".join((chunk.tokens[ind],chunk.tags[ind])))
                                    
                                if current_noun not in nounList:
                                    nounList.append(current_noun) 
                                else:
                                    presence_N=nounList.index(current_noun)
                            if assocNoun != -1:
                                if((len(adjectiveList)==1) and (len(nounList)==1)):
                                    collocation_matrix[0][0]=1
                                else:
                                    if((presence_N!=-1) and (presence_A!=-1)):
                                        collocation_matrix[presence_N][presence_A]+=1
                                    elif((presence_N==-1) and (presence_A==-1)):
                                         seq=np.array([0 for k in xrange(collocation_matrix.shape[1])])
                                         collocation_matrix=np.vstack((collocation_matrix,seq))
                                         seq=np.array([0 for k in xrange(collocation_matrix.shape[0])])
                                         seq[-1]=1
                                         collocation_matrix=np.column_stack((collocation_matrix,seq))
                                    elif((presence_N!=-1) and (presence_A==-1)): 
                                         seq=np.array([0 for k in xrange(collocation_matrix.shape[0])])
                                         collocation_matrix=np.column_stack((collocation_matrix,seq))
                                         collocation_matrix[presence_N][-1]=1
                                    elif((presence_N==-1) and (presence_A!=-1)):     
                                         seq=np.array([0 for k in xrange(collocation_matrix.shape[1])])
                                         collocation_matrix=np.vstack((collocation_matrix,seq))        
                                         collocation_matrix[-1][presence_A]=1
                                        
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
            collocation_result[adjectiveList[j]]=[noun_names,noun_max]
    else:
        for j in xrange(collocation_matrix.shape[0]):
            ind_non_zero=sorted(collocation_matrix[j],reverse=True).index(0)
            adjective_max = sorted(collocation_matrix[j],reverse=True)[0:ind_non_zero]
            adjective_index=np.argsort(collocation_matrix[j])[-ind_non_zero:]
            adjective_index=list(adjective_index)
            adjective_index.reverse()
            adjective_names=[adjectiveList[m] for m in adjective_index]
            collocation_result[nounList[j]]=[adjective_names,adjective_max]
    return collocation_result
            
#calculates the conditional probability of a noun given adjective            
def nounAndAdjectiveSimilarityMatrix():
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
   
#calculates the conditional probability of an adjective given noun               
def adjectiveAndNounSimilarityMatrix():
    #calculating sum of the matrix
    sum_of_adj=collocation_matrix.sum(0)
    sum_of_array=sum(sum_of_adj)
    #normalizing the array
    collocation_matrix1=collocation_matrix/sum_of_array
    sum_normal_noun=collocation_matrix1.sum(1)
    for i in xrange(collocation_matrix1.shape[0]):
        collocation_matrix1[i] = collocation_matrix1[i]/sum_normal_noun[i]
    collocation_result =top_members_extract(collocation_matrix1, rev=1)
    return collocation_result
       
    
def AdjNounColocMatrix():
    collocation_result =top_members_extract(collocation_matrix.copy(), rev=1)
    return collocation_result      
    
def writerColl(write_dictionary,dbase):
    tmp=open(dbase+"all_adj_given_noun.txt","wb")
    logger = tmp.write
    for k in write_dictionary:
        logger("%s|%s|%s\n" %(k," ".join(write_dictionary[k][0]),write_dictionary[k][1]))
    
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
        makeMCRes(ifname, docid_cols, col, rfname, dbase,serializer = json.dumps)
        #print(collocation_matrix.shape())
