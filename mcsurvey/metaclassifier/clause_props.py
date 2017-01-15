# -*- coding: utf-8 -*-
"""
Created on Sat Oct 25 08:44:01 2014

@author: vh
"""
from config import *
from processText import updateTokenAndChunkProperties
from token_properties import TLP_PLURAL, TLP_INDEF_PRONOUNS, TLP_DEF_NOUN, TLP_CONJ
from token_properties import TLP_AUXVERB, TLP_WHWORD, TLP_V_FINITE
from collections import Counter
#from chunk_pols import updateChunkPolarities

def isQuestionQM(chunkedClausedSentence):
    """Check if clause contains question mark"""
    #basically have to check the last tok of the last chunk of the last clause
    #but looping just to guard against sentencer redefinitions.
    #also mebbe to provide for any sylistic special cases in use of qm
    for c, clause in enumerate(chunkedClausedSentence):
        for h, chunk in enumerate(clause):
            for t, tok in enumerate(chunk.tokens):
                if '?' in tok:
                    return True
#                    if chunk.tags[t] == ',':
#                        return True
    return False


_SIEXCEPTIONS = {'do': ('i', 'you', 'u', 'we', 'they'),
                        'have' :('i', 'you', 'u', 'they', 'we'),
                        'had': ('i', 'you', 'u', 'we', 'they', 'she', 'he')
                        }
_SI_RELCHUNKS = set(['VP'])

def isQuestionSI(chunkedClausedSentence):

    #begins with e.g., will psu allow the stadium?
    firstClause = chunkedClausedSentence[0]

    chPat = [chunk.chunkType for chunk in firstClause]
    vpIdx = [k for k, chp in enumerate(chPat) if chp == 'VP']

    if not vpIdx: #no VPs, move on nothing to see here.
        return False

    #only the first VP counts.
    if vpIdx[0] != 0: #something before the first verb.
        npidx = []
        for chp in chPat[:vpIdx[0]]: #each chunk before the first verb
            if chp == 'NP':
                return False # has a subject already

    firstChunkofFirstClause = []
    fcfcProps = []
    prvChunk = None
    for idx, chunk in enumerate(firstClause[:-1]):
        if chunk.chunkType in _SI_RELCHUNKS and ((idx == 0) or (prvChunk.chunkType == PTKEY_CHUNKTYPE_NONE)): #['NONE', 'NP']:
            firstChunkofFirstClause = chunk
            nxtChunk = firstClause[idx+1]
            break
        else:
            prvChunk = chunk

    fcfc = firstChunkofFirstClause

    if fcfc and fcfc.chunkType == 'VP' and fcfc.tags.__len__() == 1:
        vptok = fcfc.tokens[0]
        vptag = fcfc.tags[0]
        vpProps = fcfc.tprops[0] #fcfcProps['tokProps'][0]
        if vptag == 'V' and vpProps[TLP_AUXVERB] == 1: #in vpProps vptok in __SI_AUX_VRBS__:

            if vptok in _SIEXCEPTIONS:
                if nxtChunk.tokens[-1] in _SIEXCEPTIONS[vptok]:
                    return True
                else:
                    return False

            if nxtChunk.chunkType == 'NP': #__SI_NP__:
                #npa = (vpProps[TLP_PLURAL], vpProps[TLP_INDEF_PRONOUNS], vpProps[TLP_DEF_NOUN], vpProps[TLP_CONJ])
                #if True in npa: #npa.itervalues():  #any(npa.values()):
                return True

    return False

WF_NOUNS = set(["any", "anybody", "anything", "anyone", "ne1", "ne"])

#__INTANAL_AUX_VRBS__ = ["are","is","was", "were", "can", "could", "do", "did", "does", "have", "has", "should", "would"]
#__INTANAL_AUX_VRBS__.extend( [w for wrd in __INTANAL_AUX_VRBS__ for w in [wrd+"'nt", wrd+"n't", wrd+"nt"] ])
#__INTANAL_AUX_VRBS__.extend(["wont", "wo'nt", "won't"])
#__INTANAL_AUX_VRBS__.extend(["am", "might", "must", "shall", "will", "would"])
#__INTANAL_AUX_VRBS__ = set(__INTANAL_AUX_VRBS__)
__INTANAL_2_MISCPATTERNS__ = ['else']

