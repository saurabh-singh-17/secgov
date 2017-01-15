# -*- coding: utf-8 -*-
"""
Created on Mon Sep  1 07:34:33 2014

@author: vh
"""

from collections import defaultdict
from Resources import RESKEY_NEGATORS, RESKEY_SMILEYS
from clause_props import questionsInProcTxt
#from chunk_pols import getChunkPolarity, updateChunkPolarities
from appDefs import *
#from token_properties import tokenLexicalProps, updateTokenLexicalProperties
from processText import updateTokenAndChunkProperties

_ENUM_CONJ_ = set(["or", "and", "&"])

#def negateDegenClause(clause, hr, negators=None, pols=[], negn=[], chPat=[],  logger=None):
def negateDegenClause(clause, hr, pols=[], negn=[], chPat=[],  logger=None):
    """
    """
    if not chPat:
        chPat = [chunk.chunkType for chunk in clause]

    nchunks = len(chPat)
    vpCount = chPat.count('VP')

#    if not (pols or negn):
#        #cpnLst = [getChunkPolarity(chunk, hr, negators, logger) for chunk in clause]
#        cpnLst = [getChunkPolarity(chunk, hr, logger) for chunk in clause]
#    if not pols:
#        pols = [cpn['pol'] for cpn in cpnLst]
#    if not negn:
#        negn = [cpn['negn'] for cpn in cpnLst]

    if not (pols or negn):
        pols = [chunk.chPol for chunk in clause]
        negn = [chunk.hasNegator for chunk in clause]
    
    negd = [False]*len(clause)

    ## ********************************************************************
    ## initial scope of the negator.
    ## from the negator to next negator, or end of clause.
    ## pols = [0, -1, -1, -1, 2, 1, 0], negn = [1,  0,  0,  0, 1, 0, 1]
    ## begidx = [0, 4, 6], endidx = [4, 6, 7]
    begidx = [i for i, neg in enumerate(negn) if neg != 0]
    endidx = []
    if begidx:
        endidx = [i for i in begidx[1:]]
        endidx.append(len(negn))
    ## *********************************************************************

    for beg, end in zip(begidx, endidx):
        negatedBeg = beg
        negatedEnd = end

        if clause[beg].chunkType == 'NP':
            if vpCount == 0: #no survivors in this disaster
                negatedEnd = beg + 1
            else:
                if beg < nchunks -1 and clause[beg+1].chunkType != 'NP':
                    negatedEnd = end
                else:
                    negatedEnd = beg + 1
        else:
        #if clause[newEnd].chunkType not in ['VP','NP', 'PP', 'ADVP', 'ADJP']
            if any([tok in ["don't", "dont"] for tok in clause[beg].tokens]):
                continue
            if len(clause[beg].tokens) > 1:
                negatedBeg = beg + 1

            for k in range(negatedBeg, end):
                chunk = clause[k]
                if chunk.tags[0] == '&' and 'but' in chunk.tokens:
                    negatedEnd = k
                    break
                elif clause[k].chunkType == 'NONE' and clause[k].tags[0] == 'E': #not in ['VP','NP', 'PP', 'ADVP', 'ADJP']: #no smileys, interjections.
                    negatedEnd = k
                    break
                elif clause[k].chunkType == 'INTJ': #not in ['VP','NP', 'PP', 'ADVP', 'ADJP']: #no smileys, interjections.
                    negatedEnd = k
                    break
                elif k > negatedBeg and clause[k].chunkType == 'VP': # and not 'to' in clause[k].tokens:
                    negatedEnd = k -1
                    break

        for k in range(negatedBeg, negatedEnd):
            negd[k] = True

    return negd

_WSD_WORKLST = set(['work', 'works', 'working', 'worked'])
_WSD_PRONOUNLST = set(['i', 'we', 'they', 'he', 'she', 'myself', 'themselves'])
_WSD_NEEDLST = set(['need', 'needs', 'wish' , 'looking'])
def wsd(clause, hr, chPat, pols, negn, logger=None):
    idx = chPat.index('VP')
    nchunks = len(chPat)
    for tok in _WSD_WORKLST:
        if tok in clause[idx].tokens:
            if idx > 0:
                if chPat[idx-1] == 'NP':
                    for tok in clause[idx-1].tokens:
                        if tok in _WSD_PRONOUNLST:
                            pols[idx] = 0
                            break

    for k, chunk in enumerate(clause):
        if chunk.chunkType == 'VP':
            if any([tok in chunk.tokens for tok in _WSD_NEEDLST]):
                for n, tc in enumerate(clause[k:]):
                    if pols[k+n] > 0:
                        pols[k+n] = 0

    return pols
