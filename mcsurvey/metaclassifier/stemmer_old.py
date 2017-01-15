# -*- coding: utf-8 -*-
"""
Created on Mon Feb 16 15:03:45 2015

@author: anurag
"""

from config import *
import cPickle as pickle
from collections import defaultdict, Counter
from Resources import RESKEY_NEGATORS
#from InterrogativeAnalysis import questionsInText
from appDefs import *

TLP_V_ENDS_ING = 'ING'
TLP_V_ENDS_ED = 'ED'

VOWELS = set(['a','o','e','u','i'])

_NPA_NOUNTAGS = set(['D', '^', 'S', 'Z', 'L', 'O'])
_NPA_NTAG = set(['N'])
_IGNORE_ = set(['gcas'])



def stemNoun(tok):
    '''
    ignore list not to be stemmed
    '''
    if tok in _IGNORE_:
        return(tok)
    if(tok.endswith('\'s')):
        #print(tok)
        tok=tok[:len(tok)-2]
        flag=1
    '''
    berries->berry
    '''
    if tok.endswith('ies'):
        return(tok[:len(tok)-3]+"y")
    '''
    knives->knife
    '''
#    if (tok.endswith('ves')):
#        return(tok[:len(tok)-3]+"fe")
    '''
    match->matches
    box->boxes
    '''
    if (not tok.endswith('ss')) and (tok.endswith('es')):
        if (tok[len(tok)-4]=='c' and tok[len(tok)-3]=='h') or (tok[len(tok)-3]=='s' and tok[len(tok)-4]=='s') or (tok[len(tok)-4]=='s' and tok[len(tok)-3]=='h' ) or tok[len(tok)-3]=='x' or tok[len(tok)-3]=='z':
            return(tok[:len(tok)-2])
    if(tok.endswith('\'s')):
        tok=tok[:len(tok)-2]
    '''
    radii->radius
    '''
    if tok.endswith('ii'):
        return(tok[:len(tok)-1]+"us")
    '''file->files'''
    if (not tok.endswith('ss')) and (tok.endswith('s')):
        return(tok[:len(tok)-1])
    return(tok)

def stemVerb(tok):
    flag=0
    if tok in _IGNORE_:
        return(tok)
    if tok.endswith('ing') and tok[len(tok)-4] not in VOWELS :
        if tok[len(tok)-4]=='y' and len(tok)-3==2 :
            tok=tok[:len(tok)-4]+'ie'
            flag=1    
        '''
        creating->create
        '''
        if tok[len(tok)-4]  in set(['t','z','r','v','c','g']) and tok[len(tok)-5] in set(['a']):
            tok= tok[:len(tok)-3]+'e'
            flag=1
        '''
        closing->close
        using->use
        '''
        if tok[len(tok)-4]  in set(['s','v']) and tok[len(tok)-5] in VOWELS:
            tok= tok[:len(tok)-3]+'e'
            flag=1
        '''
        telling->tell
        '''
        if flag == 0 and tok[len(tok)-4] == tok[len(tok)-5] and tok[len(tok)-4]=='l':
            tok=tok[:len(tok)-3]
            flag=1
        '''
        getting->get
        '''
        if flag == 0 and tok[len(tok)-4] == tok[len(tok)-5]:
            tok=tok[:len(tok)-4]
            flag=1
        '''
        feeling->feel
        '''
        if flag==0:
            tok=tok[:len(tok)-3]
            flag=1
    if tok.endswith('ing') and flag==0:
        tok=tok[:len(tok)-3]
        flag=1
    if tok.endswith('ed') and tok[len(tok)-3] not in VOWELS and flag==0:
        '''
        approved->approve
        '''
        if tok[len(tok)-3]  in set(['l','s','z','r','v','c','g','n']) and (tok[len(tok)-4] in set(['a','o','i']) or len(tok)-2<=2):
            tok= tok[:len(tok)-2]+'e'
            flag=1
        else:
            '''
            realigned->realign
            '''
            tok=tok[:len(tok)-2]

        flag=1
    if tok.endswith('ied') and flag==0:
        '''
        lied->lie
        '''
        if len(tok[:len(tok)-3]) <2:
            tok=tok[:len(tok)-3]+"ie"
        else: 
            '''
            identified->identify
            '''
            tok=tok[:len(tok)-3]+"y"
        flag=1
    return(tok)




