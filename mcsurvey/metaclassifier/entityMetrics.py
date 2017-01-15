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

def normalizeTxt(txt):
    txt = txt.lower().strip()
    txt=txt.replace("at&t","att")
    txt=txt.replace("t-mobile","tmobile")
    txt=txt.replace("t mobile","tmobile")
    txt=txt.replace("@","")
    txt=txt.replace("#","")
    txt=txt.replace(" '","'")
    txt=txt.replace("' ","'")
    return txt
    
def normalizeEntity(espair):
    """
    Normalization of entity text and sentiment labels
    espair = [entity, labelsList, textIndex]
    e.g, [u'james', [u'neutral'], 0]
    """
    txt = normalizeTxt(espair[0])    
    sent = [s.lower() for s in espair[1]]
    
    espair[0] = txt
    espair[1] = sent
    return espair

def matchEntity(tru_espair, prd_espair):
    """
    espair = [entity, labelsList, textIndex]
    e.g, [u'james', [u'neutral'], 0]
    """
    tr = tru_espair[0].split()
    pr = prd_espair[0].split()    
    c = set(tr).intersection(set(pr))
    
    n = float(len(tr))    
    nc = len(c)    

    if nc/n >= 0.5:
        return True
    return False
       
def entityMetrics(tru_espairs, prd_espairs):
    """
    tru_espairs = true espairs in text
    prd_espairs = predicted espairs in text
    
    """
    fn = []
    for tru_espair in tru_espairs:
        ist = False
        for prd_espair in prd_espairs:
            if matchEntity(tru_espair,prd_espair):
                ist = True
                break                
        if not ist:
            fn.append(tru_espair)
       
    fp = []
    tp = []
    for prd_espair in prd_espairs:
        ist = False
        for tru_espair in tru_espairs:
            if matchEntity(tru_espair,prd_espair):
                ist = True
                prd_espair.append(tru_espair[1])
                tp.append(prd_espair)
                break                
        if not ist:
            fp.append(prd_espair)
                
    em = {'tp':tp, 'fp': fp, 'fn':fn}
    em['nte'] = len(tr)
    em['npe'] = len(pr)
    em['nfp'] = len(fp)
    em['ntp'] = len(tp)
    em['nfn'] = len(fn)
    return em
        
def entityEval(tru, prd, txts):
    """
    tru, prd = [{entity:'foo', 'sentiment':['positive']}]
    """        
    logger = sys.stdout.write

def _reformatPrds(prds):
    """transform list of ordered dicts to dict."""
    prdLst = []
    for prd in prds:
        edict = defaultdict(list)
        for p in prd:
            edict[p['entity']].extend(p['sentiment'])
        prdLst.append(edict)
    return prdLst
        
def print2HTML(printer, key, emLst, txts, truLst, prdLst):
    printer("<!DOCTYPE html>\n")
    printer("<html>\n<body>")
    
    for k, em in enumerate(emLst):
        if em['fp'] or em['fn']:
            printer("<p>")
            printer('%d. ' % k)
            tru = truLst[k]
            txtstr = ' '.join(txts[k])
            txtstr = normalizeTxt(txtstr)
            for t in tru:
                txtstr = txtstr.replace(t[0], '<ins>%s</ins>' % t[0])
            for t in prdLst[k]:
                txtstr = txtstr.replace(t[0], '<b>%s</b>' % t[0])
            for t in em['fp']:
                txtstr = txtstr.replace(t[0], '<del>%s</del>' % t[0])
            printer('%s' % txtstr)    
        printer("</p>")        
    printer("</body>\n</html>\n")    
        
if __name__ == "__main__":
    import cPickle as pickle
    from collections import defaultdict  
    from collections import Counter
    d = pickle.load(open(MC_LOGS_HOME + 'temp2.pik', 'rb'))

    trus = d[0]; prds = d[1]; txts = d[2]

    prds = _reformatPrds(prds)
                  
    truLst = [[normalizeEntity([e,s,k]) for e,s in espairs.iteritems()] for k, espairs in enumerate(trus)]         
    prdLst = [[normalizeEntity([e,s,k]) for e,s in espairs.iteritems()] for k, espairs in enumerate(prds)]
   
    emLst = [entityMetrics(tr, pr) for tr, pr in zip(truLst, prdLst)]    
    #       
    n_fp = sum(em['nfp'] for em in emLst)
    n_tp = sum(em['ntp'] for em in emLst)
    n_fn = sum(em['nfn'] for em in emLst) 
    total = float(n_fp + n_tp + n_fn) 
    
    logger = sys.stdout.write
    logger('No of True Positives :\t%d\t%5.3f\n' %  (n_tp, n_tp/total))
    logger('No of False Positives:\t%d\t%5.3f\n' % (n_fp, n_fp/total))
    logger('No of False Negatives:\t%d\t%5.3f\n' % (n_fn, n_fn/total))
    logger('Entity Precision:\t%5.3f\n' % (n_tp/float(n_tp+n_fp)))
    logger('Entity Recall:\t%5.3f\n' % (n_tp/float(n_tp+n_fn)))    
       
    key = 'fp'
    logfile = open(MC_LOGS_HOME + 'entity' + key+ '.htm', 'w')
    printer = logfile.write; closeprinter = True
    print2HTML(printer, key, emLst, txts, truLst, prdLst)
    if closeprinter:
        logfile.close()
        
    key = 'fn'
    logfile = open(MC_LOGS_HOME + 'entityErrors' + '.htm', 'w')
    printer = logfile.write; closeprinter = True
    print2HTML(printer, key, emLst, txts, truLst, prdLst)    
    if closeprinter:
        logfile.close()
        
    #               
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
            else:
                prlbls.extend(t[1])
                trlbls.extend(t[3])
            
    from cm import ClassifierMetrics
    cm = ClassifierMetrics(['positive', 'neutral', 'negative'])
    cm.computeMetrics(trlbls, prlbls)
    cm.printMetrics()
 
