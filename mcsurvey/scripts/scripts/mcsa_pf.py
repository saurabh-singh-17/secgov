# -*- coding: utf-8 -*-
"""
Created on Tue Jul 21 06:57:42 2015

@author: svs
"""

import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)

import csv, json
import metaclassifier.mcServicesAPI as mcapi
import metaclassifier.problem_phrases as pp
from metaclassifier.stemmer import stemNoun, stemVerb
import mcsa_word_relationships as mcsawr
from mc_categories2 import mcCategories
from itertools import product, izip, islice
from collections import defaultdict, OrderedDict
csv.field_size_limit(sys.maxsize)
import cPickle as pickle

def cleanAndStemNP(tok):
    toks  = tok.split('_NG_')  
    for t, tok in enumerate(toks):
        toks[t] = stemNoun(tok)   
    return toks



def pivotcsv(ifname,rfname,docid_cols,txtcol,catmodel,lemma_pickle_path=None):

    wfile=open(rfname,"wa")
    dfile=open(ifname)
    ipreader = csv.reader(dfile, delimiter='|')
    header = ipreader.next()
    docid_idxs = [header.index(dc) for dc in docid_cols]
    txtcol_idx = header.index(txtcol) 
    writeResult=OrderedDict()
    keys=['DOCID','SID','SENTIMENT','PHRASE','KEYWORD','LEMMA','MODIFIER','CATEGORY','SUBCATEGORY1','SUBCATEGORY2']
    dict_writer = csv.DictWriter(wfile, keys, delimiter = '|', quoting=csv.QUOTE_NONE)
    dict_writer.writeheader()
    counter=1
    if lemma_pickle_path:
        lemmas = pickle.load(open(lemma_pickle_path))
    for lines in ipreader:
        print counter
        counter+=1
        procTxt=mcapi._mcNLPipeline(lines[txtcol_idx])
        sprocTxts = mcapi.sentenceSplitProcTxts(procTxt)
        writeResult["DOCID"]=" ".join([lines[d] for d in docid_idxs])
        if writeResult["DOCID"] == "1356":
            print "its time to debug 1356"
        for ind,sentence in enumerate(sprocTxts):
            writeResult["SID"]=ind
            sdict=mcsawr.findNounIntensifyingAdj(sentence)
            vdict=mcsawr.findNounrelatedKeyVerbs(sentence)
            sdictkeys=sdict.keys()
            sdictkeystr=[' '.join([ctok for tok in sdictk.split() for ctok in cleanAndStemNP(tok[:-2])]) for sdictk in sdictkeys]
            vdictkeys=vdict.keys()
            vdictkeystr=[' '.join([ctok for tok in vdictk.split() for ctok in cleanAndStemNP(tok[:-2])]) for vdictk in vdictkeys]
            #res=mcapi.mcRunServices(str(sentence["sentences"][0])[2:-1],"entitySentiment")
            res=pp.inducedChunkPolarity(sentence,mcapi.__MC_PROD_HR__[0])
            for ent in res:#[0]["entitySentiment"]["result"]:
                writeResult["SENTIMENT"] = ent["sentiment"]
                writeResult["PHRASE"] = ' '.join([ctok for tok in ent['phrase'].split() for ctok in cleanAndStemNP(tok[:-2])])
                writeResult["KEYWORD"] = ' '.join([ctok for tok in ent['entity'].split() for ctok in cleanAndStemNP(tok[:-2])]) 
                writeResult["LEMMA"] = ""
                if lemmas:
                    for lem in lemmas:
                        if ent['entity'] in lemmas[lem]["words"]:
                            writeResult["LEMMA"] = ' '.join([ctok for tok in lemmas[lem]["lemma"].split() for ctok in cleanAndStemNP(tok[:-2])]) 
                            break
                if writeResult["LEMMA"] == "":
                    writeResult["LEMMA"] = ' '.join([ctok for tok in ent['entity'].split() for ctok in cleanAndStemNP(tok[:-2])])
                cat=catmodel.getCategories(ent["entity"].split())
                if cat:
                    writeResult["CATEGORY"] = cat[0][0][2][1]["NAME"]
                    writeResult["SUBCATEGORY1"] = cat[0][0][2][0]["NAME"]
                    writeResult["SUBCATEGORY2"] = ' '.join([ctok for tok in cat[0][0][0].split() for ctok in cleanAndStemNP(tok[:-2])]) 
                else:
                    writeResult["CATEGORY"] = ""
                    writeResult["SUBCATEGORY1"] = ""                    
                    writeResult["SUBCATEGORY2"] = ""
                atleastOne=0    
                if writeResult["KEYWORD"] in sdictkeystr:
                    indkey=sdictkeystr.index(writeResult["KEYWORD"])
                    for value in sdict[sdictkeys[indkey]]:
                        writeResult["MODIFIER"] = ' '.join([ctok for tok in value.split() for ctok in cleanAndStemNP(tok[:-2])]) 
                        dict_writer.writerow(writeResult)
                        atleastOne=1
                if writeResult["KEYWORD"] in vdictkeystr:
                    indkey=vdictkeystr.index(writeResult["KEYWORD"])
                    for value in vdict[vdictkeys[indkey]]:
                        writeResult["MODIFIER"] = ' '.join([ctok for tok in value.split() for ctok in cleanAndStemNP(tok[:-2])]) 
                        dict_writer.writerow(writeResult)
                        atleastOne=1 
                if not atleastOne:
                    writeResult["MODIFIER"] = ""
                    dict_writer.writerow(writeResult)
    wfile.close()
    dfile.close()
    
if __name__ == "__main__":

    dataset_name = 'DIL'
    docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
    txt_cols = ['SRV_Q21A_ISSUE_VERBATIM']
    tmp_home = "/home/user/Desktop/mcSurveyAnalysis/tmp"  

    dataset_name = 'MCV'
    docid_cols = ['RowID'] 
    txt_cols = ['Verbatim']        
    dhome = os.path.join(tmp_home, dataset_name)
    
    for col in txt_cols:
        dbase = os.path.join(dhome, col, col)
        ifname = dbase + '.verbatims'
        rfname = dbase + '.pivot.csv'       
        w2vmod_fname = dbase + '.w2vm'
        ctable_fname = dbase + '.ctable.csv'
        mcres_fname = dbase + '.mcres.csv'
        lemma_pickle_path = dbase + "lemma.pickle"
        catmodel = mcCategories(w2vmod_fname, ctable_fname, False)
        pivotcsv(ifname,rfname,docid_cols,col,catmodel,lemma_pickle_path)    