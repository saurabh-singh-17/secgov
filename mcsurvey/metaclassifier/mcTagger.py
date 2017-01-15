# -*- coding: utf-8 -*-
"""
Created on Mon Dec 29 18:32:07 2014

@author: vh
"""
import os
import json

# PYJNIUS INTERFACE TO CMU TAGGER
import warnings
import jnius_config
if not jnius_config.vm_running:
    if not 'METACLASSIFIER_HOME' in os.environ:
        os.environ['METACLASSIFIER_HOME'] = '/'.join(os.path.abspath(__file__).split('/')[:-1])
    os.environ['CLASSPATH'] = os.path.join(os.environ['METACLASSIFIER_HOME'], 'java/CustomTagger.jar')
    jnius_config.add_options('-Xrs', '-Xmx512m')
    #print os.environ['METACLASSIFIER_HOME']
    #print os.environ['CLASSPATH']
else:
    warnings.warn('Tagger JVM Already Running')

from jnius import autoclass #starts the JVM in    

class Tagger(object):
    def __init__(self):
        """
        """
        CustomTagger = autoclass('CustomTagger')
        self._Tagger = CustomTagger()
        self.tag = self._Tagger.tokenizeAndTag

    def getTags(self, txt):
        """ """
        return json.loads(self.tag(txt))
    
    