# -*- coding: utf-8 -*-
"""
Created on Tue Jun  9 05:06:20 2015

@author: vh
"""

import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
print home
import csv, sys, json, operator
from collections import defaultdict
import pandas as pd
import cPickle as pickle
import metaclassifier.mcServicesAPI as mcapi


csv.field_size_limit(sys.maxsize)
def getEntities(fname, th = None, top=None):
    '''
    Important entities.
    th = minimum frequency
    '''
    ents = defaultdict(int)
    with open(fname) as f:
        reader = csv.reader(f, delimiter='|')
        for line in reader:
            res = json.loads(line[1])
            
            for s, sres in enumerate(res):
                if sres:                    
                    for ent in sres['entitySentiment']['result']:
                        ents[ent['entity']] += 1 
    if th:
        ients = [ (k,v) for k, v in ents.iteritems() if v >= th and len(k.split()) ==1]
        ients.sort(key=lambda tup: tup[1], reverse=True)    
    elif top:
        ients = [ (k,v) for k, v in ents.iteritems() if len(k.split()) == 1]
        ients = [(k, ents[k]) for k in sorted(ents, key=ents.get, reverse=True)]
        ients = ients[:top]
    else:
        return((0,0))
    return zip(*ients)
mtok_sw_R = ['as', 'now', 'there', 'so', 'just', 'when', 'also', 'again', 'however', 'then', 'how']
mtok_sw_R = set([tok+'/R' for tok in mtok_sw_R])
mtok_sw_V = ['is', 'have', 'had', 'are', 'do', 'has', 'be', 'been', 'can', 'was', 'does', 'am', 'were', 'did']
mtok_sw_V.extend(['would', 'could', 'should', 'having'])
mtok_sw_V = set([tok+'/V' for tok in mtok_sw_V])
def getAVRToks(fname, th):
   
    tokCounts = defaultdict(int)
    
    with open(fname) as f:
        reader = csv.reader(f, delimiter='|')
        for line in reader:
            res = json.loads(line[1])
            for s, sres in enumerate(res):
                if sres:                    
                    toktags = sres['tokstags']['result'].split()
                    for tt in toktags:
                       # if tt[-1] in 'R' and not tt in mtok_sw_R:
                        #    tokCounts[tt] += 1
                        #if tt[-1] in 'V' and not tt in mtok_sw_V:
                         #   tokCounts[tt] += 1
                        if tt[-1] in 'A':
                            tokCounts[tt] += 1
                            
#                        if (not tt[-1] in ('G', 'O', ',', 'x', '&')) or (tt[-1] in ('D') and tt[:-2] == 'no'):
#                            tokCounts[tt] += 1
                             
#                    for ent in sres['entitySentiment']['result']:
#                        tokCounts[ent['entity']] += 1 
    
    sorted_x = sorted(tokCounts.items(), key=operator.itemgetter(1), reverse=True)
    rv = []    
    for x in sorted_x:
        if x[1] > th:
            rv.append(x)  
    return zip(*rv) #sorted_x)    
    
#funtion to make ctable for adjectives and nouns together    
def ctableAdjNoun(pickle_path,ctable_fname,file_name,count,itoks=None,cnts=None, polarity=None, polarityDict=None):
    collocation=pickle.load(open(pickle_path))
    ctable=pd.read_csv(ctable_fname,sep="\t")
    subset_ctable=ctable[ctable["LEVEL"].values == 0]
    center=[]
    members=[]
    name=[]
    cluster=[]
    level=[]
    iter1=0
    for i in xrange(subset_ctable.shape[0]):
        for ind,j in enumerate(subset_ctable.MEMBERS[i].split("|")):
            if(collocation.has_key(j)):
                iter1+=1
                center.append(j)
                name.append(j[:-2])
                collocation[j][0] = [n for n in collocation[j][0] if n.split(" ")[n.split(" ").__len__()-1][:-2] in polarityDict.keys() if polarityDict[n.split(" ")[n.split(" ").__len__()-1][:-2]] == polarity]
                collocation[j][1] = [collocation[j][1][v] for v,n in enumerate(collocation[j][0]) if n.split(" ")[n.split(" ").__len__()-1][:-2] in polarityDict.keys() if polarityDict[n.split(" ")[n.split(" ").__len__()-1][:-2]] == polarity]
                if itoks and cnts:
                    collocation[j][0] = ["**"+str(iter1)+"**"+m[:-2]+"_"+str(collocation[j][1][v])[:-2]+m[-2:] for v,m in enumerate(collocation[j][0][:count])]
                else:
                    collocation[j][0] = ["**"+str(iter1)+"**"+m for v,m in enumerate(collocation[j][0][:count])]
                members.append("|".join((collocation[j][0])))
                cluster.append(iter1)
                level.append(0)
            
    ctableAdjNoun=pd.DataFrame({"LEVEL":level,"CLUSTER":cluster,"CENTER":center,"NAME":name,"MEMBERS":members})       
    ctableAdjNoun=ctableAdjNoun.reindex_axis(["LEVEL","CLUSTER","CENTER","NAME","MEMBERS"],axis=1)   
    ctable.LEVEL=ctable.LEVEL+1
    newctable=ctableAdjNoun.append(ctable)
    newctable.index = [n for n in xrange(newctable.index.__len__())]
    if itoks and cnts:
        for ind,tokens in enumerate(newctable.CENTER):
            if tokens in itoks:
                newctable.NAME[ind] = newctable.NAME[ind] +"_"+ str(cnts[itoks.index(tokens)])
    newctable.to_csv(file_name,sep="\t",index=False)
    
        
    
