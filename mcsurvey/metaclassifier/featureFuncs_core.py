# -*- coding: utf-8 -*-
"""
Created on Sat Mar 15 18:20:13 2014

@author: vh
"""
#from warnings import warn
from utils_features import haskey
from config import *
from processText import PTKEY_TOKENS, PTKEY_TAGS, PTKEY_PRECHUNK, unigramPol
from Resources import RESKEY_POLAR_NGRAMS, RESKEY_NEGATORS, RESKEY_SMILEYS
from Resources import RESKEY_DOMAIN_NOUNS, RESKEY_PHRASE_NO_PREP, RESKEY_NO_PARTICLE
from Resources import RESKEY_OPENCLAUSALCOMPLIMENT, RESKEY_HAPPENINGVERBS
from Resources import RESKEY_PROBNOUNS, RESKEY_SOFTVERBS, RESKEY_NOTHAPPENINGVERBS, RESKEY_ENGWORDS
from collections import defaultdict

###HASHTAG
#enwords=[i.strip() for i in open("englishwords.txt").readlines()]
#wdict = dict()
#for word in enwords:
#    if wdict.has_key(word) == 0:
#        wdict[word] = True
#del enwords, word, i

INTENSIFIER_TYPE1= set(['absolutely', 'totally', 'really', 'bloody', 'incredibly', 'pretty', 'extremely', 'terribly', 'hella', 'remarkably', 'awful', 'awesomely', 'ridiculously', 'plenty', 'wicked', 'super', 'so', 'dead', 'quite', 'real', 'too', 'tooo', 'effective', 'slightly', 'somewhat', 'even', 'less', 'nearly', 'kind+of'])
#INTENSIFIER_TYPE1 = ['still', 'ever', 'even', 'absolutely', 'just_NC_too', 'significantly','seriously', 'fairly', 'totally', 'really', 'bloody',  'incredibly', 'pretty', 'extremely', 'terribly', 'hella', 'remarkably', 'awful', 'awesomely', 'ridiculously', 'plenty', 'wicked', 'super', 'so', 'dead', 'quite', 'real']

#def haskey(featureVals, fkey):
#    """
#    Check if featureVals contains FKEY
#    This is a check to see if FKEY has been previously computed.
#    """
#    if featureVals.has_key(fkey):
#        s = 'Has %s already computed' % (fkey)
#        warn(s)
#        return True 
#    return False 
        
def countPOS(procTxt, hr, featureVals = {}, FKEY = 'countPOS'): #function for extracting features from a tweet and returning feature list 
    """
    The number of polar ADJ, ADV and VERBS.
    Retval: {FKEY: {'positive': poscount, 'negative': negcount, 'neutral': neucount}}
    where:
    poscount = {'adjective': posadjcount, 'adverb': posadvcount, 'verb': posvrbcount}
    similarly for negcount and neucount.
    eg.. usage:
    fv = countPolarPOS(procTxt, hr)
    cpp = fv['countPolarPOS']
    no of neutral adjectives = cpp['neutral']['adjectives']
    sum of all positive A,R,V = sum(cpp['positive'].values())
    CODE NEEDS REWORK.
    """
    if haskey(featureVals, FKEY): return featureVals
    tokens = procTxt.tokens #procTxt[PTKEY_TOKENS]
    tags = procTxt.tags #procTxt[PTKEY_TAGS]
    pols = procTxt.pols #[ pol for sentence in procTxt[PTKEY_PRECHUNK] for pol in sentence.pols]
#    print tokens
#    print pols    
    tweet = [(tok,tag, pol) for tok, tag, pol in zip(tokens, tags, pols)]
#    if any(pols):
#        print tweet
        
#    posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE) #hr.posWords
#    negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE) #hr.negWords
    negation = hr.resources[RESKEY_NEGATORS].getDicts(1, KEY_NEGATION) #hr.negation
    hap_verbs = set(hr.resources[RESKEY_HAPPENINGVERBS])
    soft_verbs = set(hr.resources[RESKEY_SOFTVERBS])
    #openClauseComp = set(hr.resources[RESKEY_OPENCLAUSALCOMPLIMENT])
    probNouns = set(hr.resources[RESKEY_PROBNOUNS])
    #noParticle = set(hr.resources[RESKEY_NO_PARTICLE])
    nhap_verbs = set(hr.resources[RESKEY_NOTHAPPENINGVERBS])
    #tweet = tokTag    
