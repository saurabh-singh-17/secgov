# -*- coding: utf-8 -*-
"""
Created on Sat Nov  8 05:35:27 2014

@author: vh
"""
from collections import Counter
from config import *
from token_properties import *
__STYPE_DG__ = 'degenerate'
__STYPE_SV__ = 'singleverb'
__STYPE_MV__ = 'multiverb'

DEGEN_CONJUNCTIONS = set(['but', 'yet'])
def degenerateClauseAnalysis(chunklist, hr, logger = None):
    """
    degenerate clause breakdown so as to localize the polarity for entities.
    #1. we can break degen clauses on conjunctions.
        for eg., 
        clause = [NP(5/$ bars/N), NONE(,/,), NP(3g/$ sign/N), NONE(n/&), ADVP(yet/R), NONE(-/,), NP(no/D internet_NG_connection/N), NONE(./,)]
        can be broken to list of conj clause lists
        conjClause = [[NP(5/$ bars/N), NONE(,/,), NP(3g/$ sign/N), NONE(n/&)], [ADVP(yet/R), NONE(-/,), NP(no/D internet_NG_connection/N), NONE(./,)]]
    #2. with such conj clauses break down on conjunctions.    
        [NP(no/D service/N aboveground/N), PP(at/P), NP(the/D jamba/^ juice/^), NONE(,/,), NONE(but/&), ADJP(underground/A), PP(on/P), NP(the/D subway/N platform/N solid/A coverage/N), NONE(./,)]
        -->cc [NP(no/D service/N aboveground/N), PP(at/P), NP(the/D jamba/^ juice/^), NONE(,/,)]
        -->-->pp [NP(no/D service/N aboveground/N)]
        -->-->pp [PP(at/P), NP(the/D jamba/^ juice/^), NONE(,/,)]
        -->cc [NONE(but/&), ADJP(underground/A), PP(on/P), NP(the/D subway/N platform/N solid/A coverage/N), NONE(./,)]
        -->-->pp [NONE(but/&), ADJP(underground/A), PP(on/P), NP(the/D subway/N platform/N solid/A coverage/N), NONE(./,)]        
    
    retval 
    dga = list of conjclauses
    conjclauses = list of pp clauses.
    for conjclause in dga:
        for ppclause in conjclause
    """
    ignoreThis = len(chunklist) == 1 and len(chunklist[0].tokens) == 1
    if logger and not ignoreThis:
        logger('%s\n' % ' '.join(['%s' % ch for ch in chunklist]))
        
    conjIdxs = [idx for idx, ch in enumerate(chunklist) 
        if ch.chunkType in ('NONE', 'ADVP') and ch.tags[0] in ('&', 'R') 
        and ch.tokens[0] in DEGEN_CONJUNCTIONS]
    
    conjClauses = [chunklist[i:j] for i, j in zip([0]+conjIdxs, conjIdxs+[None])]    
    
    dga = []
    for cc, conjClause in enumerate(conjClauses):
        chpat = [ch.chunkType for ch in conjClause]
        ppIdxs = [idx for idx, ch in enumerate(conjClause) 
            if ch.chunkType == 'PP' and ch.tokens[0] not in ('of', 'for') and 'NP' in chpat[:idx]]
        ppClauses = [conjClause[i:j] for i, j in zip([0]+ppIdxs, ppIdxs+[None])]        
        dga.append(ppClauses)
    
        if logger and not ignoreThis:        
            logger('CC-->: %s\n' % conjClause)
            for ppc in ppClauses:
                logger('PP---->: %s\n' % ppc)           

    if logger and not ignoreThis:    
        logger('---\n')
    
    return dga
   
