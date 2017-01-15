# -*- coding: utf-8 -*-
"""
meta.classifier API

Created on Tue Apr 22 14:01:02 2014

@author: Mu Sigma
"""
import json, nltk
from mcServicesAPI import mcPrintConfig, mcRunServices, mcGetServiceNames, mcNormTxt, mcSentences
a = mcServicesAPI.mcInit()
__all__ = [mcPrintConfig, mcRunServices, mcGetServiceNames, mcSentences, mcNormTxt]

