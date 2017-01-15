# -*- coding: utf-8 -*-
"""
Created on Fri Nov 14 06:31:35 2014

@author: vh
"""
from Resources import RESKEY_DOMAIN_NOUNS
from clause_pol import clausePolarity
from phrase_analysis2 import extract_words
from clause_properties import degenerateClauseAnalysis, clauseVPAnalysis 
from clause_props import questionsInProcTxt
from collections import defaultdict     
from processText import updateTokenAndChunkPropertiesPD   
from config import *   
from collections import OrderedDict
def hasDomainNoun(chunkList, domainNouns):
    """
    Identify the domain nouns in a chunklist such as a clause or sentence.
    returns the indices of the chunks in chunklist containing the domaining nouns
    """
    #domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    hasDN = [] #[0]*len(chunkList)
    hasDN_append = hasDN.append
    for h, chunk in enumerate(chunkList):
        for t, tok in enumerate(chunk.tokens):
            if tok in domainNouns:
                hasDN_append(h)
    return hasDN

def hasNoun(chunkList):
    """
    Identify the domain nouns in a chunklist such as a clause or sentence.
    returns the indices of the chunks in chunklist containing the domaining nouns
    """
    #domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    hasN = [] #[0]*len(chunkList)
    hasN_append = hasN.append
    for h, chunk in enumerate(chunkList):
        for t, tag in enumerate(chunk.tags):
            if tag in ['N', '@', '#', 'Z', '^']:
                hasN_append(h)
    return hasN

def ppd_degenerateClause(clause, clpols, vpidx, hr): #(chunkList, hr):
    """ 
    """
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    ndn = defaultdict(list)
    dnChunksIdx = hasDomainNoun(clause, domainNouns)
    nChunksIdx = hasNoun(clause)
    
    nChunksIdx = list(set((nChunksIdx + dnChunksIdx)))
    
    if not nChunksIdx:
        return ndn
    
    allNeutral = True
    for pol in clpols:
        if pol[0]:
            allNeutral = False
            break
    
    noNegation = True
    for ng in clpols:
        if ng[1]:
            noNegation = False
            break   
    
    if allNeutral and noNegation:
        return ndn

    dn = [ k in nChunksIdx for k, ch in enumerate(clause)]
    tndn = []
    for h, chunk in enumerate(clause):
        pols = clpols[h]
        if pols[0] < 0: # and not negtd[h]:
            tndn.append((chunk, clpols[h], dn[h]))#(h)
        elif pols[0] > 0:  #and negtd[h]:
            tndn.append((chunk, clpols[h], dn[h]))#(h)
        elif pols[1]:
            tndn.append((chunk, clpols[h], dn[h]))#(h)
        elif dn[h]:
            tndn.append((chunk, clpols[h], dn[h]))#(h)
    ndn['LHS'] = tndn                 
    return ndn
    
from collections import Counter


_PPD_AUX = set(['need', 'would', 'would_NG_like', 'want', 'hope', 'hoping', 'needed', 'wanted', 'tryna', 'trying', 'tryin', 'showed_NG_up'])
_PPD_AUX_PART = set(['to'])
_PPD_ACTVRB = set(['reset', 'log', 'pay', 'enter', 'set', 'delete', 'alter', 'change', 'cancel', 'request', 'register', 'apply', 'get', 'access'])

