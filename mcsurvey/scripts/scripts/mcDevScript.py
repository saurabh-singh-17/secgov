# -*- coding: utf-8 -*-
"""
Example script to use proctxts.
Created on Wed Jun 17 05:58:29 2015

@author: vh
"""
import metaclassifier.mcServicesAPI as mcapi
from mcProctxts import mcProctxts
mcapi.mcInit()


txtfile = '/home/user/Desktop/mcSurveyAnalysis/tmp/DIL/SRV_Q21A_ISSUE_VERBATIM/SRV_Q21A_ISSUE_VERBATIM.verbatims'
saveas = '/home/user/Desktop/mcSurveyAnalysis/tmp/DIL/SRV_Q21A_ISSUE_VERBATIM/SRV_Q21A_ISSUE_VERBATIM.proctxt'
docid_cols = ['SRV_ACCT_ID', 'YYYYMM'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
txt_cols = 'SRV_Q21A_ISSUE_VERBATIM'

#make new proctxts            
#proctxts = mcProctxts()
#proctxts.make(txtfile, docid_cols, txt_cols, saveas, Maxlines = 2000, Npar=3)

##use            
import metaclassifier.problem_phrases as pp
proctxts = mcProctxts()
proctxts.load(saveas)
hr = mcapi.__MC_PROD_HR__[0]

for t, sproctxts in enumerate(proctxts):
    for proctxt in sproctxts:
    #print len(proctxt)
        #print type(proctxt)
        if not proctxt:
            continue
        #aa = pp.problemPhraseBases(proctxt, hr)
        aa = pp.problemPhraseAnalysis(proctxt, hr)
        print aa
#        if aa['problemPhraseBases']['HAS_PROB_CLAUSE']:
#            problems = pp.probPhrasePretty(proctxt, hr)
#            for sentence in proctxt['chunksInClauses']:
#                for clause in sentence:
#                    print '%s' %  ' '.join([repr(chunk) for chunk in clause])
#                print 'PROBLEM PHRASE'
#            print problems
#            print '---'