#    adj=[]  #list containing all the adjectives
#    adv=[]
   
    retpos = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retneg = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retneu = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retval = {KEY_POLARITY_POSITIVE:retpos, KEY_POLARITY_NEGATIVE:retneg, KEY_POLARITY_NEUTRAL:retneu}
    #noun_keys=["N","O","S"]
    #check if txt contains relevant tags.
    #adj = [tw[0] for tw in tweet if tw[1] == POSKEY_ADJ]
    containsRelTags = [tw[0] for tw in tweet if tw[1] in [POSKEY_ADJ,POSKEY_ADV, POSKEY_VRB,POSKEY_NOUN,POSKEY_INTJ]]
    tweet = [(tw[0].replace('#',""), tw[1], tw[2]) for tw in tweet]
    
    if containsRelTags:
        #POS counters
        posj, negj, neuj, posadv, negadv, neuadv, posver, negver, neuver, posnou, negnou, neunou, posintj, negintj, neuintj= [0]*15 # #posj, negj, neuj = [0]*3 #posj=0; negj=0; neuj=0; posadv=0; negadv=0; neuadv=0; posver=0; negver=0; neuver=0
        #prev tok position vars
        prev_adj, prev_verb, prev_adver, prev_noun = [-1]*4 #prev_adj=-1; prev_verb=-1; prev_adver=-1 
        
        #flag for storing whether polarity of previous POS was reversed or not, if 1 then it was reversed else 0
        prev_act, prev_act_verb, prev_act_adver, prev_act_noun = [0]*4 #prev_act=0; prev_act_verb=0; prev_act_adver=0 

        for i, tw in enumerate(tweet): #in range(len(tweet)): #for loop number :1
            #print tweet[i]
            pos, neg = [0]*2            #flag for telling whether the current word is positive/negative or not
            adjec, ver, adver, nou, intj = [0]*5   #flag for denoting whether current polar word is an adverb or not

            #if(tweet[i][1]!=POSKEY_ADJ and tweet[i][1]!=POSKEY_ADV and tweet[i][1]!=POSKEY_VRB):
            if not tweet[i][1] in [POSKEY_ADJ, POSKEY_VRB, POSKEY_ADV, POSKEY_NOUN, POSKEY_INTJ]:    
                continue
            elif(tweet[i][1]==POSKEY_ADJ):#if word is adjective
                if tweet[i][0] in negation:# if word is a negation then got to the next iteration of the loop :1
                    continue
                elif tweet[i][2] > 0: #tweet[i][0] in posWords :#if word is positive 
                    posj=posj+1 #increase positive counter
                    pos=1	    #flag for polarity of the word
                elif tweet[i][2] < 0: #tweet[i][0] in negWords: #if word is negative
                    negj=negj+1 
                    neg=1	    
                else:
                    neuj=neuj+1 #if none of the above cases are true then word is neutral, hence incrementing neutral counter
                    continue    #since there is no polarity to be assigned hence moving to next iteration of loop :1
                adjec=1

            elif(tweet[i][1]==POSKEY_ADV):#if word is adverb
                if tweet[i][0] in negation:# if word is a negation then got to the next iteration of the loop :1
                    continue
                elif tweet[i][2] > 0: #tweet[i][0] in posWords :#if word is positive 
                    posadv=posadv+1#increase positive counter
                    pos=1  #flag for polarity of the word
                elif tweet[i][2] < 0: #tweet[i][0] in negWords:#if word is negative
                    negadv=negadv+1 #increase negative counter
                    neg=1    #flag for polarity of the word
                else:
                    neuadv=neuadv+1 #if none of the above cases are true then word is neutral hence incrementing neutral counter
                    continue #since there is no polarity to be assigned hence moving to next iteration of the loop :1
                adver=1
				
            elif(tweet[i][1]==POSKEY_VRB): #if the word is a verb
                if tweet[i][0] in negation:# if word is a negation then got to the next iteration of the loop
                    continue
                elif tweet[i][2] > 0: #tweet[i][0] in posWords : #if word is positive
                    posver=posver+1 #increase positive counter
                    pos=1  #flag for polarity of the word
                elif ((tweet[i][2] < 0)): # or (tweet[i][0] in hap_verbs) or (tweet[i][0] in soft_verbs)) : #tweet[i][0] in negWords: #if word is negative
                    negver=negver+1 #increase negative counter
                    neg=1 #flag for polarity of the word
                else:
                    neuver=neuver+1 #if none of the above cases are true then word is neutral hence incrementing neutral counter
                    continue  #since there is no polarity to be assigned hence moving to next iteration of the loop :1
                ver=1
                if(i<(len(tweet)-1)):#if there ia an adjective or adverb next to a verb , don`t change the verb`s polarity and move to next iteration of loop :1
                    if(tweet[i+1][1] == POSKEY_ADJ or tweet[i+1][1]==POSKEY_ADV):
                        prev_verb=i
                        prev_act_verb=0
                        continue
            elif(tweet[i][1]==POSKEY_NOUN): #if the word is a verb
                if tweet[i][0] in negation:# if word is a negation then got to the next iteration of the loop
                    continue
                elif tweet[i][2] > 0: #in posWords : #if word is positive
                    posnou=posnou+1 #increase positive counter
                    pos=1  #flag for polarity of the word
                elif ((tweet[i][2] < 0)): # or (tweet[i][0] in probNouns)): #if word is negative
                    negnou=negnou+1 #increase negative counter
                    neg=1 #flag for polarity of the word
                else:
                    neunou=neunou+1 #if none of the above cases are true then word is neutral hence incrementing neutral counter
                    continue  #since there is no polarity to be assigned hence moving to next iteration of the loop :1
                nou=1
             			
          
            elif(tweet[i][1]==POSKEY_INTJ): #if the word is a verb
                if tweet[i][0] in negation:# if word is a negation then got to the next iteration of the loop
                    continue
                elif tweet[i][2] > 0 : #if word is positive
                    posintj=posintj+1 #increase positive counter
                    pos=1  #flag for polarity of the word
                elif tweet[i][2] < 0 : #if word is negative
                    negintj=negintj+1 #increase negative counter
                    neg=1 #flag for polarity of the word
                else:
                    neuintj=neuintj+1 #if none of the above cases are true then word is neutral hence incrementing neutral counter
                intj=1
                continue
                


				
            for k in reversed(range(i)):#running a reversed loop from start of the current word to its left
                if tweet[k][0] in negation:#checking for negation tagging
                    counter=0 #counter for telling number of permitted POS between negation and word
                    m=k+1
                    while(m<i):#checking the pos between word and negation
                        if(adjec==1):#for adjectives
                            if (tweet[m][1] == POSKEY_DET or tweet[m][1]==POSKEY_PREP or tweet[m][1]==POSKEY_CC or tweet[m][0]==POSKEY_PUNC or tweet[m][1]==POSKEY_VRB):
                                counter=counter+1 #increment the counter if the word belongs to above POS
                            elif(tweet[m][1] == POSKEY_ADJ or tweet[i][1]==POSKEY_ADV):
