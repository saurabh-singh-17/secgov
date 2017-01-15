# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 07:51:03 2015

@author: vh
"""


from ptdatatypes import *
def proctxt2tt(proctxt):
    '''
    '''
    tt = []
    for s, sentence in enumerate(proctxt['chunksInClauses']):
        for c, clause in enumerate(sentence):
            for h, chunk in enumerate(clause):
                for tok, tag in zip(chunk.tokens, chunk.tags):
                    tt.append('%s/%s' % (tok, tag))

    tt = ' '.join(tt)                   
    return tt
    
if __name__ == "__main__":
    import cPickle as pickle
    from ptdatatypes import *
    fname = '/home/vh/volte-0.1/data/CR_VERBATIM/proctxts/CR_VERBATIM.000'
    proctxts = pickle.load(open(fname))
    for proctxt in proctxts:
        proctxt2tt(proctxt)