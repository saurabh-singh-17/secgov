# -*- coding: utf-8 -*-
"""
Created on Tue Jun  9 05:51:14 2015

@author: vh
"""
import numpy as np
from mcsa_w2v import mcW2V
from operator import itemgetter
from mcsa_clusters import mcClusters
    
class mcCategories(object):
    def __init__(self, w2vobj, mccobj, verbose=True):
        '''
        mcCategorization
        w2vmodelfname
        '''
        if verbose:
            print w2vmodelfname
            print ctablefname
            
        self.w2v = w2vobj #gensim.models.Word2Vec.load(w2vmodelfname)
        self.clusters = mccobj
        
        #self.ctable=readCtable(ctablefname)
        #self.G = ctable2G(self.ctable)
        
        ancestory = self.clusters.getHierarchy()
        
        seeds = ancestory.keys() 
               
        if verbose: print (len(seeds)), 'seeds'
        bad_seeds = [seed for seed in seeds if not seed in self.w2v.model.vocab]
        for seed in bad_seeds:
            seeds.remove(seed)
        if verbose and bad_seeds:
                print 'removed bad seeds:%s' % (bad_seeds)
        self.seeds = seeds        
        self.seeds_U = {seed:self.w2v.getUVectors(seed) for seed in seeds}
        self.seed_ancestory = {seed:ancestory[seed] for seed in seeds}
        
        self._SCS_VALID_TAGS = set(['A','R','V','N','^','S','M','L','Z'])
        
#    def getCategory(self, tok_list, th = 0.6):
#        """
#        """
#        if not tok_list: 
#            return ()
#        
#        tok_membership = []
#        for tok in tok_list:
#            if not tok[-1] in self._SCS_VALID_TAGS: #ignore non-NAVRs ~ P, puncs, garbage url, emoticons etc...
#                continue
#            if not tok in self.w2v.model.vocab:
#                continue
#            
#            if tok in self.seeds_U:
#                tok_uv = self.seeds_U[tok]
#            else:
#                tok_uv = mu.unitvec(self.model[tok])
#                
#            seed_dists = [np.dot(tok_uv, self.seeds_U[seed]) for seed in self.seeds]
#            
#            idx = np.argmax(seed_dists)
#            tok_membership.append((self.seeds[idx], seed_dists[idx]))
#
#        if tok_membership:
#           best_seed, membership = max(tok_membership, key=itemgetter(1))
#           return {'BEST_SEED': best_seed, 'MEM': membership, 'HIERARCHY': self.seed_ancestory[best_seed]}
#        else:
#           return {'BEST_SEED': '', 'MEM': None, 'HIERARCHY': {}} 

    def getCategories(self, tok_list, ncats = 5):
        """
        """
        if not tok_list: 
            return ()
        
        tok_membership = []
        for tok in tok_list:
            if not tok[-1] in self._SCS_VALID_TAGS: #ignore non-NAVRs ~ P, puncs, garbage url, emoticons etc...
                continue
            if not tok in self.w2v.model.vocab:
                continue
            
            if tok in self.seeds_U:
                tok_uv = self.seeds_U[tok]
            else:
                tok_uv = self.w2v.getUVectors(tok) #mu.unitvec(self.w2v.model[tok])
                
            seed_dists = [np.dot(tok_uv, self.seeds_U[seed]) for seed in self.seeds]
            
            sidxs = np.argsort(seed_dists)[::-1][:ncats] # sorted indices.
            tm = [(self.seeds[idx], seed_dists[idx], self.seed_ancestory[self.seeds[idx]]) 
                    for idx in sidxs]  #if seed_dists[idx] > th]
            tok_membership.append(tm)

        return tok_membership
        
if __name__ == "__main__":
    #Path for Output File
    import time, os
    
    dataset_name = 'volte'        
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q3B_SAT_DATA_WHY']
    col = 'SRV_Q2B_SAT_VOICE_WHY' #'SRV_Q1B_WTR_WHY' #['SRV_Q1D_SAT_VALUE_ATT_WHY']

#    dataset_name = 'UVERSE' 
#    docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    col = 'W4_NOT_WTR_ATT_WHY' #'U1A_SAT_TV_WHY' #'W4_NOT_WTR_ATT_WHY' #, 'U1A_SAT_TV_WHY', 'U2A_SAT_INTERNET_WHY']
#    
    tmp_home = "/home/vh/surveyAnalysis/tmp"          
    dhome = os.path.join(tmp_home, dataset_name)
        
    bname = os.path.join(dhome, col, col)
    w2v_fname = bname + '.w2vm'
    ctable_fname = bname + '.ctable_temp.csv'

    w2vm = mcW2V(w2v_fname)
    mcc = mcClusters(w2vm)
    mcc.load(ctable_fname)
    mcc.plot()
    catmodel = mcCategories(w2vm, mcc, False) 
    print catmodel.getCategories(['spotty/A'])       
    