#__INTANAL_2_QWRDS__ = ['who', 'what', 'when', 'why', 'where', 'how']
#__INTANAL_2_QWRDS__.extend( [w for wrd in __INTANAL_2_QWRDS__ for w in [wrd+"'s", wrd+"z", wrd+"s"] ])
#__INTANAL_2_QWRDS__.extend(["whom"])
#__INTANAL_2_QWRDS__ = set(__INTANAL_2_QWRDS__)

#def isQuestionWF1(chunkedClausedSentence, chunkPropsLst):
def isQuestionWF(chunkedClausedSentence):
    for c, clause in enumerate(chunkedClausedSentence):
        for h, chunk in enumerate(clause):
            whrds = [(idx, chunk.tokens[idx]) for idx, tp in enumerate(chunk.tprops) if tp[TLP_WHWORD]]
            if not whrds:
                continue

            nchunks = len(clause)
            ntoks = len(chunk.tokens)
            for whwrd in whrds:
                whwrdidx = whwrd[0]
                wrd = whwrd[1]
                if whwrdidx == 0 and chunk.tags[whwrdidx] == 'L':
                    #print '%s\t%s' % (chunk, clause)
                    return True

                if 'when' in wrd or 'where' in wrd or 'how' in wrd: # these are always adverbs.

                    #first chunk with another verb VP(when/R are/V)
                    if ntoks > 1 and whwrdidx < ntoks-1:
                        if chunk.tprops[whwrdidx + 1][TLP_AUXVERB]:
                            return True
                        else: #VP(when/R buying/V), VP(even/R when/R canceling/V)
                            return False
#                    if h == 0:

                    if h < nchunks-1 and ('O' in clause[h+1].tags or '^' in clause[h+1].tags):
                        return False

                    #if no aux VPs to the right move on.
                    #auxVPs = [i for i, ch in enumerate(clause[h:]) if [1 for tp in ch.tprops if tp[TLP_AUXVERB]]]
                    auxidx = None
                    for i, ch in enumerate(clause[h:]):
                        for tp in ch.tprops:
                            if tp[TLP_AUXVERB]:
                                auxidx = i
                                break
                        if auxidx:
                            break

                    if not auxidx:
                        return False

                    if auxidx: #where the fuck will this end
                        #if first verb to the right is aux subject inversion.
                        if auxidx < nchunks-1 and clause[auxidx+1].chunkType == 'NP' \
                            and len(clause[auxidx].tokens) == 1:
                            return True
                    else: #ADVP(when/R), NP(i/O), VP(went/V), PP(to/P), NP(marana/^)
                        return False

                elif 'why' in wrd:
                    if h == 0:
                        if whwrdidx == 0:
                            return True #print '%s\t%s' % (chunk, clause)
                        elif not [1 for i, t in enumerate(chunk.tokens[:whwrdidx]) if chunk.tprops[i][TLP_AUXVERB]]: #'that's why it is...
                            return True #print '%s\t%s' % (chunk, clause)
                        else:
                            return False
                    else:
                        if clause[h-1].chunkType != 'VP':
                            if not [1 for i, t in enumerate(chunk.tokens[:whwrdidx]) if chunk.tprops[i][TLP_AUXVERB]]:
                                return True #print '%s\t%s' % (chunk, clause)

                elif 'who' in wrd: #these are always O
#                    if h < nchunks-1 and ('O' in clause[h+1].tags or '^' in clause[h+1].tags):
#                        print '%s\t%s' % (chunk, clause)
                    #if no aux VPs to the right move on.
                    #auxVPs = [i for i, ch in enumerate(clause[h:]) if [1 for tp in ch.tprops if tp[TLP_AUXVERB]]]
                    if whwrdidx == 0:
                        if h== 0 and nchunks > 1: # and clause[h+1].chunkType == 'VP'
                            #print '%s\t%s' % (chunk, clause)
                            return True
                        else:
                            return False

