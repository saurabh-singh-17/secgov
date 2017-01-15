# -*- coding: utf-8 -*-
"""
Created on Wed Apr  2 15:35:08 2014

@author: vh
"""

#from ngdict import ngDictionaries #, checkMembership #, ngToken, isngToken 
from  ngdict import isngToken, parseAsNgrams #,ngToken ngtok
from utils_features import haskey, discVar2Feature
from config import *  
from Resources import RESKEY_DOMAINMEMDICTS

def NGramizeFromDomainDict(procTxt, hr, featureVals = {}, FKEY = 'NGramizeFromDomainDict'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals
    #S = [t[0] for t in procTxt]
    #ngd = ngDictionaries('dbg/dicts/telcomDicts/')
    retval = parseAsNgrams(hr.resources[RESKEY_DOMAINMEMDICTS], procTxt) 
   
    featureVals[FKEY] = retval            
    return featureVals

def countNGInDomainDict(procTxt, hr, featureVals = {}, FKEY = 'countNGInDomainDict'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals
    
    featureVals = NGramizeFromDomainDict(procTxt, hr, featureVals)
    ngtoks = featureVals['NGramizeFromDomainDict']

    retval = {KEY_POLARITY_POSITIVE: [], KEY_POLARITY_NEGATIVE: [], KEY_POLARITY_NEUTRAL: []}    
    for tok in ngtoks:
        if isngToken(tok) and not tok.isNull():
            ng = tok.n
            pol = tok.polarity
            
#            if ncount.has_key(pol) == False:
#                ncount[pol] = list()
            retval[pol].append(ng)

    featureVals[FKEY] = retval            
    return featureVals
                           
    
#def countNGInDomainDictFeatureTest(procTxt, hr, featureVals = {}, featureSets = {}): 
#    """
#    Domain Dict feature
#    """   
#
#    featureVals = countNGInDomainDict(procTxt, hr, featureVals)
#    ncount = featureVals['countNGInDomainDict']
#
#    for k in ncount.keys():
#        tdict = discVar2Feature(len(ncount[k]), k + ' NG In TELCOM Dict', lims = [1,3], collapse = [False, True]) #negative smiley
#        featureSets.update(tdict.items())
#    
#    return (featureVals, featureSets)


if __name__ == "__main__":
    S = "adds more savings to the blah blady".split()
    tokTag = [('my', 'O'), ('phone', 'N'), ('is', 'V'), ('not', 'A'), ('good', 'A'), (':)', 'E')]
    procTxt = {'tokens': [tt[0] for tt in tokTag], 'tags':[tt[1] for tt in tokTag]}
    #hr = HostedResources()
    import cPickle as pickle
    #hr = pickle.load(open('./resourcesSentiment.res'))
    hr = pickle.load(open(DEFAULT_HR_FILE, 'rb'))
    
    ngd = hr.resources[RESKEY_DOMAINMEMDICTS]
    #fv = NGramizeFromDomainDict(procTxt, hr, featureVals = {})
    #print fv 
    import time
    tt= time.time()
    fv = countNGInDomainDict(procTxt, hr)
    print time.time() - tt 
    print fv
