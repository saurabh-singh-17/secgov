# -*- coding: utf-8 -*-
"""
Created on Thu Mar 13 11:22:44 2014

@author: vh
"""
import os
from ngdict import ngDictionaries
import cPickle as pickle
import utils_gen as ug
import warnings
from config import *
from collections import defaultdict

RESKEY_POLAR_NGRAMS = 'polar_ngrams'
RESKEY_NEGATORS = 'negators'
RESKEY_SMILEYS = 'smileys'
RESKEY_DOMAINMEMDICTS = 'domain_membership_dicts'
RESKEY_POLAR_INTERJECTIONS = 'polar_interjections'

RESKEY_HAPPENINGVERBS = 'happening_verbs'
RESKEY_SOFTVERBS = 'soft_verbs'
RESKEY_PROBNOUNS = 'prob_nouns'
RESKEY_NOTHAPPENINGVERBS = 'not_hapenning_verbs'
RESKEY_PHRASE = 'phrase'
RESKEY_OPENCLAUSALCOMPLIMENT = 'open_clausal_complement'
RESKEY_NO_PARTICLE = 'no_particle'
RESKEY_PHRASE_NO_PREP = 'phrase_no_prep'
RESKEY_DOMAIN_NOUNS = 'domain_nouns'
RESKEY_PREP = 'prep'

RESKEY_POLAR_NOUNS = "polar_nouns_dict"
RESKEY_POLAR_VERBS = "polar_verbs_dict"
RESKEY_POLAR_ADJS = "polar_adjs_dict"
RESKEY_POLAR_ADVS = "polar_advs_dict"
RESKEY_POLAR_ANYPOS = "polar_anypos_dict"
RESKEY_ENGWORDS = "engWords"

class HostedResources(object):
    def __init__(self, resources={}):
        self.resources = resources

    def removeResource(self, resource = 'all'):
        if resource == 'all':
            self.resources.clear()
            return
        if resource in self.resources:
            del self.resources[resource]
    def addResource(self, resource, val, overwrite = False):
        if overwrite == False and resource in self.resources:
            warnings.warn('Did not add resource %s overwrite set to %s' % (resource, overwrite))
            return
        self.resources[resource] = val
    def getResource(self, resource):
        if resource in self.resources:
            return self.resources[resource]
        return None
        
    def listResources(self):
        print ('-'*60)
        print ('%2s %-25s  %-35s %s' % ('#', 'Resource Name', 'Type', 'Labels'))
        print ('-'*70)
        for k, key in enumerate(self.resources):
            res = self.resources[key]
            rtype = type(res)
            vals = ''
            if rtype in [dict, defaultdict]:
               vals = list(set(res.values()))
            elif rtype == ngDictionaries:
                vals = []
                for n in res.availableNgrams:
                    pdict = res._ngDictionaries__ngdicts[n]

            print '%2d %-25s  %-35s %s' % (k, key, type(self.resources[key]), vals)
        print ('-'*60)

def makeDictionaries(fname, sep = '|' , tokColIdx = 0, polColIdx = 1):
    """
    create a Py dictionary from csv 
    """
    if not sep: sep = '|'
    if not tokColIdx: tokColIdx = 0
    if not polColIdx: polColIdx = 1
    
    lines = ug.readlines(fname)
    wdict = defaultdict(int)
    for k, line in enumerate(lines):
        x = line.split(sep)
        wdict[x[tokColIdx]] = x[polColIdx]
        if len(x) < 2:
            raise Warning("ignoring line: %d %s" % (k,line))
    
    return wdict 
        
def makeDefaultResources(Home, verbose = False):

    ngstr = '_NG_'
    hr = HostedResources()

    if verbose: print 'ADDING: POLAR NGRAMS'
    ngcore = ngDictionaries(os.path.join(Home, DEFAULT_POLARNGRAMS_FILE))
    hr.addResource(RESKEY_POLAR_NGRAMS, ngcore)
    
    if verbose: print 'ADDING: NEGATORS'
    ngnegn = ngDictionaries(os.path.join(Home, DEFAULT_NEGATORS_FILE)) 
    hr.addResource(RESKEY_NEGATORS, ngnegn)

    if verbose: print 'ADDING: SMILEYS'
    sd = ngDictionaries(os.path.join(Home, DEFAULT_SMILEYS_FILE))
    hr.addResource(RESKEY_SMILEYS, sd)

