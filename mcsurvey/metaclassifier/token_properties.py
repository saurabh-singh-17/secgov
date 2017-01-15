# -*- coding: utf-8 -*-
"""
Created on Fri Oct 24 15:03:45 2014

@author: vh
"""

from config import *
import cPickle as pickle
from collections import defaultdict, Counter
from Resources import RESKEY_NEGATORS
#from InterrogativeAnalysis import questionsInText
from appDefs import *

TLP_V_ENDS_ING = 'ING'
TLP_V_ENDS_ED = 'ED'
TLP_V_TO_INF = 'TOINF'
TLP_V_FINITE = 'FNT'
TLP_NEGATOR = 'NGTR'

TLP_INTENSIFIER = 'INTENSIFIER'
TLP_REDUCER = 'REDUCER'
TLP_PLURAL = 'HASPLURAL'
TLP_INDEF_PRONOUNS = 'has_indef_pronouns'
TLP_DEF_NOUN = 'has_def_noun'
TLP_CONJ = 'has_conj'
TLP_NINTENSIFIER = 'NINTENSIFIER'
TLP_AUXVERB = 'AUXVERB'
TLP_WHWORD = 'WHWORD'

VERBS_ENDING_IN = ['explain', 'win', 'join', 'complain', 'attain',
                       'obtain', 'train','refrain',
                       'ordain','abstain','ascertain','attain','bargain',
                       'begin','bin','brin','chain','spin','coin','cojoin',
                       'constrain','curtain','destain','detain','retain',
                       'disdain','disjoin','detrain','devein','distain',
                       'distrain','drain','enchain','enjoin','entertain',
                       'entrain','explain','strain','fain','foreordain',
                       'gain','grin','gin','ingrain','jin','coin','slain',
                       'noggin','origin','skin','sin','lain','pain','pin',
                       'rain','ruin','sprain','sustain','thin']

VERBS_ENDING_IN = list(set(VERBS_ENDING_IN))
VERBS_ENDING_IN_PREFIX = ['un', 'out', 'over', 'non', 'pre', 'pro', 're', 'under']

VERBS_ENDING_IN.extend( [w for wrd in VERBS_ENDING_IN for w in [p + wrd for p in VERBS_ENDING_IN_PREFIX] ])
VERBS_ENDING_IN = set(VERBS_ENDING_IN)

VERBS_ENDING_ING = set(['bring', 'spring', 'wring', 'string'])
VERBS_ENDING_ED =set(['need', 'heed', 'seed'])



## DEFINITIONS
INTENSIFIER_TYPE1 = ['absolutely', 'insanely', 'just too', 'significantly','seriously', 'fairly', 'totally', 'really', 'bloody',  'incredibly', 'pretty', 'extremely', 'terribly', 'hella', 'remarkably', 'awful', 'awesomely', 'ridiculously', 'plenty', 'wicked', 'super', 'so', 'dead', 'quite', 'real']
INTENSIFIER_TYPE2 = ['too', 'tooo'] #negate +ves and Us, intensify -ves
#too good/beautiful/random/existential = -1, too bad/vulgar/sadistic/ironic = -1.
INTENSIFIER_TYPE3 = ['effective']  #intensify +ves and Us, intensify -ves
#effective care/relationship/affair/campaign = +1 effective torture/disaster
REDUCER_TYPE1 = ['slightly', 'somewhat', 'less', 'nearly', 'kind+of']
REDUCER_TYPE2 = ['slight']
NEGATOR_TYPE1 = ['not', 'barely', 'rarely', 'scarcely', 'hardly', 'nt', "'nt", "isnt", "is'nt", "wasnt", "was'nt"]
VERBS_TYPE1 = ["is", "are", "was", "were"]
VERBS_NEGATED_TYPE1 = [w for wrd in VERBS_TYPE1 for w in [wrd+"'nt", wrd+"nt", wrd+"n't"] ]
VERBS_TYPE1.extend(["be", "am", "been", "being"])
__LEXPROP_TAGS__ = set([POSKEY_ADV, POSKEY_ADJ])

