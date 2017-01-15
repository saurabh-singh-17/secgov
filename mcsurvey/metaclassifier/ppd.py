# -*- coding: utf-8 -*-
"""
Created on Sun Jun 22 07:59:24 2014

@author: shardulnaithani
"""

import cPickle as pickle
from Resources import RESKEY_POLAR_NGRAMS,RESKEY_NEGATORS
from Resources import RESKEY_DOMAIN_NOUNS, RESKEY_PHRASE_NO_PREP, RESKEY_NO_PARTICLE
from Resources import RESKEY_OPENCLAUSALCOMPLIMENT, RESKEY_HAPPENINGVERBS
from Resources import RESKEY_PROBNOUNS, RESKEY_SOFTVERBS, RESKEY_NOTHAPPENINGVERBS
   
from config import KEY_POLARITY_POSITIVE, KEY_POLARITY_NEGATIVE, KEY_NEGATION, PTKEY_CHUNKTYPE_NONE
from ngdict import parseTokensAsNgrams, isngToken

def domainNounsInTokLst(tokLst, hr):
    dnngd = hr.resources[RESKEY_DOMAIN_NOUNS+'TST']
    ngTokLst = parseTokensAsNgrams(dnngd, tokLst)
    domainNouns = []
    for ngtok in ngTokLst:
        if isngToken(ngtok) and not ngtok.isNull():
            domainNouns.extend(ngtok.val)
    return domainNouns

__NOVP_TAGS__ =  ['NP','NONE', 'ADJP', 'ADVP', 'PP']
__ONLYVP_TAGS__ =  ['VP', 'NONE'] 
__VP_TAGS__ = 'VP'
__STYPE_DG__ = 'degenerate'
__STYPE_SV__ = 'singleverb'
__STYPE_MV__ = 'multiverb'
 
def sentenceType(chunkedSentence):
    """
    """
    chunkPattern = [ch.chunkType for ch in chunkedSentence]
    # degenerate        
    noVP = [ch in __NOVP_TAGS__ for ch in chunkPattern]
    onlyVP = [ch in __ONLYVP_TAGS__ for ch in chunkPattern]
    vp = [1 for ch in chunkPattern if ch == __VP_TAGS__]
    
    degenerate = all(noVP) or all(onlyVP) #onlyVP:
    singleVerb = sum(vp) == 1
    
    if degenerate:
        return __STYPE_DG__
    elif singleVerb:
        return __STYPE_SV__
    else:
        return __STYPE_MV__
        
##############################################################################
        
##############################################################################        
__phrasePolmap = {'negative':-1, 'positive':1, 'neutral':0}   
def phrasePolarity(tokLst, hr):
    """
    negative: phrasePosteriorPolarity < 0 
    positive: phrasePosteriorPolarity > 0
    
    Ngram lookup from all dictionaries.
    """
    dnngd = hr.resources[RESKEY_POLAR_NGRAMS]
    nhap_verbs = set(hr.resources[RESKEY_HAPPENINGVERBS])
    soft_verbs = set(hr.resources[RESKEY_SOFTVERBS])
    openClauseComp = set(hr.resources[RESKEY_OPENCLAUSALCOMPLIMENT])
    probNouns = set(hr.resources[RESKEY_PROBNOUNS])
    noParticle = set(hr.resources[RESKEY_NO_PARTICLE])
    hap_verbs = set(hr.resources[RESKEY_NOTHAPPENINGVERBS])
    negation = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)
    
    phrasePosteriorPolarity = 0
    tokPolarity = []
    ngTokLst = []
    #print tokLst
    ngParseLst = parseTokensAsNgrams(dnngd, tokLst)

    for ngtok in ngParseLst:
        if isngToken(ngtok) and not ngtok.isNull():
            tokPolarity.append(__phrasePolmap[ngtok.polarity])
            ngTokLst.append('+'.join(ngtok.val))
        else:
            ngTokLst.append(ngtok)
            tokPolarity.append(0)

    negatorLst = []
    for k, tok, in enumerate(ngTokLst):
        if tok in nhap_verbs: 
            tokPolarity[k] = -1
        elif tok in soft_verbs:
            tokPolarity[k] = -1
        elif tok in hap_verbs:
            tokPolarity[k] = 1
        elif tok in openClauseComp:
            tokPolarity[k] = -1
        elif tok in probNouns:
            tokPolarity[k] = -1
        elif tok in noParticle:
            tokPolarity[k] = -1
        elif tok in negation:
            negatorLst.append(1)
            #print 'DUPLICATE-->', chunk, tok, tag, pols[k]   
        
        phrasePosteriorPolarity = sum(tokPolarity)
        if sum(negatorLst) > 0:
            phrasePosteriorPolarity = phrasePosteriorPolarity*(-1)
            
    #print 'ngpol -->', ngTokLst, tokPolarity, phrasePosteriorPolarity        
    return phrasePosteriorPolarity
            