#                                if(tweet[m][0] not in posWords):
#                                    if(tweet[m][0] not in negWords):
#                                        counter=counter+1#increment the counter if word is a neutral adjective or adverb
                                if tweet[m][2] == 0:
                                    counter += 1                                    
                        elif(adver==1):# for adverbs (same as adjectives)
                            if (tweet[m][1] == POSKEY_DET or tweet[m][1]==POSKEY_PREP or tweet[m][1]==POSKEY_CC or tweet[m][0]==POSKEY_PUNC or tweet[m][1]==POSKEY_VRB ):
                                counter=counter+1
                            elif(tweet[m][1] == POSKEY_ADJ or tweet[i][1]==POSKEY_ADV ):
#                                if(tweet[m][0] not in posWords):
#                                    if(tweet[m][0] not in negWords):
#                                        counter=counter+1
                                if tweet[m][2] == 0:
                                    counter += 1
                                    
                        elif(ver==1):#for verbs	
                            if(tweet[m][1]==POSKEY_VRB):#increment the counter only when the word between negation and verb is a verb
                                counter=counter+1
                        	
                        elif(nou==1):#for verbs	
                            if(tweet[m][1]==POSKEY_VRB or tweet[m][1] == POSKEY_DET or tweet[m][1]==POSKEY_PREP or tweet[m][1]==POSKEY_CC or tweet[m][0]==POSKEY_PUNC or tweet[m][1] == POSKEY_ADJ or tweet[i][1]==POSKEY_ADV or tweet[i][1]=='Z' ):#increment the counter only when the word between negation and verb is a verb
                                counter=counter+1
                        m=m+1
					
                    word_len=i-(k+1) #this counter tells the actual number of words between negation and current polar POS
                    if (counter==word_len): #if all the words are of permitted POS type then change the poarity
                        if(adjec==1):								
                            prev_act=1 #flag stores whether polarity was changed or not in case of adjectives
                        elif(ver==1):
                            prev_act_verb=1 #flag stores whether polarity was changed or not in case of verb
                        elif(adver==1):
                            prev_act_adver=1 #flag stores whether polarity was changed or not in case ofadverb
                        if(pos == 1):  #check the polarity for being positive and change correspoding flag accordingly							
                            if(adjec==1):
                                posj=posj-1
                                negj=negj+1
                            elif(ver==1):
                                posver=posver-1
                                negver=negver+1
                            elif(adver==1):
                                posadv=posadv-1
                                negadv=negadv+1
                            elif(nou==1):
                                posnou=posnou-1
                                negnou=negnou+1
								
                        elif(neg==1):
                            if(adjec==1):
                                posj=posj+1
                                negj=negj-1
                            elif(ver==1):
                                posver=posver+1
                                negver=negver-1
                            elif(adver==1):
                                posadv=posadv+1
                                negadv=negadv-1
                            elif(nou==1):
                                posnou=posnou+1
                                negnou=negnou-1
                             
                    else: #now we have to check whether there are any previous polar adverbs ,a djectives or verbs between negation and current polar word
                        if(adjec==1): # check for adjectives
                            if(prev_adj !=-1): #if this is not the first polar adjective
                                count=0
                                position=prev_adj+1
                                while(position<i): #check from current polar word till prev polar adjective
                                    if ((tweet[position][1] == POSKEY_DET or tweet[position][1]==POSKEY_PREP or tweet[position][1]==POSKEY_CC or tweet[position][0]==POSKEY_PUNC) and tweet[position][0] != 'but'): # if word is mentioned POS tag except but then increment the counter
                                        count=count+1
                                    elif(tweet[position][1] == POSKEY_ADJ or tweet[position][1] == POSKEY_ADV):# if word is a non polar adjective or adverb then increment the counter
