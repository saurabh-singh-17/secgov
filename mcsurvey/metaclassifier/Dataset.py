# -*- coding: utf-8 -*-
"""
Created on Mon Mar 24 20:55:34 2014

@author: vh
"""
from random import sample, seed
from collections import defaultdict

class Dataset(object):    
    def __init__(self, lbls, seedVal = -1):
        self.idxsByLbl = dict()
        self.N = dict()
        for k, lbl in enumerate(lbls):
            if self.idxsByLbl.has_key(lbl) == True:
                self.idxsByLbl[lbl].append(k)
            else:
                self.idxsByLbl[lbl] = [k]
        
        for k in self.idxsByLbl.keys():
            self.N[k] = len(self.idxsByLbl[k])
        
        self.seedVal = seedVal
        if seedVal != -1:            
            seed(seedVal)  
                      
    def getNlbls(self, lbl = 'all'):
        if lbl in ['', 'all']:
            return self.N
        if lbl in self.idxsByLbl.keys():
            return self.N[lbl]

    def getLabels(self):
        return self.idxsByLbl.keys()    
    def makeSetByLbl(self, lbl, count = 0, randflag = True):                                            
        assert lbl in self.idxsByLbl.keys()
        assert (count >= 0) and (count <= self.N[lbl])
        
        relidxs = self.idxsByLbl[lbl]
        if (count == 0) or (count == self.N[lbl]): return relidxs 
        if randflag == False: 
            return relidxs[0:count] 
        else:
            samples = sample(xrange(0, self.N[lbl]), count)
            return [relidxs[s] for s in samples]
            
            
if __name__ == "__main__":
    import utils_gen as ug 
    lbls = ug.readlines('dbg/data/data_semeval_5399_train.lbls') 
    ds = Dataset(lbls, seedVal = 2)
    for k in ds.idxsByLbl.keys():
        print len(ds.idxsByLbl[k])
    
    print ds.getNlbls('all')
    print ds.getNlbls('positive') 

    idx = ds.makeSetByLbl('negative', 12, randflag=True)
    print len(idx), idx
    idx = ds.makeSetByLbl('negative', 12, randflag=True)
    print len(idx), idx                     