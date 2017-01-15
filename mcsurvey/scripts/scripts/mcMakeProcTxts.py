# -*- coding: utf-8 -*-
"""
proctxts are outputs of the nlp pipeline that are precomputed and saved.
make new proctxts for development and debugging algorithms.
Created on Wed Jun 17 05:58:29 2015

@author: vh
"""
import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
from mcProctxts import mcProctxts
import metaclassifier.mcServicesAPI as mcapi
mcapi.mcInit()


txtfile = '/home/user/Desktop/mcSurveyAnalysis/tmp/DIL/SRV_Q21A_ISSUE_VERBATIM/SRV_Q21A_ISSUE_VERBATIM.verbatims'

    
saveas = '/home/user/Desktop/mcSurveyAnalysis/tmp/DIL/SRV_Q21A_ISSUE_VERBATIM/SRV_Q21A_ISSUE_VERBATIM.proctxt'
docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
txt_cols = 'SRV_Q21A_ISSUE_VERBATIM'

            
proctxts = mcProctxts()
proctxts.make(txtfile, docid_cols, txt_cols, saveas, Maxlines = 100, Npar=1)

