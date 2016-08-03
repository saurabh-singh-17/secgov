# -*- coding: utf-8 -*-
"""
Created on Tue Jul 05 13:01:40 2016

@author: U505118
"""

#***************************************************************************
######################  SVM  ###############################################
#***************************************************************************
import numpy as np
#import pandas as pd
import pylab as pl
from sklearn.metrics import roc_curve, roc_auc_score, auc
from sklearn.feature_extraction.text import CountVectorizer
import re
import pickle
import matplotlib.pyplot as plt
from sklearn import preprocessing
import sklearn.metrics
from pandas import DataFrame

'''Class svm creates an object through which we are able to:
    -- Predict the test data
    -- Show model evaluation metrics'''

class svm(object):
      
    def __init__(self, phraseList, actualInd):    #Initialises the variables required for prediction    
        with open('C:/Users/U505118/Desktop/FinalReview/SVM/stopwords_SVM.txt','rb') as f:   #Creates a list of stopwords
            self.stopwords = f.read().split(',')                                      #from a text file 
        f.close()
        with open('C:/Users/U505118/Desktop/FinalReview/SVM/SVMVocab.txt','rb') as f:    #Creates a list of features
            self.vocab = f.read().split(',')                                      #from a text file
        f.close()
        
        self.phraseList = phraseList    #List of sentences to be classified by the model (Test data)
        self.actualInd = actualInd    #List of actual indicators to evaluate the model
        self.df_model = DataFrame()    #Creating a df to be used for model evaluation
        f.close()
        
    def Clean_Data(self):    #Cleans the test data
        for i in range(len(self.phraseList)):    #Cleaning the data by removing numbers so as to make vectorization faster
            self.phraseList[i] = re.sub('\d+', '', self.phraseList[i])
        
    def predict(self):   #Classifies the data based on model
        
        self.Clean_Data()
        
        with open('C:/Users/U505118/Desktop/FinalReview/SVM/SVMmodel.pickle', 'rb') as filehandler:    #Using pickle to import the
            model = pickle.load(filehandler)                                                    #model saved as a .pickle file
    
        '''Vectorizing the test data'''
    
        vect_test = CountVectorizer(stop_words = self.stopwords, ngram_range = (1, 2), vocabulary = self.vocab) #Using CountVectorizer
        testArray = vect_test.fit_transform(self.phraseList).toarray() #to tokenize the data with respect to the given vocabulary
        
        '''Testing the model'''
        
        testInd = model.predict(testArray)    #Predicting the class of each sentence using the model object
        self.predicted_ind = testInd.tolist()    #Converting the output of the model to a list
        
        self.indnum = []
        for x in self.predicted_ind:    #Converting the YES or NO output of the predict() to numerical 1 or 0
            if x == 'Yes':              #where 1 corrosponds to YES and 0 corrosponds to NO
                self.indnum.append(1)
            elif x == 'No':
                self.indnum.append(0)
        
        self.prob = model.predict_proba(testArray).tolist()    #Extracts the probability of each sentence to be YES
        prob_list = []                                         #as decided by the model
        for x in self.prob:
            prob_list.append(x[1])
        self.prob = prob_list 
        
        self.df_model['SVM Indicator'] = self.predicted_ind    #Appending the predicted indicator to df_model
        self.df_model['Indicator'] = self.actualInd    #Appending the actual indicator to df_model
        self.df_model['Probability'] = self.prob    #Appending the calculated probabilities to df_model
            
        self.prob = np.asarray(prob_list)   #Converting the list of probablities to a NUMPY array
        
        self.CalcBasicMetrics()    #Calculate basic metrics
        
        return self.indnum, self.prob   #Retunrs the list of 1/0 and probablities to the user
        
    def CalcBasicMetrics(self):    #Calculate TP, FP, FN, TN, FPR, TPR and thresholds
        self.TP = 0.0    #True Positive
        self.TN = 0.0    #True Negative
        self.FP = 0.0    #False Positive
        self.FN = 0.0    #False Negative
        self.sensitivity = 0.0    #Also known as Recall
        self.specificity = 0.0    #Also known as Recall
        self.precision = 0.0    #Also known as Postive Predictive Value
        self.NPV = 0.0    #Negative Predictive Value
        self.accuracy = 0.0
        
        for i in range(len(self.df_model)):
            if self.df_model.loc[i, 'Indicator'] == 'Yes':          #If the indicator is Yes:
                if self.df_model.loc[i, 'SVM Indicator'] == 'Yes':  #and predicted is YES, then TP
                    self.TP = self.TP + 1 
                elif self.df_model.loc[i, 'SVM Indicator'] == 'No': #and predicted NO, then FN
                    self.FN = self.FN + 1
            elif self.df_model.loc[i, 'Indicator'] == 'No':        #If the indicator is No:
                if self.df_model.loc[i, 'SVM Indicator'] == 'Yes': #and predicted is YES, then FP
                    self.FP = self.FP + 1
                elif self.df_model.loc[i, 'SVM Indicator'] == 'No':#and predicted is NO, then TN
                    self.TN = self.TN + 1
        
        '''Calculating actual number of positive cases'''
        
        actual = []
        for x in self.df_model['Indicator']:
            if x == 'Yes':
                actual.append(1)
            elif x == 'No':
                actual.append(0)
                
        actualvalArray = np.asarray(actual)
        del actual        
        
        self.FPR, self.TPR, self.thresholds = roc_curve(actualvalArray, self.prob)
    
    def ConfusionMatrix(self):    #Calculates and prints the confusion 
                       
        '''Calculating metrics'''
                
        self.sensitivity = (self.TP/(self.TP + self.FN))*100.0
        self.specificity = (self.TN/(self.TN + self.FP))*100.0
        self.precision = (self.TP/(self.TP + self.FP))*100.0
        self.NPV = (self.TN/(self.TN + self.FN))*100.0
        self.accuracy = (self.TP + self.TN)/(self.TP + self.TN + self.FP + self.FN)
        
        '''Printing the Confusion Matrix'''
        
        print '\n\n\n\t\t\t---------Confusion Matrix---------\n'
        print '\t\t\t\t     Predicted\n'
        print '\t\t\t\tYes\t\tNo'
        print '\t\t\t---------------------------------'
        print '\t\t\t|\t\t|\t\t|' 
        print '\t\tYes\t|\t' + str(self.TP) + '\t|\t' + str(self.FN) + '\t|\tPrecision : %f' %self.precision
        print '\t\t\t|\t\t|\t\t|'
        print '      Actual\t\t---------------------------------'
        print '\t\t\t|\t\t|\t\t|'       
        print '\t\tNo\t|\t'+ str(self.FP)+ '\t|\t' + str(self.TN) + '\t|\tNPV : %f' %self.NPV
        print '\t\t\t|\t\t|\t\t|'
        print '\t\t\t---------------------------------\n\n'
        print ('\t\tSensitivity : %f\t\tSpecificity : %f\n\n' %(self.sensitivity, self.specificity))
        print'\t\t\t\tAccuracy : %f' %self.accuracy
        
    def ROC(self):
        '''Calculating actual number of positive cases'''
        
        actual = []
        for x in self.df_model['Indicator']:
            if x == 'Yes':
                actual.append(1)
            elif x == 'No':
                actual.append(0)
                
        actualvalArray = np.asarray(actual)
        del actual
        
        '''Calculating FPR, TPR and AUCROC'''
        
        self.FPR, self.TPR, self.thresholds = roc_curve(actualvalArray, self.prob)
        self.roc_auc = roc_auc_score(actualvalArray, self.prob)
        
        
        print("Area under the ROC curve : %f" % self.roc_auc)
        
        '''Plotting the AUCROC'''
        
        pl.clf()
        pl.plot(self.FPR, self.TPR, label='ROC curve')
        pl.plot([0, 1], [0, 1], 'k--')
        pl.xlim([0.0, 1.0])
        pl.ylim([0.0, 1.0])
        pl.xlabel('False Positive Rate')
        pl.ylabel('True Positive Rate')
        pl.title('Receiver operating characteristic')
        pl.legend(loc='lower right')
        pl.show()
        
    def GainChart(self):
        '''Declaring necessary variables'''    
        
        gain_model = [0]
        gain_random = [0]
        random_cumul = 0.0
        model_cumul = 0.0
        dec = len(self.df_model)/10
        df_GLsort = self.df_model.sort(columns = 'Probability', inplace = False, ascending = False)
        df_GLsort = df_GLsort.reset_index(drop = True)
        
        '''Dividing the data set into deciles and calculating gain'''    
        
        for i in range(10):
            random = 0.0
            model = 0.0
            for k in range(i*dec, (i*dec) + dec):
                if df_GLsort.loc[k, 'Indicator'] == 'Yes':
                    model = model + 1
                if self.df_model.loc[k, 'Indicator'] == 'Yes':
                    random = random + 1
            random_cumul = random_cumul + random
            model_cumul = model_cumul + model
            gain_model.append(((model_cumul)/(self.TP + self.FN))*100.00)
            gain_random.append(((random_cumul)/(self.TP + self.FN))*100.00)
        
        '''Plotting the cumulative gain chart'''
        
        percent_pop = range(0, 110, 10)
        
        pl.clf()
        pl.plot(percent_pop, gain_model, label='Model')
        pl.plot(percent_pop, gain_random, label='Random')
        pl.xlim([0.0, 100.0])
        pl.ylim([0.0, 100.0])
        pl.xlabel('Percentage of Data Set')
        pl.ylabel('Percentage of Positive Cases')
        pl.title('Cumulative Gain Chart')
        pl.legend(loc='lower right')
        pl.show()
        
    def SenSpec(self):
        
        '''Calculating specificity from FPR calculated in AUROC'''    
        
        self.ideal_threshold = 0.0
        self.TNR = self.FPR
        for i in range(len(self.FPR)):    
           self.TNR[i] = 1 - self.FPR[i]
           if abs((self.TNR[i] - self.TPR[i])) <= 0.0001:
               self.ideal_threshold = self.thresholds[i]
        
        '''Plotting sensitivity vs specificity curve'''    
        print '\nIdeal threshold : %f\n' %self.ideal_threshold
        pl.clf()
        pl.plot(self.thresholds, self.TPR, label='Sensitivity')
        pl.plot(self.thresholds, self.TNR, label='Specificity')
        pl.xlim([-0.025, 1.0])
        pl.xlabel('Probability')
        pl.title('Sensitivity vs Specificity')
        pl.legend(loc='lower right')
        pl.show()
        
    def ShowMetrics(self):
        print '\n\n'
        self.ConfusionMatrix()
        print '\n\n'
        self.ROC()
        print '\n\n'
        self.GainChart()
        print '\n\n'
        self.SenSpec()
        print '\n\n'