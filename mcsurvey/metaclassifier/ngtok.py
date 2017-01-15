# -*- coding: utf-8 -*-
"""
Created on Mon Sep  1 15:55:34 2014

@author: vh
"""

def isngToken(object):
    """Test whether a token is an ngToken or not."""
    return type(object) == ngToken #isinstance(object, ngToken)        

def containsngToken(ngAsWords):
    """Checks whether a list of tokens contains any ngTokens
    ngAsWords a list of tokens
    """
    #return any([isinstance(tok, ngToken) for tok in ngAsWords])
    for tok in ngAsWords:
        if type(tok) == ngToken: #isinstance(tok, ngToken): #isngToken(tok):
            return True
    return False
    
class ngToken(object):
    """
    ngToken: An n-gram token type, that is used to replace an n-gram that exists
    in an n-gram dictionary
    
    creation: 
    ng = ngToken(n, polarity)
    ng.saveContext(n-gram, sentence, begIndex, endIndex) -- optional step
    where, n is 1 for 1gram, 2 for 2gram ... & polarity is its polarity
    n-gram (eg., fish out of water), the sentence in which the n-gram was 
    identified, and the beginning & ending indices in the sentence.
    
    public methods:
    Create/Set: ngToken, saveContext
    Get: n, polarity, val (n-gram), sentence, bidx, eidx
    Helper: ==, print, isNull   
    """
    __nmax = 7
    __ncounts = [0 for n1 in xrange(__nmax)]
    del n1    
    def __init__(self, n1 = None , polarity = None, mv = 1):
        """ 
        Constructor. n1 is the n of the n-gram, polarity is polarity of the n-gram
        """
        self.n= n1
        self.polarity = polarity
        self.mv = 1
        self.hasContext = False
        if n1 > 0:
            ngToken.__ncounts[n1-1] += 1
            self.__id = ngToken.__ncounts[n1-1]
        else:
            self.__id = None
    
    def __repr__(self):
        """
        Print ngToken 
        """
        if self.hasContext == False:
            return ('ngToken(id=%s ngrm=%s pol=%s mv=%s)' 
                % (repr(self.__id), repr(self.n), repr(self.polarity), repr(self.mv)))
        else:
            return ('ngToken(val=%s, id=%s ngrm=%s pol=%s mv=%s)' 
                % (repr(self.val), repr(self.__id), repr(self.n), repr(self.polarity), repr(self.mv)))   
                           
    def isNull(self):
        """ Null Checker"""
        return self.__id == None
                           
    def saveContext(self, val, S = None, bidx = None, eidx = None):
        """
        Set the context of a token.
        Context = {the n-gram, [sentence], [begining index], [ending index]}
        Only the value which contains the n-gram (eg., 'fish out of water')
        is mandatory.
        """
        self.hasContext = True
        self.val = val
        self.S = S
        self.bidx = bidx
        self.eidx = eidx
        
    def __eq__(self, other):
        """ 
        Check if two tokens are equal (eg., tokA == tokB).
        Argument(s): other -- token to compare with.
        if token has context checks if the bidxs and the n-grams are same
        o.w. checks for similarity n of the n-gram & polarity.
        """
        if not (type(other) == ngToken): #not isinstance(other, ngToken):
            return False
        if self.hasContext and other.hasContext:
            return self.bidx == other.bidx and self.val == other.val
        else:
            return self.n == other.n and self.polarity == other.polarity
 