def problem_phrase(verb_phrase,hr):
    """
    chunk negative hein ya nahi
    """
    negation = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION)
    pos_words = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE) #hr.posWords
    neg_words = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE) #hr.negWords
    not_happening = hr.resources[RESKEY_NOTHAPPENINGVERBS]
 
    phrases_without_prep=hr.resources[RESKEY_PHRASE_NO_PREP]
    open_clausal_compliment=hr.resources[RESKEY_OPENCLAUSALCOMPLIMENT]
    happening_verbs_lst=hr.resources[RESKEY_HAPPENINGVERBS]
    problem_nouns_lst=hr.resources[RESKEY_PROBNOUNS]
    softer_verbs_lst=hr.resources[RESKEY_SOFTVERBS]
    without_particle = hr.resources[RESKEY_NO_PARTICLE]
    neg=0
    pos=0
    #print verb_phrase
    domainNounsInTokLst(verb_phrase, hr)
    for index_word,k in enumerate(verb_phrase):
        #print(k)
        #print(index_word)
        if(any(k in i for i in [phrases_without_prep,neg_words,open_clausal_compliment,happening_verbs_lst,problem_nouns_lst,softer_verbs_lst, without_particle])==True):
              
              start_pos=index_word-1
              #print(start_pos)
              neg+=1
              #print("jamalo")
              if(start_pos>=0):
                  neg_find=start_pos
                  while(neg_find>=0):
                      if (verb_phrase[neg_find] in negation):
                          neg-=1
                          pos+=1
                          break
                      neg_find=neg_find-1
        elif(any(k in i for i in [not_happening,pos_words])==True):
              start_pos=index_word-1
              #print(start_pos)
              pos+=1
              #print("holla")
              if(start_pos>=0):
                  neg_find=start_pos
                  while(neg_find>=0):
                      #print(verb_phrase[neg_find])
                      if (verb_phrase[neg_find] in negation):
                          #print("lelel")
                          neg+=1
                          pos-=1
                          break
                      neg_find=neg_find-1
    return(neg)

##############################################################################
def degenerate_func(degen_sent, hr):
    """
    Polarity of Degenerate Sentence
    """
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    degen_list=degen_sent.split(" ")
    #myprint("%s\n"%degen_list)
    degen_str=[str(n) for n in degen_list]
    #neg_degen=problem_phrase(degen_list, hr)
    phPol = phrasePolarity(degen_list, hr)
    problem_context=[]
    polarity=0
    #print 'phrase pol', neg_degen
    if phPol < 0:  #(neg_degen>0):
        polarity=1
        #print degen_list
#        probWords = domainNounsInTokLst(degen_list, hr)
#        problem_context.append(probWords)
        #print 'PW:', probWords
        for prob_word in degen_list:
            if(prob_word in domainNouns):
                problem_context.append(prob_word)
    problem_context=set(problem_context)
    problem_context=list(problem_context)
    return([problem_context,polarity])

##############################################################################
__MF_RELCHUNKS = ["NP","PP","ADJP","ADVP"]
__MF_RELTOKS = [",","?","!","."]    
def merge_func(LHS,tok_LHS,flag):
    """
    """
    lhs_list=[]
    phrase_range=range(len(LHS))
    if(flag==1):
        phrase_range.reverse()
    for i in phrase_range:
        if((str(tok_LHS[i]) in __MF_RELCHUNKS)):
            lhs_list.extend(LHS[i])
        elif((str(tok_LHS[i]) in [PTKEY_CHUNKTYPE_NONE])):
            sum_tok=0
            if(len(LHS[i])==1):
                expanded_none=LHS[i][0]
                for m in expanded_none:
                    if(m in __MF_RELTOKS):
                        sum_tok+=1
                if(sum_tok==len(expanded_none)):
                    break
            lhs_list.extend(LHS[i])
    return(lhs_list)

