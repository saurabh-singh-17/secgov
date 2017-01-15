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
CONS=set(['b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','y','z'])
HAS=set(['has','had','have'])
BE=set(['is','am','am','was','are','were','be'])
_NPA_NOUNTAGS = set(['D', '^', 'S', 'Z', 'L', 'O'])
_NPA_NTAG = set(['N'])
_IGNORE_ = set(['gcas'])
VERBS_D=set(["abided","aboded","abraded","acceded","aggraded","aided","alluded","ambuscaded","anteceded","arcaded","balustraded","barded","barricaded","betided","bided","biodegraded","bladed","blended","blindsided","blockaded","boded","brigaded","broadsided","brocaded","cannonaded","cascaded","ceded","chided","cockaded","coded","coincided","collided","colluded","colonnaded","conceded","concluded","confided","corraded","corroded","counterblockaded","cowhided","crusaded","cyanided","debrided","decided","decoded","defiladed","degraded","deluded","demoded","denuded","derided","detruded","discommoded","disploded","dissuaded","divided","downgraded","duded","elided","eluded","encoded","enfiladed","eroded","escaladed","evaded","excided","excluded","exploded","extruded","exuded","faded","forboded","foreboded","gasconaded","glided","glissaded","graded","grided","guided","haded","hided","horded","impeded","imploded","included","incommoded","interceded","intergraded","intruded","invaded","jaded","laded","marinaded","masqueraded","miscoded","misgraded","misguided","motorcaded","nided","nitrided","obtruded","occluded","outchided","outguided","outmoded","outtraded","overladed","overpersuaded","overtraded","palisaded","paraded","pasquinaded","peroxided","persuaded","pervaded","pomaded","preceded","precluded","precoded","prefaded","preluded","presided","prided","promenaded","protruded","provided","rawhided","reacceded","receded","recoded","redecided","reded","redivided","regraded","reinvaded","renegaded","resided","respaded","retroceded","retrograded","seceded","secluded","seconded","serenaded","shaded","sided","spaded","stampeded","stockaded","subdivided","subsided","sueded","suicided","superceded","superseded","tided","traded","transuded","unladed","upgraded","waded"])

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
        if len(tok[:len(tok)-3])<3:
            return(tok[:len(tok)-1])
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
        if (tok[len(tok)-4]=='c' and tok[len(tok)-3]=='h') or (tok[len(tok)-3]=='s' and tok[len(tok)-4]=='s') or (tok[len(tok)-4]=='s' and tok[len(tok)-3]=='h' ) or tok[len(tok)-3]=='x' :
            return(tok[:len(tok)-2])
    if(tok.endswith('\'s')):
        tok=tok[:len(tok)-2]
    '''
    radii->radius
    '''
    if tok.endswith('ii'):
        return(tok[:len(tok)-1]+"us")
    '''file->files'''

    if tok == 'us':
        return 'usa'
        
    if (not tok.endswith('ss')) and (tok.endswith('s')):
        return(tok[:len(tok)-1])
    return(tok)

def stemVerb(tok):
    flag=0
    if tok in _IGNORE_:
        return(tok)
    if tok in HAS:
        return('has')
    if tok in BE:
        return('be')
    if tok in VERBS_D:
        return(tok[:len(tok)-1])
    if tok.endswith('ing') and tok[len(tok)-4] not in VOWELS  :
        if tok[len(tok)-4]=='y' and len(tok)-3==2 :
            tok=tok[:len(tok)-4]+'ie'
            flag=1    
        '''
        creating->create
        '''
        if tok[len(tok)-4]  in set(['t','z','r','v','c','g']) and tok[len(tok)-5] in set(['a']) and flag==0:
            tok= tok[:len(tok)-3]+'e'
            flag=1
        '''
        closing->close
        using->use
        '''
        if tok[len(tok)-4]  in set(['s','v']) and tok[len(tok)-5] in VOWELS and flag==0:
            tok= tok[:len(tok)-3]+'e'
            flag=1
        '''
        telling->tell
        '''
        if tok[len(tok)-4] == tok[len(tok)-5] and tok[len(tok)-4]=='l' and  flag==0:
            tok=tok[:len(tok)-3]
            flag=1
        '''
        getting->get
        '''
        if tok[len(tok)-4] == tok[len(tok)-5] and flag==0:
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
    # if tok.endswith('cked') and flag==0:
    #     tok=tok[:len(tok)-3]
    #     flag=1
    if tok.endswith('ed') and tok[len(tok)-3] not in VOWELS and flag==0:
        '''
        approved->approve
        '''
        if tok[len(tok)-3]  in set(['l','s','z','r','v','c','g'])  or len(tok)-2<=2:
#            tok= tok[:len(tok)-2]+'e'
#            flag=1
            pass
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
    '''applies->apply'''
    if tok.endswith('ies') :
        if tok[len(tok)-4] in CONS:
            tok=tok[:len(tok)-3]+'y'
            flag=1
    if tok.endswith('es'):
        '''does->do'''
        if tok[len(tok)-3]=='o' and flag==0:
            tok=tok[:len(tok)-2]
            flag=1
        '''accesses->access'''
        if tok[:len(tok)-2].endswith('ss') and flag==0:
            tok=tok[:len(tok)-2]
            flag=1
        '''reaches->reach'''
        if tok[:len(tok)-2].endswith('ch') and flag==0:
            tok=tok[:len(tok)-2]
            flag=1
        '''blushes->blush'''
        if tok[:len(tok)-2].endswith('sh') and flag==0:
            tok=tok[:len(tok)-2]
            flag=1
    '''works->work'''
#    if tok.endswith('s') and (not tok[-2] in ('i', 's')) and flag==0:
#        tok=tok[:len(tok)-1]
#        flag=1
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
    print("lies"+"|"+stemNoun("lies"))
    print("prizes"+"|"+stemNoun("prizes"))
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
    print("saving"+"|"+stemVerb("saving"))
    print("approved"+"|"+stemVerb("approved"))
    print("realigned"+"|"+stemVerb("realigned"))
    print("lied"+"|"+stemVerb("lied"))
    print("identified"+"|"+stemVerb("identified"))
    print("changed"+"|"+stemVerb("changed"))
    print("upgraded"+"|"+stemVerb("upgraded"))
    print("works"+"|"+stemVerb("works"))
    # import csv
    # f=open('stem_verbs_ed.txt','w')
    # #print(stemVerb('calling '))
    # with open('test_verbs.csv', 'rb') as csvfile:
    #     for line in csvfile.readlines():
    #         array = line.split(',')
    #         x=array[2]
    #         f.write(array[0]+","+stemVerb(x.strip())+"\n")   
    #         #print(array[4])



 


            



                   
