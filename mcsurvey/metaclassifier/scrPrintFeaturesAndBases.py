#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Pretty print the features and the bases for a given model.

Created on Thu Oct 16 01:51:37 2014
@author: vh
"""
import sys
from config import *
import cPickle as pickle
from ptPreProc import normalizeAndTag
from processText import sentencifyAndChunk
from metaclassifier_utils import computeFeatures

modelname = 'SAModel042_RTRN_BestModel'
logger = sys.stdout.write


hr = pickle.load(open(DEFAULT_HR_FILE))
model = pickle.load(open(MC_MODELS_HOME + modelname + '.msmdl'))

txts = ['dummy text']
featureNames = model['features']

normTxtLst = normalizeAndTag(txts, MC_TAGGER_HOME)
procTxtLst = sentencifyAndChunk(normTxtLst, hr)
extractedFeatures = computeFeatures(procTxtLst[0], hr, featureNames)

for k, featureName in enumerate(extractedFeatures):
    logger('%d %s\n' % (k,featureName))
    for base, val in extractedFeatures[featureName].iteritems():
        logger('\t%s:%s\n' % (base,val))