# -*- coding: utf-8 -*-
"""
Created on Sun Oct 19 06:28:11 2014

@author: vh
"""
import time, sys
from nltk.classify.maxent import MaxentClassifier as nltkmec
from sklearn.linear_model import LogisticRegression as lr
from metaclassifier_utils import extractBases, makeSKFormat
from metaclassifier_utils import MC_CLASSIFIER_NLTK_MAXENT, MC_CLASSIFIER_SKLEARN_LR

def _train_ME_Classifier(extractedBases, lbls, params = {}):
    """ NLTK ME Training Wrapper"""

    trainset = [[eb, lbl] for eb, lbl in zip(extractedBases, lbls)]

    optimizer = params.get('optimizer', 'GIS')
    trace = params.get('trace', 3)
    encoding = params.get('encoding',None)
    labels = params.get('labels', None)
    sparse = params.get('sparse', True)
    gaussian_prior_sigma = params.get('gaussian_prior_sigma', 0)
    max_iter = params.get('max_iter', 25)

    classifier = nltkmec.train(trainset, optimizer, trace=trace, \
    	encoding=encoding, labels=labels, sparse=sparse, gaussian_prior_sigma=gaussian_prior_sigma, max_iter = max_iter)

    return classifier, classifier.labels()

def _train_SKLR_Classifier(extractedBases, lbls, params = {}):
    """ NLTK ME Training Wrapper"""

    Xtrn = makeSKFormat(extractedBases)
    ytrn = lbls

    C = params.get('C', 10)
    penalty = params.get('penalty', 'l1')
    class_weight = params.get('class_weight','auto')
    tol = params.get('tol', 1e-6)

    classifier = lr(C=C, penalty=penalty,
                    class_weight=class_weight, tol=tol)

    classifier.fit(Xtrn,ytrn)

    return classifier, list(classifier.classes_)

__ME_CLASSIFIER_TRAIN = {MC_CLASSIFIER_NLTK_MAXENT:_train_ME_Classifier,
                         MC_CLASSIFIER_SKLEARN_LR:_train_SKLR_Classifier}

def trainClassifierDev(procTxtLst, lbls, hr, featureNames, ctype, params = {}, logger=None):
    """
    Classifier Training.
    """
    if not logger:
        logger = sys.stdout.write

    logger('Meta Classifier Training\n')
    logger('Extracting Bases ..')
    st = time.time()
    extractedBases = [
        extractBases(procTxt, hr, featureNames) for procTxt in procTxtLst]
    logger('. Done. %8.6f secs.\n' % float(time.time() - st))

    try:
        train_Classifier = __ME_CLASSIFIER_TRAIN[ctype]
    except:
        raise Exception('MC Train Unknown Classifier type %s' % ctype)

    logger('Training Model %s ..\n' % ctype)
    st = time.time()
    classifier, labels = train_Classifier(extractedBases, lbls, params)
    logger('Done. %8.6f secs.\n' % float(time.time() - st))

    model = {'classifier': classifier, 'prdLabels': labels}
    model['features'] = featureNames
    model['createdon'] = time.strftime("%b %d %Y %H:%M:%S %z", time.gmtime())
    model['type'] = ctype

    return model