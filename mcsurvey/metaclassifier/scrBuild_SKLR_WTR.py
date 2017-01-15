#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Script to build classifier models using SKLEARN Logistic Regression.
Currently only support for manual tweaking for the hyperparams of the fit are
supported. Ideally the hyperparams should be identified via an outer optimization.

Created on Fri Oct  3 18:58:22 2014
@author: vh
"""
import mcServicesAPI as mcs
import time, sys
import utils_gen as ug
import cPickle as pickle
from config import *
from Dataset import Dataset
from cm import ClassifierMetrics, countInstances
from processText import updateTokenAndChunkProperties

from metaclassifier_utils import MC_CLASSIFIER_SKLEARN_LR
from metaclassifier_train import trainClassifierDev


#SA Features
coreFeatures = ['countPolarPOSFeature', 'totalPolarityFeature', 'netPOSPolarityURLFeature']
ngramFeatures = ['containsPolar2GFeature', 'containsPolar3GFeature']
chunkFeatures = ['countPosteriorPolarChunksFeature', 'netPosteriorPolarChunksFeature']
syntacticFeatures = ['positiveinterjectionFeature','negativeinterjectionFeature', 'hashtag_calcFeature', 'hasIntensifierFeature']
txtMoodFeatures = ['countSmileyFeature','exclamationFeature','dollarFeature','periodFeature','questionFeature', 'txtContainsProfanityFeature']
# PD Features
ptdchunkFeatures = ['probnounapproxFeature','act_behaveapproxFeature','phrasalapproxFeature']
ppdchunkFeatures =['degenerate_sentFeature', 'singleword_sentFeature', 'multiverb_sentFeature']
#ppdchunkFeatures =['multiverb_sentFeature']

ppdNewFeatures = ['txtContainsNegatedDomainNounFeature', 'problemPhraseBasesFeature']
## Feature Selection ********************************************************* 
featureNames = []
#featureNames.extend(coreFeatures)
#featureNames.extend(chunkFeatures)
#featureNames.extend(txtMoodFeatures)
#featureNames.extend(syntacticFeatures)
#featureNames.extend(['isAdFeature'])

#PD.
#featureNames.extend(chunkFeatures)
featureNames.extend(ptdchunkFeatures)
#featureNames.extend(ppdchunkFeatures)
featureNames.extend(ppdNewFeatures)
## TRAINING DATA & MODEL PARAMS
#trn_data_name = 'evaldata/data_semeval_6399_train'
trn_data_name = 'ptd/data_ptd_train'

##hr_file = DEFAULT_HR_FILE
#modelname = 'WTR_0' #'PD_New2ChunksNewNoMV2' #PyProcPosDictOnlyChunkNewAllNP'
#ctype = MC_CLASSIFIER_SKLEARN_LR
#hyperparams = {'C':10, 'penalty':'l1', 'tol': 1e-6, 'class_weight': 'auto'}
##for more options see
##http://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html
#
#logger = sys.stdout.write
#
###
#txts = []
#lbls = []
#dname = "/home/vh/surveyresults/volte_rel_20150130.csv"
#def getData(fname):
#    with open(fname, 'r') as ifile:
#        for n, line in enumerate(ifile):
#            if n == 0:
#                continue
#            else:
#                #print n,
#                if (n % 1000) == 0:
#                    print n
#                datas = line.split('|')
#                yield (datas[1], datas[2])
#            
#dd = (mcs._mcNLPipeline(txt[1]) for txt in getData(dname))  #pickle.load(open(MC_DATA_HOME + trn_data_name + '.proctxts'))
#lbls = [d[0] for d in dd]
#proctxtLst = [ d[1] for d in dd]
# 
##for procTxt in proctxtLst:
##    procTxt = updateTokenAndChunkProperties(procTxt, hr)
##    
#mfname = MC_MODELS_HOME + modelname + ctype + '.msmdl'
#
#proctxtLst_trn = proctxtLst[:10000]
#lbls_trn = lbls[:10000]
#
##logger('Training Data\nSize: %d\nSelectedFeatures: %d\n'
##        % (len(lbls_trn), len(featureNames)))
##
##model = trainClassifierDev(proctxtLst_trn, lbls_trn,
##                           hr, featureNames, ctype, hyperparams, logger=None)
##
##pickle.dump(model, open(mfname, 'wb'))
##print 'model saved in %s' % mfname

