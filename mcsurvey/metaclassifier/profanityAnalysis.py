# -*- coding: utf-8 -*-
"""
Created on Sun Jun 29 09:15:42 2014

@author: vh
"""
from utils_features import haskey 
from config import PTKEY_TOKENS, PTKEY_TAGS
from collections import defaultdict
#from processText import ptSentence, ptChunk
#from ptdatatypes import ptSentence, ptChunk
from Resources import *

import re
       
__PROFANITYPATTERN = re.compile(r"(fu[ckxq]+)|(sh[i|y]+[t|d]+)|(suck|sux)|(slu[t|d]+)|(whore)|(bitch)|(cr[a|\*|\@]p)")
__PROFANITYSEARCH = __PROFANITYPATTERN.search
__PROFANITYIGNORETAGS = set(['U', '@'])
#positive_interjection=set(["br","hagn","hand","hth","jk","lhh","lmao","lol","tftf","tftt","ty","tyia","tyvw","yw","gr8","yw","rofl","gg","tgif","bff","ftw","hbd","yummy","goodluck","good-bye","hehehehe","congrats","haha","hehehe","hahahaha","hahahahahahaha","hahahah","hehe","lolz","lolzz"])
#negative_interjection=set(["ayfkmwts","bh","dam","ffs","fml","fubar","gmafb","gtfooh","nfw","nsfw","smdh","smh","sob","stfu","stfw","ffs","fml","stfu","gtfo","dgaf","dtf","fomo","smfh","roflmao","ptfo"])

positive_interjection=set(["br","hagn","hand","hth", "yay", "jk","tftf","tftt","ty","tyia","tyvw","yw","gr8","yw","rofl","gg","tgif","bff","ftw","hbd","yummy","goodluck","good-bye","congrats"])
negative_interjection=set(["ayfkmwts","bh","dam","ffs","fml","fubar","gmafb","gtfooh","nfw","nsfw","smdh","smh","sob","stfu","stfw","ffs","fml","stfu","gtfo","dgaf","dtf","fomo","smfh","ptfo"])
def profanitiesInClauses(procTxt, hr):
    """
    retval = {profanity1:count1, profanity2:count2 ...}
    """
    pdict = defaultdict(list)
    for s, sentence in enumerate(procTxt['chunksInClauses']):
        for c, clause in enumerate(sentence):
            for h, chunk in enumerate(clause):
                for tok, tag in zip(chunk.tokens, chunk.tags):
                    if (tag not in __PROFANITYIGNORETAGS) and (__PROFANITYSEARCH(tok)):
                        key = '%s' % chunk
                        pdict[key].append(chunk)                      
    return pdict
    
def profanitiesInText(procTxt, hr):
    """
    retval = {profanity1:count1, profanity2:count2 ...}
    """
    pdict = defaultdict(int)
    for tok, tag in zip(procTxt[PTKEY_TOKENS], procTxt[PTKEY_TAGS]):
        if (tag not in __PROFANITYIGNORETAGS) and (__PROFANITYSEARCH(tok)):
            pdict[tok]+=1    
    return pdict
        
def txtContainsProfanity(procTxt, hr, featureVals = {}, FKEY = 'txtContainsProfanity'):
    """
    Profanity In Texts Wrapper 
    """ 
    if haskey(featureVals, FKEY): return featureVals
    
    featureVals[FKEY] = False
    if profanitiesInText(procTxt, hr):
        featureVals[FKEY] = True
    return featureVals  
###################################################
 #hr.posWords

def positiveinterjectionInText(procTxt, hr):
    """
    retval = {profanity1:count1, profanity2:count2 ...}
    """
    flag_inter=0
    #posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE)
    for tag, tok in enumerate(procTxt[PTKEY_TOKENS]):
        if ((tok in positive_interjection)):
            if((procTxt[PTKEY_TAGS][tag]=="!")or(procTxt[PTKEY_TAGS][tag]=="G")or(procTxt[PTKEY_TAGS][tag]=="L")):
                flag_inter=1
                return flag_inter
    return flag_inter
def negativeinterjectionInText(procTxt, hr):
    """
    retval = {profanity1:count1, profanity2:count2 ...}
    """
    flag_inter=0
    #negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
    for tag, tok in enumerate(procTxt[PTKEY_TOKENS]):
        if ((tok in negative_interjection)):
            if((procTxt[PTKEY_TAGS][tag]=="!")or(procTxt[PTKEY_TAGS][tag]=="G")or(procTxt[PTKEY_TAGS][tag]=="L")):
                flag_inter=1
                return flag_inter
    return flag_inter

