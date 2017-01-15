# -*- coding: utf-8 -*-
"""
Created on Tue Jul 05 13:04:20 2016

@author: U505118
"""
import numpy as np
import pandas as pd
import pylab as pl
from sklearn.metrics import roc_curve, roc_auc_score, auc
from sklearn.feature_extraction.text import CountVectorizer
import re
import pickle
import matplotlib.pyplot as plt
from sklearn import preprocessing
import cPickle
import sklearn.metrics
from collections import Counter
from sklearn.ensemble import RandomForestClassifier

#*****************************************************************************
##############################  Maxent  ######################################
#*****************************************************************************


class MaxEnt:
    def LiftGainTable(self):
        # DF: Dataframe read from CSV
        # T: Total number of Actual Rights 
        # F: Total number of Actual Wrongs    
        # frame,yT,fT
        deciles=self.AnswerFrame.sort('y', ascending=0)   # Sorting table based on Yes Probability in descending order
        deciles=deciles.reset_index(drop=True)  # Reseting indexes to traverse by deciles
        length=deciles.__len__()    # Total Population
        sub=int(length/10)  # Population of each decile
        rem=int(length%10)  # Number of deciles to increse Population by 1 (as total population may not necessarily be divisible by 10)
        popu=[sub for item in xrange(10) if 1]  # Making list of population per decile
        popu[:rem]=[(sub+1) for item in xrange(rem) if 1] # Adding 1 to deciles to remove remainders
        last=0 # Population Traveresed until now
        self.lift=pd.DataFrame(columns=['0','1','GT','PercentRights','PercentWrongs','PercentPopulation','CumPercentRight','CumPercentPop','LiftAtdecile','TotalLift'])
        self.lift.loc[0]=[0,0,0,0,0,0,0,0,0,0]   #A dded to make graphs look pretty    
        cumr=0  # Cumulative rights
        cumw=0  # Cumulative Wrongs
        for cin in xrange(10): # As decile
            t0=0    # Number of right per decile, used to calculate decile gain, needed for decile lift
            t1=0    # Number of wrongs per decile
            end=last+popu[cin]  # Decile's ending index
            for i in xrange(last,end):
                if deciles.loc[i,'actual']=='Yes':
                    t1+=1
                else:
                    t0+=1
            t=t0+t1     # Poulation per decile same as popu[cin]
            cumr+=t1    # Cumulative Rights
            cumw+=t0    # Cumulative Wrongs
            last=end    # Shifting start point for next decile
            pr=(t1*100)/self.yT   # Percentage right wrt to total rights that are present in current decile
            pw=(t0*100)/self.fT   # Percentage wrong wrt to total wrongs that are present in current decile
            pp=(t*100)/length   # Percentage on population in current decile
            pcr=(cumr*100)/self.yT    # Perentage of cumulative rights wrt to total rights up to the current decile
            pcp=(end*100)/length    # Percentage of Population traversed till now 
            ld=(pr*100)/pp  # Lift at current decile
            cld=(pcr*100)/pcp   # Total lift 
            self.lift.loc[cin+1]=[t0,t1,t,pr,pw,pp,pcr,pcp,ld,cld]   # Adding entry of decile to dataframe. Index+1 because we filled first row with 0's
            # lift Dataframe is in the same format as lift Gain Chart at http://www.analyticsvidhya.com/blog/2016/02/7-important-model-evaluation-error-metrics/
            return self.lift   
            
    def Lift_Chart(self):   # Displays the lift Chart: either per Decile or Total depending on the value assigned to select
        # l: Dataframe output from  LiftGainTable()
        # select: Selects the chart to display: 'decile' or 'total' lift
        plt.figure()
        plt.plot(self.lift.CumPercentPop,self.lift.TotalLift, label='Lift curve' )
        plt.plot([0, 100], [100, 100], 'k--')   # Graph of random pick model, used as a refence to see how much better our model does than randomly selecting
        plt.xlim([10.0, 100.0])     # Starting from 10% as 0% population lift cannot be calculated (Div by zero)
        plt.ylim([0.0, max(self.lift.TotalLift)])    
        plt.xlabel('Cumulative % of Polulation')
        plt.ylabel('Total % Lift')
        plt.title('Total Lift Chart')
        plt.legend(loc="upper right")   # Upper right as normally the graph has a downward slope near the right end
        plt.show()
        # Sample graph:
        # Decile: http://www.analyticsvidhya.com/wp-content/uploads/2015/01/Liftdecile.png
        # Total: http://www.analyticsvidhya.com/wp-content/uploads/2015/01/Lift.png
    
    def Gain_Chart(self):    # Displays the Total Gain Chart
        # g: Dataframe output from  LiftGainTable()
        plt.figure()
        plt.plot(self.lift.CumPercentPop, self.lift.CumPercentRight, label='Gain curve' )
        plt.plot([0, 100], [0, 100], 'k--')     # Graph of random pick model, used as a refence to see how much better our model does than randomly selecting
        plt.xlim([0.0, 100.0])  # Population percentage always between 0 and 100
        plt.ylim([0.0, 100])    # Gain is always between 0 and 100. Curve always starts at 0 and ends at 100. Refer Sample Graph
        plt.xlabel('Cumulative % of Polulation')
        plt.ylabel('Cumulative % of Right')
        plt.title('Gain Chart')
        plt.legend(loc="lower right")   # Lower right as the graph touches 100 at right end
        plt.show()
        # Sample graph:
        # http://www.analyticsvidhya.com/wp-content/uploads/2015/01/CumGain.png   
        
    def ROC_Curve(self):    # Receiver Operating Characteristic Chart
        # f: False positive rate
        # t: True positive rate 
        # fpr, tpr
        plt.figure()
        plt.plot(self.fpr,self.tpr,label='ROC curve' )
        plt.plot([0, 1], [0, 1], 'k--')     # Graph of random pick model, used as a refence to see how much better our model does than randomly selecting
        plt.xlim([0.0, 1.0])    # False Positive Rate always less than 1
        plt.ylim([0.0, 1.01])   # True POsitive Rate always less than 1 however 1.01 used to visualize the top of the graph better
        plt.xlabel('False Positive Rate')
        plt.ylabel('True Positive Rate')
        plt.title('Receiver Operating Characteristic')
        plt.legend(loc="lower right")   # Curve finally reaches (1,1) freeing up the lower right corner
        plt.show()
        print 'ROC Score: ' +self.Score
        # Sample Graph:
        # http://www.analyticsvidhya.com/wp-content/uploads/2015/01/ROC.png
    
    def SenSpec(self): # Shows Sensitivity vs Cutoff and Specificity vs Cutoff on same graph
        # Point of intersecting of the two graphs is ideal threshold
        # FPR: False Positive Rate
        # SEN: Sensitivity or True Positive Rate
        # C: Thresholds
        plt.figure()
        plt.plot(self.thresholds, self.tpr*100, label='Sensitivity curve' )
        plt.plot(self.thresholds, (1-self.fpr)*100, label='Specificity curve' ) # Specificity= 1-FalsePositiveRate
        # Sensitivity and Specificity graphs change based on model. If slopes are too steep the values can saturate quickly
        # In such cases, displaying beyond the maximum can reduce the quality of the graph and impair visualization
        if (max(self.thresholds)-min(self.thresholds)) > 0.5:
            plt.xlim([0, 1])
        else:
            plt.xlim([0, max(self.thresholds)+0.05]) # +0.05 for better visualization
        plt.ylim([0.0, 100])
        plt.xlabel('Cutoff Probability')
        plt.ylabel('Percentage')
        plt.title('Sensitivity Specificity Plot')
        plt.legend(loc="lower right")
        plt.show()
        # Sample Graph:
        # http://www.analyticsvidhya.com/wp-content/uploads/2015/01/curves.png
        
    def MakeFeatures(self):
        data=pd.read_csv(self.pathOfData)
        data=data[[self.text,self.indicator]]
        words = []

        for row in data[self.text]:
            words =words + row.split()
            
        all_words = []

        for w in words:
            all_words.append(w.lower())

        all_words = nltk.FreqDist(all_words)

        word_features = list(all_words.keys())

        def find_features(document):
            words = set(document)
            features = {}
            for w in word_features:
                features[w] = (w in words)
            return features

        zipped = zip(data[self.text],data[self.indicator])
        featuresets = [(find_features(text.lower().split()), category) for (text, category) in zipped]
        self.featuresets = featuresets


    
    def MakeClassifier(self):
        trainingSet=featureset
        pass
    
    def LoadClassifier(self):
        f = open(self.PathToSavedClassifier,'rb')   # Reading has to be done in 'rb' Mode
        self.classifier = pickle.load(f)
        f.close()
        
    def LoadFeatures(self):
        f = open(self.PathToTrainPara,'rb')   # Reading has to be done in 'rb' Mode
        self.train_para = pickle.load(f)
        f.close()
        
    def ClassifySentences(self):
        test=[]
        for i in xrange(self.phrase.__len__()):
            feature={}
            for parai in self.train_para:
                if parai in self.phrase[i].lower():
                    value=True
                else:
                    value=False
                feature[parai]=value
            test.append(feature)
        answer=[]
        for featureset in test:
            pdist = self.classifier.prob_classify(featureset)
            answer.append([pdist.prob('Yes'), pdist.prob('No')])
        self.AnswerFrame=pd.DataFrame(columns=['actual','y','n'])
        master=0
        for i in xrange(self.phrase.__len__()):
            self.AnswerFrame.loc[master]=[self.indicator[i],answer[master][0],answer[master][1]]
            master+=1
    
    def FindOptimal(self):
        idx = np.argwhere(np.isclose((1-self.fpr)*1000,self.tpr*1000, atol=10)).reshape(-1)
        self.Optimal = round(self.thresholds[idx[idx.__len__()/2]],3)        
    
    def Process(self):
        self.y_scores=self.AnswerFrame.loc[:,'y']   # Model given probability of yes
        self.y_true =self.AnswerFrame.loc[:,'actual'] # Actual Yes or No 
        self.y_scores = np.array(self.y_scores)
        self.y_true=[(item=='Yes') for item in self.y_true if 1]  # Coverting from Yes No to True and False
        self.y_true_count=Counter(self.y_true).items() # Clusters True and false together in an tuple and gives its freq
        if self.y_true_count[0][0]: 
            self.yT=self.y_true_count[0][1]
            self.fT=self.y_true_count[1][1]
        else:
            self.yT=self.y_true_count[1][1]
            self.fT=self.y_true_count[0][1]
        
        self.Score=str(round(roc_auc_score(self.y_true, self.y_scores),3)) # Area under ROC
        # Score Ranges and Model Evaluation
        # 0.90-1 = excellent (A)
        # 0.80-.90 = good (B)
        # 0.70-.80 = fair (C)
        # 0.60-.70 = poor (D)
        # 0.50-.60 = fail (F)
        
        self.fpr, self.tpr, self.thresholds = roc_curve(self.y_true, self.y_scores)
    
    def CalculateConfusion(self):
        # Nomenclature: ModelPrediction Actual
        self.tt=0 # Model predicts True and is Actually True
        self.tf=0 # Model predicts True but is Actually False
        self.ff=0 # Model predicts False and is Actually False
        self.ft=0 # Model Predicts False but is Aactually True
        
        if self.UseOptimumCutoff:
            self.cutoff=self.Optimal
            print 'Using Optimal Cutoff for confusion matrix\n'
        self.output=[]
        for i in xrange(self.AnswerFrame.__len__()):
            if self.AnswerFrame.loc[i,'y']>self.cutoff:
                self.output.append((self.AnswerFrame.loc[i,'actual'],True))
                if self.AnswerFrame.loc[i,'actual']=='Yes':
                    self.tt+=1
                else:
                    self.tf+=1
            else:
                self.output.append((self.AnswerFrame.loc[i,'actual'],False))
                if self.AnswerFrame.loc[i,'actual']=='No':
                    self.ff+=1
                else:
                    self.ft+=1
        
        # How parameters are calculated: http://www.analyticsvidhya.com/wp-content/uploads/2015/01/Confusion_matrix.png
        #                               Definitions:
        # Accuracy : the proportion of the total number of predictions that were correct.
        # Positive Predictive Value or Precision : the proportion of positive cases that were correctly identified.
        # Negative Predictive Value : the proportion of negative cases that were correctly identified.
        # Sensitivity or Recall : the proportion of actual positive cases which are correctly identified.
        # Specificity : the proportion of actual negative cases which are correctly identified.
        self.accuracy= str(round(float(self.tt+self.ff)*100/float(self.tt+self.ff+self.tf+self.ft),2))
        self.precision= str(round(float(self.tt)*100/float(self.tt+self.tf),2)) # Same as Positive Predicted Value
        self.sensitivity= str(round(float(self.tt)*100/float(self.tt+self.ft),2))
        self.specificity= str(round(float(self.ff)*100/float(self.tf+self.ff),2))
        self.npv=str(round(float(self.ff)*100/float(self.ft+self.ff),2)) # Negative predicted value
        
    def ShowModel(self):
        #-----------------------------------------------------------------------
        #            Calculations of Model Metrics
        print '-----------------------------------------------------------\n'
        print 'Confusion Matrix with threshold as: '+ str(self.cutoff)+'\n'
        print '-----------------------------------------------------------\n'
        print '\t  Actual\t\n'
        print 'Model\tYes\tNo\t\n'
        print 'Yes\t'+str(self.tt)+'\t'+str(self.tf)+'\t\t'+'Precision: '+self.precision+'\n'
        print 'No\t'+str(self.ft)+'\t'+str(self.ff)+'\t\t'+'NPV: '+self.npv+'\n'
        print 'Sensitivity:\tSpecificity:\tAccuracy:\n'
        print self.sensitivity+'\t\t'+self.specificity+'\t\t'+self.accuracy+'\n'
        print '-----------------------------------------------------------\n'
        print 'Model Evaluation Metrics\n'
        print 'ROC Score: ' +self.Score
        print '-----------------------------------------------------------\n'
        print 'Optimal Cutoff: '+str(self.Optimal)+'\n'
    def PrepareForOutput(self):
        self.df=pd.DataFrame(columns=['a','p','0/1'])
        for i in xrange(self.y_scores.__len__()):
            if self.y_scores[i]>self.cutoff:
                #output.append(1)
                self.df.loc[i]=[self.y_true[i],self.y_scores[i],1]
            else:
                self.df.loc[i]=[self.y_true[i],self.y_scores[i],0]
        
    def RUN(self):
        self.LoadClassifier()
        self.LoadFeatures()
        self.ClassifySentences()
        self.Process()
        self.FindOptimal()
        self.CalculateConfusion()
        self.LiftGainTable()
        #self.ShowModel()
        self.PrepareForOutput()
        return self.df['p'].tolist(),self.df['0/1'].tolist()

    def __init__(self,P,A,ClassifierLocation,FeatureLocation,OptimumCutoff=True,c=0.44572,pathOfData,indicator,text,trainPercentage=70):
        self.phrase=P
        self.indicator=A
        self.PathToSavedClassifier=ClassifierLocation
        self.PathToTrainPara=FeatureLocation
        self.UseOptimumCutoff=OptimumCutoff
        self.cutoff=c
        self.pathOfData=pathOfData
        self.indicator=indicator
        self.text=text
        self.trainPercentage=trainPercentage