#                print clause[idx-1].tokens, clause[idx-1].tags


def clausePolarity(clause, hr, logger=None):
    chPat = [chunk.chunkType for chunk in clause]
    vpCount = chPat.count('VP')
    #negators = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)
    #cpp = [getChunkPolarity(chunk, hr, negators) for chunk in clause]

    pols = [chunk.chPol for chunk in clause]
    negn = [chunk.hasNegator for chunk in clause]
    
    #making the NP polarity as negative if the proceeding VP has an auxilary
    #verb and is having a negative polarity
    for ind,phrase in enumerate(clause):
        if phrase.tprops[0].has_key("AUXVERB") and ind > 0:
            if phrase.chPol < 0 and clause[ind-1].chunkType == "NP" and pols[ind-1] >= 0:
                pols[ind-1] = -1       
            elif ind < clause.__len__()-1:
                if clause[ind+1].chPol < 0 and clause[ind-1].chunkType == "NP" and pols[ind-1] >= 0:
                    pols[ind-1] = -1
            break        
        if phrase.chPol < 0  and negn[ind] == 0 and ind > 1 and ind < clause.__len__()-3:
            if clause[ind+2].chunkType == "NP" and clause[ind+2].chPol >= 0 and pols[ind+2] >= 0:
                pols[ind+2] = -1
            break    
        if phrase.chunkType in ["VP","ADJP","ADVP"] and phrase.chPol < 0 and ind>0 and clause[ind-1].chunkType == "NP":
            pols[ind-1] = -1
        if phrase.chunkType in ["VP","ADJP","ADVP"] and phrase.chPol < 0 and ind < clause.__len__()-2 and clause[ind+1].chunkType == "NP":
            pols[ind+1] = -1
#    cpp = [getChunkPolarity(chunk, hr) for chunk in clause]
#    pols = [cp['pol'] for cp in cpp]
#    negn = [cp['negn'] for cp in cpp]

    if vpCount > 0:
        pols = wsd(clause, hr, chPat, pols, negn, logger=None)
    if vpCount == 0:
        negtd = negateDegenClause(clause, hr) #, negators)
    elif vpCount == 1:
        negtd = negateDegenClause(clause, hr) #, negators)
    else:
        negtd = negateDegenClause(clause, hr) #, negators)

    return (chPat, pols, negn, negtd)

TPC_CHUNKTYPES = ['NP', 'VP', 'PP', 'ADJP', 'ADVP', 'NONE', 'INTJ']
TPC_POLTYPES = ['+N', '+P', '+U']
TPCCS_CTYP = ['NP', 'VP', 'PP', 'ADJP', 'ADVP', 'NONE', 'INTJ']
TPCCS_POLS = [-1, 1, 0]
TPCCS_NGTR = [1, 0]
TPCCS_NGTD = [1, 0]
TPCCS_ISQ = [1, 0]
TPCCS = [TPCCS_CTYP,TPCCS_POLS,TPCCS_NGTR, TPCCS_NGTD, TPCCS_ISQ]

import itertools
TPPC_CTYP = ['NP', 'VP', 'PP', 'ADJP', 'ADVP'] #, 'NONE', 'INTJ']
#TPPC_POLS = [-1, 1, 0]
TPPC_POLS = [-1, 1]

