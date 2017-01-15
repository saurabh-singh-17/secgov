# -*- coding: utf-8 -*-
"""
Created on Sat Jun 14 07:27:17 2014

@author: vh
"""

from Resources import RESKEY_PROBNOUNS, RESKEY_PHRASE, RESKEY_NO_PARTICLE, RESKEY_PHRASE_NO_PREP, RESKEY_PREP
#import types
#import numpy as np
#from nltk.tree import Tree
from config import POSKEY_verb_tag, POSKEY_noun_tag, POSKEY_NOUNPHRASE, POSKEY_VERBPHRASE
from config import PTKEY_TOKENS, PTKEY_TAGS, PTKEY_CHUNKEDSENTENCES, PTKEY_SENTENCES
from utils_features import haskey
import nltk
from ppd import *

#happening_verbs_lst=["fail","crash","overload","trip","fix","mess","break","overcharge","disrupt","charging"] 
#problem_nouns_lst=["crash","failure","issue","outage","problem","trouble"]
#softer_verbs_lst=["die","drop","bite","fuck","trouble","foil"]
import cPickle as pickle
import utils_gen as ug
import sys
##***** Lexicons ************
##happening_verbs_lst = ug.readlines('dbg/dicts/hapwrds.txtp')
#problem_nouns_lst=ug.readlines('dbg/dicts/nouns.txtp')
##softer_verbs_lst=ug.readlines('dbg/dicts/softvrbs.txtp')
#############################Inserted by shardul
##domain_words = ['att', 'phone', 'calls','call','calling','dialing','texts','text','texting','mobile','reps', 'wifi', 'network', 'device', 'plan', 'service', 'message', 'messages','wireless', 'commercial', 'uverse', 'u-verse', 'bill', 'signal', 'bar', 'bars', 'reception', 'internet', 'coverage', '3g', 'comcast', 'cable', 'customer', 'iphone', 'apple', 'verizon', 'samsung', 'outage', 'dropped', 'switching', 'fix', 'cell', 'mobility','vz', 'update', 'online', 'email','paying','pay','payment','pays','bill','billing','bills','hotspot','connect','connection','connecting','connected']
##
##not_happening=["work","receive","send","function","connect","get","perform","run","stable","respond","working","receiving","sent","function","connect","got","performing","ran","stability","response","worked","received","sending","functional","connection","getting","performance","running","stabelized","responding","functioning","connecting","performed","stabilizing","responsive"]
#phrase_list=["fuck up",	"fucks up",	"fucked up",	"fucking up",	"hang up",	"hangs up",	"hanged up",	"hanging up",	"screw up",	"screws up",	"screwed up",	"screwing up",	"knocked up",	"knocks up",	"knock up",	"knocking up",	"cut up",	"cuts up",	"cutting up",	"act up",	"acting up",	"acts up",	"acted up",	"fuck off",	"fucks off",	"fucked off",	"fucking off",	"hang off",	"hangs off",	"hanged off",	"hanging off",	"screw off",	"screws off",	"screwed off",	"screwing off",	"knocked off",	"knocks off",	"knock off",	"knocking off",	"cut off",	"cuts off",	"cutting off",	"act off",	"acting off",	"acts off",	"acted off",	"fuck at",	"fucks at",	"fucked at",	"fucking at",	"hang at",	"hangs at",	"hanged at",	"hanging at",	"screw at",	"screws at",	"screwed at",	"screwing at",	"knocked at",	"knocks at",	"knock at",	"knocking at",	"cut at",	"cuts at",	"cutting at",	"act at",	"acting at",	"acts at",	"acted at"]
##
##open_clausal_compliment=["stop","refuse","cease","stopped","refused","ceased","stopping","refusing","ceasing","stops","refuses","ceases"]
##negation=["no","not","none","no one","nobody","nothing","neither","nowhere","never","hardly","scarcely","barely","doesn't","isn't","wasn't","shouldn't","wouldn't","couldn't","won't","can't","don't","nor","n't","doesnt","isnt","wasnt","shouldnt","wouldnt","couldnt","wont","cant","dont","nor","nt"]
#
#phrases_without_prep=["fuck",	"fucks",	"fucked",	"fucking",	"hang",	"hangs",	"hanged",	"hanging",	"screw",	"screws",	"screwed",	"screwing",	"knocked",	"knocks",	"knock",	"knocking",	"cut",	"cuts",	"cutting",	"act",	"acting",	"acts",	"acted"]
#without_particle=["act","acting","acted","acts","behave","behaving","behaviour","behaves","behaved"]
#prep=["up","off","out"]
## ******************************************