__INDEF_PRONOUNS__ = ['some', 'any', 'no', 'ne', 'every']
__INDEF_PRONOUNS__.extend([w for wrd in __INDEF_PRONOUNS__ for w in [wrd+'one', wrd+'body', wrd+'thing']])
_NPA_NOUNTAGS = set(['D', '^', 'S', 'Z', 'L', 'O'])
_NPA_CONJTAGS = set(['&'])
_NPA_NTAG = set(['N'])

__NINTENSIFIERS__ = set(["great", "most", "greatest", "largest", "enormous", "considerable", "substantial", "sheer", "unqualified", "magnificient", "total", "significant", "serious", "extraordinary", "utter"])

TLP_NEGATOR_LST = ["no", "nothing", "no body", "no longer", "doesnt", "not", "none", "no one", "nobody", "neither", "nowhere", "never", "cannot", "without", "hardly", "rarely", "scarcely", "barely", "doesn't", "ain't", "ai'nt", "aint", "aren't", "are'nt", "arent", "can't", "ca'nt", "cant", "couldn't", "could'nt", "couldnt", "cudn't", "cud'nt", "cudnt", "didn't", "did'nt", "didnt", "don't", "do'nt", "dont", "hadn't", "had'nt", "hadnt", "hasn't", "has'nt", "hasnt", "haven't", "have'nt", "havent", "isn't", "is'nt", "isnt", "'nt", "nor", "shan't", "sha'nt", "shouldn't", "should'nt", "shudn't", "shud'nt", "wasn't", "was'nt", "wasnt", "weren't", "were'nt", "won't", "wo'nt", "wont", "wouldn't", "would'nt", "wouldnt", "wud'nt", "wudnt", "without"]
TLP_NEGATOR_LST = ['_NG_'.join(ng.split()) for ng in TLP_NEGATOR_LST]
TLP_NEGATOR_LST = set(TLP_NEGATOR_LST)

__TLP_AUX_VRBS__ = ["are","is","was", "were", "can", "could", "do", "did", "does", "have", "has", "had", "shall", "should", "would"]
__TLP_AUX_VRBS__.extend( [w for wrd in __TLP_AUX_VRBS__ for w in [wrd+"'nt", wrd+"n't", wrd+"nt"] ])
__TLP_AUX_VRBS__.extend(["wont", "wo'nt", "won't"])
__TLP_AUX_VRBS__.extend(["am", "might", "must", "shall", "will", "would"])
__TLP_AUX_VRBS__ = set(__TLP_AUX_VRBS__)

__TLP_2_QWRDS__ = ['who', 'what', 'when', 'why', 'where', 'how']
__TLP_2_QWRDS__.extend( [w for wrd in __TLP_2_QWRDS__ for w in [wrd+"'s", wrd+"z", wrd+"s"] ])
__TLP_2_QWRDS__.extend(["whom"])
__TLP_2_QWRDS__ = set(__TLP_2_QWRDS__)

def tokenLexicalProps(chunk, hr, logger=None):
    """ """
    props = [defaultdict(int) for tok in chunk.tokens]
    ntoks = chunk.tokens.__len__()
    #negators = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)

    toks = chunk.tokens
    tags = chunk.tags
                
    for k,tok in enumerate(toks): #(chunk.tokens):
        tag = chunk.tags[k]

        if tok in __TLP_2_QWRDS__:
            props[k][TLP_WHWORD] = 1
        elif tok in TLP_NEGATOR_LST:
            props[k][TLP_NEGATOR]=1
        elif '_NG_' in tok:
            ngtoks = tok.split('_NG_')
            for ngt in ngtoks:
                if ngt in TLP_NEGATOR_LST:
                    props[k][TLP_NEGATOR]=1
                    #print tok
                    break

        if tag in ('V','L','Y', 'P'):  #POSKEY_VRB:
            if tok in __TLP_AUX_VRBS__ or tag in ('L', 'Y'):
                props[k][TLP_AUXVERB] = 1
                props[k][TLP_V_FINITE] = 1
            elif (tok not in VERBS_ENDING_ING and tok.endswith('ing')) or \
                (tok not in VERBS_ENDING_IN and tok.endswith('in')):
                    props[k][TLP_V_ENDS_ING] = 1