#                                        if(tweet[position][0] not in posWords):
#                                            if(tweet[position][0] not in negWords):
#                                                count=count+1
                                        if tweet[position][2] == 0:
                                            count += 1
                                            
                                    position=position+1
                                word_bet=i-position# this counter provides the number of words between current word and previous polar word
                                if (count==word_bet): # if number of words belong to permitted class of POS tags then change the polarity
                                    if(prev_act==1):
                                        if(pos == 1):
                                            posj=posj-1
                                            negj=negj+1
                                        elif(neg==1):
                                            negj=negj-1
                                            posj=posj+1
                                    elif(prev_act==0):
                                        prev_act=0
                                else:
                                    prev_act=0
                        elif(adver==1): #check for adjverbs , same as adjectives
                            if(prev_adver !=-1):
                                count=0
                                position=prev_adj+1
                                while(position<i):
                                    if ((tweet[position][1] == POSKEY_DET or tweet[position][1]==POSKEY_PREP or tweet[position][1]==POSKEY_CC or tweet[position][0]==POSKEY_PUNC) and tweet[position][0] != 'but'):
                                        count=count+1
                                    elif(tweet[position][1] == POSKEY_ADJ or tweet[position][1] == POSKEY_ADV):
#                                        if(tweet[position][0] not in posWords):
#                                                if(tweet[position][0] not in negWords):
#                                                    count=count+1
                                        if tweet[position][2] == 0:
                                            count += 1
                                    position=position+1
                                word_bet=i-position
                                if (count==word_bet):
                                    if(prev_act_adver==1):
                                        if(pos == 1):
                                            posadv=posadv-1
                                            negadv=negadv+1
                                        elif(neg==1):
                                            negadv=negadv-1
                                            posadv=posadv+1
                                    elif(prev_act_adver==0):
                                        prev_act_adver=0
                                else:
                                    prev_act_adver=0
                        elif(ver==1): #if current polar word is a verb
                            if(prev_verb !=-1 ):# if this is not the first polar verb
                                count=0
                                position=prev_verb+1
                                while(position<i):#check from current polar word till prev polar verb
                                    if (tweet[position][0] == POSKEY_PUNC or tweet[position][0]=='and' or tweet[position][0]=='or'): #increment the counter only when word belongs to these POS
                                        count=count+1
                                    position=position+1
                                word_bet=i-position #this counter tells the actual number of words between the current verb and previous polar verb
                                if (count==word_bet):
                                    if(prev_act_verb==1):
                                        if(pos == 1):
                                            posver=posver-1
                                            negver=negver+1	
                                        elif(neg==1):
                                            negver=negver-1
                                            posver=posver+1
                                        prev_act_verb=1
                                    elif(prev_act_verb==0):
                                        prev_act_verb=0
                                else:
                                    prev_act_verb=0
                    break
                else:
                    continue
            if(adjec==1):#storing position of current polar adjective as previous position for next polar adjective
                prev_adj=i
            elif(ver==1):#storing position of current polar verb as previous position for next polar verb
                prev_verb=i
            elif(adver==1):#storing position of current polar adverb as previous position for next polar adverb
                prev_adver=i
                               
        retval[KEY_POLARITY_POSITIVE]['adjective'] = posj; retval[KEY_POLARITY_NEGATIVE]['adjective'] = negj; retval[KEY_POLARITY_NEUTRAL]['adjective'] = neuj;
        retval[KEY_POLARITY_POSITIVE]['adverb'] = posadv; retval[KEY_POLARITY_NEGATIVE]['adverb'] = negadv; retval[KEY_POLARITY_NEUTRAL]['adverb'] = neuadv;
        retval[KEY_POLARITY_POSITIVE]['verb'] = posver; retval[KEY_POLARITY_NEGATIVE]['verb'] = negver; retval[KEY_POLARITY_NEUTRAL]['verb'] = neuver;
        retval[KEY_POLARITY_POSITIVE]['noun'] = posnou; retval[KEY_POLARITY_NEGATIVE]['noun'] = negnou; retval[KEY_POLARITY_NEUTRAL]['noun'] = neunou;
        retval[KEY_POLARITY_POSITIVE]['interjection'] = posintj; retval[KEY_POLARITY_NEGATIVE]['interjection'] = negintj; retval[KEY_POLARITY_NEUTRAL]['interjection'] = neuintj;
    #featureVals[FKEY] = retval
    #print(retval)
    return retval
        ####normal features

    #return features

