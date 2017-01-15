# -*- coding: utf-8 -*-
"""
Created on Thu Mar 12 10:33:07 2015

@author: vh
"""

import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
#import metaclassifier.mcServicesAPI as mcapi
from collections import defaultdict, Counter
from clause_pol import clausePolarity
from clause_properties import clauseVPAnalysis 
#from metaclassifier.mcServicesAPI import __MC_PROD_HR__ as hr
from stemmer import stemNoun, stemVerb
#import chunk_cleanup
#from extract_categories import parallel_category
#stabs = {}
#with open('us_state_abs.csv', 'r') as usabs:
#    for line in usabs:
#        line = line.strip().split('|')
#        st = line[0].lower()
#        ab = line[1]
#        stabs[st] = ab
        
def cleantok(tok):
    toks  = tok.split('_NG_')       
    return ' '.join(toks)
    
def cleanAndStemNP(tok):
    toks  = tok.split('_NG_')  
    for t, tok in enumerate(toks):
        toks[t] = stemNoun(tok)   
    return toks

def cleanAndStemVP(tok):
    toks  = tok.split('_NG_')  
    for t, tok in enumerate(toks):
        toks[t] = stemVerb(tok)        
    return toks
                                                      
def npContext(chunk):
    toks = chunk.tokens
    tags = chunk.tags
    tagpat = '+'.join(tags)
    pols = chunk.pols
           
    ntoks = len(chunk.tokens)                
    tprops = chunk.tprops
    tc = Counter(tags)
    
    if tagpat.startswith('X+N'):
        head = zip(toks[1:], tags[1:])
    elif '$' in tags[0]:
        head = zip(toks, tags)
    elif (tags[0] == 'D' and 'no' == toks[0]):
        if ntoks > 1:
            head = zip([toks[0], toks[-1]], [tags[0], tags[-1]])
        else:            
            head = zip([toks[0]], [tags[0]])
             
    else:
        head = zip([toks[-1]], [tags[-1]])
     
    chead = ['%s/%s' % (tok, tag) for tok, tag in head] 
#    chead = []    
#    for tok in head:
#        tt = tok[0].replace('representative', 'rep')
#        chead.append(tt)

    return chead
      
                                                           
def ngramizer(proctxt, hr):
    txt = []
    for s, sentence in enumerate(proctxt['chunksInClauses']):
        sent = []
        for c, clause in enumerate(sentence):
            nc = len(clause)
            inClause = [0]*nc
            claus = []
            chPat, pols, negn, negtd = clausePolarity(clause, hr)
            for h, chunk in enumerate(clause):
                toks = chunk.tokens
                tags = chunk.tags
                pols = chunk.pols
                
                ntoks = len(chunk.tokens)

                if chunk.chunkType == 'NP':
                    if ntoks == 1:
                        if tags[0] in ('O','X'):
                            continue
#                    tprops = chunk.tprops
#                    tc = Counter(tags)
                    claus.append((chunk, npContext(chunk)))                    
            sent.append(claus)
        txt.append(sent)
    return(txt)    

def phraseAnalysis(proctxt, hr):
    '''
    '''
    phrases = ngramizer(proctxt, hr) 
    
    stoks = []
    shead = ''
    pol = 0
    
    phraseLst = []
    for phrase in phrases:
        for sphrase in phrase:
            for cphrase in sphrase:
                chunk = cphrase[0]
                head = cphrase[1]
                
                shead = []
                for tt in head:
                    tag = tt[-1]
                    tok = tt[:-2]
                    
                    ctok = ' '.join(cleanAndStemNP(tok))
                    shead.append('%s/%s' % (ctok, tag))
                shead = ' '.join(shead)

                #print chunk.tokens
                stoks = []
                for k, tok in enumerate(chunk.tokens):
                    tag = chunk.tags[k]
                    tp = chunk.tprops[k]
                    if tag in ('D', 'O') and not (tp['NGTR'] or 'no' in tok):
                        continue
                    stoks.append('%s/%s' % (tok, tag)) #cleantok(tok))
                stoks = ' '.join(stoks)
                #print chunk.tokens, stoks
                
                if chunk.chPol < -2: pol = -2
                if chunk.chPol > 2: pol = 2    
                pol = chunk.chPol
                if not pol and chunk.hasNegator:
                    pol = -1
                
                if not stoks:
                    continue  
                phraseLst.append({'phrase':stoks, 'head':shead, 'pol':pol})
    return phraseLst
    
                        
if __name__ == "__main__": 
    import time, sys, glob, operator
    from itertools import islice
    import cPickle as pickle
    from joblib import Parallel, delayed
    from collections import defaultdict
    from metaclassifier.clause_properties import clauseVPAnalysis 
    from metaclassifier.clause_pol import clausePolarity
    from metaclassifier.mcServicesAPI import __MC_PROD_HR__ as hr
    
    files = glob.glob(os.path.join('/home/vh/volte-0.1/data/WTR/proctxts/', '*'))
    #files = glob.glob(os.path.join('/home/vh/volte/data/UVERSE_WTR_ATT/proctxts/', '*'))
    files.sort()

    logger = sys.stdout.write; cloself = False       
    ctdict = defaultdict(int)
    
    for f in files[20:21]:
        proctxts = pickle.load(open(f, 'rb'))
        for t, tp in enumerate(proctxts):
            if not tp:
                continue
            docid, proctxt = tp
            if (not docid) or (not proctxt): # no docid typically the header from pandas.
                continue

            print phraseAnalysis(proctxt, hr)