# -*- coding: utf-8 -*-
"""
Created on Wed May 27 04:39:59 2015

@author: vh
"""
import gensim
import gensim.matutils as mu

import networkx as nx
import numpy as np

import csv
from collections import defaultdict
from operator import itemgetter

def readCtable(cfname):
    ctable = []
    with open(cfname) as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            row['MEMBERS'] = row['MEMBERS'].split('|')
            ctable.append(row)
    return ctable
                    
def ctable2G(ctable):
    G = nx.DiGraph()
    for row in ctable:
        lid = int(row['LEVEL'])
        cid = int(row['CLUSTER'])
        rtoks = ['%d_%s' % (lid, tok) for tok in row['MEMBERS']]
        pkey = '%d_%s' % (lid+1, row['CENTER'])
        for rtok in rtoks:
            G.add_edge(pkey, rtok)
            G.node[pkey]['CLUSTER'] = cid
            G.node[pkey]['LEVEL'] = lid+1
            G.node[pkey]['NAME'] = row['NAME']
            G.node[pkey]['CENTER'] = row['CENTER']
    return G

def parentClusters(G, tok):
    parents = []
    rtok = tok #'0_%s' % tok
    while(True):
        pars = G.predecessors(rtok)
        #print rtok, pars
        if not pars:
            break
        else:
            rtok = pars[0]
            parents.append(rtok)
    return parents
    
def getLeafNodes(G, returnToks = True):
    if returnToks:
        return ['_'.join(node.split('_')[1:]) for node in G.succ if not G.succ[node]]
    return [{'NODE':node, 'TOKEN':'_'.join(node.split('_')[1:])}  for node in G.succ if not G.succ[node]]

def getHierarchy(G):
    leafNodes = getLeafNodes(G, returnToks=False)
    ancestory = {}
    for leaf in leafNodes:
        pars = parentClusters(G, leaf['NODE'])
        anc = [{'LEVEL': int(par.split('_')[0]), 'NAME': G.node[par]['NAME']} for par in pars]
        ancestory[leaf['TOKEN']] = anc
    return ancestory

def getClusterMembers(G):
    topnodes = [node for node in G.pred if not G.pred[node]]
    #print topnodes
    clusterMembers = defaultdict(list)
    for tnode in topnodes:
        dfs = nx.dfs_successors(G, tnode)
        for node in dfs:
            for mem in dfs[node]:
                if int(mem.split('_')[0]) == 0:
                    clusterMembers[tnode].append(mem)
    return clusterMembers
        
      
from sklearn.decomposition import PCA 
from sklearn.decomposition import TruncatedSVD as PCA    
class mcSpatialRep(object):
    def __init__(self, w2vmodelfname, ctablefname, n_components=2, verbose=True):
        
        if verbose:
            print w2vmodelfname
            print ctablefname
            
        self.model = gensim.models.Word2Vec.load(w2vmodelfname)
        self.n_components = n_components
        
        self.pca_global = PCA(n_components=n_components)
        self.Xls_global = self.pca_global.fit_transform(self.model.syn0)
        print 'done global'
        
        self.ctable=readCtable(ctablefname)
        self.G = ctable2G(self.ctable)
        self.clusters = getClusterMembers(self.G)
        
        pca_local = {}
        for cluster, members in self.clusters.iteritems():
            X = np.array([self.model['_'.join(mem.split('_')[1:])] for mem in members])
            #print X.shape
            pca = PCA(n_components=n_components)
            pca.fit(X)
            #cname = G.node[cluster]['NAME']
            pca_local[cluster] = pca
        self.pca_local = pca_local
        print 'done local'
        
    def getLS_Global(self, tok):
        return [float(x) for x in np.nditer(self.Xls_global[self.model.vocab[tok].index, :])]
    
    def getLS_Local(self, tok):
        rv = {}
        if not tok in self.model.vocab:
            return rv
            
        for cluster, pca in self.pca_local.iteritems():
            rv[cluster] = [float(x) for x in np.nditer(pca.transform(self.model[tok]))]
        
        return rv
                          
