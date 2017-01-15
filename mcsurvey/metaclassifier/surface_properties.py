# -*- coding: utf-8 -*-
"""
Created on Tue Mar  3 17:02:47 2015

@author: vh
"""

def charCounts(procTxt):
    ns = len(procTxt['chunksInClauses'])
    cc = [0]*ns
    wc = [0]*ns 
    for s, sentence in enumerate(procTxt['chunksInClauses']):
        for clause in sentence:
            for chunk in clause:
                wc[s] += len(chunk.tags)
                for tok in chunk.tokens:
                    cc[s] += len(tok)
    return (cc, wc)