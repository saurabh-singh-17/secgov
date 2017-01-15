#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Script to be run everytime changes are made to the dictionary source files (csv/txt).
Because of pre-chunking and prior polarity lookups in procTxts, both
dictionaries & proctxts must be updated everytime the dictionaries are updated.

A good side-effect of this script is that resources and procTxt pickles are well
formed. See: http://stefaanlippens.net/pickleproblem

Created on Fri Jul 11 04:16:56 2014
@author: vh
"""

import os
from time import time
import cPickle as pickle
from processText import sentencifyAndChunk
from Resources import makeDefaultResources
from config import * #MC_RESOURCES_HOME, MC_DATA_HOME, DEFAULT_HR_FILE
import sys

logger = sys.stdout.write

#remove all editor backups to prevent ngdicts from picking up garbage.
#cleaner would way would be to fix the ngdicts. TBD
deleters = ['~']
for root, subFolders, files in os.walk(MC_RESOURCES_HOME):
    for fil in files:
        fileName, fileExtension = os.path.splitext(fil)
        fname = os.path.join(root, fil)
        if any([d in fileExtension for d in deleters]):
            logger('**Removing %s %s %s\n' % (fname, fileExtension, '*'))
            os.remove(fname)

##update resources from resources/
hr = makeDefaultResources()
pickle.dump(hr, open(DEFAULT_HR_FILE,'wb'))

#MC_NORM_TXTS = ".normtxts"
#MC_PROC_TXTS = ".proctxts"
#
###update procTxts in dev/
#logger('\nProcessing Files\n')
#tFolder = MC_DATA_HOME
#tFolder = MC_PYHOME + 'dev/ptd/' #'MC_DATA_HOME + 'train/'
#tFolder = MC_DATA_HOME + 'ptd/' #
##tFolder = MC_DATA_HOME + 'evaldata/' #'cmpdata/'
##tFolder = MC_DATA_HOME + 'aspectdata/' #'cmpdata/'
#for fil in os.listdir(tFolder):
#    fileName, fileExtension = os.path.splitext(fil)
#    if fileExtension == MC_NORM_TXTS: #MC_PROC_TXTS: #
#        ptname =  tFolder + fileName + MC_PROC_TXTS
#        normTxtLst = pickle.load(open(tFolder + fil))
#
#        logger('%s ...' % fileName)
#        st = time()
#        procTxtLst = sentencifyAndChunk(normTxtLst, hr)
#        logger('\nProcessed in %f secs\n' % (time() - st))
#        pickle.dump(procTxtLst, open(ptname, 'wb'))
#        logger('Saved As: %s\n' % ptname)

# Example
#normTxtLst = pickle.load(open(normTxtPath))
#procTxtLst = sentencifyAndChunk(normTxtLst, hr)
#pickle.dump(procTxtLst, open(ptname, 'wb'))