_TPC_CANTLST = set(["can't", "cant", "cannot"])
def postPolInClause(procTxt, hr, logger=None):

    clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
    isq = questionsInProcTxt(procTxt)
    txtPostPol = []
    for k, sentence in enumerate(clausedSentences):

        senPostPol = []
        senchPat = []
        for n, clause in enumerate(sentence):
            chPat, pols, negn, negtd = clausePolarity(clause, hr, logger)
            postPol = [cmp(pol,0) for pol in pols]
            isQ = False
            senchPat.append(chPat)

            isQ = any(isq[k].values())

            tsp = []
            nchunks = len(chPat)
            for m, ng in enumerate(negtd):
                if chPat[m] == 'NONE':
                    postPol[m] = 0
                    if n > 0 and '&' in clause[m].tags and 'but' in clause[m].tokens:
                        tsp.append([chPat[m], postPol[m]])
                        for i, spp in enumerate(senPostPol[:n]):
                            for j, pp in enumerate(spp):
                                senPostPol[i][j][1] = 0
                    continue
                
                if chPat[m] == 'INTJ':
                    tsp.append([chPat[m], postPol[m]])
                    continue

                if clause[m].chunkType == 'VP':
                    if any([tok in _TPC_CANTLST for tok in clause[m].tokens]):
                        if "wait" in clause[m].tokens:
                            if (m == 0) or ( m > 0 and clause[m-1].chunkType in ['NONE', 'INTJ']): #
                                #print clause
                                postPol[m] = 1
                                cado = 1
                    elif any([tok in ["don't", "dont"] for tok in clause[m].tokens]):
                        if postPol[m] > 0:
                            postPol[m] = -1*postPol[m]

                if (not isQ) :
                    if ng:
                        postPol[m] = -1*postPol[m]
                    if m == nchunks-1 or (m == nchunks-2 and chPat[m+1] == 'NONE'):
                        if postPol == 0 and (negn[m] or ng): #((not 'NP' in chPat) and (ng)):
                            postPol[m] = -1
                else:
                    if postPol[m] > 0:
                        postPol[m] = 0
                        
                tsp.append([chPat[m], postPol[m]])

            senPostPol.append(tsp)
        txtPostPol.append(senPostPol)
    return txtPostPol
            
def txtPosteriorPolarChunks(procTxt, hr, logger=None):

#    try:
#        procTxt[PTKEY_CHUNKEDCLAUSES][0][0][0].tprops
#    except:
#        procTxt = updateTokenLexicalProperties(procTxt, hr)

    #procTxt = updateChunkPolarities(procTxt, hr)
    clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
    #keys = list(itertools.product(*TPCCS))
    keys = ['_'.join(map(str,key)) for key in list(itertools.product(*[TPPC_CTYP, TPPC_POLS]))]
    cpdict = {key:0 for key in keys}

    isq = questionsInProcTxt(procTxt)

    for k, sentence in enumerate(clausedSentences):

        senPostPol = []
        senchPat = []
        for n, clause in enumerate(sentence):
            chPat, pols, negn, negtd = clausePolarity(clause, hr, logger)
            postPol = [cmp(pol,0) for pol in pols]
            isQ = False
            senchPat.append(chPat)

            isQ = any(isq[k].values())

            tsp = []
            nchunks = len(chPat)
            for m, ng in enumerate(negtd):
                if chPat[m] == 'NONE':
                    postPol[m] = 0
                    if n > 0 and '&' in clause[m].tags and 'but' in clause[m].tokens:
                        tsp.append([chPat[m], postPol[m]])
                        for i, spp in enumerate(senPostPol[:n]):
                            for j, pp in enumerate(spp):
                                senPostPol[i][j][1] = 0
                    continue
                
                if chPat[m] == 'INTJ':
                    tsp.append([chPat[m], postPol[m]])
                    continue

                if clause[m].chunkType == 'VP':
                    if any([tok in _TPC_CANTLST for tok in clause[m].tokens]):
                        if "wait" in clause[m].tokens:
                            if (m == 0) or ( m > 0 and clause[m-1].chunkType in ['NONE', 'INTJ']): #
                                #print clause
                                postPol[m] = 1
                                cado = 1
                    elif any([tok in ["don't", "dont"] for tok in clause[m].tokens]):
                        if postPol[m] > 0:
                            postPol[m] = -1*postPol[m]

                if (not isQ) :
                    if ng:
                        postPol[m] = -1*postPol[m]
                    if m == nchunks-1 or (m == nchunks-2 and chPat[m+1] == 'NONE'):
                        if postPol == 0 and (negn[m] or ng): #((not 'NP' in chPat) and (ng)):
                            postPol[m] = -1
                else:
                    if postPol[m] > 0:
                        postPol[m] = 0



#                if chPat.count('VP') == 1:
#                    vpidx = chPat.index('VP')
#                    if postPol[vpidx] < 0:
#                        for i, pp in enumerate(postPol[vpidx+1:]):
#                            if pp > 0:
#                                postPol[i] = -1
                tsp.append([chPat[m], postPol[m]])

            senPostPol.append(tsp)
                #key = 'CTYPE:%s_POSTPOL:%d' % (chPat[m], postPol[m])


        for i, spp in enumerate(senPostPol):
            for j, pp in enumerate(spp):
                if not (pp[0] in ["NONE", "INTJ"]):
                    if pp[1] != 0:
                        key = '_'.join(map(str,(pp[0], cmp(pp[1],0))))
                        cpdict[key] += 1