def ppd_SVClause(clause, clpols, vpidx, hr):
    """ 
    clpols = (pols[k], negn[k], negtd[k])
    """
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    ndn = defaultdict(list)
    dnChunksIdx = hasDomainNoun(clause, domainNouns)
    nChunksIdx = hasNoun(clause)
    
    nChunksIdx = list(set((nChunksIdx + dnChunksIdx)))
    
    if not nChunksIdx:
        return ndn
    
    allNeutral = True
    for pol in clpols:
        if pol[0]:
            allNeutral = False
            break
    
    noNegation = True
    for ng in clpols:
        if ng[1]:
            noNegation = False
            break   

    PPD_ATTEMPT =False
    for h, chunk in enumerate(clause):
        if chunk.chunkType == 'VP':
            hasPPDAUX = None
            for t, tok in enumerate(chunk.tokens):
                if tok in _PPD_AUX:
                    hasPPDAUX = t
                    break
               
            if hasPPDAUX != None: 
                    PPD_ATTEMPT = True
                        
    if (not PPD_ATTEMPT) and (allNeutral and noNegation):
        return ndn
    
    clLabels = ['LHS', 'VP', 'RHS']
    clauseBranches = [clause[:vpidx], [clause[vpidx]], clause[vpidx+1:]]
    clauseBranchPols = [clpols[:vpidx], [clpols[vpidx]], clpols[vpidx+1:]]
    isdn = [ k in nChunksIdx for k, ch in enumerate(clause)]
    isdn = [isdn[:vpidx], [isdn[vpidx]], isdn[vpidx+1:]]
    
    for c, clauseBranch in enumerate(clauseBranches):
        pols = clauseBranchPols[c]
        dn = isdn[c]
        tndn = []
        for h, chunk in enumerate(clauseBranch):
            if pols[h][0] < 0: # and not negtd[h]:
                tndn.append((chunk, pols[h], dn[h]))
            elif pols[h][0] > 0:  #and negtd[h]:
                if c == 0:
                    pols[h][0] = 0
                tndn.append((chunk, pols[h], dn[h]))
            elif pols[h][1]:
                tndn.append((chunk, pols[h], dn[h]))
            elif dn[h]:
                tndn.append((chunk, pols[h], dn[h]))
            elif chunk.chunkType == 'VP':
                hasPPDAUX = None
                for t, tok in enumerate(chunk.tokens):
                    if tok in _PPD_AUX:
                        ntoks = len(chunk.tokens)
                        if t < ntoks-1:
                           hasPPDAUX = t
                           break
#                hasPPDACTVRB = None
#                for t, tok in enumerate(chunk.tokens):
#                    if tok in _PPD_ACTVRB:
#                        hasPPDACTVRB = t
#                        break                        
                if hasPPDAUX != None: # and hasPPDACTVRB != None:
#                    print clause
#                    if hasPPDACTVRB > hasPPDAUX:
                    tndn.append((chunk, pols[h], dn[h]))
#                        print hasPPDAUX #, hasPPDACTVRB
#                        print chunk
#                        print tndn
                
        ndn[clLabels[c]] = tndn  
       
    return ndn

def ppd_MVClause(clause, clpols, vpfIdxs, hr):
#    print vpIdx
    
    vpidxs = [vp[1] for vp in vpfIdxs]
    triples = [[vpf, clpols[k], int(k in vpidxs)] for k, vpf in enumerate(clause)]
    
    splittriples = [triples[i:j] for i, j in zip([0]+ [f+1 for f in vpidxs[:-1]], vpidxs[1:]+[None])]
    
    svClauses = [[t[0] for t in tri] for tri in splittriples]
    svPols = [[t[1] for t in tri] for tri in splittriples]
    isvp = [[t[2] for t in tri] for tri in splittriples]

    clause_problem = []
    for k, svc in enumerate(svClauses):
        svp = svPols[k]
        vpidx = isvp[k].index(1)
        frac_problem = ppd_SVClause(svc, svp, vpidx, hr)
        clause_problem.append(frac_problem)
    
    return clause_problem
    
import itertools
PD_LOC = ['LHS', 'VP', 'RHS']
PD_CTYP = ['NP','ADJP','ADVP','VP', 'INTJ', 'NONE', 'PP']
PD_POLS = [-1, 0, 1]
PD_NEGN = [0, 1]
PD_NEGD = [0, 1]
PD_DN = [0,1]
_ATT_VALID_TAGS = set(('@', '^', 'Z', 'N'))

def problemPhraseAnalysis(procTxt, hr):
    """ """
    
    procTxt = updateTokenAndChunkPropertiesPD(procTxt, hr)    
    problems = []
    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
        sentence_problem = []               
        for c, clause in enumerate(sentence):
            clause_problem = defaultdict(list) 
            n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
            chPat, pols, negn, negtd = clausePolarity(clause, hr)
            pols = [cmp(pol,0) for pol in pols]
            clpol = [[p, int(n), int(t)] for p,n,t in zip(pols, negn, negtd)]
            if n_vp == 0:
                clause_problem = ppd_degenerateClause(clause, clpol, vpidx, hr)
                clause_problems = [clause_problem]
            elif n_vpfinite < 2: 
                clause_problem = ppd_SVClause(clause, clpol, vpidx, hr)
                clause_problems = [clause_problem]
            else:
                clause_problems = ppd_MVClause(clause, clpol, vpidx, hr)
            sentence_problem.append(clause_problems)
        problems.append(sentence_problem)
        
    return problems
           
           