#                            if clause[h-1].chunkType == 'NP':
#                                #print '%s\t%s' % (chunk, clause)
#                                return False
#                            elif clause[h-1].chunkType == 'VP':
#                                #print '%s\t%s' % (chunk, clause)
#                                return False
##                            elif clause[h-1].chunkType == 'NONE' and clause[h-1].tokens[0] == ',':
##                                print '%s\t%s' % (chunk, clause)
#
#                            else:
#                                #print '%s\t%s' % (chunk, clause)
#                                return True
            #break

    return False


#def getChunksClausedSentence(sentence):
#
#    chunks = [chunk for clause in sentence for chunk in clause]
#from token_properties import updateTokenLexicalProperties

def questionsInProcTxt(procTxt, hr = []):
    """
    """
#    try:
#        procTxt[PTKEY_CHUNKEDCLAUSES][0][0][0].tprops
#    except:
#        procTxt = procTxt = updateTokenAndChunkProperties(procTxt, hr)

    retval = []
    for idx, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
        qm = isQuestionQM(sentence)
        si = isQuestionSI(sentence)
        wf = isQuestionWF(sentence)

        retval.append({'QM': qm, 'SI': si, 'WF': wf})

    return retval

if __name__ == "__main__":

    from config import MC_DATA_HOME, MC_LOGS_HOME
    from config import DEFAULT_HR_FILE, KEY_NEGATION
    from config import PTKEY_CHUNKEDCLAUSES, PTKEY_CHUNKEDSENTENCES
    from Resources import RESKEY_NEGATORS
    from collections import defaultdict
    from chunk_pols import getChunkPolarity
    import cPickle as pickle
    hr = pickle.load(open(DEFAULT_HR_FILE))
    ptfname = MC_DATA_HOME + 'evaldata/data_merged_2854_test.proctxts'
    ptfname = MC_DATA_HOME + 'ptd/coechatsamples.proctxts' 
    #ptfname = MC_DATA_HOME + 'evaldata/data_semeval_6399_train.proctxts'
    #ptfname = MC_DATA_HOME + 'AttensityTestData.proctxts'
    #ptfname = MC_DATA_HOME + 'cmpdata/data_eval_merged.proctxts'

    logfile = open(MC_LOGS_HOME + 'QuestionsData.csv', 'w')
    logger = logfile.write
    procTxtLst = pickle.load(open(ptfname, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))
    for tw, procTxt in enumerate(procTxtLst):
        procTxt = updateTokenAndChunkProperties(procTxt, hr)
        isq = questionsInProcTxt(procTxt, hr)

        clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
        for s , sentence in enumerate(clausedSentences):
            if isq[s]['SI']: #any(isq[s].itervalues()):
                chunks = [chunk for clause in sentence for chunk in clause]
                print 'SI', ' '.join(['%s' % chunk for chunk in chunks])

#            #chunkPropsLst = [getChunkPolarity(ch, hr) for ch in sentence]
#            chunkPropsLst = [[getChunkPolarity(ch, hr) for ch in cl] for cl in sentence]

#            #isQuestionWF1(procTxt[PTKEY_SENTENCES][s])
#            isq = questionsInProcTxt(procTxt)
#            isQ = any(isq[k].values())
#
#            iswh = isQuestionWF(sentence)
#            if iswh:
#                chunks = [chunk for clause in sentence for chunk in clause]
#                print 'WH', ' '.join(['%s' % chunk for chunk in chunks])
#            isSI = isQuestionSI(sentence)
#            if isSI:
#                chunks = [chunk for clause in sentence for chunk in clause]
#                print 'SI', ' '.join(['%s' % chunk for chunk in chunks])
#            isqm = isQuestionQM(sentence)
#            if isqm:
#                chunks = [chunk for clause in sentence for chunk in clause]
#                print 'SI', ' '.join(['%s' % chunk for chunk in chunks])
#
##            if isSI:
##                logger('%d\t%d\t%d'% (1, tw, s))
##                #logger('%d\t%d\t%d\n' % (1, tw, s))
##                logger('\t%s\n' % sentence)

    logfile.close()