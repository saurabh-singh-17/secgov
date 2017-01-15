# -*- coding: utf-8 -*-
"""
Created on Fri Oct 24 18:01:57 2014

@author: vh
"""
#from token_properties import tokenLexicalProps, updateTokenLexicalProperties
from token_properties import TLP_INTENSIFIER, TLP_REDUCER, TLP_NEGATOR
from token_properties import TLP_NINTENSIFIER
from Resources import RESKEY_SMILEYS
from appDefs import *
from collections import defaultdict

def defaultChunkPolarity(chunk, hr, logger=None):
    """
    """
    props = chunk.tprops #tokenLexicalProps(chunk, hr)
    toks = chunk.tokens
    tags = chunk.tags
    pols = chunk.pols

    intensifier = [tokpr[TLP_INTENSIFIER] for tokpr in props] #lexprop['intensifier']
    reducer = [tokpr[TLP_REDUCER] for tokpr in props] #lexprop['reducer']
    negator = [tokpr[TLP_NEGATOR] for tokpr in props] #lexprop['negator']

    chunkPol = 0
    for k, tok in reversed(list(enumerate(toks))):
        tag = tags[k]
        if not (intensifier[k] or reducer[k] or negator[k]):
            chunkPol += pols[k]
        elif intensifier[k]:
            if intensifier[k] == 1:
                chunkPol = 2*chunkPol
            elif intensifier[k] == 2:
                if chunkPol > 0:
                    chunkPol = -2*chunkPol
                elif chunkPol == 0:
                    chunkPol = -1
                else:
                    chunkPol = 2*chunkPol
            elif intensifier[k] == 3:
                if chunkPol >= 0:
                    chunkPol = 2*chunkPol

        elif reducer[k]:
            chunkPol = 0.5*chunkPol
        elif negator[k]:
            #print toks
            chunkPol = -1*chunkPol

    ## if only intensifiers then consider their prior-pols.
    iidx = [i for i, val in enumerate(intensifier) if val]
    nidx = [i for i, val in enumerate(negator) if val]
    if iidx and chunkPol == 0:
        ipols = [pols[i] for i in iidx]
        chunkPol = sum(ipols)

    negatorF = False
    if nidx:
        negatorF = True
    #print nidx, negator, negatorF
    if logger:
        logger('%s %s %s\n' % (chunk, chunkPol, negatorF))

    chunkProps = {'pol': chunkPol, 'negn': negatorF} #, 'tokProps': props}
    return chunkProps #{'pol': chunkPol, 'negn': negatorF}

def __nounChunkPolarity(chunk, hr, logger=None):
    """
    """
    props = chunk.tprops #tokenLexicalProps(chunk, hr)
    toks = chunk.tokens
    tags = chunk.tags
    pols = chunk.pols

    intensifier = [tokpr[TLP_INTENSIFIER] for tokpr in props] #lexprop['intensifier']
    reducer = [tokpr[TLP_REDUCER] for tokpr in props] #lexprop['reducer']
    negator = [tokpr[TLP_NEGATOR] for tokpr in props] #lexprop['negator']
    nintensifier = [tokpr[TLP_NINTENSIFIER] for tokpr in props]
    
    chunkPol = 0
    for k, tok in reversed(list(enumerate(toks))):
        tag = tags[k]

        conflictFlag = False
        if abs(chunkPol) > 0 and abs(pols[k]) > 0 and chunkPol != pols[k]: #polar opposites
            conflictFlag = True
            if tag in POSKEY_ADJ and nintensifier[k]:
                #print 'gets here'
                intensifier[k] += 1

        if not (intensifier[k] or reducer[k] or negator[k]):
            if conflictFlag:
                if tag in POSKEY_ADJ and pols[k]:
                    chunkPol = pols[k]
                else: #tag in 'N' disaster prevention
                    chunkPol = chunkPol
            else:
                chunkPol += pols[k]
        elif intensifier[k]:
            if intensifier[k] == 1:
                chunkPol = 2*chunkPol
            elif intensifier[k] == 2:
                if chunkPol > 0:
                    chunkPol = -2*chunkPol
                elif chunkPol == 0:
                    chunkPol = -1
                else:
                    chunkPol = 2*chunkPol
            elif intensifier[k] == 3:
                if chunkPol >= 0:
                    chunkPol = 2*chunkPol

        elif reducer[k]:
            chunkPol = 0.5*chunkPol
        elif negator[k]:
            #print toks
            chunkPol = -1*chunkPol

    ## if only intensifiers then consider their prior-pols.
    iidx = [i for i, val in enumerate(intensifier) if val]
    nidx = [i for i, val in enumerate(negator) if val]
    if iidx and chunkPol == 0:
        ipols = [pols[i] for i in iidx]
        chunkPol = sum(ipols)

    negatorF = False
    if nidx:
        negatorF = True

    if logger:
        logger('%s %s %s\n' % (chunk, chunkPol, negatorF))
    #return {'pol': chunkPol, 'negn': negatorF}
    chunkProps = {'pol': chunkPol, 'negn': negatorF} #, 'tokProps': props}
    return chunkProps #{'pol': chunkPol, 'negn': negatorF}