def countPolarPOS(procTxt, hr, featureVals = {}, FKEY = 'countPolarPOS'):
    
    if haskey(featureVals, FKEY): return featureVals
    retpos = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retneg = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retneu = {'adjective': 0, 'adverb':0, 'verb': 0,'noun':0,'interjection':0}
    retval = {KEY_POLARITY_POSITIVE:retpos, KEY_POLARITY_NEGATIVE:retneg, KEY_POLARITY_NEUTRAL:retneu}
    for clausedSentence in procTxt['clausedSentences']:
	for clause in clausedSentence:
            buff_retval=countPOS(clause,hr,featureVals)
            #print("######################################")
            #print(buff_retval)
            #print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
            for pol in retval: #plbls:
                 for pos in buff_retval[pol]:    
                     retval[pol][pos]+= buff_retval[pol][pos] 

    featureVals[FKEY] = retval
    return featureVals

def hash_take(htag, wdict):
    

    if(htag[0]=="#"):
        htag=htag[1:]
    nc = len(htag)
    begidx = 0
    parsedhtag = list()
    while begidx < nc:
        endidx = begidx
        flag=0
        for n in xrange(begidx,nc+1):
            tidx = n
            tw = htag[begidx:tidx]
        #print tw
            if tw.lower() in wdict: #.has_key(tw.lower()):
                flag=1
                endidx = tidx
        if(flag==0):
            endidx=nc
    
        parsedhtag.append(htag[begidx:endidx])
        begidx = endidx 
    #parsedhtag=" ".join(parsedhtag)
    return parsedhtag
    
