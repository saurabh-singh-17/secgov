# -*- coding: utf-8 -*-
"""
Created on Thu Sep 18 13:20:10 2014

@author: vh
"""

import cPickle as pickle
from collections import defaultdict, OrderedDict
import operator
from extractKeywords import *
from config import *
#from chunkPol import clausePolarity
from clause_pol import clausePolarity
from token_properties import tokenLexicalProps, updateTokenLexicalProperties

from config import  MC_DATA_HOME, MC_LOGS_HOME #, MC_TAGGER_HOME
from ppd_clause import *

#hr = pickle.load(open(DEFAULT_HR_FILE))
#neg_words = hr.resources[RESKEY_POLAR_NGRAMS].getDicts(1, KEY_POLARITY_NEGATIVE)

__KW_REL_NN_TAGS__ =  set([ 'Z','^','#', 'N','@'])#,'Z' #, '#',['V', 'P', 'R', 'L', 'Y', 'T']
inf_verb=['would','will','should','shall','must','might','may','have','had','has','having','do','did','does','doing','could','can','be','is','are','was','were','being','am']

__KW_NP_KEY__ = ["NP"]
__DAYS__= ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday","weekend","weekday","weekends","weekdays","tommorrow","today","yesterday","tonight"]
__DAYS__.extend(["mon","tue", "wed", "thurs", "fri", "sat", "sun"])
__TIMEWORDS__ = ["day", "time", "morning", "night", "evening", "afternoon", "month", "hour", "year", "week"]
__TIMEWORDS__.extend([t + "s" for t in __TIMEWORDS__])
__TIMEWORDS__.extend(["today", "yesterday", "tomorrow"])

__MISC__ = ["god", "lot", "life"]
__PROFANITY__ = ["ass", "nigga", "nigger", "porn"]

__NSTOPS__ = ["no", "some", "every", "any", "other","thanks","thank"]
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

pols_dict={0:"neutral",1:"positive",-1:"negative"}
#dict_noun=hr.resources['polar_nouns_dict']
def current_chunkpolarity(c,clause,pols,chPat):
    """function for extracting current chunk polarity"""
    #chPat, pols, negn, negtd = clausePolarity(clause, hr, None)
    ff=pols[c]
    if(pols[c]!=0):
        #if(pols[c]>1):
        #    ff=1
        #elif(pols[c]<0):
        #    ff=-1
        #return(int(ff/abs(ff)))
        pols[c]=int(ff/abs(ff))
        return(pols)
    else:
        if(c>0):
            k=c-1
            if((chPat[k] in ["VP","ADVP","ADJP","NP"])and (pols[k]!=0)):
                ff=pols[k]
                pols[c]=int(ff/abs(ff))
                #return((pols,int(ff/abs(ff))))
                return(pols)
            elif(((chPat[k]=="VP"))or(chPat[k]=="PP")or((chPat[k]=="NONE")and(clause[k].tags[0] in [",","&"]) and(clause[k].tokens[0] != "but"))):
                if(k>0):
                    m=k-1
                    if((chPat[m] in ["VP","ADVP","ADJP","NP"])and (pols[m]!=0)):
                        ff=pols[m]
                        pols[c]=int(ff/abs(ff))
                        #return((pols,int(ff/abs(ff))))
                        return(pols)

        if(c<(len(chPat)-1)):
            k=c+1
            if((chPat[k] in ["VP","ADVP","ADJP","NP"])and (pols[k]!=0)):
                ff=pols[k]
                pols[c]=int(ff/abs(ff))
                #return((pols,int(ff/abs(ff))))
                return(pols)
                #and(any([mo for mo in clause[k].tokens if mo in inf_verb])
            elif(((chPat[k]=="VP")) or(chPat[k]=="PP")or ((chPat[k]=="NONE")and(clause[k].tags[0] in [",","&"]) and(clause[k].tokens[0] != "but")) ):
                if(k<(len(chPat)-1)):
                    m=k+1
                    if((chPat[m] in ["VP","ADVP","ADJP","NP"])and (pols[m]!=0)):
                        ff=pols[m]
                        pols[c]=int(ff/abs(ff))
                        #return((pols,int(ff/abs(ff))))
                        return(pols)
    #return((pols,int(ff)))
    return(pols)