if __name__ == "__main__":
    import os
    import matplotlib.pyplot as plt
    from mcsa_w2v import mcW2V
    from mcsa_clusters import mcClusters
    dataset_name = 'volte'        
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q2B_SAT_VOICE_WHY', 'SRV_Q3B_SAT_DATA_WHY']
    txt_cols = ['SRV_Q3B_SAT_DATA_WHY']; dname = 'DATA' 
    #txt_cols = ['SRV_Q2B_SAT_VOICE_WHY']; dname = 'VOICE' 
    txt_cols = ['SRV_Q1B_WTR_WHY']; dname = 'WTR'  
    #txt_cols = ['SRV_Q1D_SAT_VALUE_ATT_WHY']; dname = 'VALUE'   
    
    #dataset_name = 'UVERSE' 
    #docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    #txt_cols = ['W4_NOT_WTR_ATT_WHY']; dname = 'ATT-WHY'
    #txt_cols = ['U2A_SAT_INTERNET_WHY']; dname = 'INTERNET' 
    #txt_cols = ['U1A_SAT_TV_WHY']; dname = 'TV'
    
    #dataset_name = 'EMP_SURVEY'
    ##    dataset_fname = '/home/vh/surveyAnalysis/data/empsurv.csv' 
    #docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    #txt_cols = ['Q1:Comments-How would you describe the current ATO work culture? ']  
    #dname = 'CULTURE'
    #    
    #dataset_name = 'CHATS'
    #docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    #txt_cols = ['Text'] #['Verbatim'] 
    #dname = 'CHAT-Text'
    dataset_name = 'DIL'
    #dataset_fname = '/home/vh/surveyAnalysis/data/DIL_VERBATIMS.csv' 
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM', 'SRV_Q21B_RESOLVE_VERBATIM'] 
    dnames = ['DIL-ISSUE', 'DIL-RESOLVE']



    dataset_name = 'DIL'
    #dataset_fname = '/home/vh/surveyAnalysis/data/DIL_VERBATIMS.csv' 
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM']; dname = 'DIL-ISSUE' 
    #txt_cols = ['SRV_Q21B_RESOLVE_VERBATIM']; dname = 'DIL-RESOLVE' 
    #dnames = ['DIL-ISSUE', 'DIL-RESOLVE']
    dataset_name = 'MCV'
    docid_cols = ['RowID'] 
    txt_cols = ['Verbatim'] 
    dnames = ['MCV-verbatim']    
        
    tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"           
    dhome = os.path.join(tmp_home, dataset_name)
    basemodel_path="/home/user/Desktop/mcSurveyAnalysis/tmp/volte/SRV_Q1B_WTR_WHY/SRV_Q1B_WTR_WHY.w2vm"
    plt.close('all')     
    for col in txt_cols:
        dbase = os.path.join(dhome, col, col)
        mcres_fname = dbase + '.mcres.csv'
        ctable_fname = dbase + '.ctable.csv'
        w2v_fname = dbase + '.w2vm'
        verb_noun_pickle_path = dbase + 'Coloc_verb_noun.pickle'
        adj_noun_pickle_path = dbase + 'Coloc_adj_noun.pickle'
    
        resbase = "/home/user/Desktop/mcSurveyAnalysis/results/" + '__'.join([dataset_name, col]) 
        
        #itoks, cnts = getEntities(mcres_fname, th=102, top=None)
        itoks, cnts = getEntities(mcres_fname, th=None, top=20)
        #itoks, cnts = getAVRToks(mcres_fname, th=600)
        w2vm= mcW2V()
        w2vm = w2vm.build(mcres_fname,baseModel = basemodel_path, saveas = w2v_fname)
        #w2vm = w2vm.build(mcres_fname,baseModel = None, saveas = w2v_fname)
        w2vm = mcW2V(w2v_fname)
        mcc = mcClusters(w2vm) #create mcClusters object.
        mcc.makeClusters(itoks, cnts,saveSimMat=".".join((dbase,"SimMat.csv")))
        mcc.plot(pname=dname) #visualize
        mcc.save(open(ctable_fname, 'wb').write)
        
        #making of adjective and noun similarity graph
        #loading the file for adj and noun co-loc matrix
        ctableAdjNoun(pickle_path=adj_noun_pickle_path,ctable_fname=ctable_fname,file_name=dbase + 'ctable_noun_adj.csv',count=3,itoks=itoks,cnts=cnts,polarity="negative",polarityDict=mcapi.__MC_PROD_HR__[0].getResource("polar_adjs_dict"))  
        mccnew = mcClusters(w2vm) #create mcClusters object.
        mccnew.load(dbase + 'ctable_noun_adj.csv')    
        mccnew.plot(pname=dname)