def hashtag_calc(procTxt, hr, featureVals = {}, FKEY = 'hashtag_calc'):
    if haskey(featureVals, FKEY): return featureVals
    flag_hash=0
    hash_list=[]
    wdict = hr.resources[RESKEY_ENGWORDS]
    for k,i in enumerate(procTxt["tags"]):
        if(i=="#"):
            hash_list.extend(hash_take(procTxt["tokens"][k], wdict))
            flag_hash=1
    hashmaxpos = 'positivehashtag'
    hashmaxneg = 'negativehashtag'
    hashpol = 'negposhashtag'
    hashneu='neuhashtag'
    neg_cou=0
    pos_cou=0
    retval={hashmaxpos:False,hashmaxneg:False,hashpol:False,hashneu:False} 
    countDict = defaultdict(int)
    
    if(flag_hash==1):
        
        for hashWord in hash_list:
            pol = unigramPol(hashWord,  hr)
            countDict[pol] += 1
            
#        posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE) #hr.posWords
#        negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
#        neg_cou=len([i for i in hash_list if i in  negWords])
#        pos_cou=len([i for i in hash_list if i in  posWords])

    neg_cou = countDict[-1]
    pos_cou = countDict[1]
    
    retval=(neg_cou,pos_cou)
    featureVals[FKEY] = retval
    return featureVals

def countSmiley(procTxt, hr, featureVals = {}, FKEY = 'countSmiley'):
    """
    Number of Positive & Negative Smileys
    Retval: {FKEY: (N_NegSmiley, N_PosSmiley)}
    e.g, usage:
    fv = countSmiley(procTxt, hr)
    N_negsmiley, N_possmiley = fv['countSmiley']
    """
    if haskey(featureVals, FKEY): return featureVals
    
    tokens = procTxt[PTKEY_TOKENS]
    tags = procTxt[PTKEY_TAGS]
    
    smiley = hr.resources[RESKEY_SMILEYS]
    smileyNeg = smiley.getDicts(1,KEY_POLARITY_NEGATIVE)
    smileyPos = smiley.getDicts(1,KEY_POLARITY_POSITIVE)
    
    Nneg = 0; Npos = 0;
    #for tt in tokTag:
    for tok, tag in zip(tokens, tags):    
        #if(tt[1]== POSKEY_EMOT):
        if(tag == POSKEY_EMOT):    
            #if tt[0] in smileyNeg:
            if tok in smileyNeg:    
                Nneg += 1
            if tok in smileyPos:
                Npos += 1 
    retval = (Nneg, Npos)
    
    featureVals[FKEY] = retval            
    return featureVals
    
def hasIntensifier (procTxt, hr, featureVals = {}, FKEY = 'hasIntensifier'):
#    posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE) #hr.posWords
#    negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
    if haskey(featureVals, FKEY): return featureVals
    counter=0
    for l,m in enumerate(procTxt["tokens"]):
        
        if((m in INTENSIFIER_TYPE1) and(procTxt["tags"][l]=="R") ):
            if((l<(len(procTxt["tokens"])-1))): 
                if((procTxt["tags"][l+1] in ["R","A"])) :
                    counter+=1
    retval=counter
    featureVals[FKEY] = retval            
    return featureVals

#def negativeintensifier (procTxt, hr, featureVals = {}, FKEY = 'negativeintensifier'):
#    #posWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_POSITIVE) #hr.posWords
#    negWords = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)
#    if haskey(featureVals, FKEY): return featureVals
#    counter=0
#    for l,m in enumerate(procTxt["tokens"]):
#        
#        if((m in INTENSIFIER_TYPE1) and(procTxt["tags"][l]=="R") ):
#            if((l<(len(procTxt["tokens"])-1)) and (procTxt["tags"][l+1] in ["R","A"]) and ((procTxt["tokens"][l+1] in negWords))):
#                counter+=1
#    retval=counter
#    featureVals[FKEY] = retval            
#    return featureVals

                  