##############################################################################

__VPKEY = "VP"
def singleverb_func(chunkPattern,sentPattern, hr):
#def singleverb_func(chunkedSentence, hr):    
    """
    Polarity of SV Sentence
    """
#    chunkPattern = [ch.chunkType for ch in chunkedSentence]
#    sentPattern = [ch.tokens for ch in chunkedSentence]   
    
    problem_term=[]
    polarity=0
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    
    for jk in range(len(chunkPattern)):
        if(chunkPattern[jk]==__VPKEY):
            flag_vp=1
            chunk_list=[str(n) for n in sentPattern[jk]]
            LHS=sentPattern[:jk]
            tok_LHS=chunkPattern[:jk]
            RHS=sentPattern[jk+1:]
            tok_RHS=chunkPattern[jk+1:]
            lhs_new=merge_func(LHS,tok_LHS,1)
            lhs_list=[str(n) for n in lhs_new]
            rhs_new=merge_func(RHS,tok_RHS,0)
            rhs_list=[str(n) for n in rhs_new]
            full_list=lhs_list+chunk_list+rhs_list

            #trouble_verb=problem_phrase(chunk_list, hr)
            phPol = phrasePolarity(chunk_list, hr)
            count_prob=0
            if phPol < 0: #(trouble_verb>0):
                #print full_list
#                probWords = domainNounsInTokLst(full_list, hr)
#                problem_term.extend(probWords)
                #print 'PW:', probWords    
                for prob_lhs in full_list:
                    if(prob_lhs in domainNouns):
                        problem_term.append(prob_lhs)
                count_prob=1
                polarity=1
            else:
#                rhs_prob=problem_phrase(rhs_list, hr)
#                lhs_prob=problem_phrase(lhs_list, hr)
                rhsPol = phrasePolarity(rhs_list, hr)
                lhsPol = phrasePolarity(lhs_list, hr)
                if rhsPol < 0:  #(rhs_prob>0):   
                    #print rhs_list
#                    probWords = domainNounsInTokLst(rhs_list, hr)
#                    problem_term.extend(probWords)
                    #print 'PW:', probWords                 
                    for prob_rhs in rhs_list:
                        if(prob_rhs in domainNouns):
                            problem_term.append(prob_rhs)
                    count_prob=1
                    polarity=1
                if lhsPol < 0:  #(lhs_prob>0):
                    #print rhs_list
#                    probWords = domainNounsInTokLst(lhs_list, hr)
#                    problem_term.extend(probWords)
                    #print 'PW:', probWords                 
                    for prob_rhs in lhs_list:
                        if(prob_rhs in domainNouns):
                            problem_term.append(prob_rhs)
                    count_prob=1
                    polarity=1
            if(count_prob==0):
                #print full_list
#                probWords = domainNounsInTokLst(full_list, hr)
#                problem_term.extend(probWords)
#                #print 'PW:', probWords 
#                if probWords:
#                    polarity = 1
                for prob_rhs in full_list:
                    if(prob_rhs in domainNouns):
                        problem_term.append(prob_rhs)
                        polarity = 1
                #count_prob=1
    #print problem_term                
    problem_term=set(problem_term)
    problem_term=list(problem_term)
    return([problem_term,polarity])

def multiverb_func(chunkPattern,sentPattern, hr):
#def multiverb_func(chunkedSentence, hr):
    """
    Polarity of MV Sentence
    """
