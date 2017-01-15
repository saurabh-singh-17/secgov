# -*- coding: utf-8 -*-
"""
Created on Tue Jul 21 05:03:32 2015

@author: svs
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

'''
finds the adjective intensifier for the nouns

'''
def findNounIntensifyingAdj(res):
    nounTags=['N','S','Z','^']
    returnDict={}
    for chunkSentences in res["chunkedSentences"]:
        for indc,chunk in enumerate(chunkSentences):
            if chunk.chunkType in ["NP","ADJP"]:
                for ind,tags in enumerate(chunk.tags):
                    if tags == "A":
                        assocNoun=-1
                        current_noun = []
                        for i in xrange(ind+1,chunk.tags.__len__()):
                            if chunk.tags[i] in nounTags:
                                assocNoun=i
                                current_noun="/".join((chunk.tokens[i],chunk.tags[i]))
                            elif chunk.tags[i] == "P":
                                break
                        #print("0")    
                        if assocNoun == -1:
                            if indc >= 2:
                                if ((chunkSentences[indc-1].chunkType == "VP") and (chunkSentences[indc-2].chunkType == "NP")):
                                    if  chunkSentences[indc-1].tprops[0].has_key("AUXVERB"):
                                        for j in xrange(chunkSentences[indc-2].tags.__len__()):
                                            if chunkSentences[indc-2].tags[j] in nounTags:
                                                assocNoun=j
                                                current_noun="/".join((chunkSentences[indc-2].tokens[j],chunkSentences[indc-2].tags[j]))
                                            elif chunkSentences[indc-2].tags[j] == "P":
                                                break
                        if assocNoun != -1:
                            current_adj = "/".join((chunk.tokens[ind],chunk.tags[ind]))
                            if ind !=0:
                                if chunk.tags[ind-1] == "R" and chunk.tokens[ind-1] in ["not","never"]:
                                    current_adj=" ".join(("not/R","/".join((chunk.tokens[ind],chunk.tags[ind]))))
                                    
                            if(returnDict.has_key(current_noun)):
                                returnDict[current_noun].append(current_adj)
                            else:
                                returnDict[current_noun]=[current_adj]
    return returnDict                            



'''
finds key verbs related to the nouns

'''
def findNounrelatedKeyVerbs(res,allVerbs=None):
    nounTags=['N','S','Z','^']
    AUX_VERB= ["do","does","did","has","have","had","is","am","are","was","were","be","being","been","may","must","might","should","could","would","shall","will","can"]
    returnDict={}
    for chunkSentences in res["chunkedSentences"]:
        for indc,chunk in enumerate(chunkSentences):
            if chunk.chunkType in ["VP"]:
                for ind,tags in enumerate(chunk.tags):
                    if (tags == "V" and chunk.tokens[ind] not in AUX_VERB):
                        if allVerbs:
                            if chunk.tokens[ind] not in allVerbs:
                                continue
                        assocNoun=-1
                        current_noun = []
                        if chunkSentences.__len__() - indc > 2:
                            if chunkSentences[indc+1].chunkType == "PP" and chunkSentences[indc+2].chunkType == "NP":
                                for i in xrange(chunkSentences[indc+2].tags.__len__()):
                                    if chunkSentences[indc+2].tags[i] in nounTags:
                                        assocNoun=i
                                        current_noun="/".join((chunkSentences[indc+2].tokens[i],chunkSentences[indc+2].tags[i]))
                                        
                        if assocNoun == -1:
                            if indc >= 1:
                                if (chunkSentences[indc-1].chunkType == "NP"):
                                    if  (chunk.tprops[0].has_key("AUXVERB") and chunk.tokens.__len__() > 1) or (chunk.tprops[0].has_key("AUXVERB") == False):
                                        for j in xrange(chunkSentences[indc-1].tags.__len__()):
                                            if chunkSentences[indc-1].tags[j] in nounTags:
                                                assocNoun=j
                                                current_noun="/".join((chunkSentences[indc-1].tokens[j],chunkSentences[indc-1].tags[j]))
                        
                        if assocNoun == -1:                             
                            if chunkSentences.__len__() - indc > 1:
                                if chunkSentences[indc+1].chunkType == "NP":
                                    for i in xrange(chunkSentences[indc+1].tags.__len__()):
                                        if chunkSentences[indc+1].tags[i] in nounTags:
                                            assocNoun=i
                                            current_noun="/".join((chunkSentences[indc+1].tokens[i],chunkSentences[indc+1].tags[i]))

                        
                        if assocNoun != -1:
                            current_verb = "/".join((chunk.tokens[ind],chunk.tags[ind]))
                            if ind !=0:
                                if chunk.tags[ind-1] == "R" and chunk.tokens[ind-1] in ["not","never"]:
                                    current_verb=" ".join(("not/R","/".join((chunk.tokens[ind],chunk.tags[ind]))))
                                    
                            if(returnDict.has_key(current_noun)):
                                returnDict[current_noun].append(current_verb)
                            else:
                                returnDict[current_noun]=[current_verb]
    return returnDict                            
