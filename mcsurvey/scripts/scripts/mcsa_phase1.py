# -*- coding: utf-8 -*-
"""
Created on Sun Apr 26 18:30:26 2015

@author: vh
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

import csv, json, time
from itertools import islice
from joblib import Parallel, delayed
import metaclassifier.mcServicesAPI as mcapi

csv.field_size_limit(sys.maxsize)

def callMC(line, docid_idxs, txtcol_idx, serializer = json.dumps):   
    docid = [line[idx] for idx in docid_idxs]
    txt = line[txtcol_idx]
    
    rv = [serializer(docid), serializer([{}])]        
    if txt: 
        res = mcapi.mcSentences(txt) #, ['sentiment', 'entitySentiment'])
        rv[-1] = serializer(res)
            
    return rv

def _mc_CSVPBSW(func, ifname, docid_cols, txtcol, rfname, serializer = json.dumps):
    '''
    CSV parallel batch processing and serialized writer 
    ''' 
    with open(rfname, 'wb') as ofile: 
        writer = csv.writer(ofile, delimiter='|')
        with open(ifname) as dfile:
            ipreader = csv.reader(dfile, delimiter='|')
            
            #header parse and find indices.
            header = ipreader.next()
            docid_idxs = [header.index(dc) for dc in docid_cols]
            txtcol_idx = header.index(txtcol) 
            #print docid_idxs, txtcol_idx
            
            part = 0
            while True:
                n_lines = list(islice(ipreader, 1000))
                if not n_lines:
                    break
                       
                resps = [callMC(line, docid_idxs, txtcol_idx) for line in n_lines] #if "439293759" in line[docid_idxs[0]]         
                st = time.time()
                #resps = Parallel(n_jobs=3)(delayed(func)(line, docid_idxs, txtcol_idx, serializer) for line in n_lines)
                writer.writerows(resps)               
                print '%3d %4d %4.3f' % (part, len(n_lines), time.time() - st)
                part += 1  
                
def makeMCRes(ifname, docid_cols, txtcol, rfname, serializer = json.dumps):
    _mc_CSVPBSW(callMC, ifname, docid_cols, txtcol, rfname, serializer = json.dumps)
                                                 
if __name__ == "__main__":
    import time, os
    import csv

    dataset_name = 'volte'        
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q2B_SAT_VOICE_WHY', 'SRV_Q3B_SAT_DATA_WHY']
    txt_cols = ['SRV_Q3B_SAT_DATA_WHY'] #['SRV_Q2B_SAT_VOICE_WHY'] #['SRV_Q1B_WTR_WHY'] #['SRV_Q1D_SAT_VALUE_ATT_WHY']   
    
    
    dataset_name = 'DIL'
    #dataset_fname="/home/user/Desktop/mcSurveyAnalysis/tmp/dil_verbatims.txt"
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM', 'SRV_Q21B_RESOLVE_VERBATIM'] 
    #dnames = ['DIL-ISSUE', 'DIL-RESOLVE']


#    dataset_name = 'UVERSE' 
#    docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    txt_cols = ['U2A_SAT_INTERNET_WHY'] #'W4_NOT_WTR_ATT_WHY', 
#
#    dataset_name = 'CONSUMER_REPORTS'
#    docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    txt_cols = ['SRV_Q4B_YEAR_AGO_WHY']  #'SRV_Q1_WTR_WIRELESS_WHY',
#  
#    dataset_name = 'EMP_SURVEY'
#    dataset_fname = '/home/vh/surveyAnalysis/data/empsurv.csv' 
#    docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    txt_cols = ['Q1:Comments-How would you describe the current ATO work culture? ']   
  
#    dataset_name = 'CHATS'
#    docid_cols = [] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    txt_cols = ['Text']  #['Verbatim'] 
    
    tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"          
    dhome = os.path.join(tmp_home, dataset_name)

    for col in txt_cols:
        dbase = os.path.join(dhome, col, col)
        ifname = dbase + '.verbatims'
        rfname = dbase + '.mcres.csv'
#        wfname = dbase + '.w2vm'
#        baseModel = os.path.join(dhome, col, 'SRV_Q1B_WTR_WHY.w2vm')
#        resfile = os.path.join("/home/user/Desktop/mcSurveyAnalysis/results/", '__'.join([dataset_name, col]) + '.csv')
#        opf = open(resfile, 'wb')
#        logger = opf.write

        print 'Extracting Surface Properties & Polarities'
        makeMCRes(ifname, docid_cols, col, rfname, serializer = json.dumps)