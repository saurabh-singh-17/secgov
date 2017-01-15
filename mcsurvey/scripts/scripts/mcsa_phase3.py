# -*- coding: utf-8 -*-
"""
Created on Wed May 27 10:05:10 2015

@author: vh
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

from mc_categories2 import mcCategories, mcSpatialRep
#from mcsa_categories
import time, os, csv, json, sys
from collections import defaultdict
from itertools import islice
import metaclassifier.mcServicesAPI as mcapi

mtok_sw_R = ['as', 'now', 'there', 'so', 'just', 'when', 'also', 'again', 'however', 'then', 'how']
mtok_sw_R = set([tok+'/R' for tok in mtok_sw_R])
mtok_sw_V = ['is', 'have', 'had', 'are', 'do', 'has', 'be', 'been', 'can', 'was', 'does', 'am', 'were', 'did']
mtok_sw_V.extend(['would', 'could', 'should', 'having'])
mtok_sw_V = set([tok+'/V' for tok in mtok_sw_V])

def updateEntities(res):   
    for s, sres in enumerate(res):
        if sres:                    
            toktags = sres['tokstags']['result'].split()
            sentence= [x.split("/")[0] for x in toktags]
            sentence= " ".join(sentence)
            nlpres=mcapi._mcNLPipeline(sentence)
            for tt in toktags:
                phr = tt
                if nlpres.has_key("chunkedSentences"):
                    for chunk in nlpres["chunkedSentences"][0]:
                        if tt.split("/")[0] in chunk.tokens:
                            phr=chunk.toktagstr()
                if tt[-1] in 'R' and not tt in mtok_sw_R:
                    ent = {'entity': tt, 'phrase':phr, 'sentiment': 'NEUTRAL'}
                    sres['entitySentiment']['result'].append(ent)
                    #sres['entitySentiment']['result']['entity'] = tt #tokCounts[tt] += 1
                if tt[-1] in 'V' and not tt in mtok_sw_V:
                    ent = {'entity': tt, 'phrase':phr, 'sentiment': 'NEUTRAL'}
                    sres['entitySentiment']['result'].append(ent)
                    #sres['entitySentiment']['result']['entity'] = tt #tokCounts[tt] += 1
                elif tt[-1] in 'A':
                    ent = {'entity': tt, 'phrase':phr, 'sentiment': 'NEUTRAL'}
                    sres['entitySentiment']['result'].append(ent)
                    #sres['entitySentiment']['result']['entity'] = tt #tokCounts[tt] += 1

csv.field_size_limit(sys.maxsize)

dataset_name = 'volte'        
docid_cols = ['SRV_ACCS_ID']
txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q2B_SAT_VOICE_WHY', 'SRV_Q3B_SAT_DATA_WHY']
col = 'SRV_Q1D_SAT_VALUE_ATT_WHY' #'SRV_Q3B_SAT_DATA_WHY' #'SRV_Q2B_SAT_VOICE_WHY' #'SRV_Q1B_WTR_WHY' #['SRV_Q1D_SAT_VALUE_ATT_WHY']


dataset_name = 'DIL'
docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
txt_cols = ['SRV_Q21A_ISSUE_VERBATIM']
col="SRV_Q21A_ISSUE_VERBATIM"

#txt_cols = ['SRV_Q21B_RESOLVE_VERBATIM']
#col="SRV_Q21B_RESOLVE_VERBATIM"

#dataset_name = 'UVERSE'SRV_Q21A_ISSUE_VERBATIM 
#docid_cols = ['DOCID'] #['PERIOD', 'WTR1VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#col = 'W4_NOT_WTR_ATT_WHY' #'U1A_SAT_TV_WHY' #'W4_NOT_WTR_ATT_WHY' #, 'U1A_SAT_TV_WHY', 'U2A_SAT_INTERNET_WHY']
#
#dataset_name = 'CHATS'
#docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#col = 'Text' #'Verbatim'
#dname = 'CHAT-Text'

tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"         
dhome = os.path.join(tmp_home, dataset_name)
    
bname = os.path.join(dhome, col, col)
w2vmod_fname = bname + '.w2vm'
ctable_fname = bname + '.ctable_temp.csv'
mcres_fname = os.path.join(dhome, col, col + '.mcres.csv')
   
#catmodel = mcCategories(w2vmod_fname, ctable_fname, False)
#print 'done catmodel'
#srepmodel = mcSpatialRep(w2vmod_fname, ctable_fname, 2, False)
#print 'done'
def mcPhase3(line, catmodel=None, srepmodel=None):
    docid = line[0]
    sres = json.loads(line[1])
    updateEntities(sres)
    for res in sres:
        if res:           
            for ent in res["entitySentiment"]["result"]:
                cats = catmodel.getCategory(ent['phrase'].split())
                ent.update(cats)
                key = ent['entity'].split()[-1]
                ent['SREP_GLOBAL'] = srepmodel.getLS_Global(key)
                ent['SREP_LOCAL'] = srepmodel.getLS_Local(key)
    return [docid, json.dumps(sres)]

print 'Phase 3'    
print 'Inferring Categories & Spatial Representations'
if __name__ == "__main__":

    for k in txt_cols:
        print(k)
        col=k
        dhome = os.path.join(tmp_home, dataset_name)
        bname = os.path.join(dhome, col, col)
        w2vmod_fname = bname + '.w2vm'
        ctable_fname = bname + '.ctable.csv'
        mcres_fname = os.path.join(dhome, col, col + '.mcres.csv')
        catmodel = mcCategories(w2vmod_fname, ctable_fname, False)
        print 'done catmodel'
        srepmodel = mcSpatialRep(w2vmod_fname, ctable_fname, 2, False)

        print 'Phase 3'
        print 'Inferring Categories & Spatial Representations'
        with open(mcres_fname+'.3', 'wb') as ofile:
                writer = csv.writer(ofile, delimiter='|')
                with open(mcres_fname) as f:
                    ipreader = csv.reader(f, delimiter='|')
                    part = 0
                    while True:
                        n_lines = list(islice(ipreader, 1000))
                        if not n_lines:
                            break
                        resps = [mcPhase3(line, catmodel, srepmodel) for line in n_lines]
                        #resps = [mcPhase3(line) for line in n_lines]
                        writer.writerows(resps)
                        sys.stdout.write('%s ' % '.')
                        if (part+1) % 10 == 0:
                            sys.stdout.write(' %d \n' % (part+1))
                        part += 1


    sys.stdout.write('\n')
#print catmodel.getCategories(['kind/A', 'reps/N'], th = 0.6)
#print catmodel.getCategories([], th = 0.6)
##foo = w2vEntities(fnames, catmodel)
#print srepmodel.getLS_Local('reps/N')