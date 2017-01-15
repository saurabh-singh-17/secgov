# -*- coding: utf-8 -*-
"""
Meta.Classifier Pipeline Services Wrapper Functions.
Functions defined here are refered in the mcservices_config.json files.

Created on Fri Oct 17 16:50:33 2014
@author: vh
"""

__MCAPI_RESULT__ = 'result'
__MCAPI_ISAD__ = 'isAd'
__PPKEY_PC__ = 'context'
__MCAPI_ASPECT__ = 'entities'
__MCAPI_TEXT__ = 'text'
__PPKEY_PCDM__ = 'contextDomainNoun'

from metaclassifier import getProbPredictions, MCKEY_LABEL
from extractKeywords import extractKeywords
from ppd import problemPhraseDetector
from problem_phrases import probPhrasePretty
from problem_phrases import problemContextDetector
#from polar_clauses import entity_sentiment
from appDefs import PTKEY_TOKENS
from adDetect import adDetection
from surface_properties import charCounts
from w2vutils import proctxt2tt
from phrase_analysis import phraseAnalysis
from phrase_analysis2 import entity_sentiment

def mcserviceswrapper_tokstags(proctxt, hres, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Sentiment"""
    
    result = {__MCAPI_RESULT__:proctxt2tt(proctxt)}
    return result
    
def mcserviceswrapper_phraseanalysis(proctxt, hres, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Sentiment"""
    
    result = {__MCAPI_RESULT__:phraseAnalysis(proctxt, hres)}
    return result    


def mcserviceswrapper_sentiment(proctxt, hres, model, computedFeatures=None, featureVals={}):
    """Output formating for Sentiment"""
    result = getProbPredictions(proctxt, hres[0], model[0], computedFeatures)
    result[__MCAPI_RESULT__] = result.pop(MCKEY_LABEL)
    return result

def mcserviceswrapper_problem(proctxt, hres, model, computedFeatures=None, featureVals={}):
    """Output formating for Problem Text and Context Detection"""
    result = getProbPredictions(proctxt, hres[0], model[0], computedFeatures)
    result[__MCAPI_RESULT__] = int(result.pop(MCKEY_LABEL))
    #result[__PPKEY_PC__] = probPhrasePretty(proctxt, hres[0])

    if result[__MCAPI_RESULT__] == 1:
        #result[__PPKEY_PC__] = probPhrasePretty(proctxt, hres[0]) #problemPhraseDetector(proctxt, hres[0])
        #result[__PPKEY_PC__] = problemPhraseDetector(proctxt, hres[0])
        problem_context_dm,problem_context = problemContextDetector(proctxt, hres[0])
        result[__PPKEY_PCDM__] = problem_context_dm
        result[__PPKEY_PC__] = problem_context
    else:
        result[__PPKEY_PCDM__] = []
        result[__PPKEY_PC__] = []
    return result

def mcserviceswrapper_keywords(proctxt, hres, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Keywords"""
    result = {__MCAPI_RESULT__:extractKeywords(proctxt, hres[0])}
    return result

def mcserviceswrapper_counts(proctxt, hres, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Keywords"""
    result = {__MCAPI_RESULT__:charCounts(proctxt)}
    return result
    
def mcserviceswrapper_ads(proctxt, hres=None, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Ad Detection"""
    if not 'adDetection' in featureVals:
        featureVals = adDetection(proctxt, hres, featureVals)
        
    result = {__MCAPI_RESULT__: featureVals['adDetection']} #proctxt[__MCAPI_ISAD__]}
    return result

def mcserviceswrapper_entity(proctxt, hres=None, model=None, computedFeatures=None, featureVals={}):
    """Output formating for Entity based Sentiment"""
    result = {__MCAPI_RESULT__:entity_sentiment(proctxt, hres[0], sentiment_flag=1)}
    return result

from processText import sentenceSplitProcTxts
def mcserviceswrapper_sentenceLevelSentiment(procTxt, hres, model, computedFeatures=None, featureVals={}):
    """Output formating for Sentiment"""
    sprocTxtLst = sentenceSplitProcTxts(procTxt)
    result = []
    for sprocTxt in sprocTxtLst:
        sprocTxt[__MCAPI_ISAD__] = procTxt[__MCAPI_ISAD__]
        tresult = getProbPredictions(sprocTxt, hres[0], model[0])
        tresult[__MCAPI_RESULT__] = tresult.pop(MCKEY_LABEL)
        tresult[__MCAPI_ASPECT__] = entity_sentiment(sprocTxt, hres[0], sentiment_flag=1)
        tresult[__MCAPI_TEXT__] = ' '.join(sprocTxt[PTKEY_TOKENS])
        result.append(tresult)
    return result
    
    
