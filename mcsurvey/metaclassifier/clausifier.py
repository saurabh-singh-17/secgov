# -*- coding: utf-8 -*-
"""
Created on Tue Jul  8 01:27:49 2014

@author: shardulnaithani
"""

import cPickle as pickle
import sys
from ptdatatypes import ptSentence
#import utils_gen as ug
#from Resources import HostedResources,RESKEY_POLAR_NGRAMS,RESKEY_NEGATORS
#from config import DEFAULT_HR_FILE,  KEY_POLARITY_POSITIVE, KEY_POLARITY_NEGATIVE, KEY_NEGATION, DEFAULT_HR_PD


coordinating_conjunctions=set(["and", "&", "but","or","nor","for","yet","so",","])
#subordinating_conjunctions_2gram=["as if","now since","now that","now when","as though","where if","even if","even though","if only","if when","if then ","just as","provided that","rather than","so that"]
#subordinating_conjunctions_3gram=["as long as","as much as","as soon as","in order that"]
#subordinating_conjunctions_1gram=set(["that", "if", "although", "as", "cuz", "cause","because","since","supposing","than","though","till","unless","until","when","whenever","where","whereas","wherever","whether","which","while","who","whoever","what","whom","whose","how","why"])
subordinating_conjunctions_1gram=set(["if", "although", "as", "cuz", "cause","because","since","supposing","than","though","till","unless","until","when","whenever","where","whereas","wherever","whether","which","while","whoever","what","whom","whose","how","why"])
#that, who
subordinating_conjunctions_1gram=set(["if", "although", "as", "cuz", "cause","because","since","supposing","than","though","till","unless","until","when","whenever","where","whereas","wherever","whether", "while","whoever","what","whom","whose","how","why"])

subordinating_conjunctions_1gram=set(["although", "cuz", "cause","because","since","supposing", "though","till","unless","until","whereas"])


#,"that" ,"if"
#relative_conjunction_1st_half=["both","not only","either","neither","whether","as","such","scarcely","as many","no sooner","rather"]
#relative_conjunction_2nd_half=["and","but also","or","nor","or","as","that","when","as","than","than"]

noun_tags=set(["N","S","Z","O","^"])
verb_tags=set(["V","L","M","Y"])

def coordinating_check(tags,tw,lensent):
    if(((tw>0)and(tw<(lensent-1)))and ((tags[tw]=="&") or(tags[tw]==","))):
        if((tags[tw-1]!=tags[tw+1])and(any([tags[tw-1] not in noun_tags,tags[tw+1] not in noun_tags]))):
            return(1)
    return(0)

def subordinating_check(tags,tw,lensent):
    if((tw>0)and(tw<(lensent-1))):
        if((tags[tw-1]!=tags[tw+1])and(any([tags[tw-1] not in noun_tags,tags[tw+1] not in noun_tags]))):
    	    return(1)
    return(0)

#def lhs_rhsanalysis(lhs,rhs,type_flag,rhs_tok):
#    if(any(k for k in lhs if k in noun_tags)):
#	if(any(i for i in lhs if i in verb_tags)):
#	    if(any(j for j in rhs if j in noun_tags)):
#                if(any(g for g in rhs if g in verb_tags)):
#                    if(type_flag==1):
#	                for tw,m in enumerate(rhs_tok):
#			    if(m in coordinating_conjunctions):
#                                conj_check=coordinating_check(rhs,tw,len(rhs))
#	                        if(conj_check==1):
#                                    return(0)
#                                else:
#                                    return(1)
#                            else:
#                                return(1)
#                    else:
#                        return(1)
#    return(0)

def lhs_rhsanalysis(lhs,rhs,type_flag,rhs_tok):
    if(any([1 for k in lhs if k in noun_tags])):
        if(any([1 for i in lhs if i in verb_tags])):
            if(any([1 for j in rhs if j in noun_tags])):
                if(any([1 for g in rhs if g in verb_tags])):
                    if(type_flag==1):
                        for tw,m in enumerate(rhs_tok):
                            if(m in coordinating_conjunctions):
                                    conj_check=coordinating_check(rhs,tw,rhs.__len__())
                                    if(conj_check==1):
                                        return(0)
                                    else:
                                        return(1)
                            else:
                                return(1)
                    else:
                        return(1)
    return(0)