def getNONEChunkPolarity(chunk, hr, logger=None):
    hrr = hr.resources
    pols = []
    smiley = hrr[RESKEY_SMILEYS]
    smileyNeg = smiley.getDicts(1,KEY_POLARITY_NEGATIVE)
    smileyPos = smiley.getDicts(1,KEY_POLARITY_POSITIVE)

    for k, tok in enumerate(chunk.tokens):
        tag = chunk.tags[k]
        if tag in ['E']:
            if tok in smileyNeg:
                pols.append(-1)
            elif tok in smileyPos:
                pols.append(1)
    if logger:
        logger('%s %s %s\n' % (chunk, sum(pols), False))
    return {'pol': sum(pols), 'negn': False} #, 'tokProps':[defaultdict(int)]}


def __verbChunkPolarity(chunk, hr, logger=None):

    rv = defaultChunkPolarity(chunk, hr, logger)
    if 'please' in chunk.tokens and rv['pol'] > 0:
        rv['pol'] = 0
    if 'if' in chunk.tokens and rv['pol'] > 0:
        rv['pol'] = 0

    return rv

#def getChunkPolarity(chunk, hr,logger=None):
#
#    chType = chunk.chunkType
#    if chType == 'NONE':
#        return getNONEChunkPolarity(chunk, hr, logger)
#    elif chType == 'NP':
#        return __nounChunkPolarity(chunk, hr, logger)
#    elif chType == 'VP':
#        return  __verbChunkPolarity(chunk, hr, logger) #__defaultChunkPolarity(chunk, hr, logger)
#    elif chType == 'ADJP':
#        return defaultChunkPolarity(chunk, hr, logger)
#    elif chType == 'ADVP':
#        return defaultChunkPolarity(chunk, hr,logger)
#    else:
#        return defaultChunkPolarity(chunk, hr, logger)

def getChunkPolarity(chunk, hr,logger=None):

    chType = chunk.chunkType
    if chType == 'NONE':
        rv = getNONEChunkPolarity(chunk, hr, logger)
    elif chType == 'NP':
        rv = __nounChunkPolarity(chunk, hr, logger)
    elif chType == 'VP':
        rv =  __verbChunkPolarity(chunk, hr, logger) #__defaultChunkPolarity(chunk, hr, logger)
    elif chType == 'ADJP':
        rv = defaultChunkPolarity(chunk, hr, logger)
    elif chType == 'ADVP':
        rv = defaultChunkPolarity(chunk, hr,logger)
    else:
        rv = defaultChunkPolarity(chunk, hr, logger)
        
#    setattr(chunk, 'chPol', rv['pol'])
#    setattr(chunk, 'hasNegator', rv['negn'])
    chunk.chPol = rv['pol']
    chunk.hasNegator = rv['negn']
    return chunk
        
        
#def updateChunkPolarities(procTxt, hr):
#    procTxt = updateTokenLexicalProperties(procTxt, hr)
#
#    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
#        for c, clause in enumerate(sentence):
#            for h, chunk in enumerate(clause):
#                getChunkPolarity(chunk, hr)
#
#    return procTxt

if __name__ == "__main__":

    from config import MC_DATA_HOME, MC_LOGS_HOME
    from config import DEFAULT_HR_FILE, KEY_NEGATION
    from config import PTKEY_CHUNKEDCLAUSES, PTKEY_CHUNKEDSENTENCES
    from Resources import RESKEY_NEGATORS
    from collections import defaultdict
    import cPickle as pickle
    from processText import updateTokenAndChunkProperties
    
    ptfname = MC_DATA_HOME + 'evaldata/data_merged_2854_test.proctxts'
    ptfname = MC_DATA_HOME + 'evaldata/data_semeval_6399_train.proctxts'
    ptfname = MC_DATA_HOME + 'ptd/coechatsamples.proctxts' 
    #ptfname = MC_DATA_HOME + 'AttensityTestData.proctxts'
    #ptfname = MC_DATA_HOME + 'cmpdata/data_eval_merged.proctxts'
    procTxtLst = pickle.load(open(ptfname, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))

    logfile = open(MC_LOGS_HOME + 'chunkpols2' + '.csv', 'w')
    logger = logfile.write
    negators = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)

    svdict = defaultdict(int)

    for tw, procTxt in enumerate(procTxtLst):
        procTxt = updateTokenAndChunkProperties(procTxt, hr)
        clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
        for sentence in clausedSentences:
            for clause in sentence:
                for chunk in clause:
                    print chunk
#                    chunkProps = getChunkPolarity(chunk, hr)
#                    key = '%s\t%s' % (chunk, chunkProps['pol'])
#                    svdict[key] += 1


    for k, v in svdict.iteritems():
        logger('%s\t%d\n' % (k,v))

    logfile.close()

#        logfile = open(MC_LOGS_HOME + 'chunkpols' + '.csv', 'w')
#    logger = logfile.write
#    negators = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)
#
#    svdict = defaultdict(int)
#



#    ## relative clause experiments.
#    for tw, procTxt in enumerate(procTxtLst):
#        clausedSentences = procTxt[PTKEY_CHUNKEDCLAUSES]
#        for sentence in clausedSentences:
#            for clause in sentence:
#                for h, chunk in enumerate(clause):
#                    chunkProps = getChunkPolarity(chunk, hr)
#                    if h < len(clause)-1:
#                        if chunk.chunkType == 'NP' and 'that' in clause[h+1].tokens:
#                            print clause
##                    key = '%s\t%s' % (chunk, chunkProps['pol'])
##                    svdict[key] += 1
#
#
#    for k, v in svdict.iteritems():
#        logger('%s\t%d\n' % (k,v))
#
#    logfile.close()