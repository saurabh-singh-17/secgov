# -*- coding: utf-8 -*-
"""
Created on Mon Jun 16 15:23:42 2014

@author: vh
"""
from processText import PTKEY_SENTENCES, PTKEY_CHUNKEDSENTENCES 
from config import KEY_POLARITY_NEGATIVE 
from Resources import RESKEY_POLAR_NGRAMS

#__KW_REL_NN_TAGS__ =  set(['NN', 'NNS', 'NNS','NNP', 'NNPS', 'NNP-ORG']) #'NN', 'NNS', 
__KW_REL_NN_TAGS__ =  set(['#', '^', 'N']) #, ['V', 'P', 'R', 'L', 'Y', 'T']

__KW_NP_KEY__ = "NP"
__DAYS__= ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
__DAYS__.extend(["mon","tue", "wed", "thurs", "fri", "sat", "sun"])
__TIMEWORDS__ = ["day", "time", "morning", "night", "evening", "afternoon", "month", "hour", "year", "week"]
__TIMEWORDS__.extend([t + "s" for t in __TIMEWORDS__])
__TIMEWORDS__.extend(["today", "yesterday", "tomorrow"])

__MISC__ = ["god", "lot", "life"]
__PROFANITY__ = ["ass", "nigga", "nigger", "porn"]

__NSTOPS__ = ["no", "some", "every", "any", "other"]
__NSTOPSE = [n + "one" for n in __NSTOPS__]
__NSTOPSE.extend([n + "body" for n in __NSTOPS__])
__NSTOPSE.extend([n + "thing" for n in __NSTOPS__])
__NSTOPSE.extend(['one', 'body', 'thing', 'others', 'life', 'man', 'dude', 'woman'])
__NSTOPS__.extend(__NSTOPSE)

__KW_NP_STOP_WORDS__ = [] #set(["ass", "dawg", "nigga", "ass", "anyone", "everyone", "noone", "someone", "anybody", "nobody", "somebody"])
__KW_NP_STOP_WORDS__.extend(__NSTOPS__)
__KW_NP_STOP_WORDS__.extend(__PROFANITY__)
__KW_NP_STOP_WORDS__.extend(__TIMEWORDS__)
__KW_NP_STOP_WORDS__.extend(__DAYS__)

__KW_NP_STOP_WORDS__ = set(__KW_NP_STOP_WORDS__)

def extractKeywordsUniGrams(procTxt, hr):
    """
    """            
    sentences = procTxt[PTKEY_SENTENCES]
    #chunkedSentences = procTxt[PTKEY_CHUNKEDSENTENCES]
    neg_words = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
    reltoks = []
    for s in sentences:
        tt = [tok for tok, tag in zip (s.tokens, s.tags) if tag in __KW_REL_NN_TAGS__ and (not tok in neg_words)]
        tt = [t for tok in tt for t in tok.split('_NG_')]
#        tt = []
#        for tok, tag in zip (sentence.tokens, sentence.tags):
#            if tag in __KW_REL_NN_TAGS__ and (not tok in neg_words):
#                tt.append(tok)
        
        if tt: reltoks.extend(tt)
                    
    reltoks = set(reltoks)  
    return list(reltoks)
    
def extractKeywords(procTxt, hr):
    """
    """            
    chunkedSentences = procTxt[PTKEY_CHUNKEDSENTENCES]
    neg_words = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
    reltoks = []
    for s, chunkedSentence in enumerate(chunkedSentences):
        for chunk in chunkedSentence:
            if chunk.chunkType in __KW_NP_KEY__:
                tt  = []
                for tok, tag in zip(chunk.tokens, chunk.tags):
                    if tag in __KW_REL_NN_TAGS__:
                        if len(tok) > 1  and tok not in __KW_NP_STOP_WORDS__ and (tok not in neg_words):
                            tt.append(' '.join(tok.split('_NG_')))  #tok)  
                if tt: reltoks.append(' '.join(tt)) #reltoks.extend(tt)
    #reltoks = set(reltoks)  
    return list(set(reltoks))
 
if __name__ == "__main__":
    import cPickle as pickle
    from collections import defaultdict   
    import operator
    from config import DEFAULT_HR_FILE
    procTxtLst = pickle.load(open('dev/data/data_cf.proctxts')) #data_semeval_1009_test.proctxts'))
    hr = pickle.load(open(DEFAULT_HR_FILE))
    
    f = open('keywords.txt','w') 
    myprint = f.write
    
    tokdict =defaultdict(int)
    for k, procTxt in enumerate(procTxtLst): #[procTxtLst[-5]]):
        reltoks = extractKeywords(procTxt, hr)
        for tok in reltoks:
            tokdict[tok] += 1
    tokdict = sorted(tokdict.iteritems(), key=operator.itemgetter(1), reverse=True)
    
    for k, v in tokdict:
        myprint('%s|%s\n' % (k,v))
    f.close()     