# -*- coding: utf-8 -*-
"""
Created on Sun Mar 15 07:32:32 2015

@author: vh
"""
from collections import defaultdict, Counter
from ptdatatypes import ptChunk

_cc_temporal = set(['yesterday', 'today', 'tomorrow']) 
def splitNP_MR(chunk):
    tags = chunk.tags
    tagCounts = Counter(tags)
    
    splitchunk = []
    if tagCounts['A'] > 1 or tagCounts['R'] > 1:
        #print chunk
        lastTag = ''
        tchunk = []
        
        for t, tag in enumerate(chunk.tags[:]):
            #print chunk.tprops
            if tag in ('A') and not lastTag in ('A', 'D', 'R'):
                if tchunk: 
                    splitchunk.append(tchunk)
                    tchunk = []
            elif tag in ('D') and chunk.tokens[t] in  ('no'): #chunk.tprops[t]['NGTR']:
                if tchunk:
                    splitchunk.append(tchunk)
                    tchunk = []
                    
            tchunk.append((chunk.tokens[t], tag, chunk.pols[t]))
            lastTag = tag    
        if tchunk:
            splitchunk.append(tchunk)
        #print 'x', splitchunk

        retChunks = []        
        for t, sc in enumerate(splitchunk):
            toks, tags, pols = zip(*sc)
            toks = list(toks)
            tags = list(tags)
            pols = list(pols)
            ch = ptChunk(toks, tags, pols = pols, chunkType = 'NP')
            retChunks.append(ch)
        
        #print 'x', retChunks
        return retChunks 
    else:
        return [chunk]

def splitNP_D(chunk):
    tags = chunk.tags
    tagCounts = Counter(tags)
    
    splitchunk = []
    if tagCounts['D'] > 0:
        lastTag = ''
        tchunk = []
        for t, tag in enumerate(chunk.tags[:]):    
            if t > 0 and tag in ('D'):
                if lastTag in ('N', '^'):
                    splitchunk.append(tchunk)
                    tchunk = []
#                else:
#                    print 'y', chunk
            tchunk.append((chunk.tokens[t], tag, chunk.pols[t]))
            lastTag = tag
        if tchunk:
            splitchunk.append(tchunk)
        #print 'x', splitchunk
        
        retChunks = []        
        for t, sc in enumerate(splitchunk):
            toks, tags, pols = zip(*sc)
            toks = list(toks)
            tags = list(tags)
            pols = list(pols)
            ch = ptChunk(toks, tags, pols = pols, chunkType = 'NP')
            retChunks.append(ch)
        
        #print 'x', retChunks
        return retChunks 
    
    else:
        return [chunk]
        
def npCleanup(chunk):
    schunks = [c for ch in splitNP_MR(chunk) for c in splitNP_D(ch)]
    return schunks