###########################################
## COMMON COMPUTATIONS
###########################################
def exclamation_feature(word_list):
    if ("!" in word_list):
        return(1)
    return(0)
    
def question_feature(word_list):
    if ("?" in word_list):
        return(1)
    return(0)

def period_feature(word_list):
    if ("." in word_list):
        return(1)
    return(0)
    
def dollar_feature(word_list):
    if ("$" in word_list):
        return(1)
    return(0)

def probnoun_minparse(tokens,tags, hr):
    for tok,tag in zip(tokens, tags):
        if tag in ["N", "^"] and tok.lower() in hr.resources[RESKEY_PROBNOUNS]:
            return 1
    return 0
        
#    for k in range(len(tokens)):
#        if(tokens[k].lower() in problem_nouns_lst):
#            if((tags[k] == "N") or (tags[k] == "^")):
#                return(1)
#    return(0)
        
def phrase_minparse(tokens, hr):
    bigram_phrase=nltk.bigrams(tokens)
    for k in bigram_phrase:
        phrase=" ".join(k).lower()
        if(phrase in hr.resources[RESKEY_PHRASE]):
            return(1)
    for k in range(len(tokens)-1):
        if (tokens[k].lower() in hr.resources[RESKEY_PHRASE_NO_PREP]):
                new_index=k+1
                for i in range(new_index,len(tokens)):
                    if(tokens[i].lower() in hr.resources[RESKEY_PREP]):
                        return(1)
    return(0)
    
def act_behave_minparse(tokens,tag, hr):
    
    for k in range(len(tokens)-1):
        if(tokens[k].lower() in hr.resources[RESKEY_NO_PARTICLE]):
            if((tag[k] == "V")):
                new_index=k+1
                for i in range(new_index,len(tokens)):
                    if ((tag[i]=='A') or (tag[i]=='R')):
                        return(1)
    return(0)    
