#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Script to build classifier models using NLTK ME.
Created on Fri Mar 21 19:57:39 2014
@author: Mu-Sigma
"""

import utils_gen as ug
from metaclassifier_utils import MC_CLASSIFIER_NLTK_MAXENT
from metaclassifier_train import trainClassifierDev
import time, sys
import cPickle as pickle
from Dataset import Dataset
from config import *
from config import MC_MODELS_HOME, MC_LOGS_HOME

## Feature Selection *********************************************************
coreFeatures = ['countPolarPOSFeature', 'totalPolarityFeature', 'netPOSPolarityURLFeature']#, ,]#,
ngramFeatures = ['containsPolar2GFeature', 'containsPolar3GFeature']
chunkFeatures = ['countPosteriorPolarChunksFeature', 'netPosteriorPolarChunksFeature'] #['countPolarChunksInClausedSentencesFeature'] ##['countPolarChunksFeature','netPolarChunksFeature']
syntacticFeatures = ['positiveinterjectionFeature','negativeinterjectionFeature', 'hashtag_calcFeature', 'hasIntensifierFeature']
txtMoodFeatures = ['countSmileyFeature','exclamationFeature','dollarFeature','periodFeature','questionFeature', 'txtContainsProfanityFeature']
#featureNames = ['hasHapenningVerbsFeature', 'hasSoftVerbsFeature','PhrasalVerbsFeature','act_behaveFeature' 'hasProbNounFeature','notHapenningVerbsFeature','PhrasalVerbsFeature','act_behaveFeature','exclamationFeature','hasProbNounFeature','dollarFeature','periodFeature','questionFeature']

ptdchunkFeatures = ['probnounapproxFeature','act_behaveapproxFeature','phrasalapproxFeature']
ppdchunkFeatures =['degenerate_sentFeature', 'singleword_sentFeature', 'multiverb_sentFeature']
telecomFeatures = ['countNGInTelecomDictFeature']

featureNames = []
#featureNames.extend(coreFeatures)
#featureNames.extend(ngramFeatures)
featureNames.extend(chunkFeatures)
#featureNames.extend(['positiveinterjectionFeature', 'negativeinterjectionFeature', 'hasIntensifierFeature'])
#featureNames.extend(txtMoodFeatures)
#featureNames.extend(syntacticFeatures)
##featureNames.extend(['isAdFeature']) #, 'txtContainsProfanityFeature']) #'txtContainsProfanityFeature', 'hasURLFeature',
#

#featureNames.extend(ptdchunkFeatures)
#featureNames.extend(ppdchunkFeatures)
#featureNames.extend(telecomFeatures)
## Feature Selection *********************************************************

##
trn_data_name = 'evaldata/data_semeval_6399_train'
modelname = 'SA_NewMCTrain_Chunk' #PyProcPosDictOnlyChunkNewAllNP'
ctype = MC_CLASSIFIER_NLTK_MAXENT
params = {'max_iter': 5}
N_Iters = 3

logger = sys.stdout.write
proctxtLst = pickle.load(open(MC_DATA_HOME + trn_data_name + '.proctxts'))
lbls = ug.readlines(MC_DATA_HOME + trn_data_name + '.lbls')
mfname = MC_MODELS_HOME + modelname + ctype + '.msmdl'
hr = pickle.load(open(DEFAULT_HR_FILE))

##****************************************************************************
ds = Dataset(lbls, seedVal = 17) #12
#cm = ClassifierMetrics(ds.getLabels()) #initialize metrics object
idxneg = ds.makeSetByLbl('negative')
idxneu = ds.makeSetByLbl('neutral', len(idxneg), randflag=True)
idxpos = ds.makeSetByLbl('positive', len(idxneg), randflag=True)
idx = idxneu + idxneg + idxpos

lbls_trn = [lbls[k] for k in idx]
proctxtLst_trn = [proctxtLst[k] for k in idx]

logger('Training Data\nSize: %d\nSelectedFeatures: %d\n'
        % (len(lbls_trn), len(featureNames)))
model = trainClassifierDev(proctxtLst_trn, lbls_trn,
                           hr, featureNames, ctype, params, logger=None)

pickle.dump(model, open(mfname, 'wb'))
print 'model saved in %s' % mfname
