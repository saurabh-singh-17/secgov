# -*- coding: utf-8 -*-
"""
@author: Mu-sigma
@maintainer:Mu-Sigma
"""
import nltk
import sklearn
from nltk.classify.maxent import MaxentClassifier as nltkmec
from sklearn.linear_model import LogisticRegression as lr
from collections import defaultdict
import operator
from metaclassifier_utils import computeFeatures, makeSKFormat
MCKEY_LABEL = 'label'
MCKEY_SCORES = 'scores'
MCKEY_CLASSIFIER = 'classifier'
MCKEY_FEATURES = 'features'
MCKEY_PRDLABELS = 'prdLabels'

def _get_SKLR_ProbPredictions(bases, classifier, prdLabels):
    """
    Wrapper for SKLEARN Logistic Regression Predictions.
    Performs bases transformation to list of lists, calls appropriate method, and
    unpacks the results in the {label_1: Pr_1, label_2: Pr_2, ...} format.
    """
    #print("###############")
    global write_file
    global flag_headings
    global flag_count
    bases , basesNames= makeSKFormat([bases],returnBasisNames=True)
    tp = classifier.predict_proba(bases)
    rdict = {lbl:tp[0][k] for k, lbl in enumerate(prdLabels)}
    return rdict

def _get_ME_ProbPredictions(bases, classifier, prdLabels):
    """
    Wrapper for NLTK Maxent Predictions
    Calls appropriate method, and
    unpacks the results in the {label_1: Pr_1, label_2: Pr_2, ...} format.
    """
    classifyMethod = classifier.prob_classify
    tp = classifyMethod(bases)
    rdict = {lbl:tp.prob(lbl) for lbl in prdLabels}
    return rdict

from clause_pol import clausePolarity
import sys
from config import PTKEY_CHUNKEDCLAUSES
def getProbPredictions(procTxt, hr, model, computedFeatures = None, dbg = False):
    """
    Entry point for probabilistic classifier predictions.
    """
    
    if not procTxt:
        return ['NA']

    classifier = model[MCKEY_CLASSIFIER]
    featureNames = model[MCKEY_FEATURES]
    prdLabels = model[MCKEY_PRDLABELS]

    if not computedFeatures:
        computedFeatures = computeFeatures(procTxt, hr, featureNames)

#    logger = sys.stdout.write
#    chunkedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
#    for chunkedSentence in chunkedSentences:
#        for clause in chunkedSentence:
#
#            chPat, pols, negn, negtd = clausePolarity(clause, hr, logger) 
#            logger('CLAUSE: %s\n' % clause)
#            logger('POLS: %s\n' % pols)
#            logger('NEGN: %s\n' % negn)
#            logger('NEGTD: %s\n' % negtd)
#            logger('-\n')
#    
#    logger('%s\n' % ' '.join(procTxt['tokens']))
#    for featureFuncName, features in computedFeatures.iteritems():
#        for feature, val in features.iteritems():
#            if val:                    
#                logger('%s %s\n' % (feature, val))
    #Keeping this separated from computeFeatures to avoid recomputing features
    #in the pipeline.
    bases = {}
    for feature in featureNames:
        bases.update(computedFeatures[feature])

    if type(classifier) == nltk.classify.maxent.MaxentClassifier:
        rdict = _get_ME_ProbPredictions(bases, classifier, prdLabels)
    elif type(classifier) == sklearn.linear_model.logistic.LogisticRegression:
        rdict = _get_SKLR_ProbPredictions(bases, classifier, prdLabels)

    retval = {MCKEY_SCORES: rdict, MCKEY_LABEL: max(rdict, key=rdict.get)}

    return retval

