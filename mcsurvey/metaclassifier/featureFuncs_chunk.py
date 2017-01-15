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
from processText import PTKEY_TOKENS, PTKEY_TAGS
from utils_features import haskey
import nltk
#happening_verbs_lst=["fail","crash","overload","trip","fix","mess","break","overcharge","disrupt","charging"] 
#problem_nouns_lst=["crash","failure","issue","outage","problem","trouble"]
#softer_verbs_lst=["die","drop","bite","fuck","trouble","foil"]
import cPickle as pickle
import utils_gen as ug

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