#            elif tok not in VERBS_ENDING_ED and tok.endswith('ed'):
#                    props[k][TLP_V_ENDS_ED ] = 1
            elif tok == 'to' and (k < ntoks-1 and chunk.tags[k+1] == 'V'):
                    #props[k][TLP_V_TO_INF ] = 1
                    props[k+1][TLP_V_TO_INF] = 1
            elif (TLP_V_TO_INF not in props[k]): 
                if chunk.tags[k] in ('V'):
                    if not props[k][TLP_V_TO_INF]: 
                        props[k][TLP_V_FINITE] = 1
                    else:
                        props[k][TLP_V_FINITE] = 0
                elif chunk.tags[k] in ('L', 'Y'):
                    props[k][TLP_V_FINITE] = 1

        elif tag == POSKEY_ADV:
            if (k < ntoks -1) and tags[k+1] in __LEXPROP_TAGS__:
                if tok in INTENSIFIER_TYPE1:
                    props[k][TLP_INTENSIFIER] = 1
                elif tok in INTENSIFIER_TYPE2:
                    props[k][TLP_INTENSIFIER] = 2
                elif tok in REDUCER_TYPE1:
                    props[k][TLP_REDUCER] = 1

        elif tag in _NPA_NTAG:
            if (not tok.endswith('ss')) and (tok.endswith('s') or tok.endswith('es')):
                props[k][TLP_PLURAL] = 1
            if tok in __INDEF_PRONOUNS__: #
                props[k][TLP_INDEF_PRONOUNS] = 1
            if tag in _NPA_NOUNTAGS:
                props[k][TLP_DEF_NOUN] = 1
            if tag in _NPA_CONJTAGS:
                props[k][TLP_CONJ] = 1

        elif tag in POSKEY_ADJ and tok in __NINTENSIFIERS__:
            props[k][TLP_NINTENSIFIER] = 1

    #setattr(chunk, 'tprops', props)
    chunk.tprops = props
    return props #, chunk

def updateTokenLexicalProperties(proctxt, hr):
    for s, sentence in enumerate(proctxt[PTKEY_CHUNKEDCLAUSES]):
        for c, clause in enumerate(sentence):
            for h, chunk in enumerate(clause):
                props = tokenLexicalProps(chunk, hr)
    return proctxt

if __name__ == "__main__":

    proctxtLst = pickle.load(open(MC_DATA_HOME + 'evaldata/data_merged_2854_test.proctxts'))
    #proctxtLst = pickle.load(open(MC_DATA_HOME + 'evaldata/data_semeval_6399_train.proctxts'))
    hr = pickle.load(open(DEFAULT_HR_FILE))
    for p, proctxt in enumerate(proctxtLst):
        for s, sentence in enumerate(proctxt[PTKEY_CHUNKEDCLAUSES]):
            for c, clause in enumerate(sentence):
                for h, chunk in enumerate(clause):
                    for tag in chunk.tags:
                        if tag == 'L':
                            tokenLexicalProps(chunk, hr)
#                    #props = 
#                    containsNegator = [1 for tpr in props if TLP_NEGATOR in tpr]
#
##                    if not containsNegator:
##                        continue
##                    #logger('%s' % chunk)
##                    for tk in props:
##                        for k in tk.keys():
##                            logger('\t%s' % k)
##                    logger('\n')
##
##        proctxtLst[p] = proctxt
##    logfile.close()
#
#
#    for p, proctxt in enumerate(proctxtLst):
#        for s, sentence in enumerate(proctxt[PTKEY_CHUNKEDCLAUSES]):
#            for c, clause in enumerate(sentence):
#                for h, chunk in enumerate(clause):
#                    chunk.tprops


