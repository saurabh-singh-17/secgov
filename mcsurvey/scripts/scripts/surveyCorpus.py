# -*- coding: utf-8 -*-
"""
Created on Tue Apr 14 19:50:25 2015

@author: vh
"""
import os
import pandas as pd
from collections import defaultdict
#import metaclassifier.mcServicesAPI as mcapi
import json
import cPickle as pickle

class mcCorpus(object):
    def __init__(self, fname, **kwargs):
        self.fname = fname
        self.kwargs = kwargs
        
        rkw = {k:v for k, v in kwargs.iteritems() if not k in ('iterator', 'chunksize')}
        
        a = pd.read_csv(self.fname, iterator=True, chunksize=1, **rkw).get_chunk()
        self.colNames = list(a.columns.values)
                 
        self.indexCols = None
               
    def colNames2Idx(self, rcnames):
        if isinstance(rcnames, str):
            rcnames = [rcnames]
            
        cnames = self.colNames    
        idxs = {rc:cnames.index(rc) for rc in rcnames if rc in cnames}  
        
        if len(idxs) != len(rcnames):
            pkeys = [rc for rc in rcnames if not rc in idxs]
            raise LookupError('Index Cols not found or duplicate Cols: %s' % pkeys)
            
        return [(rc, idxs[rc]) for rc in rcnames] 
            
    def docid_isunique(self, rcnames):
        if isinstance(rcnames, str):
            rcnames = [rcnames]
        
        df = pd.read_csv(self.fname, usecols = rcnames, **self.kwargs)
        df.set_index(keys=rcnames, inplace=True, verify_integrity=True)

    def extractTxtCols(self, txt_cols, docid_cols, dpath = None):
        cols = docid_cols + txt_cols 
        df = pd.read_csv(self.fname, usecols = cols, **self.kwargs)
        if docid_cols:
            df.set_index(keys=docid_cols, inplace=True, verify_integrity=True)

        if dpath:
            for col in txt_cols:        
                tdpath = os.path.join(dpath, col)                
                if not os.path.exists(tdpath):
                    os.makedirs(tdpath)
                
                ofname = os.path.join(tdpath, col + '.verbatims')    
                df.to_csv(ofname, cols=[col], sep = '|')
            return
        else:    
            return df

#    def _callMC(line, docid_idxs, txtcol_idx, serializer):   
#        docid = [line[idx] for idx in docid_idxs]
#        txt = line[txtcol_idx]
#        
#        rv = [serializer(docid), serializer([{}])]        
#        if txt: 
#            res = mcapi.mcSentences(txt)
#            rv[-1] = serializer(res)
#                
#        return rv

print "i am before main"  
  
if __name__ == "__main__":
    import time
    import os
    
#    dataset_name = 'volte'
#    dataset_fname = '/home/vh/surveyAnalysis/data/volte_20150209.txt' 
#    docid_cols = ['SRV_ACCS_ID']
#    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q2B_SAT_VOICE_WHY', 'SRV_Q3B_SAT_DATA_WHY']

    dataset_name = 'UVERSE'
    dataset_fname = '/home/vh/surveyAnalysis/data/CEE2014-Revised-3-27-15.csv' 
    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['W4_NOT_WTR_ATT_WHY', 'U1A_SAT_TV_WHY', 'U2A_SAT_INTERNET_WHY']
 
    dataset_name = 'CONSUMER_REPORTS'
    dataset_fname = '/home/vh/surveyAnalysis/data/cr_verbatims_clean.txt' 
    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q1_WTR_WIRELESS_WHY', 'SRV_Q4B_YEAR_AGO_WHY']   

    dataset_name = 'EMP_SURVEY'
    dataset_fname = '/home/vh/surveyAnalysis/data/empsurv.csv' 
    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['Q1:Comments-How would you describe the current ATO work culture? ']   
    
    dataset_name = 'CCEVAL'
    dataset_fname = '/home/vh/surveyAnalysis/tmp/evalsentences.txt' 
    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['TXT']   

    dataset_name = 'CHATS'
    dataset_fname = '/home/vh/surveyAnalysis/data/Chats.csv' 
    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['Verbatim', 'Text']      
    
    dataset_name = 'DIL'
    dataset_fname="/home/user/Desktop/mcSurveyAnalysis/tmp/dil_verbatims.txt"
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM', 'SRV_Q21B_RESOLVE_VERBATIM'] 
    dnames = ['DIL-ISSUE', 'DIL-RESOLVE']


    data_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"          
    
    
    data_home = os.path.join(data_home, dataset_name)
    corpus = mcCorpus(dataset_fname, delimiter='|', dtype=str)
    st = time.time()    
    corpus.extractTxtCols(txt_cols, docid_cols, data_home)
    print time.time() - st
    
print "i am after main"  
#volte.colNames2Idx('SRV_ACCS_ID')
#print getColNames(dataset_fname)

#import csv
#from collections import defaultdict
#class mcCorpus(object):
#    def __init__(self, fname, *args, **kwargs):
#        self.fname = fname
#        self.args = args
#        self.kwargs = kwargs
#        
#        with open(self.fname, 'rb') as f:
#             self.colNames = csv.reader(f, *self.args, **self.kwargs).next()           
#        self.indexCols = None
#               
#    def colNames2Idx(self, rcnames):
#        if isinstance(rcnames, str):
#            rcnames = [rcnames]
#            
#        cnames = self.colNames    
#        idxs = {rc:cnames.index(rc) for rc in rcnames if rc in cnames}  
#        
#        if len(idxs) != len(rcnames):
#            pkeys = [rc for rc in rcnames if not rc in idxs]
#            raise LookupError('Index Cols not found or duplicate Cols: %s' % pkeys)
#            
#        return [(rc, idxs[rc]) for rc in rcnames] 
#            
#    def docid_isunique(self, rcnames):
#        if isinstance(rcnames, str):
#            rcnames = [rcnames]
#        
#        idxs = self.colNames2Idx(rcnames)        
#
#        docid = defaultdict(int)
#        with open(self.fname, 'rb') as f:
#            reader = csv.reader(f, *self.args, **self.kwargs)
#            for line in reader:
#
#                tid = '+'.join([line[idx[1]] for idx in idxs])
#                docid[tid] += 1
#                
##                if tid in docid:
##                    return False
##                docid.add(tid)
#        return [idx for idx in docid if docid[idx] > 1]        
#        return True
#         
#dataset_name = 'volte'
#dataset_fname = '/home/vh/volte/data/raw/volte_20150209.txt'
#docid_colnames = ['SRV_ID','SRV_SRV_ACCS_ID']
#
#import time
#volte = mcCorpus(dataset_fname, delimiter='|')
#st = time.time()
#volte.docid_isunique(['SRV_ACCS_ID', 'YYYYMM'])
#print time.time() - st
##volte.colNames2Idx('SRV_ACCS_ID')
##print getColNames(dataset_fname)