def netPOSPolarity(procTxt, hr, featureVals = {}, FKEY = 'netPOSPolarity'):   
    """
    net POS Polarity based on polar POS counts.
    max 
    """
    if haskey(featureVals, FKEY): return featureVals

    if featureVals.has_key('countPolarPOS') == False:
        featureVals = countPolarPOS(procTxt, hr, featureVals)
    pposCount = featureVals['countPolarPOS']        

    maxposkey = 'max of positive words'
    maxnegkey = 'max of negative words'
    maxneukey = 'max of neutral words'    
    
    #plbls = [KEY_POLARITY_NEGATIVE, KEY_POLARITY_NEUTRAL, KEY_POLARITY_POSITIVE] #polarity labels
    POSLbls = ['adjective', 'adverb', 'verb']
               
    #sum by polarity.
    #num = {plbls[0]: 0, plbls[1]: 0, plbls[2]: 0}
    num = {KEY_POLARITY_NEGATIVE: 0, KEY_POLARITY_NEUTRAL: 0, KEY_POLARITY_POSITIVE: 0}
    for pol in num: #plbls:
        for pos in POSLbls:    
            num[pol] += pposCount[pol][pos] 

    
    maxcount = max(num.values())   
    retval = {maxposkey:False, maxnegkey:False, maxneukey:False, 'num':num}     
    #find net polarity.            
    #maxcount = max([num[plbls[0]], num[plbls[1]], num[plbls[2]]])        
    
    if sum(num.values()) > 0:
#        if(maxcount==num[plbls[0]]): retval[maxnegkey] = True
#        if(maxcount==num[plbls[1]]): retval[maxneukey] = True    
#        if(maxcount==num[plbls[2]]): retval[maxposkey] = True 
        if(maxcount==num[KEY_POLARITY_NEGATIVE]): retval[maxnegkey] = True
        if(maxcount==num[KEY_POLARITY_NEUTRAL]): retval[maxneukey] = True    
        if(maxcount==num[KEY_POLARITY_POSITIVE]): retval[maxposkey] = True  
        

    featureVals[FKEY] = retval
    return featureVals    
       
def totalPolarity(procTxt, hr, featureVals = {}, FKEY = 'totalPolarity'):
    """
    """
    
    if haskey(featureVals, FKEY): return featureVals 
        
    nopolkey = 'no pol words'
    nonegkey = 'no neg words'
    noposkey = 'no pos words'
    
    retval = {nopolkey:False, nonegkey:False, noposkey:False}   
    if featureVals.has_key('netPOSPolarity') == False:
        featureVals = netPOSPolarity(procTxt, hr, featureVals)
    netpol = featureVals['netPOSPolarity'] 
    num = netpol['num'] 

    if (num[KEY_POLARITY_POSITIVE] == 0) and (num[KEY_POLARITY_NEGATIVE] == 0):
        retval[nopolkey] = True
    if (num[KEY_POLARITY_POSITIVE] > 0) and (num[KEY_POLARITY_NEGATIVE] == 0):
        retval[nonegkey] = True
    if (num[KEY_POLARITY_POSITIVE] == 0) and (num[KEY_POLARITY_NEGATIVE] > 0):
        retval[noposkey] = True
    

    featureVals[FKEY] = retval
    return featureVals    
    
def hasURL(procTxt, hr, featureVals = {}, FKEY = 'hasURL'):
    """
    text contains url?
    retval {'hasURL': true/false}
    """    
    if haskey(featureVals, FKEY): return featureVals           
    tokens = procTxt[PTKEY_TOKENS]
    tags = procTxt[PTKEY_TAGS]
    
    retval = False
    for tag in tags: #tokTag:        
        if (tag == POSKEY_URL): #tt[1]
            retval = True
            break
            
    featureVals[FKEY] = retval
    return featureVals 
    
def netPOSPolarityURL(procTxt, hr, featureVals = {}, FKEY = 'netPOSPolarityURL'):
    """
    net POS polarity for texts with URL
    """
    if haskey(featureVals, FKEY): return featureVals
   
    urlmaxpos = 'url with max of positive words'
    urlmaxneg = 'url with max of negative words'
    urlmaxneu = 'url with max of neutral words'
    urlpol='url with polar words'
    retval = {urlmaxpos: False, urlmaxneg:False, urlmaxneu:False,urlpol:False}
    
    if featureVals.has_key('totalPolarity') == False:        
        featureVals = totalPolarity(procTxt, hr, featureVals)
        
    if featureVals.has_key('hasURL') == False:
        featureVals = hasURL(procTxt, hr, featureVals)
        
    netpol = featureVals['totalPolarity']
    hasurl = featureVals['hasURL']
         
    ####features with URL
    if(hasurl==1):
        if(netpol['no neg words']):
            retval[urlmaxpos] = True   
        if(netpol['no pos words']):
            retval[urlmaxneg] = True
        if(netpol['no pol words']):
            retval[urlmaxneu] = True
        if((netpol['no neg words']==False)and(netpol['no pos words']==False)and(netpol['no pol words']==False)):
            retval[urlpol] = True
    featureVals[FKEY] = retval
    return featureVals