#    chunkPattern = [ch.chunkType for ch in chunkedSentence]
#    sentPattern = [ch.tokens for ch in chunkedSentence]    

    polarity_list=[]
    problem_term=[]
    vp_pos=[i for i,k in enumerate(chunkPattern) if k==__VPKEY]

    for ma,k in enumerate(vp_pos):
        if(ma==0):
            
            svo_sent=sentPattern[:k]+[sentPattern[k]]+sentPattern[k+1:vp_pos[ma+1]]
            svo_chunk=chunkPattern[:k]+[chunkPattern[k]]+chunkPattern[k+1:vp_pos[ma+1]]
        elif(ma==(len(vp_pos)-1)):
            
            svo_sent=sentPattern[(vp_pos[ma-1]+1):k]+[sentPattern[k]]+sentPattern[k+1:]
            svo_chunk=chunkPattern[(vp_pos[ma-1]+1):k]+[chunkPattern[k]]+chunkPattern[k+1:]
        else:
            svo_sent=sentPattern[(vp_pos[ma-1]+1):k]+[sentPattern[k]]+sentPattern[k+1:vp_pos[ma+1]]
        
            svo_chunk=chunkPattern[(vp_pos[ma-1]+1):k]+[chunkPattern[k]]+chunkPattern[k+1:vp_pos[ma+1]]
        #problem_term.extend(singleverb_func(svo_chunk,svo_sent, hr)[0]) 
        list_pol_prob=singleverb_func(svo_chunk,svo_sent, hr)    
        problem_term.extend(list_pol_prob[0])
        polarity_list.append(list_pol_prob[1])
        
    problem_term=set(problem_term)
    problem_term=list(problem_term)
    #return(problem_term)
    return([problem_term,polarity_list])

from config import *
from clause_pol import clausePolarity
import sys

def hasDomainNoun(chunkList, hr):
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    hasDN = [] #[0]*len(chunkList)
    for h, chunk in enumerate(chunkList):
        for t, tok in enumerate(chunk.tokens):
            if tok in domainNouns:
                hasDN.append(h)
                break
    return hasDN
        
def negatedDomainNoun(procTxt, hr):
    """ """
#    logger = sys.stdout.write
    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
    
    ndn = []
    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
        for c, clause in enumerate(sentence):
            chPat, pols, negn, negtd = clausePolarity(clause, hr)
            for h, chunk in enumerate(clause):                    
                if chPat[h] == 'NP':
                    hasDomainNoun = False
                    for t, tok in enumerate(chunk.tokens):
                        if tok in domainNouns:
                            hasDomainNoun = True
                            break
                    
                    if hasDomainNoun:
                        if negn[h]:
                            ndn.append(chunk)
                        elif pols[h] < 0 and not negtd[h]:
                            ndn.append(chunk)
                        elif negtd[h]:
                            ndn.append(chunk)
    #                        logger('\n')                   
    return ndn

from ppd_clause import clauseVPAnalysis
from collections import Counter, defaultdict
def domainNounInSV(procTxt, hr):
    """ """
    rlhs = []
    rrhs = []
    rvp = []
    for s, sentence in enumerate(procTxt[PTKEY_CHUNKEDCLAUSES]):
        for c, clause in enumerate(sentence):
            chPat, pols, negn, negtd = clausePolarity(clause, hr)
            n_vp, n_vpfinite, vpidx, lhs, vp, rhs = clauseVPAnalysis(clause)
         
            if n_vp == 1 or n_vpfinite == 1:               
                cpnn = [(ch, pols[k], negn[k], negtd[k]) for k, ch in enumerate(clause)]
                
                lhs = [q for q in cpnn[:vpidx]]
                rhs = [q for q in cpnn[vpidx+1:]]
                
                lhspols = [item[1] for item in lhs]
                cc = Counter(lhspols)
                if cc[1] and cc[-1]:
                    print clause
                    print lhs
                    print vp
                    print rhs
                    print '----'
                
#                
#                lhschunks = [q[0] for q in lhs]
#                rhschunks = [q[0] for q in rhs]
#                
#                lhsDNidx =  hasDomainNoun(lhschunks, hr)
#                rhsDNidx = hasDomainNoun(rhschunks, hr)
#                
#                rlhs = [lhs[k] for k in lhsDNidx]
#                rrhs = [rhs[k] for k in rhsDNidx]
#                rvp = [(vp, pols[vpidx], negn[vpidx], negtd[vpidx])]
                
                
#                if len(rlhs) > 1:
#                    print rlhs, rvp, rrhs
                    