def stem(chunk):
    toks = chunk.tokens
    tags = chunk.tags
    for k,tok in enumerate(toks): #(chunk.tokens):
        chunkstr=str(chunk)
        tag = chunk.tags[k]
        flag=0
        if tok in _IGNORE_:
            return(tok)
        if tag == "V" and tok.endswith('ing') and tok[len(tok)-4] not in VOWELS :
            '''
            creating->create
            '''
            if tok[len(tok)-4]  in set(['t','l','z','r','v','d','c','g','n']) and tok[len(tok)-5] in set(['a']):
                chunk.tokens[k]= tok[:len(tok)-3]+'e'
                flag=1
            '''
            closing->close
            using->use
            '''
            if tok[len(tok)-4]  in set(['s']) and tok[len(tok)-5] in VOWELS:
                chunk.tokens[k]= tok[:len(tok)-3]+'e'
                flag=1
            '''
            telling->tell
            '''
            if tok[len(tok)-4] == tok[len(tok)-5] and tok[len(tok)-4]=='l' and  flag==0:
                chunk.tokens[k]=tok[:len(tok)-3]
                flag=1
            '''
            getting->get
            '''
            if tok[len(tok)-4] == tok[len(tok)-5] and flag==0:
                chunk.tokens[k]=tok[:len(tok)-4]
                flag=1
            '''
            feeling->feel
            '''
            if flag==0:
                chunk.tokens[k]=tok[:len(tok)-3]
                flag=1
        if tag == "V" and tok.endswith('ed') and tok[len(tok)-3] not in VOWELS and flag==0:
            '''
            approved->approve
            '''
            if tok[len(tok)-3]  in set(['t','l','s','z','r','v','d','c','g','n']) and (tok[len(tok)-4] in set(['a','o','i']) or len(tok)-2<=2):
                chunk.tokens[k]= tok[:len(tok)-2]+'e'
                flag=1
            else:
                '''
                realigned->realign
                '''
                chunk.tokens[k]=tok[:len(tok)-2]

            flag=1
        if tag == "V" and tok.endswith('ied') and flag==0:
            '''
            lied->lie
            '''
            if len(tok[:len(tok)-3]) <2:
                chunk.tokens[k]=tok[:len(tok)-3]+"ie"
            else: 
                '''
                identified->identify
                '''
                chunk.tokens[k]=tok[:len(tok)-3]+"y"
            flag=1
        if tag in _NPA_NTAG:
            '''
            berries->berry
            '''
            if (tok.endswith('ies')):
                chunk.tokens[k]=tok[:len(tok)-3]+"y"
                flag=1
            '''
            match->matches
            box->boxes
            '''
            if (tok.endswith('es')):
                if (tok[len(tok)-4]=='c' and tok[len(tok)-3]=='h') or (tok[len(tok)-3]=='s' and tok[len(tok)-4]=='s') or (tok[len(tok)-4]=='s' and tok[len(tok)-3]=='h' ) or tok[len(tok)-3]=='x' or tok[len(tok)-3]=='z':
                    chunk.tokens[k]=tok[:len(tok)-2]
                    flag=1

            if(tok.endswith('\'s')):
                chunk.tokens[k]=tok[:len(tok)-2]
                flag=1
            '''file->files'''
            if (not tok.endswith('ss') ) and (tok.endswith('s')) and (not flag):
                chunk.tokens[k]=tok[:len(tok)-1]
                flag=1
            '''radii->radius'''
            if tok.endswith('ii'):
                chunk.tokens[k]=tok[:len(tok)-1]+"us"
                flag=1
    
    return(chunk)










if __name__ == "__main__":
    

    #proctxtLst = pickle.load(open(MC_DATA_HOME + 'evaldata/data_merged_2854_test.proctxts'))
    # proctxtLst = pickle.load(open(MC_DATA_HOME + 'entityEval.proctxts'))
    # f= open('stemmed.txt','w')
    # proctxtLst = pickle.load(open(MC_DATA_HOME + 'evaldata/data_semeval_6399_train.proctxts'))
    # hr = pickle.load(open(DEFAULT_HR_FILE))
    # for p, proctxt in enumerate(proctxtLst):
    #     for s, sentence in enumerate(proctxt[PTKEY_CHUNKEDCLAUSES]):
    #         for c, clause in enumerate(sentence):
    #             for h, chunk in enumerate(clause):
    #                 stemmed = stem(chunk)
    #                 f.write(str(stemmed)+" \n")
    # f.close()
    print("radii"+"|"+stemNoun("radii"))
    print("berries"+"|"+stemNoun("berries"))
    print("knives"+"|"+stemNoun("knives"))
    print("matches"+"|"+stemNoun("matches"))
    print("boxes"+"|"+stemNoun("boxes"))
    print("files"+"|"+stemNoun("files"))
    print("site's"+"|"+stemNoun("site's"))
    print("catched"+"|"+stemVerb("catched"))
    print("creating"+"|"+stemVerb("creating"))
    print("closing"+"|"+stemVerb("closing"))
    print("using"+"|"+stemVerb("using"))
    print("telling"+"|"+stemVerb("telling"))
    print("getting"+"|"+stemVerb("getting"))
    print("feeling"+"|"+stemVerb("feeling"))
    print("approved"+"|"+stemVerb("approved"))
    print("realigned"+"|"+stemVerb("realigned"))
    print("lied"+"|"+stemVerb("lied"))
    print("identified"+"|"+stemVerb("identified"))
    # import csv
    # f=open('stem_verbs_ed.txt','w')
    # #print(stemVerb('calling '))
    # with open('test_verbs.csv', 'rb') as csvfile:
    #     for line in csvfile.readlines():
    #         array = line.split(',')
    #         x=array[2]
    #         f.write(array[0]+","+stemVerb(x.strip())+"\n")   
    #         #print(array[4])



 


            



                   