class mcCategories(object):
    def __init__(self, w2vmodelfname, ctablefname, verbose=True):
        
        if verbose:
            print w2vmodelfname
            print ctablefname
            
        self.model = gensim.models.Word2Vec.load(w2vmodelfname)
        
        
        self.ctable=readCtable(ctablefname)
        self.G = ctable2G(self.ctable)
        ancestory = getHierarchy(self.G)
        
        seeds = ancestory.keys() 
               
        if verbose: print (len(seeds)), 'seeds'
        bad_seeds = [seed for seed in seeds if not seed in self.model.vocab]
        for seed in bad_seeds:
            seeds.remove(seed)
        if verbose and bad_seeds:
                print 'removed bad seeds:%s' % (bad_seeds)
        self.seeds = seeds        
        self.seeds_U = {seed:mu.unitvec(self.model[seed]) for seed in seeds}
        self.seed_ancestory = {seed:ancestory[seed] for seed in seeds}
        
        self._SCS_VALID_TAGS = set(['A','R','V','N','^','S','M','L','Z'])
        
    def getCategory(self, tok_list, th = 0.6):
        """
        """
        if not tok_list: 
            return ()
        
        tok_membership = []
        for tok in tok_list:
            if not tok[-1] in self._SCS_VALID_TAGS: #ignore non-NAVRs ~ P, puncs, garbage url, emoticons etc...
                continue
            if not tok in self.model.vocab:
                continue
            
            if tok in self.seeds_U:
                tok_uv = self.seeds_U[tok]
            else:
                tok_uv = mu.unitvec(self.model[tok])
                
            seed_dists = [np.dot(tok_uv, self.seeds_U[seed]) for seed in self.seeds]
            
            idx = np.argmax(seed_dists)
            tok_membership.append((self.seeds[idx], seed_dists[idx]))

        if tok_membership:
           best_seed, membership = max(tok_membership, key=itemgetter(1))
           return {'BEST_SEED': best_seed, 'MEM': membership, 'HIERARCHY': self.seed_ancestory[best_seed]}
        else:
           return {'BEST_SEED': '', 'MEM': None, 'HIERARCHY': {}} 

    def getCategories(self, tok_list, ncats = 5):
        """
        """
        if not tok_list: 
            return ()
        
        tok_membership = []
        for tok in tok_list:
            if not tok[-1] in self._SCS_VALID_TAGS: #ignore non-NAVRs ~ P, puncs, garbage url, emoticons etc...
                continue
            if not tok in self.model.vocab:
                continue
            
            if tok in self.seeds_U:
                tok_uv = self.seeds_U[tok]
            else:
                tok_uv = mu.unitvec(self.model[tok])
                
            seed_dists = [np.dot(tok_uv, self.seeds_U[seed]) for seed in self.seeds]
            
            sidxs = np.argsort(seed_dists)[::-1][:ncats] # sorted indices.
            tm = [(self.seeds[idx], seed_dists[idx], self.seed_ancestory[self.seeds[idx]]) 
                    for idx in sidxs]  #if seed_dists[idx] > th]
            tok_membership.append(tm)

        return tok_membership
              
if __name__ == "__main__":
    #Path for Output File
    import time, os
    from joblib import Parallel, delayed 

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
    modname = bname + '.w2vm'
    cfname = bname + '.ctable_temp.csv'
       
    catmodel = mcCategories(modname, cfname, False)
    fnames = os.path.join(dhome, col, col + '.mcres.csv')
    print catmodel.getCategories(['spotty/A'], ncats = 5)
    
    #print catmodel.getCategories([], th = 0.6)
    #foo = w2vEntities(fnames, catmodel)
    #catmodel = mcSpatialRep(modname, cfname, 2, False)
    #print catmodel.getLS_Local('reps/N')