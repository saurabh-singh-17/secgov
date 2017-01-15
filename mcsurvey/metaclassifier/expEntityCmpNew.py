# -*- coding: utf-8 -*-
"""
Created on Mon Nov 10 14:07:50 2014

@author: vh
"""

import utils_gen as ug
from config import *
import ast
import re
import sys
import cPickle as pickle

def normalizeEntity(ent):
    txt = ent[0].lower().strip()
#    ent = ent.replace("'","")
    txt = txt.replace("t mobile","tmobile")
    txt = re.sub(r'([^\s\w]|_)+', '', txt) #everything but alphanumeric and space
    sent = [s.lower() for s in ent[1]]
    
    ent[0] = txt
    ent[1] = sent
    return ent

def matchEntity(tr, pr):
    tr = tr[0].split()
    pr = pr[0].split()
    n = float(len(tr))
    
    c = set(tr).intersection(set(pr))
    nc = len(c)
    
    if nc/n >= 0.5:
        return True
    return False
    
def entityMetrics(tr, pr):
    """
    tr = true entity
    pr = predicted entity
    """
    fn = []
    for t in tr:
        ist = False
        for p in pr:
            if matchEntity(t,p):
                ist = True
                break                
        if not ist:
            fn.append(t)
       
    fp = []
    tp = []
    for p in pr:
        ist = False
        for t in tr:
            if matchEntity(t,p):
                ist = True
                p.append(t[1])
                tp.append(p)
                break                
        if not ist:
            fp.append(p)
                
    em = {'tp':tp, 'fp': fp, 'fn':fn}
    em['nte'] = len(tr)
    em['npe'] = len(pr)
    em['nfp'] = len(fp)
    em['ntp'] = len(tp)
    em['nfn'] = len(fn)
    return em
        
        
        
#data = ug.readlines(MC_LOGS_HOME + 'entitycomparison2.csv')

logger = sys.stdout.write
datap = pickle.load(open(MC_LOGS_HOME + 'entity_pickle'))

trep = []
prep = []
txts = []
idxs = []
for idx, data in datap.iteritems():
    idxs.append(idx)
    trep.append([[k,v, data['txts']] for k,v in data['actual'].iteritems()])
    prep.append([[k,v, data['txts']] for k,v in data['predicted'].iteritems()])
    txts.append(data['txts'])
    
print len(trep), len(prep)
#       
tre = [[normalizeEntity(t) for t in tr] for tr in trep] 
pre = [[normalizeEntity(t) for t in tr] for tr in prep] 

emLst = []
for i, (tr, pr) in enumerate(zip(tre, pre)):        
    em = entityMetrics(tr, pr)
    emLst.append(em)
#    
fpLst = [em['nfp'] for em in emLst]
fnLst = [em['nfn'] for em in emLst]
tpLst = [em['ntp'] for em in emLst]

total_fp = sum(fpLst)
total_tp = sum(tpLst)
total_fn = sum(fnLst)
total = float(sum([total_fp, total_tp, total_fn]))

logger('No of True Positives :\t%d\t%5.3f\n' %  (total_tp, total_tp/total))
logger('No of False Positives:\t%d\t%5.3f\n' % (total_fp, total_fp/total))
logger('No of False Negatives:\t%d\t%5.3f\n' % (total_fn, total_fn/total))
logger('Entity Precision:\t%5.3f\n' % (total_tp/float(total_tp+total_fp)))
logger('Entity Recall:\t%5.3f\n' % (total_tp/float(total_tp+total_fn)))
#               
from collections import Counter
fp = Counter(fpLst)
fn = Counter(fnLst)
tp = Counter(tpLst)

tpe = [em['tp'] for em in emLst if em['tp']]
trLblsLst = [t[3] for tp in tpe for t in tp]
prLblsLst = [t[1] for tp in tpe for t in tp]
ptxts = [t[2] for tp in tpe for t in tp]

prlbls = []
trlbls = []

for tpem in tpe:
    for t in tpem:
        if len(t[1]) != len(t[3]):
            pass
#            print 'prd', t[0], t[1]
#            print 'act', t[0], t[3]
#            print t[2]
#            print '----'
        else:
            prlbls.extend(t[1])
            trlbls.extend(t[3])

for k, tr in enumerate(trlbls):
    if 'negatives' == tr:
        trlbls[k] = 'negative'            
from cm import ClassifierMetrics
cm = ClassifierMetrics(['positive', 'neutral', 'negative'])
cm.computeMetrics(trlbls, prlbls)
cm.printMetrics()
        
#for trLbls, prLbls, txt in zip(trLblsLst, prLblsLst, ptxts):
#    if len(trLbls)!= len(prLbls):
#        print trLbls
#        print prLbls
#        print txt
        
#ntxts = len(trep)
#logger('text level stats\n')
#logger('false negatives (missed entities)\n')


#
#print n/float(len(tre))
#    
#    
#    
#    
