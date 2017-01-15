# -*- coding: utf-8 -*-
"""
Data-types and functionality to handle n-grams
Class ngToken
Class ngDictionaries
N-gram processing functions:
1) parseAsNgrams --> ngramizer 
2) makeNgrams --> make meaningful ngrams from a sentence.
"""
#from os import listdir, isdir
import os
import csv
import re
from collections import defaultdict
from config import PTKEY_TOKENS, PTKEY_TAGS
    
__NGPATTERN = re.compile(r"[^a-zA-Z0-9_*+\-$&\/']") 
    
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
        
# ****************************************************************************
# NG-DICTIONARIES class.
# ****************************************************************************        
class ngDictionaries(object):
    """
    Labeled n-gram dictionaries.
    {
    1:{'positive':{ng1:mv1, ng2:mv2, ...}, 'negative':{ng1:mv1, ng2:mv2, ...}}
    2:{'positive':{ng1:mv1, ng2:mv2, ...}, 'negative':{ng1:mv1, ng2:mv2, ...}}
    ...
    }
    """
    __NGPATTERN = re.compile(r"[^a-zA-Z0-9_*+\-$&\/]")

    def __updateWithDicts(self, ngDict):
        for nkey in ngDict:
            if self.__ngdicts.has_key(nkey) == False:
                self.__ngdicts[nkey] = dict()
            for pkey in ngDict[nkey]:
                pdict = self.__ngdicts[nkey]
                if pdict.has_key(pkey) == False:
                    pdict[pkey] = dict()
                pdict[pkey].update(ngDict[nkey][pkey]) #set(
         
        self.availableNgrams = [int(k) for k in self.__ngdicts]
        self.availableNgrams.sort(reverse = True)
    
    def __fileSanityChecks(self, ipfiles):
        isfile = os.path.isfile; isdir = os.path.isdir; lstdir = os.listdir
        if type(ipfiles) in [str, unicode]:
            if isdir(ipfiles):
                dname = ipfiles
                ipfnames = [dname + fname for fname in lstdir(dname) if isfile(dname + fname)]
            elif isfile(ipfiles): #assuming it is a file
                ipfnames = [ipfiles]
            else: #some wierd string. 
                ipfnames = []                   
        else: #ipfiles is a list
            ipfnames = [fname for fname in ipfiles if isfile(fname)]
            
        return ipfnames    

    def __csv2ngdicts(self, ipfnames, sep='|'):
                   
        dictlst = dict()
        for fname in ipfnames:    
                
            with open(fname, 'rb') as csvfile: 
                 reader = csv.reader(csvfile, delimiter=sep, quotechar = '"')
                 for row in reader:
                    if len(row) != 2:
                        print 'here', fname, row
                        print fname
                        print row
                        continue
                    mv = 1    
                    if len(row) == 3:
                        mv = row[2]
                        
                    ngram = row[0].lower().strip() 
                    ngkey = len(row[0].split())
                    pol = row[1]

                    try:
                        dictlst[ngkey]
                    except KeyError:
                        dictlst[ngkey] = {}
                    try:
                        dictlst[ngkey][pol]
                    except KeyError:
                        dictlst[ngkey][pol] = {}                            
                            
                    dictlst[ngkey][pol].update({ngram:mv})
        return dictlst 
                
    def __init__(self, initvar='', sep='|', verbose=False):

        self.__ngdicts = dict()
        
        ngDict = {}        
        if type(initvar) == dict:
            ngDict = initvar
        else: #initialize from csv files.       
            ipfnames = self.__fileSanityChecks(initvar)                       
            if ipfnames:
                ngDict = self.__csv2ngdicts(ipfnames, sep)                               
        self.__updateWithDicts(ngDict)
        if verbose: print 'Available n-grams:', self.availableNgrams
        if verbose: self.ngDictStats()
    
    def update(self, initvar='', sep='|'):
        ngDict = {}        
        if type(initvar) == dict:
            ngDict = initvar
        else: #initialize from csv files.       
            ipfnames = self.__fileSanityChecks(initvar)                       
            if ipfnames:
                ngDict = self.__csv2ngdicts(ipfnames, sep)                               
        self.__updateWithDicts(ngDict)
        #print 'Available n-grams:', self.availableNgrams
        #self.ngDictStats()
        
    def __makeKey(self,ngstr):
        """
        Make-keys for dictionary look up. 
        Not implemented yet.
        """       
    
    def ngDictStats(self):
        """
        Prints number of entries of ngram.
        """
        ngdict = self.__ngdicts
        if not ngdict:
            print 'Empty Dictionaries'
            return
        for nkey in ngdict:
            mem = []; pol = []
            for pkey in ngdict[nkey]:
                mem.append(len(ngdict[nkey][pkey]))
                pol.append(pkey)
            print '%1d-gram: %6d %s' % (nkey, sum(mem), zip(pol, mem))
    
    def getDicts(self, n, pol):
        return self.__ngdicts[n][pol]        
              
    def __checkMem(self, ng, n):
        """
        """
        ngdicts = self.__ngdicts
        for pkey in ngdicts[n]:
            if ng in ngdicts[n][pkey]:
                return ngToken(n,pkey, ngdicts[n][pkey][ng])
        
        return ngToken() 
              
    def checkMembership(self, ng, n = None):
        """
        check the membership of ng in the n-gram dictionaries.
        Allows checking for strings or split strings. 
        checkMembership('This Works')
        checkMembership(['This', 'too', 'works'])
        """
        
        if type(ng) in [str, unicode]:
            tng = ng
            tn = len(ng.split())
        else:
            if type(ng) == list and type(ng[0]) != list:
                if containsngToken(ng):
                    return ngToken() 
                else:
                     tng = ' '.join(ng)
                tn = ng.__len__() #len(ng)
            else:
                raise Exception("ngDictionaries: Cannot Check Membership for type:\n" + str(type(ng)))     

        if n != None:
            tn = n 
            
        if tn in self.availableNgrams:
            return self.__checkMem(tng, tn)
            
        return ngToken()


