#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 11 13:27:59 2014

@author: vh
"""
import os
import sys
from config import MC_DATA_HOME
from collections import defaultdict

def availableDataSets():
    pd = defaultdict(list) #possible datasets
    for fil in os.listdir(MC_DATA_HOME):
        fileName, fileExtension = os.path.splitext(fil)
        if fileExtension in ['.txts', '.lbls']:
            pd[fileName].append(1)

    ad = [ k for k,v in pd.iteritems() if sum(v) == 2]

    return ad        

if __name__ == "__main__":
    logger = sys.stdout.write
    ad = availableDataSets()
    for a in ad:
        logger('%s\n' % a)        
    
    