def netPOSPolarityLen(procTxt, hr, featureVals = {}, FKEY = 'netPOSPolarityLen'):
    """
    net POS polarity for short senetences.
    """
    if haskey(featureVals, FKEY): return featureVals
    tokens = procTxt[PTKEY_TOKENS]
    tags = procTxt[PTKEY_TAGS]
    
    #feature names.
    ssmaxpos = 'short sentence with max of positive words'
    ssmaxneg = 'short sentence with max of negative words'
    ssmaxneu = 'short sentence with max of neutral words'

    if featureVals.has_key('netPOSPolarity') == False:
        featureVals = netPOSPolarity(procTxt, hr, featureVals)
    netpol = featureVals['netPOSPolarity'] 
    num = netpol['num']
    retval = {ssmaxpos:False, ssmaxneg:False, ssmaxneu:False}
                   
    twLen = len(tokens) #(tokTag)
    if(sum(num.values()) > 0 and twLen <= 5):
        if(netpol['max of positive words']):
            retval[ssmaxpos] = True
        if(netpol['max of negative words']):
            retval[ssmaxneg] = True    
    #if(twLen <= 5):       
        if (netpol['num'][KEY_POLARITY_POSITIVE] == 0) and (netpol['num'][KEY_POLARITY_NEGATIVE] == 0):   
            retval[ssmaxneu] = True
    
    featureVals[FKEY] = retval        
    return featureVals    

from clause_pol import netPosteriorPolarChunks
from adDetect import adDetection
def isPolAd(procTxt, hr, featureVals = {}, FKEY = 'isPolAd'):
    """ """
    if FKEY in featureVals: return featureVals
    
    if not 'netPosteriorPolarChunks' in featureVals:    
        featureVals = netPosteriorPolarChunks(procTxt, hr, featureVals)
    if not 'adDetection' in featureVals:
        featureVals = adDetection(procTxt, hr, featureVals)
        
    cnt = featureVals['netPosteriorPolarChunks']
    isad = featureVals['adDetection']

    retval = {}    
    retval['isAdPOS'] = False
    if cnt > 0 and isad:
        retval['isAdPOS'] = True
    retval['isAdNEG'] = False
    if cnt < 0 and isad:
        retval['isAdNEG'] = True

    featureVals[FKEY] = retval        
    return featureVals                 
    
if __name__ == "__main__":
   #tokTag = [('this', 'O'), ('is', 'V'), ('not', 'A'), ('good', 'A'), (':)', 'E')]
   #procTxt = {'tokens': ['i', "don't", 'have', 'service', 'on', 'the', 'train', 'anymore', '?', 'verizon', ',', 'what', 'the', 'fuck', 'is', 'up', 'with', 'that', '?'], 
   #'tags': ['O', 'V', 'V', 'N', 'P', 'D', 'N', 'R', ',', '^', ',', 'O', 'D', 'N', 'V', 'T', 'P', 'O', ',']}
   
   #from Resources import HostedResources
   #hr = HostedResources()
   #hr = pickle.load(open(DEFAULT_HR_FILE, 'rb'))
   #fv = countSmiley(procTxt, hr)
   #fv = countSmiley(procTxt, hr, fv)
   #fv = netPOSPolarityURL(procTxt, hr, fv)
   #fv = netPOSPolarityLen(procTxt, hr, fv)
   #print fv
   #print netPOSPolarityURLFeature(tokTag, hr)

    import cPickle as pickle
    #from processText import ptSentence, ptChunk
    from ptdatatypes import ptSentence, ptChunk
    import utils_gen as ug 
    from Resources import HostedResources
    toktagfilename = 'dbg/data/data_semeval_test_orig.proctxts' #'dbg/data/cleanedupTestData.proctxts'    
    procTxtLst = pickle.load(open(toktagfilename, 'rb'))
    hr = pickle.load(open(DEFAULT_HR_FILE))
    num_sent=0
    twNum = 21
    chunktype = 'NP'
    
    ## Print Polarities of chunks in text:
    for tw, procTxt in enumerate(procTxtLst[twNum:(twNum+1)]):
        print(" ".join(procTxt["tokens"]))
        print netPOSPolarityURL(procTxt, hr) 