#################################33inserted by shardul
#######################################################
## FEATURES
########################################################    
def exclamation(procTxt, hr, featureVals = {}, FKEY = 'exclamation'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    retval  = exclamation_feature(procTxt[PTKEY_TOKENS])    
    featureVals[FKEY] = retval            
    return featureVals

def dollar(procTxt, hr, featureVals = {}, FKEY = 'dollar'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals       
    retval  = dollar_feature(procTxt[PTKEY_TOKENS])    
    featureVals[FKEY] = retval            
    return featureVals

def period(procTxt, hr, featureVals = {}, FKEY = 'period'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals        
    retval  = period_feature(procTxt[PTKEY_TOKENS])    
    featureVals[FKEY] = retval            
    return featureVals

def question(procTxt, hr, featureVals = {}, FKEY = 'question'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    retval  = question_feature(procTxt[PTKEY_TOKENS])   
    featureVals[FKEY] = retval            
    return featureVals

def probnounapprox(procTxt, hr, featureVals = {}, FKEY = 'probnounapprox'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals       
    retval  = probnoun_minparse(procTxt[PTKEY_TOKENS],procTxt[PTKEY_TAGS], hr)    
    featureVals[FKEY] = retval            
    return featureVals

def act_behaveapprox(procTxt, hr, featureVals = {}, FKEY = 'act_behaveapprox'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals       
    retval  = act_behave_minparse(procTxt[PTKEY_TOKENS],procTxt[PTKEY_TAGS], hr)    
    featureVals[FKEY] = retval            
    return featureVals  

def phrasalapprox(procTxt, hr, featureVals = {}, FKEY = 'phrasalapprox'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    retval  = phrase_minparse(procTxt[PTKEY_TOKENS], hr)
    featureVals[FKEY] = retval            
    return featureVals  

from Resources import RESKEY_POLAR_NGRAMS, RESKEY_NEGATORS 
from config import KEY_NEGATION, KEY_POLARITY_NEGATIVE, KEY_POLARITY_POSITIVE

#def sentenceType(procTxt, hr, myprint = None):


__POLARCHUNKS__ =  ['NP', 'ADJP', 'ADVP', 'VP']             

def chunkPolarity(chunk, hr):
    """
    """
    negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE) #hr.negWords
    posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE)    
    negation = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION) #hr.negation
    
    tokenPriorPolarity = []
    containsNegn = []
    chunkPosteriorPolarity = 0
    if chunk.chunkType in __POLARCHUNKS__:
        for tok, tag in zip(chunk.tokens, chunk.tags):
            if (tok in negWords) or (tok in hr.resources[RESKEY_PHRASE]):
                tokenPriorPolarity.append(-1)
            elif (tok in posWords):
                tokenPriorPolarity.append(1)
            elif tok in negation:
                containsNegn.append(1)
            else:
                tokenPriorPolarity.append(0)
            
        negn = sum(containsNegn)
        chunkPosteriorPolarity = sum(tokenPriorPolarity)
        if negn > 0:
            chunkPosteriorPolarity = chunkPosteriorPolarity*(-1)
    return chunkPosteriorPolarity         

def degenerateSentencePolarity(chunkedSentence, hr):
    """
    """
    pol = [chunkPolarity(chunk, hr) for chunk in chunkedSentence]
    return sum(pol)

def svSentencePolarity(chunkedSentence, hr):
    """
    """
    #vidx = [k for k, ch in enumerate(chunkedSentence) if ch.chunkType == 'VP']
    
    for vidx, ch in enumerate(chunkedSentence):
        if ch.chunkType == 'VP':
            break
        
    vp = chunkedSentence[vidx]
    lhs = chunkedSentence[:vidx]
    rhs = chunkedSentence[vidx+1:]
    vpol = chunkPolarity(vp, hr)
    lpol = degenerateSentencePolarity(lhs, hr)
    rpol = degenerateSentencePolarity(rhs, hr)
    
#    if vpol <0:
#        senPol = vpol
#    else:
    #print vp, '(', lhs, ',', rhs, ')'
    return (vp, vpol, lhs, lpol, rhs, rpol)

def resentment(procTxt, hr, myprint = None):
    """
    Typical Tweet Pattern: <DGL>* <SV|MV>* <DGR>*
    """
    if not myprint:
        myprint = sys.stdout.write 
        
#    negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE) #hr.negWords
#    negation = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION) #hr.negation
#    
    sentences = procTxt['sentences'] #ptSentencify(procTxt)
    chunkedSentences = procTxt['chunkedSentences'] #chunkify(sentences)
    myprint('%s\n' % ' '.join(procTxt['tokens']))
    leftBound = 0
    leftBoundFound = False
    rightBound = 0
    rightBoundFound = False
    
    senPol = []    
    for s, (sentence, chunkedSentence) in enumerate(zip(sentences, chunkedSentences)):
        senPol.append(0)
        chunkPattern = [ch.chunkType for ch in chunkedSentence]
#        #print chunkPattern
#        #myprint('%d, %s\n' % (s, '+'.join(chunkPattern)))
#        noVP = [ch in ['NP','NONE', 'ADJP', 'ADVP', 'PP'] for ch in chunkPattern]
#        onlyVP = [ch in ['VP', 'NONE'] for ch in chunkPattern]
#        typeflag = all(noVP) or all(onlyVP) #onlyVP:
#        #myprint('%s\n' % all(onlyVP))
#        print s, onlyVP
        if sentenceType(chunkedSentence) == 'degenerate':
            if not leftBoundFound: 
                leftBound = s+1
            if not rightBound: 
                rightBound = s       
        else:
            leftBoundFound = True
            rightBound = 0
    #print senPol
    if rightBound == 0: rightBound = s+1       
    #myprint('%d %d\n' %(leftBound, rightBound))
    dgsl = sentences[:leftBound] #left degenerate sentences
    dgsr = sentences[rightBound:] #right degenerate sentences
    
    dgl_pols = [degenerateSentencePolarity(dgs) for dgs in dgsl] #polarity of dgsl's
    dgr_pols = [degenerateSentencePolarity(dgs) for dgs in dgsr] #polarity of dgsr's  
    
    return {'dgsl': dgsl, 'dgslpol': dgl_pols, 'dgsr': dgsr, 'dgsrpol': dgr_pols}    

#    for s, sentence in enumerate(sentences[:leftBound]):
#        myprint(' %s [%d]' % (repr(sentence), senPol[s]))
#    myprint('\n')
#    
#    myprint('Text End:')
#    if rightBound == len(sentences):
#        myprint('[]')
#    else: 
#        for s, sentence in enumerate(sentences[rightBound:]):
#            myprint(' %s[%d]' % (repr(sentence), senPol[rightBound + s]))    
#    myprint('\n\n')
                 
            #myprint(' %d\n' % postpol)
#def resentment(procTxt, hr, featureVals = {}, FKEY = 'resentment'):
#    if haskey(featureVals, FKEY): return featureVals
# 
                 
def chunkedSentencePolarity(chunkedSentence, hr, senType = None):
    """
    """
    if not senType:
        senType = sentenceType(chunkedSentence)
    if senType == 'degenerate':
        return degenerateSentencePolarity(chunkedSentence, hr)
    else:
        return 0
        
def chunkedSentenceAnalysis(procTxt, hr, myprint = None):   
    if not myprint:
        myprint = sys.stdout.write 
            
    sentences = procTxt['sentences'] #ptSentencify(procTxt)
    chunkedSentences = procTxt['chunkedSentences'] #chunkify(sentences)
    #myprint('%s\n' % ' '.join(procTxt['tokens'])) 
    
    
    for s, (sentence, chunkedSentence) in enumerate(zip(sentences, chunkedSentences)):
        sentype = sentenceType(chunkedSentence)
        #print sentype
        chunkPattern = [ch.chunkType for ch in chunkedSentence]
#        if sentype == 'degenerate':
#            myprint('%s|' % sentype)
#            myprint('%s|' % ('+'.join(chunkPattern)))
#            sp = chunkedSentencePolarity(chunkedSentence, hr)
#            myprint('%d|' % sp)
#            myprint('%s\n' % sentence)
            
        if sentype == 'singleverb':
            vb, vpol, lhs, lpol, rhs, rpol = svSentencePolarity(chunkedSentence, hr)
            myprint('\"%s\"\t\"%d\"\t' % (vb.tokString(), vpol))
            myprint('\"%s\"\t\"%d\"\t' % (' '.join([c.tokString() for c in lhs]), lpol))
            myprint('\"%s\"\t\"%d\"\n' % (' '.join([c.tokString() for c in rhs]), rpol))
#            myprint('%s|' % sentype)
#            myprint('%s|' % ('+'.join(chunkPattern)))
#            sp = chunkedSentencePolarity(chunkedSentence, hr)
#            myprint('%d|' % sp)
#            myprint('%s\n' % sentence)
            
#        else:
#            myprint('\n')
    return  
##############################################################################
#def domain_word_presence(tokens,tag, hr):
#    domainNouns = hr.resources[RESKEY_DOMAIN_NOUNS]
#    for k in range(len(tokens)):
#        phrase=tokens[k].lower()
#        if((phrase in domain_words) and ((tag[k]=="N")or (tag[k] == "^"))):
#            return(1)
#    
#    return(0)

def degen_feat(chunked_list,sent_list, hr):
    count_degen=0   	
    for s, (sentence, chunkedSentence) in enumerate(zip(sent_list,chunked_list)):
        type_sent=sentenceType(chunkedSentence)
        if(type_sent=="degenerate"):
              buff_context=degenerate_func(' '.join(sentence.tokens), hr)
#
              if( (buff_context[1]==1)and(len(buff_context[0])!=0) ):
                  count_degen+=1
    return(count_degen)
    
def single_feat(chunked_list,sent_list, hr):
    count_single=0
    for s, (sentence, chunkedSentence) in enumerate(zip(sent_list,chunked_list)):
        chunkPattern = [ch.chunkType for ch in chunkedSentence]
        sentPattern = [ch.tokens for ch in chunkedSentence]
        type_sent=sentenceType(chunkedSentence)
        if(type_sent=="singleverb"):
            buff_context=singleverb_func(chunkPattern,sentPattern, hr)
            if((len(buff_context[0])!=0) and (buff_context[1]==1)):
                  count_single+=1
    
    return(count_single)
    
def multiple_feat(chunked_list,sent_list, hr):
    count_multiple=0

    for s, (sentence, chunkedSentence) in enumerate(zip(sent_list,chunked_list)):
        chunkPattern = [ch.chunkType for ch in chunkedSentence]
        sentPattern = [ch.tokens for ch in chunkedSentence]
        type_sent=sentenceType(chunkedSentence)
        if(type_sent=="multiverb"):
            buff_context=multiverb_func(chunkPattern,sentPattern, hr)
            #print chunkedSentence, buff_context
            if((len(buff_context[0])!=0) and (sum(buff_context[1])>0)):
            #if buff_context:    
                  count_multiple+=1	
    return(count_multiple)
    
def degenerate_sent(procTxt, hr, featureVals = {}, FKEY = 'degenerate_sent'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    #tree = Tree(procTxt[DKEY_TREE])
    
    retval  = degen_feat(procTxt[PTKEY_CHUNKEDSENTENCES],procTxt[PTKEY_SENTENCES], hr)
    
    featureVals[FKEY] = retval            
    return featureVals
    
def singleword_sent(procTxt, hr, featureVals = {}, FKEY = 'singleword_sent'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    #tree = Tree(procTxt[DKEY_TREE])
    
    retval  = single_feat(procTxt[PTKEY_CHUNKEDSENTENCES],procTxt[PTKEY_SENTENCES], hr)
    
    featureVals[FKEY] = retval            
    return featureVals 

def multiverb_sent(procTxt, hr, featureVals = {}, FKEY = 'multiverb_sent'):
    """
    """
    if haskey(featureVals, FKEY): return featureVals    
    #tree = Tree(procTxt[DKEY_TREE])
    
    retval  = multiple_feat(procTxt[PTKEY_CHUNKEDSENTENCES],procTxt[PTKEY_SENTENCES], hr)
    
    featureVals[FKEY] = retval            
    return featureVals 
        
if __name__ == "__main__":
    import utils_gen as ug
    import time
    from Resources import DEFAULT_HR_FILE
    home = '/home/vh/PD/pdpack/ProblemDetection/'
    datahome = home + 'inst/python/dbg/data/' 
    data_name = 'processedProbTweets_train_real' 
    hr = pickle.load(open(DEFAULT_HR_PD))
    #procTxtLst = pickle.load(open('dbg/data/' + data_name + '.proctxts', 'rb'))
    
    f = open('logs/chunkpatterns_SVPOlarities.csv','w')
    myprint = f.write 
    
    for tw, procTxt in enumerate(procTxtLst):
#        fv = phrasalapprox(procTxt, hr, {})
#        print fv
        #print tw
        #myprint('**Tweet %d**\n' % tw)
        #resentment(procTxt, hr, myprint)
        chunkedSentenceAnalysis(procTxt, hr, myprint)
    f.close()