def problemContextDetector(procTxt, hr):
    problem_context_dm=[]
    problem_context=[]
    problems=problemPhraseAnalysis(procTxt,hr)
    for problem in problems:
        for current_problems in problem:
            for current_problem in current_problems:
                for key in current_problem:
                    for phrase in current_problem[key]:
                        for ind,token in enumerate(phrase[0].tokens):
                            if (phrase[1][0] == -1 and (phrase[1][2] - phrase[1][1]) <= 0) or ((phrase[1][2] - phrase[1][1]) > 0) or (phrase[1][0] == 0 and phrase[1][1] == 1):
                                if token in hr.resources["domain_nouns"]:
                                    problem_context_dm.append(" ".join(phrase[0].tokens))
                                    break
                                elif phrase[0].tags[ind] in ["N","Z"]:
                                    problem_context.append(" ".join(phrase[0].tokens))
                                    break
    return(list(set(problem_context_dm)),list(set(problem_context)))


def inducedChunkPolarity(procTxt, hr):
    indSentiment=[]
    allPhrase=[]
    problems=problemPhraseAnalysis(procTxt,hr)
    for problem in problems:
        for current_problems in problem:
            for current_problem in current_problems:
                for key in current_problem:
                    for phrase in current_problem[key]:
                        od=OrderedDict()
                        entity=""
                        for ind,toks in enumerate(phrase[0].tokens):
                            if phrase[0].tags[ind] in ['N', '@', '#', 'Z', '^']:
                                if ind > 0:
                                    entity=" ".join((entity,"/".join((toks,phrase[0].tags[ind]))))
                                else:
                                    entity="/".join((toks,phrase[0].tags[ind]))
                        od["entity"]=entity
                        od["phrase"]=str([phrase[0]])[4:-2]
                        if entity and od["phrase"] not in allPhrase:
                            allPhrase.append(phrase[0])
                            if (phrase[1][0] == -1 and (phrase[1][2] - phrase[1][1]) <= 0) or ((phrase[1][2] - phrase[1][1]) > 0) or (phrase[1][0] == 0 and phrase[1][1] == 1):
                                od["sentiment"]="Negative"
                            else: 
                                od["sentiment"]="Positive"
                            indSentiment.append(od)
    return(indSentiment)
                                
            
                         
def problemPhraseBases(procTxt, hr, featureVals = {}, FKEY = 'problemPhraseBases'):
#    keys = ['_'.join(map(str,key)) for key in list(itertools.product(*[
#        PD_LOC, PD_CTYP, PD_POLS, PD_NEGN, PD_NEGD, PD_DN]))]
#    cpdict = {key:0 for key in keys}    
    
    cpdict = {'HAS_PROB_CLAUSE':False}
    problems = problemPhraseAnalysis(procTxt, hr)
    for s, sentence_problems in enumerate(problems):               
        for c, clause_problems in enumerate(sentence_problems):
            for clause_problem in clause_problems:
                if clause_problem:
                    plist = []
                    for branch, phrase in clause_problem.iteritems():
                        plist.extend(phrase)
                    pols = [p[1] for p in plist]
                    postPols = [p[0] for p in pols]
                    
                    for k, pol in enumerate(pols):
                        if pol[1] == 0 and pol[2] == 1:
                            postPols[k] = -1*postPols[k]
                    
                    if sum(postPols) < 1:
                        cpdict['HAS_PROB_CLAUSE'] = True
    
    featureVals[FKEY] = cpdict 
    
    return featureVals           

def probPhrasePretty(procTxt, hr):
    problems = problemPhraseAnalysis(procTxt, hr)
    txtProblems = []
    for sentence_problems in problems:
        for clause_problems in sentence_problems:
            for clause_problem in clause_problems:
                lhs = [t[0] for t in clause_problem['LHS']]
                vp = [t[0] for t in clause_problem['VP']]
                rhs = [t[0] for t in clause_problem['RHS']]
                lhs = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in lhs] 
                vp = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in vp] 
                rhs = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in rhs] 
                
                problem = lhs+vp+rhs
                if problem:
                    txtProblems.append(' '.join(problem))
    return list(set(txtProblems))
                
