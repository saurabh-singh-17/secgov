# -*- coding: utf-8 -*-
"""
Created on Mon Jun  8 10:06:28 2015

@author: vh
"""
import gensim
import gensim.matutils as mu
import time
import csv, json
import numpy as np
class mcresSentences(object):
    def __init__(self, fnames):
        self.fnames = fnames
        
    def __iter__(self):
        for fname in self.fnames:
            with open(fname) as f:
                reader = csv.reader(f, delimiter='|')
                for line in reader:
                    sres = json.loads(line[1])
                    for res in sres:
                        if res:
                            yield res["tokstags"]["result"].split()
                            
class mcW2V(object):
    def __init__(self, model_fname = None):
        
        self.model = None
        if model_fname:
            self.model = gensim.models.Word2Vec.load(model_fname)

    def save(self, saveas):
        '''
        Save model to file
        '''
        self.model.save(saveas)

    def build(self, mcres_fnames, baseModel = None, saveas = None, verbose=True):
        '''
        Build from mcres
        mcres_fnames mcres filenames.
        '''
        if type(mcres_fnames) == str:
            mcres_fnames = [mcres_fnames]
        if verbose:                            
            st = time.time()
            print 'Building W2V Model from %s' % mcres_fnames
        foo = mcresSentences(mcres_fnames)
        if baseModel:
            bmodel = gensim.models.Word2Vec.load(baseModel)            
            bmodel.build_vocab(foo)
            foo = mcresSentences(mcres_fnames)    
            bmodel.train(foo)
        else:
            bmodel = gensim.models.Word2Vec(foo, min_count=1, workers=4)
        
        self.model = bmodel
        if verbose:
            print time.time() - st
        bmodel.save(saveas)
      
    def getVectors(self, toks):
        '''
        Token Vectors
        '''
        v = [self.model[tok] for tok in toks]
        return v

    def getUVectors(self, toks):
        '''
        Token Unit Vectors
        '''
        if isinstance(toks, basestring):
            uv = mu.unitvec(self.model[toks])
        else:
            uv = [mu.unitvec(self.model[tok]) for tok in toks]
        return uv    
        
    def getSimMat(self, toks):
        '''
        Similarity Matrix for tokens.
        '''
        n = len(toks)
        U = self.getUVectors(toks)
        S = np.zeros((n,n))
        for k, u1 in enumerate(U):
            for j, u2 in enumerate(U):
                S[k][j] = np.dot(u1,u2)
       
        return S
       
        