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

import metaclassifier
#from processText import sentencifyAndChunk
from metaclassifier.Resources import makeDefaultResources
from metaclassifier.config import MC_RESOURCES_HOME, MC_DATA_HOME, DEFAULT_HR_FILE
import sys

logger = sys.stdout.write

logger('%s\n' % MC_RESOURCES_HOME)

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

###update resources from resources/
hr = makeDefaultResources()
#pickle.dump(hr, open(DEFAULT_HR_FILE,'wb'))

