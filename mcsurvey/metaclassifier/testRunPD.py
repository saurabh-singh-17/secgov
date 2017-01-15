# -*- coding: utf-8 -*-
"""
Created on Tue Jun 23 05:45:00 2015

@author: user
"""

import os, sys
home = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.sys.path.append(home)
os.chdir(home)
print home
print os.getcwd()
#

import cPickle as pickle
import metaclassifier.mcServicesAPI as mcapi
os.chdir("/home/user/Desktop/mcSurveyAnalysis/scripts")
import mcsa_word_relationships as mcwa
#PDpickle=pickle.load(open("/home/user/Desktop/mcSurveyAnalysis/metaclassifier/prod/PD_VPAnalysis4SKLR.msmdl"))

serviceNames=["sentiment","problemDetection"]
reqServices = mcapi._getServicesConfig(serviceNames)
allFeatures=set()
for service in reqServices:
    for serRes in service[mcapi.MCCFG_RESOURCES]:
        allFeatures = allFeatures.union(serRes[mcapi.MCKEY_FEATURES])

#nlp=mcapi._mcNLPipeline("ive put if off this long because ive been travelling but i was reminded this week when i was home that my box is horrible i talked to someone at at&t before and they said to reset the box which i have done i went to find a show tonight to watch and i noticed it did not record hence the angry xxxam chat session sure you can send them but if they claim there is no problem i am canceling my at&t service")  
#pd=mcapi.mcSentences("ive put if off this long because ive been travelling but i was reminded this week when i was home that my box is horrible i talked to someone at at&t before and they said to reset the box which i have done i went to find a show tonight to watch and i noticed it did not record hence the angry xxxam chat session sure you can send them but if they claim there is no problem i am canceling my at&t service","problemDetection")  

#box is horrible
#did not record the show
#mcapi.mcSentences("if they claim there is no problem i am canceling my at&t_NG_service","problemDetection")
#text="My name is saurabh and i am not happy with the at&t customer serivce. network is not working. Modem is good. iphone is working"
#pd=mcapi.mcSentences(text)
#nlp=mcapi._mcNLPipeline(text)
#nlp=mcapi.mcRunServices(text,"problemDetection")


#nlp=mcapi.mcRunServices("i understand its alot of data but its weird that i can not find out how much data i have used unless i am almost out.","problemDetection")

#nlp=mcapi.mcRunServices("network is not working","problemDetection")
'''
rs=mcapi.mcRunServices("Network works very very efficiently")
lpp=mcapi._mcNLPipeline("Network hanged")
lpp2=mcapi._mcNLPipeline("Networks is getting stuck")
lpp3=mcapi._mcNLPipeline("Network is hanging")
lpp4=mcapi._mcNLPipeline("Network is not hanging")
lpp5=mcapi._mcNLPipeline("Network hangs abruptly")
lpp6=mcapi._mcNLPipeline("Network does not hang")
lpp7=mcapi._mcNLPipeline("Working of the network is not good")
lpp8=mcapi._mcNLPipeline("my IPhone needs to be working")
lpp9=mcapi._mcNLPipeline("He is hard working")
lpp10=mcapi._mcNLPipeline("I am not very sure but working of network is not good")


lp=mcapi._mcNLPipeline("i wish the phone was working")
'''
text="I was not able to change my address successfully on the website.  When I called to do my upgrade over the phone, I first asked the representative to make sure my address was corrected.  I was assured this was done, however when the order did not complete and I called customer service again, I learned that not only was the order done incorrectly, but my address was never changed.  As stated previously in this survey, when I was speaking with the first representative, there was alot of noise in the background and I was informed there was a birthday celebration going on for a co-worker.  The representative was obviously distracted"
text="Network is working"

#lpp11=mcapi._mcNLPipeline(text)
#ver=mcwa.findNounrelatedKeyVerbs(res)
#adj=mcwa.findNounIntensifyingAdj(res)
text="I am happy with my current plan, but having to pay full price for phone upgrades in this plan is extremely costly"
#text="however when the order did not complete"
text="No help with my problem and I am paying an awful lot of money and I get horrible customer service"
#text="Bad customer service"
#text="joseph was patient and explained everything clearly"
text="I will be paying to get out of my service I would rather give my money to someone else that will help with a problem"
res=mcapi._mcNLPipeline(text)
nlp=mcapi.mcRunServices(text,"entitySentiment")
pd=mcapi.mcRunServices(text,"problemDetection")
#mcapi.__MC_PROD_HR__[0].resources.keys()
ver=mcwa.findNounrelatedKeyVerbs(res)
adj=mcwa.findNounIntensifyingAdj(res)

import metaclassifier.problem_phrases as pp
result=pp.inducedChunkPolarity(res,mcapi.__MC_PROD_HR__[0])

#lpp11["chunksInClauses"][0][0][3].pols
#procTxt["clausedSentences"][0][0].pols
#procTxt["chunkedSentences"][0][1].pols
#mcapi.__MC_PROD_HR__[0].getResource("polar_adjs_dict")

def printinfo( arg1, *vartuple ):
   "This prints a variable passed arguments"
   print "Output is: "
   #print arg1
   for var in vartuple:
      print var
   return
   
   
   

printinfo(1,2,3,4,5)   
   
   
aa={"e a":1,"b":1,"c":0,"d":0}
bb=["e a"]

xy=[n for n in bb if n if in aa.keys() if aa[n] == 0]
   
   
   
   