#def pdAnalysis(procTxt, hr):
#    procTxt = updateTokenAndChunkPropertiesPD(procTxt, hr)
#    #isQ = questionsInProcTxt(procTxt, hr)
#    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]    
#    problemPhraseSV(procTxt, hr)
#     
#    
#    ppa = []
##    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):               
##        for c, clause in enumerate(sentence):
##            dn = hasDomainNoun(clause, domainNouns)
##            if not dn:
##                ppa.append([[],[],[]])
##                continue
##            
##            ndn = defaultdict(list)
##            n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
##            chPat, pols, negn, negtd = clausePolarity(clause, hr)
##            clpol = [(p, int(n), int(t)) for p,n,t in zip(pols, negn, negtd)]
##
##
##            if n_vp == 0 :
##                ndn['LHS'] = [(ch, clp) for ch, clp in zip(lhs, clpol)]
##            elif n_vp == 1 or n_vpfinite == 1:    
##                ndn['LHS'] = [ (ch, clp) for ch, clp in zip(lhs, clpol[:vpidx])]
##                ndn['RHS'] = [ (ch, clp) for ch, clp in zip(rhs, clpol[vpidx+1:])]
##                ndn['VP'] = [(vp, clpol[vpidx])]
##                
##            ppa.append(ndn)
#    return ppa
                
#    
#def problemPhraseAnalysis(procTxt, hr, featureVals = {}, FKEY = 'problemPhraseAnalysis'):
#    """
#    Negated Domain Nouns Feature
#    """ 
#    if haskey(featureVals, FKEY): return featureVals
#    ppa = pdAnalysis(procTxt, hr)
#    return featureVals 
        
        
        
if __name__ == "__main__":
    import sys
    from config import *
    import cPickle as pickle
    from collections import defaultdict, Counter
    from processText import updateTokenAndChunkPropertiesPD
    from clause_properties import clauseVPAnalysis
    dname = 'ptd/coechatsamples25'
    #dname = 'ptd/data_ptd_train'
    #dname = 'entityEval'
    toktagfilename = MC_DATA_HOME + dname + '.proctxts' #'dbg/data/cleanedupTestData.proctxts'
    procTxtLst = pickle.load(open(toktagfilename, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))


    logfile = open(MC_LOGS_HOME + 'ppdsv' + '.txt', 'w'); closelogger = True
    logger = logfile.write

    #logger = sys.stdout.write; closeLogger=False
    vpd = defaultdict(int)
    vpfd = defaultdict(int)
    nctot = 0
    nc = 0
    for t, procTxt in enumerate(procTxtLst):
        
         aa = problemPhraseBases(procTxt, hr)
         if aa['problemPhraseBases']['HAS_PROB_CLAUSE']:
             problems = probPhrasePretty(procTxt, hr)
             #problems = problemPhraseAnalysis(procTxt, hr)
             print problems
#             for sentence_problems in problems:
#                 for clause_problems in sentence_problems:
#                     for clause_problem in clause_problems:
#                         lhs = [t[0] for t in clause_problem['LHS']]
#                         vp = [t[0] for t in clause_problem['VP']]
#                         rhs = [t[0] for t in clause_problem['RHS']]
#                         lhs = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in lhs] 
#                         vp = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in vp] 
#                         rhs = [' '.join([' '.join(tok.split('_NG_')) for tok in ch.tokens]) for ch in rhs] 
#                         
#                         problem = '%s %s %s' % (lhs, vp, rhs)
#                         print problem
#             print '---'
        #ppa = pdAnalysis(procTxt, hr)
        #print ppa