#    print 'ADDING: DOMAIN DICTS'
#    dmd = ngDictionaries(DEFAULT_DOMAINMEMDICTS_FILE)
#    hr.addResource(RESKEY_DOMAINMEMDICTS, dmd) 
    
    if verbose: print 'ADDING: HAP_VERBS ...'
    hr.addResource(RESKEY_HAPPENINGVERBS, set(ug.readlines(os.path.join(Home, 'resources/hapwrds.txtp'))))
    hr.addResource(RESKEY_SOFTVERBS, set(ug.readlines(os.path.join(Home, 'resources/softvrbs.txtp'))))
    hr.addResource(RESKEY_PROBNOUNS, set(ug.readlines(os.path.join(Home, 'resources/nouns.txtp'))))

    hr.addResource(RESKEY_NOTHAPPENINGVERBS, set(["work", "receive","send","function", "contact", "connect","get","perform","run","stable","respond","working","receiving","sent","function","connect","got","performing","ran","stability","response","worked","received","sending","functional","connection","getting","performance","running","stabelized","responding","functioning","connecting","performed","stabilizing","responsive"]))
    phrase = ["fuck up",	"fucks up",	"fucked up",	"fucking up",	"hang up",	"hangs up",	"hanged up",	"hanging up",	"screw up",	"screws up",	"screwed up",	"screwing up",	"knocked up",	"knocks up",	"knock up",	"knocking up",	"cut up",	"cuts up",	"cutting up",	"act up",	"acting up",	"acts up",	"acted up",	"fuck off",	"fucks off",	"fucked off",	"fucking off",	"hang off",	"hangs off",	"hanged off",	"hanging off",	"screw off",	"screws off",	"screwed off",	"screwing off",	"knocked off",	"knocks off",	"knock off",	"knocking off",	"cut off",	"cuts off",	"cutting off",	"act off",	"acting off",	"acts off",	"acted off",	"fuck at",	"fucks at",	"fucked at",	"fucking at",	"hang at",	"hangs at",	"hanged at",	"hanging at",	"screw at",	"screws at",	"screwed at",	"screwing at",	"knocked at",	"knocks at",	"knock at",	"knocking at",	"cut at",	"cuts at",	"cutting at",	"act at",	"acting at",	"acts at",	"acted at"]
    hr.addResource(RESKEY_PHRASE, set([ngstr.join(d.split()) for d in phrase]))   
    hr.addResource(RESKEY_OPENCLAUSALCOMPLIMENT, set(["forgot", "block", "blocked", "hacked", "stop", "disconnect", "disconnected", "refuse","cease","stopped","refused","ceased","stopping","refusing","ceasing","stops","refuses","ceases"]))
    hr.addResource(RESKEY_NO_PARTICLE, set(["act","acting","acted","acts","behave","behaving","behaviour","behaves","behaved"]))
    hr.addResource(RESKEY_PHRASE_NO_PREP, set(["fuck",	"fucks",	"fucked",	"fucking",	"hang",	"hangs",	"hanged",	"dropping", "hanging",	"screw",	"screws",	"screwed",	"screwing",	"knocked",	"knocks",	"knock",	"knocking",	"cut",	"cuts",	"cutting",	"act",	"acting",	"acts",	"acted"]))
                   
    domainNouns = ['phone','phones','wi-fi','wifi','data','connection','modem','router','modems','routers', 'hotspot', 'calls','calling','text','texting','call','messages','messaging','message','texts','tv','4g', 'wifi', 'network', 'device', 'plan', 'service', 'services','message', 'messages','towers','servers','email','voicemail','dsl','mobiles','mobile','server']
    domainNouns.extend(['wireless', 'commercial', 'uverse', 'u-verse', 'bill', 'signal', 'bar', 'bars', 'reception', 'internet', 'coverage', '3g', 'cable','cables', 'customer', 'iphone','iphones', 'outage', 'switching', 'cell', 'mobility', 'vz', 'update', 'online', 'email','service','mails'])
 
    dn = ug.readlines(os.path.join(Home, 'ngDicts/domainNouns.csv'))
    dn = [ngstr.join(d.split('|')[0].split()) for d in dn]
    domainNouns.extend(dn)

    dn = ug.readlines(os.path.join(Home, DEFAULT_DOMAIN_NOUNS_FILE))
    dn = ['ngstr'.join(d.split('|')[0].split()) for d in dn]
    domainNouns.extend(dn)

    hr.addResource(RESKEY_DOMAIN_NOUNS, set(domainNouns))    
#    dn = ngDictionaries(DEFAULT_DOMAIN_NOUNS_FILE)
#    hr.addResource(RESKEY_DOMAIN_NOUNS+'TST',dn)
    
    hr.addResource(RESKEY_PREP, ["up","off","out"])

    sep = '|'
    if verbose: print 'ADDING: POLARDICTS'
    wd = makeDictionaries(os.path.join(Home,DEFAULT_POLAR_ADJS_FILE), sep, tokColIdx = 0, polColIdx = 1); 
    if verbose: print (len(wd))
    hr.addResource(RESKEY_POLAR_ADJS, wd)    
    wd = makeDictionaries(os.path.join(Home,DEFAULT_POLAR_ADVS_FILE), sep, tokColIdx = 0, polColIdx = 1); 
    if verbose: print (len(wd))
    hr.addResource(RESKEY_POLAR_ADVS, wd) 
    wd = makeDictionaries(os.path.join(Home,DEFAULT_POLAR_NOUNS_FILE), sep, tokColIdx = 0, polColIdx = 1); 
    if verbose: print (len(wd))
    hr.addResource(RESKEY_POLAR_NOUNS, wd)
    wd = makeDictionaries(os.path.join(Home,DEFAULT_POLAR_VERBS_FILE), sep, tokColIdx = 0, polColIdx = 1); 
    if verbose: print (len(wd))
    hr.addResource(RESKEY_POLAR_VERBS, wd)
    wd = makeDictionaries(os.path.join(Home,DEFAULT_POLAR_ANYP_FILE), sep, tokColIdx = 0, polColIdx = 1); 
    if verbose: print (len(wd))
    hr.addResource(RESKEY_POLAR_ANYPOS, wd)
    
    hr.addResource(RESKEY_ENGWORDS, set(ug.readlines(os.path.join(Home, 'resources/englishwords.txt'))))
#    print 'ADDING: INTJ'
#    dn = ngDictionaries(DEFAULT_INTERJECTIONS_FILE)
#    hr.addResource(RESKEY_POLAR_INTERJECTIONS,dn)
    
    #pickle.dump(hr, open(DEFAULT_HR_FILE,'wb'))
    return hr
                   
if __name__ == "__main__":
     #make core resources
     #scr = HostedResources()
     #scr.restoreCoreResources()
     hr = makeDefaultResources()
     hr.listResources()
#     pickle.dump(hr, open(DEFAULT_HR_FILE,'wb'))
#     print('yayyaya')
