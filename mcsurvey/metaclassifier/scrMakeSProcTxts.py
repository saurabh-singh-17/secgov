# -*- coding: utf-8 -*-
"""
Created on Sat Sep 27 17:25:32 2014

@author: vh
"""
import os
import cPickle as pickle
from config import *
from processText import ptSentencify, priorPolAndPreChunker, clausify,chunkifyCMUTags, sentencifyAndChunk
#from processText import sentencifyAndChunk

MC_NORM_TXTS = ".normtxts"
MC_SPROC_TXTS = ".sproctxts"
import sys

hr = pickle.load(open(DEFAULT_HR_FILE))

logger = sys.stdout.write
##update procTxts in dev/
logger('\nProcessing Files\n')
for fil in os.listdir(MC_DATA_HOME):
    fileName, fileExtension = os.path.splitext(fil)
    if fileExtension == MC_NORM_TXTS:
        ptname =  MC_DATA_HOME + fileName + MC_SPROC_TXTS
        normTxtLst = pickle.load(open(MC_DATA_HOME + fil))

        logger('%s ...' % fileName)
        st = time()
        
                       
        procTxtLst = sentencifyAndChunk(normTxtLst, hr)
        senProcTxts = []
        for idx, procTxt in enumerate(procTxtLst):
            senProcTxt = []
            for s, sentence in enumerate(procTxt[PTKEY_SENTENCES]):
                sproctxt = {}
                sproctxt[PTKEY_TAGS] = sentence.tags
                sproctxt[PTKEY_TOKENS] = sentence.tokens
                sproctxt[PTKEY_SENTENCES] = [sentence]
                sproctxt[PTKEY_CHUNKEDSENTENCES] = [procTxt[PTKEY_CHUNKEDSENTENCES][s]]
                sproctxt[PTKEY_CLAUSES] = [procTxt[PTKEY_CLAUSES][s]]
                sproctxt[PTKEY_CHUNKEDCLAUSES] = [procTxt[PTKEY_CHUNKEDCLAUSES][s]]
                sproctxt[PTKEY_PRECHUNK] = [procTxt[PTKEY_PRECHUNK][s]]
                senProcTxt.append(sproctxt)
            senProcTxts.append(senProcTxt)
            
        logger('\nProcessed in %f secs\n' % (time() - st))    
        pickle.dump(senProcTxts, open(ptname, 'wb'))
        logger('Saved As: %s\n' % ptname)

