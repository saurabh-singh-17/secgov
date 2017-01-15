# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 13:31:54 2016

@author: u505119
"""
import pandas as pd
import nltk
import nltk.data
from nltk.classify import maxent
from nltk import word_tokenize
from nltk.corpus import stopwords
import pickle
import string
from collections import Counter

#/////////////////////////////////////////////////////////
#                    User Variables
#/////////////////////////////////////////////////////////
algorithm='IIS'
num=0
PercentToTrain=0.7
MinCountLimit=100
MainPath='C:/Users/U505119/Desktop/23July2016/'
pathOfTrainingData='C:/Users/U505119/Desktop/training.csv'
PathToStoreClassifier=MainPath+'my_classifier'+str(num)+'.pickle'
pathToStoreResult=MainPath+'check.csv'
PathToTrainPara=MainPath+'TrainPara.txt'

def CLEAN(start,end,thing):
    global train_para
    train_para[start:end]=[item.rstrip(thing) for item in train_para[start:end] if (len(item)>1)]

#////////////////////////////////////////////////////////
#                    Main program
#//////////////////////////////////////////////////////// 
#-----------------------------------------------------------------------
#            List of words to ignore 
list_stw= stopwords.words('english') + list(string.punctuation)
list_stw.remove('no')
list_stw.remove('other')

#-----------------------------------------------------------------------
#            Prepairing Training parameters 

frame = pd.read_csv(pathOfTrainingData)
train_para=[]
for i in xrange(int(frame.__len__()*PercentToTrain)):
    text = frame.ix[i,'Phrase']
    [i for i in word_tokenize(text.lower()) if i not in list_stw]
    train_para.extend([i for i in word_tokenize(text.lower()) if ((i not in list_stw) or ((',' in i) or ('.' in i)))])
#                       Cleaning
train_para=[item for item in train_para if not ((',' in item) or ('.' in item))]
train_para=[item for item in train_para if not item.isdigit()]
train_para=[item for item in train_para if (len(item)>1)]
train_para=Counter(train_para).items()
train_para=sorted(train_para, key=lambda x: x[1],reverse=True)
train_para=[item for item in train_para if (item[1]>MinCountLimit)]

fo = open(PathToTrainPara, 'wb')
for words in train_para:
    fo.write(str(words)+'\n')
fo.close()
#-----------------------------------------------------------------------
#            Prepairing Training Data 
train=[]
for i in xrange(int(frame.__len__()*PercentToTrain)):
    feature={}
    for parai in train_para:
        if parai[0] in frame.ix[i,'Phrase'].lower():
            value=True
        else:
            value=False
        feature[parai[0]]=value
    train.append((feature,frame.ix[i,'Indicator']))
    
#-----------------------------------------------------------------------
#            Prepairing Test Data 
test=[]
for i in xrange(int(frame.__len__()*PercentToTrain)+1,frame.__len__()):
    feature={}
    for parai in train_para:
        if parai[0] in frame.ix[i,'Phrase'].lower():
            value=True
        else:
            value=False
        feature[parai[0]]=value
    test.append(feature)

#-----------------------------------------------------------------------
#            Training Classifier 
print str(algorithm)
try:
  classifier = nltk.classify.MaxentClassifier.train(train, algorithm, trace=0, max_iter=1000)
except Exception as e:
    print('Error: %r' % e)
# Until here------------------------------------------
#-----------------------------------------------------------------------
#            Storing Classifier 

f = open(PathToStoreClassifier, 'wb')
pickle.dump(classifier, f) 
f.close()

#-----------------------------------------------------------------------
#            Classifying Test Data
answer=[]
for featureset in test:
    pdist = classifier.prob_classify(featureset)
    answer.append([pdist.prob('Yes'), pdist.prob('No')])

df=pd.DataFrame(columns=['actual','y','n'])
master=0
for i in xrange(int(frame.__len__()*0.7)+1,frame.__len__()):
    df.loc[master]=[frame.ix[i,'Indicator'],answer[master][0],answer[master][1]]
    master+=1
   
df.to_csv(pathToStoreResult, index=False,mode='wb', sep=',', header=True)

#-----------------------------------------------------------------------
#            Calculating Model Parameters
tt=0
tf=0
ff=0
ft=0
cutoff=0.4456
for i in xrange(df.__len__()):
    if df.loc[i,'y']>cutoff:
        if df.loc[i,'actual']=='Yes':
            tt+=1
        else:
            tf+=1
    else:
        if df.loc[i,'actual']=='No':
            ff+=1
        else:
            ft+=1

#-----------------------------------------------------------------------
#            Display of Confution Table

accuracy= str(round(float(tt+ff)*100/float(tt+ff+tf+ft),2))
precision= str(round(float(tt)*100/float(tt+tf),2))
sensitivity= str(round(float(tt)*100/float(tt+ft),2))
specificity= str(round(float(ff)*100/float(tf+ff),2))
npv=str(round(float(ff)*100/float(ft+ff),2))

print '\nConfusion Matrix with threshold as: '+ str(cutoff)+'\n'
print '-----------------------------------------------------------\n'
print '\t  Actual\t\n'
print 'Model\tYes\tNo\t\n'
print 'Yes\t'+str(tt)+'\t'+str(tf)+'\t\t'+'Precision: '+precision+'\n'
print 'No\t'+str(ft)+'\t'+str(ff)+'\t\t'+'NPV: '+npv+'\n'
print 'Sensitivity:\tSpecificity:\tAccuracy:\n'
print sensitivity+'\t\t'+specificity+'\t\t'+accuracy+'\n'
print '-----------------------------------------------------------\n'

#-----------------------------------------------------------------------------------------------
#                                END        OF         CODE
#-----------------------------------------------------------------------------------------------





















#path='C:/Users/U505119/Desktop/checkr.csv'

'''

import pickle
f = open('C:/Users/U505119/Desktop/my_classifier'+str()+'.pickle', 'wb')
pickle.dump(classifier, f)
f.close()



import pickle
f = open('my_classifier.pickle', 'rb')
classifier = pickle.load(f)
f.close()
'''