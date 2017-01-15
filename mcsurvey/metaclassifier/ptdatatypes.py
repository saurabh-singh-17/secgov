# -*- coding: utf-8 -*-
"""
Created on Tue Jul 22 05:45:11 2014

@author: vh
"""
__PTCHUNK_WARN_UNKTOKTYPE__ = 'Unknown token data type in creation of ptChunk'
__PTCHUNK_WARN_UNKTAGTYPE__ = 'Unknown tag data type in creation of ptChunk'
from config import PTKEY_CHUNKTYPE_NONE
from collections import defaultdict
class ptSentence(object):
    """
    Sentences
    pts = ptSentence(tokenLst, tagLst, polarityLst)
    pts.tags --> list 
    pts.toks --> list 
    pts.pols --> list
    print pts
    pts.tokString() --> string
    pts.tagString() --> string
    pts.isEmpty --> True/False
    pts1 == pts2 --> True/False
    """
    def __init__(self, toks=[], tags=[], pols = []):
#        self.tokens = []
#        self.tags = []
#        self.pols = []
#        
#        self.tokens.extend(toks)
#        self.tags.extend(tags)
#        self.pols.extend(pols)
        
        self.tokens = list(toks)
        self.tags = list(tags)
        self.pols = list(pols)
        
            
    def __repr__(self):
        """
        print sentence
        """
        return ('%s(%s)' % ('S', ' '.join(self.tokens)))
    def tokString(self):
        """
        String representation of the tokens
        """
        return ' '.join(self.tokens)
    def tagString(self):
        """
        String representation of the tags
        """
        return ' '.join(self.tags)
    def isEmpty(self):
        """
        Check if sentence is empty
        """
        if self.tokens and self.tags:
            return False
        return True
    def __eq__(self, other):
        """
        Compare two sentences
        """
        if not (type(other) == ptSentence): #not isinstance(other, ngToken):
            return False
        return (self.tags == other.tags) and (self.tokens == other.tokens)

##############################################################################
class ptChunk(object):
    """
    Chunks
    chunk = ptChunk(tokenLst, tagLst, polarityLst, chunkType)
    chunk.tags --> list 
    chunk.toks --> list 
    chunk.pols --> list
    chunk.chunkType --> string ('NONE/NP/VP/PP ...)
    print chunk e.g, NP(at&t/^)
    chunk.tokString() --> string
    chunk.tagString() --> string
    chunk.merge(otherChunk)
    chunk1 == chunk2 --> True/False
    """
    def __init__(self, tokens=[], tags=[], pols = [], chunkType=PTKEY_CHUNKTYPE_NONE):
        
        self.tokens = []
        self.tags = []
        self.pols = []
        self.chunkType = ''
        self.tprops = [defaultdict(int) for tok in self.tokens]
        self.chPol = 0
        self.hasNegator = False
        
        if type(tokens) == list:
            self.tokens.extend(tokens)
        elif type(tokens) == unicode:
            self.tokens.append(tokens.encode('ascii', 'ignore'))
        elif type(tokens) == str:
            self.tokens.append(tokens)
        else:
            warnings.warn(__PTCHUNK_WARN_UNKTOKTYPE__)
                    
        if type(tags) == list:
            self.tags.extend(tags)
        elif type(tags) == unicode:
            self.tags.append(tags.encode('ascii'))
        elif type(tags) == str:
            self.tags.append(tags)
        else:
            warnings.warn(__PTCHUNK_WARN_UNKTAGTYPE__)

        if type(pols) == list:
            self.pols.extend(pols)
        elif type(pols) == unicode:
            self.pols.append(pols.encode('ascii'))
        elif type(pols) == str:
            self.pols.append(pols)
        else:
            warnings.warn(__PTCHUNK_WARN_UNKTAGTYPE__)
            
        self.chunkType = chunkType.encode('ascii')

    def __repr__(self):
        """
            developer's print of chunk
            usage: print '%s' % repr(chunk)
        """
        ss = ' '.join([tok+'/'+tag for tok, tag in zip(self.tokens, self.tags)])
        return ('%s(%s)' % (self.chunkType, ss)) 

    def clean_toks(self):
        return [stok for tok in self.tokens for stok in tok.split('_NG_')]
        
    def toktagstr(self):
        return ' '.join(['%s/%s' % (tok, tag) for tok, tag in zip(self.tokens, self.tags)])
    
    def __str__(self):
        """
            consumer's print of chunk == pretty print of chunk tokens without NG 
            usage: print '%s' % chunk
        """
        ss = ' '.join(self.clean_toks())       
        return ss
             
                 
    def merge(self, other):
        self.tokens.extend(other.tokens)
        self.tags.extend(other.tags)
        self.pols.extend(other.pols)
        self.tprops.extend(other.tprops)
        
    def __eq__(self, other):
        if not (type(other) == ptChunk): #not isinstance(other, ngToken):
            return False
        return (self.chunkType == other.chunkType) and (self.tags == other.tags) and (self.tokens == other.tokens)

if __name__ == "__main__":
    a = ptChunk(['i_NG_have', 'like'], ['O', 'V'], [0, 1])
    print a
    print repr(a)