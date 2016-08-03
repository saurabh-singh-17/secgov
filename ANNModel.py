# -*- coding: utf-8 -*-
"""
Created on Fri Jul 01 13:15:33 2016

@author: Vijay Yevatkar
"""

from sklearn.feature_extraction.text import CountVectorizer
import matplotlib.pyplot as plt
import sklearn.metrics
import pandas as pd
import numpy as np
import re
import os
import warnings
warnings.filterwarnings("ignore")

'''
The ANN class implements the Artificial Neural Network.
For training the data it takes following inputs:
    1. X - Feature set
    2. y - Labelled Data
    3. alpha - This is the learning rate, default is 0.1
    4. max_iter - Maximum iterations to see the error minimized, default = 5000
For testing, it just takes the input data and the calculated weights

Two methods of this clasls are to calculate the activation function used in the NN.
1 - sigmoid -> the sigmoid function
2 - sigmoid_output_to derivative - calculates the derivative of the sigmoid function and returns it.
'''

class ANN(object):
    
    # Compute the Sigmoid nonlinearity
    def sigmoid(self,x):
        output = 1/(1+np.exp(-x))
        return output
    
    # Calculate the output of Sigmoid derivative
    def sigmoid_output_to_derivative(self,output):
        return output*(1-output)    
    
    #Train the data
    def trainNN(self,X,y,alpha=0.1,max_iter=5000):
            
        dim = len(X[0])
        np.random.seed(1)
    
        # randomly initialize our weights with mean 0
        synapse_0 = 2*np.random.random((dim,1)) - 1

        j=-1
        while j < max_iter:
            j+=1

            # Feed forward through layers 0 and 1
            layer_0 = X
            layer_1 = self.sigmoid(np.dot(layer_0,synapse_0))
    
            # Calculate the error in the layer
            layer_1_error = layer_1 - y
    
            # Absolute error
            err = np.mean(np.abs(layer_1_error))
            
            #Check if error is minimizing after every 100 iterations            
            #if not j%100:
            #    print "Error after "+str(j)+" iterations:" + str(err)
            
            # if error goes below 0.1, break            
            if err < 0.1:
                break
    
            # Check delta
            layer_1_delta = layer_1_error*self.sigmoid_output_to_derivative(layer_1)
    
            # Find the final weights
            synapse_0 -= alpha * (layer_0.T.dot(layer_1_delta))  
                   
        return synapse_0
    
    # Test the data
    def testNN(self,X,w):
        layer_0 = X
        layer_1 = self.sigmoid(np.dot(layer_0,w))
        return layer_1

'''
This is the SEC class, to run the training and testing datasets and to get the required output.
Input while instantiation of the WF object:
    1 - A file/panda Dataframe: You can either input the path of the file or the dataframe itself. 
        Please refer readme for the structure of the Dataframs.
'''