#*****************************************************************************
#N-gram processing ....
#*****************************************************************************
__NGRM = 'ngram'; __BIDX = 'bidx'; __EIDX = 'eidx'; __TAGS = 'tags'
__RELNGTAGS__ = ['A', 'V', 'J', 'N', 'R', '!']
def __isRelevantNgram(tokTags): 
    """
    """    
    patsearch = __NGPATTERN.search
    containsNoPhrasalTags = True
    for tt in tokTags:
        if type(tt) != tuple:
            return False
        tok = tt[0]; tag = tt[1];
        if patsearch(tok): #type(tok) not in [str, unicode] or 
            return False
        if tag in __RELNGTAGS__:
            containsNoPhrasalTags = False
#        else:
#            print 'irrelevant', tt
#    print containsNoPhrasalTags
    if containsNoPhrasalTags:
        return False
    else:        
        return True
               
def makeNgrams(N, tokTags):
                   
    ntoks = tokTags.__len__()       
    ngLst = []
    for k in xrange(ntoks - N + 1):
        ttng = tokTags[k:k+N]
                       
        if __isRelevantNgram(ttng): 
            ngLst.append({__NGRM: ttng, __BIDX:k, __EIDX: k+N})                        
    return ngLst 

def makeAllNgrams(N, tokTags):
                   
    ntoks = tokTags.__len__()       
    ngLst = []
    for k in xrange(ntoks - N + 1):
        ttng = tokTags[k:k+N]
        ngLst.append({__NGRM: ttng, __BIDX:k, __EIDX: k+N})                        
    return ngLst 
    
def __selectNgramsGlobal(self, ngtoklst):
    """ Not yet implemented"""
    return ngtoklst
    
def __selectNgramsGreedy(ngtoklst):
    """ Left to Right Non-Overlapping Ngramizer"""
    ntoks = ngtoklst.__len__() #len(ngtoklst)
    if ntoks == 0: return []
    if ntoks == 1: return ngtoklst
        
    nngtoklst = [ngtoklst[0]]
    append = nngtoklst.append
    for k in xrange(1,ntoks):
        thistok = ngtoklst[k]
        lasttok = nngtoklst[-1]
        if thistok.bidx >= lasttok.eidx:
            append(thistok) #nngtoklst.
            
    return nngtoklst
        
def __replaceWithTokens(S, toklst):
    """
    Helper Code
    Replace ngrams in dict with ngtokens and remove duplicate tokens.
    """
    if len(toklst) == 0: return S   
    ts = list(S) #copy.deepcopy(S)

    for tok in toklst:
        for k in xrange(tok.bidx,tok.eidx):
            ts[k] = tok
    
    #remove all duplicate tokens
    tS = [ts[0]]
    for t in ts[1:]:
        if isngToken(tS[-1]) == False: #if last was not ngtoken move on
            tS.append(t)
            continue
        if isngToken(t): #comeback for optimization  
            if t == tS[-1]:    
                continue
            else:
                tS.append(t)
        else:
            tS.append(t)
    
    return tS
                               