#        procTxt = updateTokenAndChunkPropertiesPD(procTxt, hr)
#        isQ = questionsInProcTxt(procTxt, hr)
#        for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):               
#            for c, clause in enumerate(sentence):
#                nctot += 1
#                n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
#                chPat, pols, negn, negtd = clausePolarity(clause, hr)
#                
#                clpol = [(p, int(n), int(t)) for p,n,t in zip(pols, negn, negtd)]
#                
#                if n_vp == 1: #n_vp == 1 or n_vpfinite == 1:
#                    nc += 1
#                    ndn = ppd_SVClause(clause, clpol, vpidx, hr)
#                    
#                    logger('%d\n' % nc)
#                    clpols = clpol[:vpidx]
#                    clchunks = clause[:vpidx]
#                    logger('LHS %s\n' % (' '.join(['%s%s' % (cl,''.join(['%s' % p for p in pl])) for cl,pl in zip(clchunks, clpols)])))
#                    clpols = [clpol[vpidx]]
#                    clchunks = [clause[vpidx]]
#                    logger('VP %s\n' % (' '.join(['%s%s' % (cl,''.join(['%s' % p for p in pl])) for cl,pl in zip(clchunks, clpols)])))
#
#                    clpols = clpol[vpidx+1:]
#                    clchunks = clause[vpidx+1:]
#                    logger('RHS %s\n' % (' '.join(['%s%s' % (cl,''.join(['%s' % p for p in pl])) for cl,pl in zip(clchunks, clpols)])))
#
#                    ph = []
#                    for nn in ndn: 
#                        ph.append([n for n in nn])
#                    if ph:
#                        logger('PHR: %s ' % ph)
#                        
#                    logger('\n----\n')
##                    #print 'ID', [clause[t] for t in tndn]
##                    print '--'
#                     
#                    
##                    if ndn:
##                        print 'clause', ' '.join(['%s' % cl for cl in clause])
##                        print 'ppd', ndn
#                    
##                vpd[n_vp] += 1
##                vpfd[n_vpfinite] += 1
##                
##                if n_vpfinite == 1:
##                    ppd_SVClause(lhs, vp, rhs, hr)
##                    nc += 1

    if closelogger:
        logfile.close()



##
#def ppd_degenerateClause(chunkList, hr):
#    
#    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
#    dga = degenerateClauseAnalysis(chunkList, hr)
#    
#    for conjcl in dga:
#        for ppcl in conjcl:
#            chPat, pols, negn, negtd = clausePolarity(ppcl, hr)
#            dnChunks = hasDomainNoun(clause, hr)
#
##            if not dnChunks:
#            
#    dnChunks = [hasDomainNoun(cl, domainNouns) for ccl in dga for cl in ccl]
#    print chunkList
#    print dnChunks
#    
##    
##    clause = chunkList
##
##    ndn = []
##    chPat, pols, negn, negtd = clausePolarity(clause, hr)
##    dnChunks = hasDomainNoun(clause, hr)
##    
##    if not dnChunks:
##        return ndn
##    
##    allNeutral = True
##    for pol in pols:
##        if pol:
##            allNeutral = False
##            break
##    
##    noNegation = True
##    for ng in negn:
##        if ng:
##            noNegation = False
##            break   
##    
##    if allNeutral and noNegation: # no polarity detected.
##        return ndn
##    
##    degerenateClauseAnalysis(chunkList, hr)
##    
##    postPol = [cmp(pol,0) for pol in pols]
##    
##    #print ' '.join(['%s%d%d%d' % (cl, p, ng, ngt) for cl, p, ng, ngt in zip(clause, pols, negn, negtd)])
##    
###    postPol = 0
###    for k, pol in enumerate(pols):
###        if negn[k]:
###            print clause
##            
###        if negtd[k] and (not negn[k]):
###            postPol += -1*pol
###        else:
###            postPol += pol
###            
###    if postPol < 0:         
###        print ' '.join(['%s%d%d%d' % (cl, p, ng, ngt) for cl, p, ng, ngt in zip(clause, pols, negn, negtd)])            
####        for chunk in clause:
##
##    #negators, negated and polar domain nouns.   
##    
##    tndn =[]
##    for h, chunk in enumerate(clause):
##        if negn[h]:
##            tndn.append(chunk)
##            continue
##        if pols[h] < 0 and not negtd[h]:
##            tndn.append(chunk)
##            continue
##        if pols[h] > 0 and negtd[h]:
##            tndn.append(chunk)
##            continue
##        if h in dnChunks:
##            tndn.append(chunk)
##            continue
##    
###    if tndn:
###        print tndn
#
##    return ndn