#def trainClassifier(procTxtLst, lbls, hr, featureNames, params = {} , dbg = False):
#    """
#    Classifier Training.
#    tokTagLst: list of lists containing token and tags pairs for training data.
#    [[(tok1, tag1), (tok2, tag2) ...], [(tok1, tag1), (tok2, tag2), ...], ...]
#    lbls = list of labels for training data.
#    hr: hosted resources - dictionaries, lists, etc..
#    featureNames: iterable containing names of feature functions.
#    params optimizer parameters.
#    dbg = True/False.
#    if true appends featureSets and feature Vals to model for further debugging.
#
#    returns
#    model = {'classifier': classifier, 'features': featureNames} if dbg = false
#    model = {'classifier': classifier, 'features': featureNames, 'flist' : flist, 'fvlist': fvlist} if dbg = true
#    """
#    flist = []
#    fvlist = []
#    for procTxt in procTxtLst:
#        extractedBases, fv = extractBases(procTxt, hr, featureNames)
#        bases = {}
#        for feature in featureNames:
#            bases.update(extractedBases[feature])
#
#        flist.append(bases)
#        fvlist.append(fv)
#
##    flist, fvlist = extractFeatures(featureNames, tokTagLst, hr)
#
#    trainset = [ [fl, lbl] for fl, lbl in zip(flist, lbls)]
#
#    optimizer = params.get('optimizer', 'GIS')
#    trace = params.get('trace', 3)
#    encoding = params.get('encoding',None)
#    labels = params.get('labels', None)
#    sparse = params.get('sparse', True)
#    gaussian_prior_sigma = params.get('gaussian_prior_sigma', 0)
#    max_iter = params.get('max_iter', 25)
#
#    classifier = nltkmec.train(trainset, optimizer, trace=trace, \
#    	encoding=encoding, labels=labels, sparse=sparse, gaussian_prior_sigma=gaussian_prior_sigma, max_iter = max_iter)
#
#    model = {'classifier': classifier, 'features': featureNames, 'prdLabels': set(lbls)}
#
#    if dbg:
#        model['flist'] = flist
#        model['fvlist'] = fvlist
#
#    return model
##
#def trainClassifierFromExtractedBases(extractedBasesLst, lbls, hr, featureNames, params = {} , dbg = False):
#    """
#    Classifier Training.
#    tokTagLst: list of lists containing token and tags pairs for training data.
#    [[(tok1, tag1), (tok2, tag2) ...], [(tok1, tag1), (tok2, tag2), ...], ...]
#    lbls = list of labels for training data.
#    hr: hosted resources - dictionaries, lists, etc..
#    featureNames: iterable containing names of feature functions.
#    params optimizer parameters.
#    dbg = True/False.
#    if true appends featureSets and feature Vals to model for further debugging.
#
#    returns
#    model = {'classifier': classifier, 'features': featureNames} if dbg = false
#    model = {'classifier': classifier, 'features': featureNames, 'flist' : flist, 'fvlist': fvlist} if dbg = true
#    """
#    flist = []
#    for extractedBases in extractedBasesLst:
#        bases = {}
#        for feature in featureNames:
#            bases.update(extractedBases[feature])
#        flist.append(bases)
#
#    trainset = [ [fl, lbl] for fl, lbl in zip(flist, lbls)]
#
#    optimizer = params.get('optimizer', 'GIS')
#    trace = params.get('trace', 3)
#    encoding = params.get('encoding',None)
#    labels = params.get('labels', None)
#    sparse = params.get('sparse', True)
#    gaussian_prior_sigma = params.get('gaussian_prior_sigma', 0)
#    max_iter = params.get('max_iter', 25)
#
#    classifier = nltkmec.train(trainset, optimizer, trace=trace, \
#    	encoding=encoding, labels=labels, sparse=sparse, gaussian_prior_sigma=gaussian_prior_sigma, max_iter = max_iter)
#
#    model = {'classifier': classifier, 'features': featureNames, 'prdLabels': set(lbls)}
#
#    return model

if __name__ == "__main__":

    from config import *
    from collections import defaultdict
    import time
    import gc
    import cPickle as pickle