def clauseVPAnalysis(listOfChunks):
    """ clause is a list of chunks """
    
    clause = listOfChunks
    vpChunks = [(ch, idx) for idx, ch in enumerate(clause) if ch.chunkType == 'VP']

    n_vp = len(vpChunks)
    #no VPs
    if not vpChunks:
        return (n_vp, 0, None, clause, [], [])
        #return __STYPE_DG__  
        
    #if the VP chunk contains atleast one finite token then split on it
    vpfinite = []
    for ch, idx in vpChunks:
        for tprop in ch.tprops:
            if tprop[TLP_V_FINITE]:
                vpfinite.append((ch, idx))
                break
    n_vpfinite = len(vpfinite)

    #single VP    
    if len(vpChunks) == 1:
        vpidx = vpChunks[0][1] #vpChunks is a list of (ch, idx) tuples
        lhs = clause[:vpidx]
        rhs = clause[(vpidx+1):]
        vp  = clause[vpidx]
        return (n_vp, n_vpfinite, vpidx, lhs, vp, rhs)
    
    #multiple VPs ()
    #case 1 multiple VPs no finite:
    #ex: [VP(having/V), NP(trouble/N), VP(logging/V), PP(in/P), NONE(./,)]
    #ex: [VP(just/R finished/V), NP(my/D), VP(paying/V), 
    #    NP(my/D installation/N fees/N)]
    #ex: [NP(the/D phone/N), VP(worked/V), PP(for/P), NP(one/$ day/N), 
    #   PP(before/P), NP(the/D dial_NG_tone/N), VP(disappeared/V), NONE(./,)]
    if not n_vpfinite:
        vpidx = vpChunks[0][1]
        lhs = clause[:vpidx]
        rhs = clause[(vpidx+1):]
        vp  = clause[vpidx]
        return (n_vp, n_vpfinite, vpidx, lhs, vp, rhs)

    elif n_vpfinite == 1:
        vpidx = vpfinite[0][1]
        lhs = clause[:vpidx]
        rhs = clause[(vpidx+1):]
        vp  = clause[vpidx]
        return (n_vp, n_vpfinite, vpidx, lhs, vp, rhs)
        
    elif n_vpfinite > 1:
                    
        lhs = [] #clause[:vpidx]
        rhs = [] #clause[(vpidx+1):]
        vp  = [] #clause[vpidx]
        if n_vpfinite == 0:
            vpp = vpChunks
        else:
            vpp = vpfinite
        return (n_vp, n_vpfinite, vpp, lhs, vp, rhs)
    else:
        print 'duh'
        
    return 0     
        
#        chPat = [ch.chunkType for ch in clause]
#        
#        beginIdx = None
#        #looking for relative pronouns and relative adverbs between to finite verbs.
#        isHead = [1]*len(vpfinite)       
#        for k, vpf in enumerate(vpfinite): #vpf is tuple (ch, idx)
#            thisChunk = vpf[0]
#            idxThisChunk = vpf[1]
#            #first check within the VP.
#            #e.g., (that is running)
#            #[NP(the/D guy/N), VP(that/P jus/R starts/V dancing/stepping/V), PP(in/P), NP(the/D middle/N), PP(of/P), NP(the/D train/N station/N), VP(iz/V), NP(funny/A a.f/N), NONE(!/,)]
#            #[NONE(but/&), NP(at&t's/Z internet/N), PP(to/P), NP(our/D studio/N), VP(is/V), ADJP(so/R slow/A), VP(that/P it's/L), ADJP(useless/A)]            
#            #[NP(the/D law/N), VP(that/P will/V make/V), NP(at&t/^), VP(pay/V), ADVP(almost/R), NONE($1/$), NONE(billion/$), PP(to/P), NP(consumers/N), NONE(-/,), NONE(__URL__/U)]            
#            #VP(do/V), NP(you/O), VP(know/V), NP(anyone/N), PP(w/P), NONE(n/&), NP(extra/A at&t/^ phone/N), VP(that/P works/V)            
#            
#            #index of finite verb token in the chunk
#            ift = [i for i, tp in reversed(list(enumerate(thisChunk.tprops))) if tp[TLP_V_FINITE]]
#            hasRelPronounInChunk = False
#            for tok in thisChunk.tokens[:ift[-1]]: #relative pronouns before the finite verb
#                if tok in set(['who', 'whom', "whose", "that", "which"]): 
#                    hasRelPronounInChunk = True
#                    isHead[k] = 0
#                    break
#            if hasRelPronounInChunk:
#                continue
##                elif tok in set(['when', 'where', 'why']):
##                    print vpf
##                    print clause
##            if idxThisChunk == 0:
##                vpidx = idxThisChunk #vpfinite[0][1]
##                lhs = clause[:vpidx]
##                rhs = clause[(vpidx+1):]
##                vp  = clause[vpidx]
##                return (n_vp, n_vpfinite, vpidx, lhs, vp, rhs)
#                
#           
#            #if not hasRelPronounInChunk: #check if relpronoun to the left.
#            if beginIdx is None:
#                beginIdx = 0
#            else:
#                beginIdx = vpfinite[k-1][1]
#                    
#            relChunks = clause[beginIdx:idxThisChunk]
#            
#            if k == 0:                
#                hasRelPronounChunks = False
#                for h, chunk in enumerate(relChunks):
#                    if (h!= 0 and chunk.chunkType == 'NP' and chunk.tags[0] in ['O'] and chunk.tokens[0] in set(['who', 'whom', "whose", "that", "which"])):  
#                        hasRelPronounChunks = True
#                        break
##                if not hasRelPronounChunks:
##                    pass
##                    #print vpf, clause
##                else:
##                    print vpf, clause
#                    
#                    
##                print clause
##                print thisChunk, '-->', relChunks
##                print '---'
#            #for chunk in clause[begidx:vpf[1]]:
#                
#            
#        vpidx = vpfinite[isHead.index(1)][1]
#        
##        if n_vpfinite == 2: #vpidx == 2:
##            print clause
##        else:
##            print clause      
        