#            for c, typ in enumerate(chPat):
#                key = 'CTYP:%s_POL:%d_NGTR:%s_NGTD:%s' % (typ, pols[c], negn[c], negtd[c])
#                key = '_'.join(map(str,(typ, cmp(pols[c],0), int(negn[c]), int(negtd[c]))))
#                cpdict[key] += 1

    return cpdict

def countPosteriorPolarChunks(procTxt, hr, featureVals={}, FKEY='countPosteriorPolarChunks'):
    """
    PosteriorPolarChunks
    """
    #if haskey(featureVals, FKEY): return featureVals
    if FKEY in featureVals:
        return featureVals

    featureVals[FKEY] = txtPosteriorPolarChunks(procTxt, hr)
    return featureVals

def netPosteriorPolarChunks(procTxt, hr, featureVals={}, FKEY='netPosteriorPolarChunks'):
    """
    netPosteriorPolarChunks
    """
    #if haskey(featureVals, FKEY): return featureVals
    if FKEY in featureVals:
        return featureVals

    if not FKEY in featureVals:
        vals = txtPosteriorPolarChunks(procTxt, hr)
    
    polarChunks = 0
    for key,val in vals.iteritems() :
        if '_1' in key:
            polarChunks += val
            #print key, val, polarChunks
        elif '_-1' in key:
            polarChunks += -val
            #print key, val, polarChunks

    #polarChunks = [v if not '+U' in k]
    #URL = 'U' in procTxt['tags']
    if polarChunks < 0:
        featureVals[FKEY] = -1 #'-1+%s' % URL #-1
    elif polarChunks > 0:
        featureVals[FKEY] = 1 #'1+%s' % URL #1
    else:
        featureVals[FKEY] = 0 #'0+%s' % URL #0
    #featureVals[FKEY] = sign(polarChunks) #sum(pola#rChunks)
    return featureVals

def txtPolarityByChunksInClausedSentences(clausedSentences, hr, logger=None):
    #keys = list(itertools.product(*TPCCS))
    keys = ['_'.join(map(str,key)) for key in list(itertools.product(*TPCCS))]
    cpdict = {key:0 for key in keys}

    for k, sentence in enumerate(clausedSentences):
        for n, clause in enumerate(sentence):
            chPat, pols, negn, negtd = clausePolarity(clause, hr, logger)
            isQ = 0
            if chPat[-1] == 'NONE' and clause[-1].tags[-1] == ',' and '?' in clause[-1].tokens[0]:
                isQ = 1
            for c, typ in enumerate(chPat):
                #key = 'CTYP:%s_POL:%d_NGTR:%s_NGTD:%s' % (typ, pols[c], negn[c], negtd[c])
                key = '_'.join(map(str,(typ, cmp(pols[c],0), int(negn[c]), int(negtd[c]), isQ)))
                cpdict[key] += 1

    return cpdict

## *********************************************************************
def countPolarChunksInClausedSentences(procTxt, hr, featureVals={}, FKEY='countPolarChunksInClausedSentences'):
    """
    countPolarChunksInClausedSentences
    """
    if haskey(featureVals, FKEY): return featureVals

    featureVals[FKEY] = txtPolarityByChunksInClausedSentences(procTxt[PTKEY_CHUNKEDCLAUSES], hr)
    return featureVals

TPC_CHUNKTYPES = ['NP', 'VP', 'PP', 'ADJP', 'ADVP', 'NONE', 'INTJ']
TPC_POLTYPES = ['+N', '+P', '+U']
def txtPolarityByChunks(chunkedSentences, hr):
    cpdict = {chtype + pol:0 for chtype in TPC_CHUNKTYPES for pol in TPC_POLTYPES}
    for chunkedSentence in chunkedSentences:
        for chunk in chunkedSentence:
            cpp = getChunkPolarity(chunk, hr)['pol']
            if cpp < 0:
                cpdict[chunk.chunkType + TPC_POLTYPES[0]] += 1
            elif cpp > 0:
                cpdict[chunk.chunkType + TPC_POLTYPES[1]] += 1
            else:
                cpdict[chunk.chunkType + TPC_POLTYPES[2]] += 1
    return cpdict

