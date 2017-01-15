# -*- coding: utf-8 -*-
"""
Created on Wed Apr  2 19:26:20 2014

@author: vh
"""
from warnings import warn
HASKEYMSG = 'Has %s already computed'

def discVar2Feature( var, varname, lims = [1,3], collapse = [False, False], ctxt = 'Has'):
    """
    Discrete Variable to Feature Convertor.
    var value of variable
    varname name of variable.
    lims = range of numbers
    lims = range of discretization.
    collapse = list with two binary vals. collapse all below lim[0] to lim[0] & collapse all above lim[1] to lim[1]
    
    e.g.,
    fdict = discVar2Feature(8, 'positive adjective', lims = [1,5], collapse [True, True]) 
    contains 1 positive adjective False
    contains 2 positive adjective False
    contains 4 positive adjective False
    contains 3 positive adjective False
    contains 5 positive adjective True
       
    """
  
    vals = xrange(lims[0], lims[1]+1) 
    
    keystr = ctxt + ' %s ' + varname
    fdict = {keystr % val:False for val in vals}    

    if collapse[0] == True:
        if lims[0] > var:
            var = lims[0]
        #var = max([var, lims[0]])
    if collapse[1] == True:
        if lims[1] < var:
            var = lims[1]
        #var = min([var, lims[1]])
    
    if var >= lims[0] and var <= lims[1]: #if collapse = False, ignore vals outside lims
        fdict[(keystr) % (var)] = True   
            
    return fdict 
    
def discVar2FeatureOld( var, varname, lims = [1,5], collapse = [False, False], ctxt = 'contains'):
    """
    Discrete Variable to Feature Convertor.
    var value of variable
    varname name of variable.
    lims = range of numbers
    lims = range of discretization.
    collapse = list with two binary vals. collapse all below lim[0] to lim[0] & collapse all above lim[1] to lim[1]
    
    e.g.,
    fdict = discVar2Feature(8, 'positive adjective', lims = [1,5], collapse [True, True]) 
    contains one positive adjective False
    contains two positive adjective False
    contains four positive adjective False
    contains three positive adjective False
    contains five positive adjective True
       
    """
    nums = ['zero','one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']
        
    vals = range(lims[0], lims[1]+1) 
    
    #init fdict
    fdict = dict()    
    for k, val in enumerate(vals):
        fdict[(ctxt + ' %s ' + varname) % (nums[val])] = False
        
    if collapse[0] == True: var = max([var, lims[0]])
    if collapse[1] == True: var = min([var, lims[1]])
    
    if var >= lims[0] and var <= lims[1]: #if collapse = False, ignore vals outside lims
        fdict[(ctxt + ' %s ' + varname) % (nums[var])] = True   
            
    return fdict 
    
def haskey(featureVals, fkey):
    """
    Check if featureVals contains FKEY
    This is a check to see if a core feature function has been previously computed.
    """
    try:
        featureVals[fkey]
    except KeyError:
        return False

    #warn(HASKEYMSG % (fkey))
    return True 
        
#    if featureVals.has_key(fkey):
#        s = 'Has %s already computed' % (fkey)
#        warn(s)
#        return True 
#    return False 
