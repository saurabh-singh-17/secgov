# -*- coding: utf-8 -*-
"""
meta.classifier API

Created on Tue Apr 22 14:01:02 2014

@author: Mu Sigma
"""
import sys, os, time, json, warnings
import cPickle as pickle
from itertools import imap, repeat
from collections import OrderedDict, Sequence, defaultdict
#from pkg_resources import resource_string, resource_filename
        
from Resources import makeDefaultResources
from mcNormalize import ptNormalize as mcNormalizer
from mcNormalize import clean_tags
#from MChttp_tagger import Tagger
from mcTagger import Tagger
#from mcTagger_zmq import Tagger

from processText import sentencifyAndChunk, sentenceSplitProcTxts 
from processText import updateTokenAndChunkProperties 

import mcservices_wrappers
from metaclassifier import computeFeatures, MCKEY_FEATURES

import re
__MC_PROD_HR__ = None
__MC_SERVICES__ = []
__MC_PYHOME__ = None
__MC_PKGNAME__ = None
__MC_CONFIG__ = None
_MC_TAGGER = None

MCCFG_NAME = 'name'
MCCFG_HR = 'hr'
MCCFG_RESFILES = 'resfiles'
MCCFG_CALL = 'call'
MCCFG_RESOURCES = 'resources'

def _getService(serviceName, logger=None):
    """ Extract the service config for service name
    """
    for service in __MC_SERVICES__:
        if serviceName == service[MCCFG_NAME]:
            return service
    return None
    
def mcInit(pkgName = 'metaclassifier', pyPath = None, logger=None):
    """
    """
    if logger:
        logger('Initiliazing ...\n')
        st = time.time() 
        
    global __MC_PROD_HR__
    global __MC_SERVICES__
    global __MC_PYHOME__
    global __MC_PKGNAME__
    global __MC_CONFIG__
    global _MC_TAGGER

    pyPath = '/'.join(os.path.abspath(__file__).split('/')[:-1])
    os.environ['METACLASSIFIER_HOME'] = pyPath
        
    if logger: logger('%s\n' % os.environ['METACLASSIFIER_HOME'])

    __MC_PYHOME__ = os.environ['METACLASSIFIER_HOME']    
    __MC_PKGNAME__ = pkgName

    #load resources:
    mcConfig = json.load(open(os.path.join(__MC_PYHOME__,'prod/mcservices_config.json'), 'r'))
    
    __MC_PROD_HR__ = [makeDefaultResources(__MC_PYHOME__)]
    
    for k, item in enumerate(mcConfig):
        resources = []
        if item.has_key(MCCFG_RESFILES) and item[MCCFG_RESFILES]:
            for r, resfile in enumerate(item[MCCFG_RESFILES]):
                fname = os.path.join(__MC_PYHOME__,resfile)
                res = pickle.load(open(fname, 'r'))
                resources.append(res)
        else:
            mcConfig[k][MCCFG_RESFILES] = []

        mcConfig[k][MCCFG_RESOURCES] = resources

        if item.has_key(MCCFG_CALL):
            mcConfig[k][MCCFG_CALL] = getattr(mcservices_wrappers, mcConfig[k][MCCFG_CALL])

#        if item[MCCFG_NAME] == MCCFG_HR:
#            __MC_PROD_HR__ = mcConfig[k][MCCFG_RESOURCES]
#        else:
#            __MC_SERVICES__.append(mcConfig[k])

        __MC_SERVICES__.append(mcConfig[k])
         
    __MC_CONFIG__ = mcConfig
    
    if not _MC_TAGGER:
        _MC_TAGGER = Tagger()

    if logger:
        logger('Done. (%5.4fs)\n' % (time.time()-st))
    
    return 1

def mcGetServiceNames():
    """ 
    List all available metaclassifier services.
    """
    if not __MC_CONFIG__:
        warnings.warn('metaclassifier is not initialized')
        return None
        
    return [service[MCCFG_NAME] for service in __MC_SERVICES__]
    
def mcPrintConfig(logger=None):
    """
    Print the status of the mcservices configuration.
    """
    if not logger:
        logger = sys.stdout.write
      
    if not __MC_CONFIG__:
        logger('\nmeta.classifier not initialized.\n')
        return -1
        
    logger('%s' % '='*80); logger('\n')
    logger('Package Name: %s\n' % __MC_PKGNAME__)
    logger('Location: %s\n' % __MC_PYHOME__)
    logger('Resources & Models:\n')
        
    for k, item in enumerate(__MC_CONFIG__):
        if item[MCCFG_NAME] == 'hr':
            if __MC_PROD_HR__ == item[MCCFG_RESOURCES]:
                for r, resfile in enumerate(item[MCCFG_RESFILES]):
                    fname = os.path.join(__MC_PYHOME__,resfile)
                    stats = os.stat(fname)
                    logger('%-30s LOADED: %-8d bytes, %s, %s\n' %
                    (item[MCCFG_NAME], stats.st_size, time.asctime(time.localtime(stats.st_mtime)), resfile))

    for k, item in enumerate(__MC_SERVICES__):
        if item.has_key(MCCFG_RESFILES) and item[MCCFG_RESFILES]:
            for r, resfile in enumerate(item[MCCFG_RESFILES]):
                fname = os.path.join(__MC_PYHOME__,resfile)
                stats = os.stat(fname)
                try:
                    ctime = item[MCCFG_RESOURCES][r]['createdon']
                except:
                    ctime = time.asctime(time.localtime(stats.st_mtime))

                logger('%-30s LOADED: %-8d bytes, %s, %s\n' %
                (item[MCCFG_NAME], stats.st_size, ctime, resfile))
        else:
            logger('%-30s No Models\n' % item[MCCFG_NAME])

        if item[MCCFG_NAME] == MCCFG_HR:
            logger('HR in Services')

    logger('%s' % '='*80); logger('\n')
    return 0


