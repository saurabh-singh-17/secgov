# -*- coding: utf-8 -*-
"""
Created on Sun Nov 16 07:47:43 2014

@author: vh
"""

import sys
from config import *
import cPickle as pickle
from collections import defaultdict, Counter
from processText import updateTokenAndChunkProperties
from clause_properties import clauseVPAnalysis

dname = 'ptd/coechatsamples25'
#dname = 'ptd/data_ptd_train'
#dname = 'entityEval'
#dname = 'evaldata/data_semeval_6399_train'
toktagfilename = MC_DATA_HOME + dname + '.proctxts' #'dbg/data/cleanedupTestData.proctxts'
procTxtLst = pickle.load(open(toktagfilename, 'rb'))
hr = pickle.load(open(DEFAULT_HR_FILE))

logger = sys.stdout.write; closeLogger=False
vpd = defaultdict(int)
vpfd = defaultdict(int)
nctot = 0

for t, procTxt in enumerate(procTxtLst):
    procTxt = updateTokenAndChunkProperties(procTxt, hr)
    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
#            nctot += 1
#            n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(sentence)
#            vpd[n_vp] += 1
#            vpfd[n_vpfinite] += 1
            
        for c, clause in enumerate(sentence):
            nctot += 1
            n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
            vpd[n_vp] += 1
            vpfd[n_vpfinite] += 1

           
printer = sys.stdout.write
printer('Data Name %s\n' % dname)
printer('N Clauses\t%d\n' % nctot)
printer('N Clauses Verb Analysis\t%d\t%d\n' % (sum(vpd.values()), sum(vpfd.values())))
printer('VP Analysis\n')
for k, v in vpd.iteritems():
    printer('%d\t%d\t%5.3f\n' % (k, v, v/float(nctot)))
printer('Finite VP Analysis\n')
for k, v in vpfd.iteritems():
    printer('%d\t%d\t%5.3f\n' % (k, v, v/float(nctot))) 