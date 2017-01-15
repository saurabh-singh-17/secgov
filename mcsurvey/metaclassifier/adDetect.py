# -*- coding: utf-8 -*-
"""
Created on Fri Dec 26 17:06:20 2014

@author: vh
"""
import re
from appDefs import PTKEY_TOKENS, PTKEY_TAGS
from collections import defaultdict, Counter

_MobDesc_Rx = "(HTC|apple|iphone(s?)|landline|(metro(.*)pcs)|android|(ipad.*(mini|air|with))|samsung|cellular|Nokia|Lumia|blackberry|(galaxy.*phone)|motorola|lg|phone(s?)|(.*G(B?)))"
_MobAcc_Rx = "(signal|booster|external|antenna|adapter|case|(skin|for|with|cover)|battery|data|cable|sim|card)"
_Sales_Rx = "(sale|chance|win|ebay|save|sell(.*?)|\\$|cool|daily|unmissable|best|deal|alert|unlimited|plan|good|excellent|condition(s?))"
_Jobs_Rx = "(job(s?))|hire|hiring|career(s?)"
_VideoProm_Rx = "(watch|episode|liked|youtube)"
_PriceNum_Rx = "(\\$|(USD)|([0-9]))"

_Rx = {'mobdsc': _MobDesc_Rx,
       'mobacc': _MobAcc_Rx,
       'mobsal': _Sales_Rx,
       'mobjob': _Jobs_Rx,
       'mobvid': _VideoProm_Rx,
       'mobprc': _PriceNum_Rx
       }
       
_compiledRx = {k: re.compile(v,re.I) for k,v in _Rx.iteritems()}

_POSx = {'nNNP': ('^', 0.15),
         'nPUN': (',', 0.1),
         'nGBG': ('G', 0.2),
         'nURL': ('U', 0.01)
        }
 
def detectAd(proctxt):
    """ """
    if not proctxt:
        return 0   
    toks = proctxt['tokens']
    re_search = re.search
    
    featTokCount = defaultdict(int)
    for tok in toks:
        for patkey, srpat in _compiledRx.iteritems(): 
            if re_search(srpat, tok):
                featTokCount[patkey] += 1
                break
    
    tokCount = Counter(proctxt['tags'])
    ntoks = float(toks.__len__())        
    tokFeatMem = [1 for feat in _Rx if featTokCount[feat] > 1]
    tagFeatMem = [1 for feat, tt in _POSx.iteritems() if tokCount[tt[0]]/ntoks >= tt[1]]
    
    if sum(tokFeatMem + tagFeatMem) > 3:
        return 1
    return 0

def adDetection(procTxt, hr = None, featureVals = {}, FKEY = 'adDetection'):
    """
    wrapper
    """    
    if FKEY in featureVals: return featureVals
    featureVals[FKEY] = detectAd(procTxt)
    return featureVals 
    
import numpy as np    
def ad(proctxt, ntries):
    times = []
    for n in xrange(ntries):
        st = time.time()
        detectAd(proctxt)
        times.append(time.time()-st)
        
    if proctxt:    
        return (np.mean(times), len(' '.join(proctxt['tokens'])))
    return (0,0)

if __name__ == "__main__":
    import cPickle as pickle
    import time
    import utils_gen as ug
    from cm import ClassifierMetrics

    cm = ClassifierMetrics([0,1])
    
    normtxts = pickle.load(open('/home/vh/mc5/MC/data/AtTweets140225_DD_4000.normtxts'))
    #normtxts = pickle.load(open('/home/vh/bmtests/data/stxts/merged.normtxts'))
    olbls = ug.readlines('/home/vh/mc5/MC/data/AtTweets140225_DD_4000.adlbls')
    olbls = [int(olbl) for olbl in olbls]

    plbls = [detectAd(normtxt) for normtxt in normtxts]
    cm.computeMetrics(olbls, plbls)
    cm.printMetrics()
    err = sum(cm._fp)    

        