####################################################3
"""
def positiveinterjection(procTxt, hr, featureVals = {}, FKEY = 'positiveinterjection'):
    if haskey(featureVals, FKEY): return featureVals
    
    featureVals[FKEY] = False
    
    if positiveinterjectionInText(procTxt, hr):
        featureVals[FKEY] = True
    return featureVals
def negativeinterjection(procTxt, hr, featureVals = {}, FKEY = 'negativeinterjection'):
    if haskey(featureVals, FKEY): return featureVals
    
    featureVals[FKEY] = False
    
    if negativeinterjectionInText(procTxt, hr):
        featureVals[FKEY] = True
    return featureVals
"""

def positiveinterjection(procTxt, hr, featureVals = {}, FKEY = 'positiveinterjection'):
    
    ###Profanity In Texts Wrapper 
     
    posintmaxpos = 'positive interjective with max of positive words'
    posintmaxneg = 'positive interjective with max of negative words'
    posintmaxneu = 'positive interjective with max of neutral words'
    posintpol='positive interjective with polar words'
    retval = {posintmaxpos: False, posintmaxneg:False, posintmaxneu:False,posintpol:False}
    if haskey(featureVals, FKEY): return featureVals
    
    featureVals[FKEY] = False
    if positiveinterjectionInText(procTxt, hr):
        featureVals[FKEY] = True
        #if featureVals.has_key('totalPolarity') == False:        
        #    featureVals = totalPolarity(procTxt, hr, featureVals)
        #netpol = featureVals['totalPolarity']
        #if(netpol['no neg words']):
        #    retval[posintmaxpos] = True   
        #if(netpol['no pos words']):
        #    retval[posintmaxneg] = True
        #if(netpol['no pol words']):
        #    retval[posintmaxneu] = True
        #if((netpol['no neg words']==False)and(netpol['no pos words']==False)and(netpol['no pol words']==False)):
        #    retval[posintpol] = True
    #featureVals[FKEY] = retval
    return featureVals 

def negativeinterjection(procTxt, hr, featureVals = {}, FKEY = 'negativeinterjection'):
    
    ###Profanity In Texts Wrapper 
     
    negintmaxpos = 'negative interjective with max of positive words'
    negintmaxneg = 'negative interjective with max of negative words'
    negintmaxneu = 'negative interjective with max of neutral words'
    negintpol='negative interjective with polar words'
    #retval = {negintmaxpos: False, negintmaxneg:False, negintmaxneu:False,negintpol:False}
    if haskey(featureVals, FKEY): return featureVals
    
    retval = False
    
    if negativeinterjectionInText(procTxt, hr):
        retval=True
        #if featureVals.has_key('totalPolarity') == False:        
        #    featureVals = totalPolarity(procTxt, hr, featureVals)
        #netpol = featureVals['totalPolarity']
        #if(netpol['no neg words']):
        #    retval[negintmaxpos] = True   
        #if(netpol['no pos words']):
        #    retval[negintmaxneg] = True
        #if(netpol['no pol words']):
        #    retval[negintmaxneu] = True
        #if((netpol['no neg words']==False)and(netpol['no pos words']==False)and(netpol['no pol words']==False)):
        #    retval[negintpol] = True
    featureVals[FKEY] = retval

    return featureVals 



##################################################################
  

if __name__ == "__main__":
    import time
    import operator
    import utils_gen as ug 
    import cPickle as pickle
    from config import DEFAULT_HR_FILE, MC_DATA_HOME, MC_LOGS_HOME
    #from Resources import HostedResources
    
    dsname = 'data_semeval_6399_train' #'AtTweets140225_DD_4000' # #'cleanedupTestData'
    ptfname = MC_DATA_HOME + dsname + '.proctxts'
    lbls  = ug.readlines(MC_DATA_HOME + dsname + '.lbls')
    procTxtLst = pickle.load(open(ptfname, 'rb'))

    hr = pickle.load(open(DEFAULT_HR_FILE))    

    profanitiesDict = defaultdict(int)
    profTxtLblDict = defaultdict(int) # labels of texts containing profanities

    tt  = time.time()
    containsProfanity = []    
    for tw, procTxt in enumerate(procTxtLst):
        
        tp = profanitiesInText(procTxt, hr)
                
        for k,v in tp.iteritems():
            profanitiesDict[k] += v
        
        if tp:
            profTxtLblDict[lbls[tw]] += 1
            containsProfanity.append(tw)
    
    print time.time()-tt

    logfile = open(MC_LOGS_HOME + 'profanityAnalysisList' + '.csv', 'w')
    logger = logfile.write                
    scp = sorted(profanitiesDict.iteritems(), key=operator.itemgetter(1), reverse=True)
    for k, v in scp:
        logger('%s|"%d"\n' % (k,v))    
    logfile.close()
    print profTxtLblDict

    logfile = open(MC_LOGS_HOME + 'profanityAnalysisPrecision' + '.csv', 'w')
    logger = logfile.write                
    for tw in containsProfanity:
        procTxt = procTxtLst[tw]
        logger('"%s"|"%s"\n' % (procTxt['sentences'], lbls[tw]))    
    logfile.close()
    
            