class SEC(object):
    
    # cleanPhrase removes all the unnessary data from the sentences.
    def cleanPhrase(self,s):
        s = re.sub(r"[^A-Za-z\']", " ", s)
        s = re.sub(r"\s{2,}", " ", s)
        s = re.sub(r" [A-Za-z] ", " ", s)
        return s.lower().strip()
    
    # Returns the dataframe after cleaning the it.
    def clean(self,data):
        phrases = data["Phrase"]
        new_phrases = []    
        for i in phrases:
            x = self.cleanPhrase(i)
            new_phrases.append(x)
        data["Phrase"] = new_phrases
        return data
    
    # Train the given data with the ANN
    def trainData(self,y):

        # Convert the given phrase list to a numpy array for input to ANN
        # 2-D matrix with phrase_list as rows and features as columns : [phrase_list X feature_set]
        nn_inp = self.cv.fit_transform(self.train_data["Phrase"].values).toarray()
        neural_net = ANN()

        # O/P is the weight matric of dimension [feature_set X 1]
        ans = neural_net.trainNN(nn_inp,y)
        return ans
        
    # Test the given data with the ANN
    def testData(self,ans):
        test_sample = self.cv.fit_transform(self.test_data["Phrase"].values).toarray()
        neural_net = ANN()        
        
        # Take the weight matrix, [feature_set X 1] and dot it on test dataset
        test_out = neural_net.testNN(test_sample,ans)    
        return test_out
    
    # Plot various modelling curves
    def plotCurves(self):
        
        # ROC Curve
        plt.plot(self.fpr, self.tpr, 'b',label = 'AUC = %0.2f'%self.roc_auc)
        plt.legend(shadow = True, fancybox = True, loc = 4)
        plt.ylabel('True Positive Rate (Sensitivity)')
        plt.xlabel('False Positive Rate (1-Specificity)')
        plt.title("ROC Curve")
        plt.show()
        
        # Sensitivity-Specificity
        fig, ax1 = plt.subplots()
        ax1.plot(self.tpr, self.thresholds, 'b')
        ax1.set_xlabel('Threshold')
        ax1.set_ylabel('Sensitivity', color = 'b')
        
        for tl in ax1.get_yticklabels():
            tl.set_color('b')
        
        ax2 = ax1.twinx()
        ax2.plot(1-self.fpr, self.thresholds, 'r')
        ax2.set_ylabel('Specificity', color = 'r')
        
        for tl in ax2.get_yticklabels():
            tl.set_color('r')
        
        plt.title("Specificity-Sensitivity Curve")
        plt.show()
        
        # Gain Curve
        plot_test_data = self.test_data.reset_index()
        del plot_test_data['index']
        plot_test_data['pred_scores'] = [i for j in self.predicted_prob.tolist() for i in j]
        plot_test_data = plot_test_data.sort(columns = ["pred_scores"], ascending = False)
        plot_test_data = plot_test_data.reset_index()
        del plot_test_data['index']
        
        dec = len(plot_test_data)/10                
        responses = [0]        
        
        # Calculate the positive responses for each decile and the total positive count
        res_count = 0 
        total_yes_count = 0
        for i in range(1, len(plot_test_data)+1):
            if not i % dec:
                responses.append(res_count)
                res_count = 0
            if plot_test_data['pred_scores'][i-1] >= self.optimal_thresh:
                res_count += 1
                total_yes_count += 1
        
        # Calculate the cummulative positive count
        cumm_response = [responses[0]]
        for i in range(1, len(responses)):
            cumm_response.append(responses[i] + cumm_response[i-1])
                    
        # What's the percentage of responses recorded in each decile
        percent = []
        for i in responses:
            per = (float(i)/total_yes_count)*100
            percent.append(float("%.2f" % per))
        
        # Find the gains values. 
        # Percent of cummulative positive count to total positive count
        self.gains = []
        for i in range(0, len(cumm_response)):
            if i == 0:
                per = 0
            else:
                per = (float(cumm_response[i])/total_yes_count)*100
            self.gains.append(float("%.2f" % per))
        
        # For random data  gains plot
        percent_pop = range(0, 110, 10)        
        
        # Lift is the ratio of gains per decile to that of the percent population
        self.lift = [self.gains[1]/percent_pop[1]]
        for i in range(1, 11):
            x = self.gains[i]/percent_pop[i]
            self.lift.append(x)        
            
        plt.plot(percent_pop, self.gains, 'b', label = "Model")
        plt.plot(percent_pop,percent_pop,'r',label = "Random")
        plt.legend(shadow = True, fancybox = True, loc = 4)        
        plt.ylabel('Target Percentage')
        plt.xlabel('Population Percentage')
        plt.title("Gains Chart")
        plt.show()
        
        plt.plot(percent_pop, self.lift, 'y', label = "Lift")
        plt.legend(shadow = True, fancybox = True, loc = 1)        
        plt.ylabel('Cummulative Lift')
        plt.xlabel('Population Percentage')
        plt.title("Lift Chart")
        plt.show()        
        
    # Print the Confusion Matrix
    def print_confusion_matrix(self):
        print "|--------------------------------------------------------------|"
        print "|                       |                 Actual               |"
        print "|--------------------------------------------------------------|"
        print "|                       |       True        |      False       |"
        print "|--------------------------------------------------------------|"
        print "|                   |Yes|        %s        |        %s        |  |Precision = %s|"%(self.ranks['tp'],self.ranks['fn'],self.precision)
        print "| Model             |---|-------------------|------------------|"
        print "|                   |No |        %s         |        %s       |  |NPV = %s|"%(self.ranks['fp'],self.ranks['tn'],self.npv)
        print "|--------------------------------------------------------------|"
        print "|                   Sensitivity = %s    Specificity = %s   |"%(self.sensitivity,self.specificity)
        print "|--------------------------------------------------------------|"
        print "|                                   Accuracy = %s            |"%(self.accuracy)
        print "|--------------------------------------------------------------|"
    
    # run function : args = print_curves. Default is False
    def run(self,print_curves=False):
        
        # Labelled O/P        
        self.y_train_scores = []
        self.y_test_scores = [] 

        for i in self.train_data["Indicator"]:
            if i=="Yes":
               self.y_train_scores.append(1)
            else:
                self.y_train_scores.append(0)
        
        for i in self.test_data["Indicator"]:
            if i=="Yes":
                self.y_test_scores.append(1)
            else:
                self.y_test_scores.append(0)        
        
        # Train the data and get the weight matrix
        valid_scores = np.array([self.y_train_scores]).T
        ans = self.trainData(valid_scores)
        
        # Get the probabilities after testing the data on the obtained weights
        self.predicted_prob = self.testData(ans)
        
        # calculate various metrics using sklearn.metrics library:
        # false positive rate: fpr
        # true positive rate: tpr
        # threshold matrix: thresholds
        # area under curve: roc_auc
        self.fpr,self.tpr,self.thresholds = sklearn.metrics.roc_curve(self.y_test_scores,self.predicted_prob)
        self.roc_auc = sklearn.metrics.auc(self.fpr, self.tpr)
        self.thresholds[0]=1.0
        
        # Get the optimal threshold (default = 0.5)
        # Optimal threshold is the point where specificity + sensitivity is maximum
        max_sum = 0
        self.optimal_thresh = 0.5
        for i in range(0, len(self.tpr)):
            temp = (self.tpr[i] + (1.0-self.fpr[i]))
            if temp > max_sum:
                max_sum = temp
                self.optimal_thresh = self.thresholds[i]
        
        # Keep track of all the values.
        # false positives : fp 
        # true positives  : tp 
        # false negatives : fn
        # true negatives  : tn
        
        self.ranks = {'tp':0,'fp':0,'fn':0,'tn':0}
        ind=0
        self.final_scores = []
        for i in self.y_test_scores:
            if i==1:
                if self.predicted_prob[ind]>self.optimal_thresh:
                    self.ranks['tp'] = self.ranks['tp']+1
                    self.final_scores.append(1)
                else:
                    self.ranks['fn'] = self.ranks['fn']+1
                    self.final_scores.append(0)
            else:
                if self.predicted_prob[ind]>self.optimal_thresh:
                    self.ranks['fp'] = self.ranks['fp']+1
                    self.final_scores.append(1)
                else:
                    self.ranks['tn'] = self.ranks['tn']+1
                    self.final_scores.append(0)
            ind+=1
        
        # Return the precision, sensitivity and accuracy            
        self.precision = float("%.2f"%(float(self.ranks['tp'])/(self.ranks['tp']+self.ranks['fp'])))
        self.sensitivity = float("%.2f"%(float(self.ranks['tp'])/(self.ranks['tp']+self.ranks['fn'])))
        self.accuracy = float("%.2f"%(float(self.ranks['tp']+self.ranks['tn'])/(self.ranks['tp']+self.ranks['tn']+self.ranks['fp']+self.ranks['fn'])))
        self.npv = float("%.2f"%(float(self.ranks['tn'])/(self.ranks['fp']+self.ranks['tn'])))
        self.specificity = float("%.2f"%(float(self.ranks['tn'])/(self.ranks['fn']+self.ranks['tn'])))

        if print_curves:
            self.plotCurves()        
        
        return ["Precision = %s"%(self.precision), "Sensitivity = %s"%(self.sensitivity), "Accuracy = %s"%(self.accuracy)]

    #instantiate the class object
    def __init__(self,file_or_df,sw="sw_default.txt",curr_path="",learn_features=False):

        if curr_path == "":
            curr_path = os.path.abspath(".")
        os.chdir(curr_path)
        self.sw_path = sw        
        
        
        if type(file_or_df) is str:
            self.file_is = file_or_df
            try:
                self.inp_df = pd.read_csv(file_or_df)
            except Exception as e:
                print e
                return
        else:
            self.inp_df = file_or_df
        
        #Divide the training and testing data. 70% = Training, 30% = Testing.
        self.train_data = self.clean(self.inp_df[0:int(0.7*len(self.inp_df))])
        self.test_data = self.clean(self.inp_df[int(0.7*len(self.inp_df)):])

        # Load the stopwords
        try:
            sw_file = open(self.sw_path)
            self.stop_words = sw_file.read().split(",")
            sw_file.close()
        except Exception as e:
            print e
            return
    
        # Learn features if specified explicitly
        if learn_features:
            yes_df = self.clean(self.train_data.loc[self.train_data["Indicator"] == "Yes"])
            no_df = self.clean(self.train_data.loc[self.train_data["Indicator"] == "No"])
            
            yes_sent = CountVectorizer(stop_words = self.stop_words, max_features = 100)  
            yes_sent.fit_transform(yes_df["Phrase"])  
               
            no_sent = CountVectorizer(stop_words = self.stop_words, max_features = 100)
            no_sent.fit_transform(no_df["Phrase"])
            
            yes_words = yes_sent.get_feature_names()
            no_words = no_sent.get_feature_names()
            
            feats = yes_words + no_words
            final_features = list(set(feats))
            
            obj = open(curr_path+"/new_vocab.txt","w+")
            for i in range(0,len(final_features)):
                obj.write(final_features[i])
                if not i == len(final_features) - 1:
                    obj.write(",")
            obj.close()
            
            self.vocab = final_features

        # else, take the initially built vocabulary for the feature set.
        else:            
            try:
                vocab = open(curr_path+"/vocab_vj.txt")
                self.vocab = vocab.read().split(",")
            except Exception as e:
                print e
                return

        # Count vectorizer to convert the sentence data to feature matrix
        self.cv = CountVectorizer(vocabulary = self.vocab)    





if __name__ == "__main__":
    SEC("C:/Users/u472290/Desktop/reference materials/internship documents/FinalReview/FinalReview/ANN/df_random.csv",curr_path="C:/Users/u472290/Desktop/reference materials/internship documents/FinalReview/FinalReview/ANN/")
    