#                
#                   
##                    if pols[vpidx] < 0:
##                        print [lhs[k] for k in lhsDN], vp, [rhs[k] for k in rhsDN]
#    
#                print rlhs, rvp, rrhs
#                print clause
#                print '-----'
    return (rlhs, rrhs, rvp)                                    

from utils_features import haskey 
def hasDomainNounsSV(procTxt, hr, featureVals = {}, FKEY = 'hasNegatedDomainNouns'):
    """
    Negated Domain Nouns Feature
    """ 
    if haskey(featureVals, FKEY): return featureVals
    rv = domainNounInSV(procTxt, hr)
    
    lhs = {'hasDomain':0, 'pol': 'mix', 'negn':0, 'ngtd':0}
    rhs = {'hasDomain':0, 'pol': 'mix', 'negn':0, 'ngtd':0}
    vp = {'hasDomain':0, 'pol': 'mix', 'negn':0, 'ngtd':0}
    
    if lhs:
        lhs['hasDomain'] = 1
        pol = 0; negn = 0; ngtd = 0;
        

    featureVals[FKEY] = retval
    return featureVals  
    
def hasNegatedDomainNouns(procTxt, hr, featureVals = {}, FKEY = 'hasNegatedDomainNouns'):
    """
    Negated Domain Nouns Feature
    """ 
    if haskey(featureVals, FKEY): return featureVals
    featureVals[FKEY] = negatedDomainNoun(procTxt, hr)
    return featureVals  
    
def problemPhraseDetector(procTxt,hr):
   sentences = procTxt['sentences'] #ptSentencify(procTxt)
   chunkedSentences = procTxt['chunkedSentences'] #chunkify(sentences)
   problem_context=[]
   for s, (sentence, chunkedSentence) in enumerate(zip(sentences, chunkedSentences)):
       
        chunkPattern = [ch.chunkType for ch in chunkedSentence]
        sentPattern = [ch.tokens for ch in chunkedSentence]
        type_sent=sentenceType(chunkedSentence)
        if(type_sent=="degenerate"):
            #print 'degen', sentence
            #buff_context=degenerate_func(' '.join(sentence.tokens,hr))[0]
            buff_context=degenerate_func(' '.join(sentence.tokens), hr)[0]
        elif(type_sent=="singleverb"):
            buff_context=singleverb_func(chunkPattern,sentPattern,hr)[0]
            #buff_context=singleverb_func(chunkedSentence,hr)[0]
        else:
            buff_context=multiverb_func(chunkPattern,sentPattern,hr)[0]
            #buff_context=multiverb_func(chunkedSentence,hr)[0]
        
        buff_context = [' '.join(bc.split('_NG_')) for bc in buff_context]
        problem_context.extend(buff_context)
           
   return(list(set(problem_context)))
    
if __name__ == "__main__":
    from config import MC_DATA_HOME
    from processText import updateTokenAndChunkProperties 
    #toktagfilename = 'dbg/data/cleanedupTestData.proctxts' #'dbg/data/train_5235_real.proctxts' #''dbg/data/Att5000.proctxts' #'dbg/data/data_5235_train.proctxts' #datahome + data_name+ '.toktags' #pickle file 
    dname = 'data_jr_1222_noAds'
    dname = 'ptd/coechatsamples25'
    toktagfilename = MC_DATA_HOME + dname + '.proctxts' #'dbg/data/cleanedupTestData.proctxts'    
    procTxtLst = pickle.load(open(toktagfilename, 'rb'))

    hr = pickle.load(open(DEFAULT_HR_FILE))
    for tw, procTxt in enumerate(procTxtLst): #[-1:][0:1] [0:100] [0:10]
        procTxt = updateTokenAndChunkProperties(procTxt, hr)
        #negatedDomainNoun(procTxt, hr)
        #domainNounInSV(procTxt, hr)
            
#        sentences = procTxt['sentences'] #ptSentencify(procTxt)
#        chunkedSentences = procTxt['chunkedSentences'] #chunkify(sentences)
        pc = problemPhraseDetector(procTxt,hr)
#        print procTxt['sentences']
#        print 'PC-->', tw, pc 

