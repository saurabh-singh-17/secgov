# -*- coding: utf-8 -*-
"""
Created on Mon Dec 29 18:32:07 2014

@author: vh
"""
import os
import json

import zmq
import numpy as np
import time, os
import json

# PYJNIUS INTERFACE TO CMU TAGGER
#import warnings
#import jnius_config
#if not jnius_config.vm_running:
#    if not 'METACLASSIFIER_HOME' in os.environ:
#        os.environ['METACLASSIFIER_HOME'] = '/'.join(os.path.abspath(__file__).split('/')[:-1])
#    os.environ['CLASSPATH'] = os.path.join(os.environ['METACLASSIFIER_HOME'], 'java/CustomTagger.jar')
#    jnius_config.add_options('-Xrs', '-Xmx512m')
#    #print os.environ['METACLASSIFIER_HOME']
#    #print os.environ['CLASSPATH']
#else:
#    warnings.warn('Tagger JVM Already Running')
#
#from jnius import autoclass #starts the JVM in    
#
class Tagger(object):
    def __init__(self):
        """
        """
#        self._context = zmq.Context()
#        self._socket = self._context.socket(zmq.REQ)
#        self._socket.connect("tcp://localhost:5559")

#        CustomTagger = autoclass('CustomTagger')
#        self._Tagger = CustomTagger()
#        self.tag = self._Tagger.tokenizeAndTag

    def getTags(self, txt):
        """ """
        self._context = zmq.Context()
        self._socket = self._context.socket(zmq.REQ)
        self._socket.connect("tcp://localhost:5559")        
        self._socket.send(txt)
        tt = self._socket.recv()
        return json.loads(tt)
    
    