def extract_words(chunk,c,chpat,hr):
    tt=[]
    for tok, tag,pola in zip(chunk.tokens, chunk.tags , chunk.pols):
        
        tkey = '%s/%s' % (tok, tag)
        
        if tag in __KW_REL_NN_TAGS__:
            if ((len(tok) > 1)  and (tok not in __KW_NP_STOP_WORDS__)and (tok not in hr.resources['polar_nouns_dict']) and (pola ==0)):#(tok not in neg_words):
                if(tag=="@"):
                    len_clause=len(chpat)
                    if(c>0):
                        prev_ind=c-1
                        if(chpat[prev_ind] in ['PP','VP','NP']):
                            #tt.append(' '.join(tok.split('_NG_')))
                            tt.append(tkey)
                            continue
                    if(c<(len_clause-1)):
                        next_ind=c+1
                        if(chpat[next_ind] in ['PP','VP','NP']):
                            #tt.append(' '.join(tok.split('_NG_')))
                            tt.append(tkey)
                            continue
                    continue
                else:
                    #tt.append(' '.join(tok.split('_NG_')))
                    tt.append(tkey)
    return(tt)



def single_verb(clause,pols,ind_verb):

    #ind_verb=chPat.index("VP")
    #verb=clause[ind_verb]
     #LHS=clause[0:ind_verb]
    LHS_pol=pols[0:ind_verb]
     #RHS=clause[ind_verb+1:len(clause)]
    RHS_pol=pols[ind_verb+1:len(clause)]
    LHS_flag=-9
    RHS_flag=-9
    gn=0
    jojoba=[int(ff/abs(ff)) for ff in LHS_pol if ff!=0]
    LHS_polarity=sum(LHS_pol)
    RHS_polarity=sum(RHS_pol)
    if((jojoba.count(-1)) and jojoba.count(1)):
       LHS_polarity=-1

    jojoba=[int(ff/abs(ff)) for ff in RHS_pol if ff!=0]
    
    if((jojoba.count(-1)) and jojoba.count(1)):
        RHS_polarity=-1
            
        
    
    verb_flag=pols[ind_verb]

    if(len(LHS_pol)!=0):
        LHS_flag=len([i for i in LHS_pol if i!=0])
    if(len(RHS_pol)!=0):
        RHS_flag=len([i for i in RHS_pol if i!=0])
    pol_rhs=RHS_pol
    pol_lhs=LHS_pol
    if(RHS_flag>0):
        if(RHS_polarity):
             #RHS_polarity=int(RHS_polarity/abs(RHS_polarity))
             pol_rhs=[RHS_polarity for i in RHS_pol]
    #elif(RHS_flag==0):
        elif(verb_flag):
      #      #verb_flag=int(verb_flag/abs(verb_flag))
            pol_rhs=[verb_flag for i in RHS_pol]
        #elif(LHS_polarity):
            #LHS_polarity=int(LHS_polarity/abs(LHS_polarity))
        #    pol_rhs=[LHS_polarity for i in RHS_pol]
#    if(LHS_flag>0):
#        if(LHS_polarity):
#             #LHS_polarity=int(LHS_polarity/abs(LHS_polarity))
#             pol_lhs=[LHS_polarity for i in LHS_pol]
#    elif(LHS_flag==0):
#        if(verb_flag):
#            #verb_flag=int(verb_flag/abs(verb_flag))
#            pol_lhs=[verb_flag for i in LHS_pol]
#        elif(RHS_polarity):
#            #RHS_polarity=int(RHS_polarity/abs(RHS_polarity))
#            pol_lhs=[RHS_polarity for i in LHS_pol]
    if(verb_flag):
            #verb_flag=int(verb_flag/abs(verb_flag))
        pol_lhs=[verb_flag for i in LHS_pol]
    elif(RHS_polarity):
            #RHS_polarity=int(RHS_polarity/abs(RHS_polarity))
        pol_lhs=[RHS_polarity for i in LHS_pol]
    elif(LHS_polarity):
         pol_lhs=[LHS_polarity for i in LHS_pol]
    #print(pol_lhs)
    pol_lhs.extend([verb_flag])
    pol_lhs.extend(pol_rhs)
    return(pol_lhs)

def entity_sentiment(ProcTxt,hr, sentiment_flag=1):