##############################################################################
## FEATURES
##############################################################################
from utils_features import haskey
def countPolarChunks(procTxt, hr, featureVals={}, FKEY='countPolarChunks'):
    """
    Count Polar Chunks
    """
    if haskey(featureVals, FKEY): return featureVals

    featureVals[FKEY] = txtPolarityByChunks(procTxt['chunkedSentences'], hr)

    return featureVals

def netPolarChunks(procTxt, hr, featureVals={}, FKEY='netPolarChunks'):
    """
    Count Polar Chunks
    """
    if haskey(featureVals, FKEY): return featureVals

    vals = txtPolarityByChunks(procTxt['chunkedSentences'], hr)
    polarChunks = 0



    for key,val in vals.iteritems() :
        if '+P' in key:
            polarChunks += val
            #print key, val, polarChunks
        elif '+N' in key:
            polarChunks += -val
            #print key, val, polarChunks

    #polarChunks = [v if not '+U' in k]
    if polarChunks < 0:
        featureVals[FKEY] = -1
    elif polarChunks > 0:
        featureVals[FKEY] = 1 #'1+%s' % URL
    else:
        featureVals[FKEY] = 0 #'0+%s' % URL
    #featureVals[FKEY] = sign(polarChunks) #sum(polarChunks)
    return featureVals



if __name__ == "__main__":

    from config import MC_DATA_HOME, MC_LOGS_HOME
    from config import DEFAULT_HR_FILE, KEY_NEGATION
    from config import PTKEY_CHUNKEDCLAUSES, PTKEY_CHUNKEDSENTENCES
    from Resources import RESKEY_NEGATORS
    from collections import defaultdict
    import cPickle as pickle
    ptfname = MC_DATA_HOME + 'evaldata/data_merged_2854_test.proctxts' #'data_semeval_6399_train.proctxts'
    #ptfname = MC_DATA_HOME + 'AttensityTestData.proctxts'
    #ptfname = MC_DATA_HOME + 'cmpdata/data_eval_merged.proctxts'
    ptfname = MC_DATA_HOME + 'ptd/coechatsamples.proctxts' 
    procTxtLst = pickle.load(open(ptfname, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))

    logfile = open(MC_LOGS_HOME + 'SVClause' + '.txt', 'w')
    logger = logfile.write
    negators = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)

    svdict = defaultdict(int)

    for tw, procTxt in enumerate(procTxtLst):
        procTxt = updateTokenAndChunkProperties(procTxt, hr)
        
        clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
        txtPosteriorPolarChunks(procTxt, hr)
        for sentence in clausedSentences:
            for clause in sentence:
                chPat, pols, negn, negtd = clausePolarity(clause, hr, logger)

#                chPat = []
#                for chunk in clause:
#                    if chunk.chunkType == 'NONE':
#                        key = '%s%s' % (chunk.chunkType, chunk.tags)
#                    else:
#                        key = chunk.chunkType
#                    chPat.append(key)
#
#                #chPat = [chunk.chunkType for chunk in clause]
#                if chPat.count('VP') == 1:
#                    chPat, pols, negn, negtd = clausePolarity(clause, hr, logger)
#                    if any(negn):
#                        for c, chunk in enumerate(clause):
#                            logger('%d\t%s\t%s\t%s\n' % (pols[c], negn[c], negtd[c], chunk))
##                    #logger('%s\n' % pols)
##                    logger('%s\n' % negn)
##                    logger('%s\n\n' % negtd)
#                        logger('\n')
#

#                key = ' '.join(chPat)
#                svdict[key] += 1

#        key = len(clausedSentences)
#        if key == 3:
#            print clausedSentences
#        svdict[key] += 1

#    for k, v in svdict.iteritems():
#        logger('%s\t%d\n' % (k,v))

    logfile.close()
#        csentences = procTxt[PTKEY_CHUNKEDSENTENCES]
#        #print netPolarChunks(procTxt, hr, featureVals = {}, FKEY = 'netPolarChunks')
#
#        aa = txtPosteriorPolarChunks(clausedSentences, hr, logger=None)
#
##        for k, sentence in enumerate(clausedSentences):
##            for n, clause in enumerate(sentence):
##                logger('%d-%d\n' % (k,n))
##                clausePolarity(clause, hr, logger)
##                logger('--\n')
##        for k, sentence in enumerate(csentences):
##            print sentence
##            for chunk in sentence:
##                getChunkPolarity(chunk, hr)
