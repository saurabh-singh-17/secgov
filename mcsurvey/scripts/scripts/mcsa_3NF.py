# -*- coding: utf-8 -*-
"""
Created on Thu May 28 04:41:09 2015

@author: vh
"""
import os
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

from metaclassifier.stemmer import stemNoun, stemVerb

import csv, json, os, operator, sys
from itertools import product, izip, islice
from collections import defaultdict, OrderedDict
from operator import itemgetter
csv.field_size_limit(sys.maxsize)

def cleantok(tok):
    toks  = tok.split('_NG_')       
    return ' '.join(toks)
    
def cleanAndStemNP(tok):
    toks  = tok.split('_NG_')  
    for t, tok in enumerate(toks):
        toks[t] = stemNoun(tok)   
    return toks
    
def unpackRes(res, docid = None):
    rv = []
    if docid == "1356":
        print "its time to debug 1356"
        
    emptyEnts = OrderedDict()
    emptyEnts['PHRASE'] = 'NA'
    emptyEnts['CONTEXT'] = 'NA'
    emptyEnts['LEMMA'] = 'NA'
    emptyEnts['POLARITY'] = 'NA'
                
    for s, sres in enumerate(res):
        temp = OrderedDict()
        if docid:
            temp['DOCID'] = docid
            
        if sres:
            temp['SID'] = str(s+1)
            temp['SENTIMENT'] =sres['sentiment']['result']
            
            if not sres['entitySentiment']['result']:
                #temp.update(emptyEnts)
                rv.append(temp)
                continue
            
            ents = defaultdict(list)
            for ent in sres['entitySentiment']['result']:
                entity = ent['entity']
                #phrase = ' '.join([cleantok(tok[:-2]) for tok in ent['phrase'].split()])
                lemma = ' '.join([ctok for tok in ent['entity'].split() for ctok in cleanAndStemNP(tok[:-2])]) 
                phrase = ' '.join([ctok for tok in ent['phrase'].split() for ctok in cleanAndStemNP(tok[:-2])]) 
                pol = ent['sentiment']
                
                tdict = OrderedDict()
                #tdict['PHRASE'] = phrase
                tdict['CONTEXT'] = entity
                tdict['LEMMA'] = lemma
                tdict['PHRASE'] = phrase
                #tdict['POLARITY'] = pol
                #cats = ent['HIERARCHY']
#                if cats:
#                    scats = sorted(cats, key=itemgetter('LEVEL'))
#                    for cat in scats:
#                        key = 'LEVEL_%s' % cat['LEVEL']
#                        tdict[key] = cat['NAME']
#                        
#                    tdict['CLOSEST_SEED'] = ent['BEST_SEED']
#                    tdict['SIMILARITY'] = '%4.3f' % ent['MEM']
                    
                srep_global = ent['SREP_GLOBAL']
                for k, dim in enumerate(srep_global):
                    key = 'SREP_GLOBAL_DIM_%d' % (k+1)
                    tdict[key] = dim

#                srep_local = ent['SREP_LOCAL']
#                for j, cluster in enumerate(srep_local):
#                    for k, dim in enumerate(srep_global):
#                        key = 'SREP_LOCAL_%s_DIM_%d' % (cluster, (k+1))
#                        tdict[key] = dim
                        
                t  = OrderedDict()
                for k, v in temp.iteritems():
                    t[k] = v
                t.update(tdict)
                rv.append(t)
               
            if not ents:
                t  = OrderedDict()
                for k, v in temp.iteritems():
                    t[k] = v
                #t.update(emptyEnts)
                rv.append(t)                
        else:
            print 'x', sres            
    return rv 
    
def mc3NFizer(fname, ofname):
	
    totnores=0
    nores = 0
    totres = 0
    part = 0
    with open(fname) as f:
        reader = csv.reader(f, delimiter='|')
        while True:
            nores = 0
            n_lines = list(islice(reader, 1000))
            print "i am here"
            if not n_lines:
                break
            
            unpackedRes = []
            for line in n_lines:
                totres+=1
                docid = json.loads(line[0])
                if type(docid) == list:
                    docid = ' '.join(['%s' % d for d in docid])
                else:
                    docid = '%s' % docid
                    
                res = json.loads(line[1])
                if (not res) or (not res[0]):
                    nores += 1
                    continue
            
                #docstr = ['|'.join(docid)]
    
                uRes = unpackRes(res, docid)
                for res in uRes:
                    #res['DOCID'] = docid
                    #prods = [dict(izip(res, x)) for x in product(*res.itervalues())]
                    #unpackedRes.extend([dict(izip(res, x)) for x in product(*res.itervalues())])
                    unpackedRes.append(res)
            if(nores==1000):
                totnores +=nores
                print nores               
                continue
            if part == 0:
                
                keys = unpackedRes[0].keys()
                for res in unpackedRes[1:]:
                    if len(res.keys()) > len(keys):
                        keys = res.keys()
                        
                output_file = open(ofname, 'wb')
                dict_writer = csv.DictWriter(output_file, keys, delimiter = '|', quoting=csv.QUOTE_NONE)
                dict_writer.writeheader()
                
            dict_writer.writerows(unpackedRes)
            part+=1
            print part, len(unpackedRes)
    output_file.close()
    print nores
    print totres

if __name__ == "__main__":

    dataset_name = 'volte'        
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q2B_SAT_VOICE_WHY', 'SRV_Q3B_SAT_DATA_WHY']
    txt_cols = ['SRV_Q2B_SAT_VOICE_WHY'] #['SRV_Q3B_SAT_DATA_WHY'] #['SRV_Q1B_WTR_WHY'] #['SRV_Q1D_SAT_VALUE_ATT_WHY'] 


    dataset_name = 'DIL'
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM']
#    txt_cols = ['SRV_Q21B_RESOLVE_VERBATIM']

#col="SRV_Q21A_ISSUE_VERBATIM"

#dataset_name = 'UVERSE' 
#docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#txt_cols = ['W4_NOT_WTR_ATT_WHY']; dname = 'ATT-WHY'
#
#dataset_name = 'CHATS'
#docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#txt_cols = ['Text'] #['Verbatim']
#dname = 'CHAT-TEXT' #'CHAT-VERBATIMS'

#txt_cols = ['U2A_SAT_INTERNET_WHY']; dname = 'INTERNET' 
#txt_cols = ['U1A_SAT_TV_WHY']; dname = 'TV'

#dataset_name = 'EMP_SURVEY'
##    dataset_fname = '/home/vh/surveyAnalysis/data/empsurv.csv' 
#docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#txt_cols = ['Q1:Comments-How would you describe the current ATO work culture? ']  
#dname = 'CULTURE'   
    dataset_name = 'MCV'
    docid_cols = ['RowID'] 
    txt_cols = ['Verbatim'] 
    dnames = ['MCV-verbatim']

    tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"         
    dhome = os.path.join(tmp_home, dataset_name)
    for col in txt_cols:
        dbase = os.path.join(dhome, col, col)
        rfname = dbase + '.mcres.csv'
        cfname = dbase + '.ctable.csv'
        wfname = dbase + '.w2vm'
        resbase = "/home/user/Desktop/mcSurveyAnalysis/results/" + '__'.join([dataset_name, col]) 
        ofname = os.path.join("/home/user/Desktop/mcSurveyAnalysis/results/", '__'.join([dataset_name, col]) + '_2.csv')

        mc3NFizer(rfname+'.3', ofname)