if __name__ == "__main__":
    from processText import updateTokenAndChunkProperties
    import sys
    from collections import defaultdict
    
    dname = 'ptd/coechatsamples25'
    #dname = 'ptd/data_ptd_train'
    dname = 'entityEval'
    toktagfilename = MC_DATA_HOME + dname + '.proctxts' #'dbg/data/cleanedupTestData.proctxts'    
    procTxtLst = pickle.load(open(toktagfilename, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))
    
    
    #logfile = open(MC_LOGS_HOME + 'sfinverbclauses' + dname + '.txt', 'w'); closelogger = True
    #logger = logfile.write
    
    logger = sys.stdout.write; closeLogger=False
    
    vpd = defaultdict(int)
    vpfd = defaultdict(int)
    yvpd = defaultdict(int)
    yvpfd = defaultdict(int)    
    ns  = 0
    
    nc = 0
    for t, procTxt in enumerate(procTxtLst):
        #print t
        procTxt = updateTokenAndChunkProperties(procTxt, hr)
        for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):   
            #n_vp, n_vpfinite, lhs, vp, rhs = clauseVPAnalysis(procTxt[PTKEY_CHUNKEDSENTENCES][s])
            for c, clause in enumerate(sentence):
                
                n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
#                if n_vp == 1 and n_vpfinite == 0:
#                    print clause
            
#                if n_vp == 0:
#                    degenerateClauseAnalysis(lhs, hr, logger)   
                if n_vpfinite > 1:
                    print vpidx
                    print len(vpidx)
                
#                if n_vp == 0 or n_vpfinite == 0 or n_vp == 1 or n_vpfinite == 1:
##                    if n_vp ==0 and n_vpfinite == 0
#
#                    nc+=1
##                    logger('CID: %d (%d-%d-%d)\n' % (nc,t,s,c))
##                    logger('LHS: %s\n' % ' '.join(['%s ' % l for l in lhs]))
##                    logger('VP: %s\n' % vp)
##                    logger('RHS: %s\n' % ' '.join(['%s ' % l for l in rhs]))
##                    logger('---\n')
#                    yvpd[n_vp] += 1
#                    yvpfd[n_vpfinite] += 1
##                    
##                if n_vpfinite == 5:
##                    print clause
#                    
#                vpd[n_vp] += 1
#                vpfd[n_vpfinite] += 1
#                ns += 1
#            
##            for c, clause in enumerate(sentence):
##                #st = sentenceType(clause)
##                vpa = clauseVPAnalysis(clause)
##                if vpa:
##                    logger('%d-%d-%d\n' % (t, s, c))
##                    logger('LHS: %s\n' % vpa[0])
##                    logger('VP: %s\n' % vpa[1])
##                    logger('RHS: %s\n' % vpa[2])
##                    logger('-----\n')
#                    
##                if st == __STYPE_MV__:
##                    logger('%s\n' % clause)
    
    if closeLogger:
        logfile.close()
            
        