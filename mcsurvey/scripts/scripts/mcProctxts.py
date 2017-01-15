# -*- coding: utf-8 -*-
"""
Created on Mon Jun 15 09:02:25 2015

@author: vh
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
import csv, sys
import cPickle as pickle
import metaclassifier.mcServicesAPI as mcapi
import time
from itertools import islice
from joblib import Parallel, delayed
from metaclassifier.processText import sentenceSplitProcTxts 

csv.field_size_limit(sys.maxsize)

def callMCNLPipeline_(line, docid_idxs, txtcol_idx):
    '''
    Wrapper function
    '''
    serializer = pickle.dumps
    docid = [line[idx] for idx in docid_idxs]
    txt = line[txtcol_idx]
    
    rv = [serializer(docid), serializer({})]        
    if txt: 
        proctxt = mcapi._mcNLPipeline(txt)
        sproctxts = sentenceSplitProcTxts(proctxt)
        rv[-1] = serializer(sproctxts)
    return rv
                
class mcProctxts(object):
    def __init__(self, delim='|'):
        self.txtfile = None
        self.proctxt_fname = None
        self.delim = delim
    
    def make(self, txtfile, docid_cols, txtcol, saveas, Maxlines = None, Npar=1, BatchSize=100):
        '''
        make and save proctxts.
        txtfile: path to csv file containing docid cols and txt col.
        docid_cols: list containing docid col(s) names
        txtcol: txtcol name
        saveas: path to file in which proctxts are to be saved.
        Maxlines: maximum number of lines to read fron txtfile.
        Npar: number of parallel threads. for jni interface use 1
        BatchSize: number for lines per read.
        '''
        n_lines = 0
        self.txtfile = txtfile
        self.proctxt_fname = [saveas]
        
        func = callMCNLPipeline_
        
        with open(saveas, 'wb') as ofile: 
            writer = csv.writer(ofile, delimiter='|')
            with open(txtfile) as dfile:
                ipreader = csv.reader(dfile, delimiter='|')
                
                #header parse and find indices.
                header = ipreader.next()
                    
                docid_idxs = [header.index(dc) for dc in docid_cols]
                txtcol_idx = header.index(txtcol) 
                
                part = 0
                while True:
                    lines = list(islice(ipreader, BatchSize))
                    if not lines:
                        break
                     
                    st = time.time() 
                    if Npar == 1:
                        resps = [func(line, docid_idxs, txtcol_idx) for line in lines] 
                    else:
                        resps = Parallel(n_jobs=3)(delayed(func)(line, docid_idxs, txtcol_idx) for line in lines)
                    writer.writerows(resps)
                    
                    rlines = len(lines)
                    print '%3d %4d %4.3f' % (part, rlines, time.time() - st)
                    part += 1 
                    n_lines += rlines
                    
                    if Maxlines and n_lines >= Maxlines:
                        break
                    
    def load(self, pfile):
        self.proctxt_fname = [pfile]
    
    def __iter__(self):
        for fname in self.proctxt_fname:
            with open(fname) as f:
                reader = csv.reader(f, delimiter=self.delim)
                for line in reader:
                    yield pickle.loads(line[1])

                            
if __name__ == "__main__":
    a = mcapi.mcInit()
    txtfile = '/home/vh/surveyAnalysis/tmp/volte/SRV_Q1B_WTR_WHY/SRV_Q1B_WTR_WHY.verbatims'
    saveas = '/home/vh/surveyAnalysis/test.proctxt'
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = 'SRV_Q1B_WTR_WHY'
                
    proctxts = mcProctxts()
    #proctxts.make(txtfile, docid_cols, txt_cols, saveas, Maxlines = 2000, Npar=3)
    proctxts.load(saveas)
    for proctxt in proctxts:
        print proctxt                                