def clausify(sentence):
    """
    """
    clausify_flag=0
    start=0
    len_sent = sentence.tags.__len__()
    end = len_sent
    sentence_clause=[]
    clausedSentence  = []
    clauseIdx = []
    last_rhs=[]
    clause_check=0

    type_conj=0
    for tw, word in enumerate(sentence.tokens):
        if(word in coordinating_conjunctions):
            clause_check=coordinating_check(sentence.tags,tw,len_sent)
            type_conj=1
        elif( (not sentence.tags[tw] in ('V')) and word in subordinating_conjunctions_1gram):
            clause_check=subordinating_check(sentence.tags,tw,len_sent)
            type_conj=2
        else:
            clause_check=0

        if(clause_check==1):

            conjunction_tok=word

            lhsIdx = xrange(start, tw)
            rhsIdx = xrange(tw+1, end)
            cnjIdx = [tw]

            lhs=sentence.tokens[start:(tw)]
            lhs_tag=sentence.tags[start:tw]
            rhs=sentence.tokens[(tw+1):end]
            rhs_tag=sentence.tags[(tw+1):end]

            lhs_rhs_check=0
            lhs_rhs_check = lhs_rhsanalysis(lhs_tag,rhs_tag,type_conj,rhs)
            #print lhs_tag,rhs_tag,type_conj,rhs
            if(lhs_rhs_check == 1):
                clausify_flag = 1
                start = tw+1
                sentence_clause.append(lhs)
                sentence_clause.append(word)
                last_rhs = rhs
                last_rhsIdx = rhsIdx
                clauseIdx.append(lhsIdx)
                clauseIdx.append(cnjIdx)


    if(clausify_flag==1):
        sentence_clause.append(last_rhs)
        clauseIdx.append(last_rhsIdx)
        for clauseIds in clauseIdx:
            if clauseIds:
                toks = [sentence.tokens[k] for k in clauseIds]
                tags = [sentence.tags[k] for k in clauseIds]
                pols = [sentence.pols[k] for k in clauseIds]
                clausedSentence.append(ptSentence(toks, tags, pols))

    else:
        sentence_clause.append(sentence.tokens)
        clausedSentence.append(sentence)

#    print 'TOK-->', sentence_clause
#    print 'IDX-->', clausedSentence

    return clausedSentence #(sentence_clause)



if __name__ == "__main__":
    from processText import ptSentencify
    from config import MC_DATA_HOME, MC_LOGS_HOME
    from config import PTKEY_TOKENS, PTKEY_TAGS, PTKEY_TAGCONF, PTKEY_SENTENCES, PTKEY_CHUNKEDSENTENCES, PTKEY_CHUNKTYPE_NONE
    from config import PTKEY_PRECHUNK
    fname = 'data_semeval_6399_train' #'data_jr_1222_noAds'
    toktagfilename=MC_DATA_HOME + fname + '.proctxts' #
    procTxtLst = pickle.load(open(toktagfilename, 'rb'))

    print(len(procTxtLst))

    t = open(MC_LOGS_HOME + 'clause' + '.txt','w')
    myprint = t.write
#    myprint = sys.stdout.write
#    p = open('test_new.txt','w')
#    pprint = p.write
    clause_count=0
    for tm, procTxt in enumerate(procTxtLst):
        sentences= procTxt[PTKEY_PRECHUNK]
        myprint('Tweet-%d\n' % tm)
        for s, sentence in enumerate(sentences):
            myprint('*S:%d ~%s\n' % (s, sentence))
            clauses=clausify(sentence) #,chunkedSentence,myprint
            if len(clauses) > 1:
                myprint("**Clauses:\n")
                for clause in clauses:
                    myprint("%s\n" % (clause))
        myprint("---\n")
#        myprint("\n\n\n")
    t.close()
#    p.close()