def parseAsNgrams(ngd, txt):
    """
    Ngramizer
    list of tokens...
    """
    if (type(txt) == dict or type(txt) == defaultdict) and (txt.has_key(PTKEY_TOKENS) and txt.has_key(PTKEY_TAGS)):
        tokens = txt[PTKEY_TOKENS]; tags = txt[PTKEY_TAGS]
        tokTags = [(tt[0], tt[1]) for tt in zip(tokens, tags)] 
    else:        
        assert(type(txt) == list and type(txt[0]) == tuple)
        tokTags = txt

    checkMembership = ngd.checkMembership

    lastSenTokTags = tokTags
    for n in ngd.availableNgrams: # For each N-gram starting with the highest n-gram
        allngInS = makeNgrams(n, lastSenTokTags) 

        # keep only those ngrams in dictionary
        ngInDict = list()
        for ng in allngInS:
            tok = [t[0] for t in ng[__NGRM]]
            ngtok = checkMembership(tok, n) #lookup the ngram dictionary
            if not ngtok.isNull(): 
                ngtok.saveContext(ng[__NGRM], lastSenTokTags, ng[__BIDX], ng[__EIDX])         
                ngInDict.append(ngtok)
    
        #ngInDict contains all ngrams in sentence that are also in dictionaries.
        #To proceed further we need to eliminate overlapping ngrams from ngInDict
        #global selection vs greedy selection 
        
        #From all the ngrams in sentence that are also in the dictionary,
        #select those that are relevant.
        selectedngs = __selectNgramsGreedy(ngInDict)
        
        #replace the selected n-grams in sentence with corresponding tokens    
        ts = __replaceWithTokens(lastSenTokTags, selectedngs)

        lastSenTokTags = ts

    return ts

def parseTokensAsNgrams(ngd, txt):
    """
    Ngramizer
    list of tokens...
    """
#    if (type(txt) == dict or type(txt) == defaultdict) and (txt.has_key(PTKEY_TOKENS) and txt.has_key(PTKEY_TAGS)):
#        tokens = txt[PTKEY_TOKENS]; tags = txt[PTKEY_TAGS]
#        tokTags = [(tt[0], tt[1]) for tt in zip(tokens, tags)] 
#    else:        
    assert(type(txt) == list)
    tokTags = txt

    checkMembership = ngd.checkMembership

    lastSenTokTags = tokTags
    for n in ngd.availableNgrams: # For each N-gram starting with the highest n-gram
        allngInS = makeAllNgrams(n, lastSenTokTags) 

        # keep only those ngrams in dictionary
        ngInDict = list()
        for ng in allngInS:
            tok = ng[__NGRM] #[t[0] for t in ng[__NGRM]]
            ngtok = checkMembership(tok, n) #lookup the ngram dictionary
            if not ngtok.isNull(): 
                ngtok.saveContext(ng[__NGRM], lastSenTokTags, ng[__BIDX], ng[__EIDX])         
                ngInDict.append(ngtok)
    
        #ngInDict contains all ngrams in sentence that are also in dictionaries.
        #To proceed further we need to eliminate overlapping ngrams from ngInDict
        #global selection vs greedy selection 
        
        #From all the ngrams in sentence that are also in the dictionary,
        #select those that are relevant.
        selectedngs = __selectNgramsGreedy(ngInDict)
        
        #replace the selected n-grams in sentence with corresponding tokens    
        ts = __replaceWithTokens(lastSenTokTags, selectedngs)

        lastSenTokTags = ts

    return ts
        
if __name__ == "__main__":
    import time
    te  = time.time()
    #ngd = ngDictionaries('dbg/dicts/ngDicts/1GramsNew.csv') 
    #ngd = ngDictionaries(ipDir='dbg/dicts/telcomDicts/')
    ngd = ngDictionaries('resources/ngDicts/')
#    ngd = ngDictionaries()
    
    print time.time() - te
    ngd.ngDictStats()
    
    S = "i do n't like great gasby".split()
    S = 'this is not as good :)'.split()
    
    b = 'abysmal'
    print b
    print ngd.checkMembership(b)
    b = 'abysmalsdsdfa'
    print b, ngd.checkMembership(b)
    b = "scold never"
    print b, ngd.checkMembership(b)
    b = "a bank i don't fuck".split()
    print b, ngd.checkMembership(b)
    #b.append(a)
    print b, ngd.checkMembership(b) 
    # End Basic Unit Test
    
#    tokTags = [('scold', 'R'), ('never', 'V'), ('is', 'V'), ('sadfsd', 'A'), ('dfsda', 'A'), (':)', 'E')]
#    toks = [t[0] for t in tokTags]
#    tags = [t[1] for t in tokTags]
#    procTxt = {'tokens': [tt[0] for tt in tokTags], 'tags':[tt[1] for tt in tokTags]}
#    allngInS = makeNgrams(2, tokTags)
#    print allngInS
#    
#    a = parseAsNgrams(ngd, procTxt) 
#    print a 
#    
#    txt = "fux up everything".split()
#    
#    a = parseTokensAsNgrams(ngd, txt)
#    print a

