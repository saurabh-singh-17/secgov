# -*- coding: utf-8 -*-
"""
Created on Mon Oct 27 05:49:37 2014

@author: vh
"""

# -*- coding: utf-8 -*-
"""
Get Single Sentence data.
Created on Sun Oct 26 04:40:45 2014
@author: vh
"""

from config import *
import utils_gen as ug
import cPickle as pickle

dname = 'evaldata/data_merged_2854_test'
procTxtLst = pickle.load(open(MC_DATA_HOME + dname + '.proctxts'))
txts = ug.readlines(MC_DATA_HOME + dname + '.txts')
lbls = ug.readlines(MC_DATA_HOME + dname + '.lbls')

hr = pickle.load(open(DEFAULT_HR_FILE))

reltxts = []
rellbls = []
relptxt = []

for p, procTxt in enumerate(procTxtLst):
    if len(procTxt[PTKEY_SENTENCES]) == 1:
        reltxts.append(txts[p])
        rellbls.append(lbls[p])
        relptxt.append(procTxt)