def mcNormTxt(txt):
    """
        Normalized token and tags
    """    
    if not isinstance(txt, basestring):
        raise TypeError('mcPipeline: Input must be a string.\n Input:%s ' % txt)
        
    if not txt:
        return {}
        
    txt = mcNormalizer([txt])
    if not txt[0]:
        return {}
        
    normTxt = _MC_TAGGER.getTags(txt[0]) 
    clean_tags(normTxt)

    return normTxt

def mcProcTxt(normtxt):
    procTxt = sentencifyAndChunk([normtxt], __MC_PROD_HR__[0])[0]
    procTxt = updateTokenAndChunkProperties(procTxt, __MC_PROD_HR__[0])
    return procTxt   
    
def _mcNLPipeline(txt):
    """
    """    
    if not isinstance(txt, basestring):
        raise TypeError('mcPipeline: Input must be a string.\n Input:%s ' % txt)
        
    if not txt:
        return {}
        
    txt = mcNormalizer([txt])
    if not txt[0]:
        return {}
        
    procTxt = _MC_TAGGER.getTags(txt[0]) 
    clean_tags(procTxt)
    
    procTxt = sentencifyAndChunk([procTxt], __MC_PROD_HR__[0])[0]
    procTxt = updateTokenAndChunkProperties(procTxt, __MC_PROD_HR__[0])
    return procTxt    
    
def _mcPipeline(procTxt, reqServices):
    """
    """
    if not procTxt:
        return {}
        
    allFeatures = set()
    for service in reqServices:
        for serRes in service[MCCFG_RESOURCES]:
            allFeatures = allFeatures.union(serRes[MCKEY_FEATURES])

    computedFeatures, featureVals = computeFeatures(procTxt, __MC_PROD_HR__[0], allFeatures, True)
    results = {}
    for service in reqServices:
        sname = service[MCCFG_NAME]
        scall = service[MCCFG_CALL] #scall = globals()[service[MCCFG_CALL]]
        smdl = service[MCCFG_RESOURCES]
        result = scall(procTxt, __MC_PROD_HR__, smdl, computedFeatures, featureVals)
        results[sname] = result

    return results
    
def _getServicesConfig(snames):
    """
    """
    #print snames
    if snames:
        if isinstance(snames, basestring):
            snames = [snames]
        elif not hasattr(snames, '__iter__'): 
            raise TypeError('Service names must be a string or iterable. \n Input:%s ' % snames)

        snames = list(OrderedDict.fromkeys(snames)) #unique order preserving list (removes duplicate service names)
        services = [_getService(sname) for sname in snames]
        if not all(services):
            badServiceNames = ['%s' % snames[k] for k, service in enumerate(services) if not service]
            raise Exception("mcRunServices: Unknown Service requested: %s" % badServiceNames)
    else: # collect config of all availables services.
        services = [_getService(service[MCCFG_NAME]) for service in __MC_SERVICES__ if service['defaultService']]
        
    return services
    
def mcRunServices(txts, serviceNames=None):
    """ 
    """
    retval = []
    if isinstance(txts, basestring):
        txts = [txts]
    elif not isinstance(txts, Sequence):
        raise TypeError('mcRunServices: Input must be a string or iterable. \n Input:%s ' % txts)
    
    services = _getServicesConfig(serviceNames)
    
    ntxt = txts.__len__()
    procTxts = imap(_mcNLPipeline, txts)
    mcp = imap(_mcPipeline, procTxts, repeat(services, ntxt))
    retval = [m for m in mcp]
    
    return retval

def mcSentences(txt, serviceNames = None):
    """
    Analyse text by sentences.
    
    """
    retval = []
    if not isinstance(txt, basestring):
        raise TypeError('mcSentences: txt must be a string \n Input:%s ' % txt)
    
    services = _getServicesConfig(serviceNames)
    
    procTxt = _mcNLPipeline(txt)
    sprocTxts = sentenceSplitProcTxts(procTxt)
    ntxt = sprocTxts.__len__()
    mcp = imap(_mcPipeline, sprocTxts, repeat(services, ntxt))
    retval = [m for m in mcp]
    return retval    
    