#        try:
#            ProcTxt[PTKEY_CHUNKEDCLAUSES][0][0][0].tprops
#        except:
#            ProcTxt = updateTokenLexicalProperties(ProcTxt, hr)

        retvaldict = defaultdict(list)
        Keyword=[]
        total_toks=[]
        fo=0

        for sen in ProcTxt[PTKEY_CHUNKEDCLAUSES]:
            for bn,clause in enumerate(sen):
                cn=[]
                fo=1
                chPat, pols, negn, negtd = clausePolarity(clause, hr, None)
                pols_neg=[]
                for ind,act in enumerate(negtd):
                    if(act==1 and negn[ind]==0):
                        pols_neg.append(pols[ind]*-1)
                    else:
                        pols_neg.append(pols[ind])
                pols=pols_neg
                mn=[]
                n_vp, n_vpfinite, vpidx, lhs, vp, rhs=clauseVPAnalysis(clause)
                if ((n_vpfinite == 0 and n_vp == 1) or (n_vpfinite == 1)):
                    pols=single_verb(clause,pols,vpidx)
                ind_np=[]
                for c, chunk in enumerate(clause):
                    #logger(' %s' % (chunk))
                    tt=[]

                    if(chunk.chunkType=="NP"):
                        tt=extract_words(chunk,c,chPat,hr)
                        if(len(tt)!=0):
                            ind_np.append(c)
                            ft=" ".join(tt)
                            mn.extend([ft])
                            pols=current_chunkpolarity(c,clause,pols,chPat)
              

                if(len(ind_np)!=0):
                    for key_ind,ind in enumerate(mn):
                        ff=pols[ind_np[key_ind]]
                        gn=ind+pols_dict[ff]
                        cn.extend([gn])
                        retvaldict[ind].append(pols_dict[ff])
                Keyword.extend(cn)

        retval = []
        if(sentiment_flag==0):
            return(retvaldict.keys())
        else:
            #return(retvaldict)
            for k, v in retvaldict.iteritems():
                od = OrderedDict()
                od['entity'] = k
                od['sentiment'] = v
                retval.append(od) #{'aspect':k,'sentiment':v})
        return(retval)


#logfile.close()
#log2.close()
def str_clean(stri):
    buff=stri.lower()
    buff=buff.strip()
    buff=buff.replace("u'","'")
    buff=buff.replace("at&t","att")
    buff=buff.replace("t-mobile","tmobile")
    buff=buff.replace("@","")
    buff=buff.replace("#","")
    buff=buff.replace(" '","'")
    buff=buff.replace("' ","'")
    return(buff)

if __name__=="__main__":
    from processText import updateTokenAndChunkProperties
    import json
    import ast
    import utils_gen as ug
    
    data_name= 'entityEval' 
    txts = ug.readlines(MC_DATA_HOME + data_name + '.txts')
    tru_entities = [ast.literal_eval(a) for a in ug.readlines(MC_DATA_HOME + data_name + '.lbls')]
    procTxts = pickle.load(open(MC_DATA_HOME + data_name + '.proctxts'))  

    hr = pickle.load(open(DEFAULT_HR_FILE)) 
    
    
    prd_entities = []
    ttxts = []
    for proctxt in procTxts:
        proctxt = updateTokenAndChunkProperties(proctxt, hr)
        prd_entities.append(entity_sentiment(proctxt,hr,1))
        ttxts.append(proctxt[PTKEY_TOKENS])
    pickle.dump([tru_entities, prd_entities, ttxts], open(MC_LOGS_HOME + 'temp2.pik', 'wb'))
     
#    predicted_entity=[]
#    actual_entity=[]
#
##    lk=[j.strip() for j in open("/home/shardulnaithani/Sentiment/untitleddocxt.2")]
#    
##    for l,k in enumerate(lk):
##        #print(l)
##        buff=str_clean(k)
##        buff=eval(buff)
##        
##        actual_entity.append(buff)
#
#    for ind,proctxt in enumerate(ProcTxts):
#        proctxt = updateTokenAndChunkProperties(proctxt, hr)
#        es = entity_sentiment(proctxt,hr,1)
#        print es
#        
##        an=str(dict(entity_sentiment(proctxt,hr,1)))
##        logger_verb("Actual_entity_sentiment%s\n"%actual_entity[ind])
##        logger_verb("\n\n\n")
##        bn=str_clean(an)
##        bn=eval(bn)
##        predicted_entity.append(bn)
##        logger2("%s\n"%an)
##    file_verb.close()
##    nj=defaultdict(dict)
##    Txts = [j.strip() for j in open((MC_DATA_HOME + data_name + '.txts'))]
##    print(len(actual_entity),len(predicted_entity),len(Txts))
##    for k,i in enumerate(Txts):
##        nj[k]["txts"]=i
##        nj[k]["actual"]=actual_entity[k]
##        nj[k]["predicted"]=predicted_entity[k]
##    log2.close()
##    
##    log3=open(MC_LOGS_HOME + 'entity_pickle', 'w')
##    pickle.dump(nj,log3)
##      
##    log3.close()
##    bn=0
##    kl=0
##    for k in nj:
##        bn+=len(nj[k]["actual"].keys())
##        for m in (nj[k]["actual"].keys()):
##            kl+=1
##            if(nj[k]["predicted"].has_key(m)):
##                if(nj[k]["actual"][m]==nj[k]["predicted"][m]):
##                    bn+=1
##            else:
##                bn+=0
##        #if(collections.Counter(nj[k]["actual"].keys())==collections.Counter(nj[k]["predicted"].keys())):
##        #if(len(nj[k]["actual"].keys())<=len(nj[k]["predicted"].keys())):
##            if(set(nj[k]["actual"].keys())& set(nj[k]["predicted"].keys())):
##                
##                
##                bn+=1
##  
#
#        
