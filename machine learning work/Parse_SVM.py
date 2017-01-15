# -*- coding: utf-8 -*-
"""
Created on Tue Jun 21 13:37:56 2016

@author: U505118
"""

from sklearn import svm
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import CountVectorizer
import pylab as pl
from sklearn.metrics import roc_curve, roc_auc_score
import re

def SVM_Parse(path):
    #-----------------Declaring necessary variables------------#
    
    vocab = [] 
    df = pd.read_csv(path)
    df_train = df[:1874]
    df_test = df[1874:].reset_index(drop = True)
    df_model = df_test
    df_yes = df[df['Indicator'] == 'Yes']
    df_no = df[df['Indicator'] == 'No']
    yes_words = df_yes['Phrase'].tolist()
    no_words = df_no['Phrase'].tolist()          
    words = df_train['Phrase'].tolist()
    words_test = df_test['Phrase'].tolist()
    indArray = np.asarray(df_train['Indicator'].tolist())
    '''vocab = ['revenue', 'revenue months', 'revenues', 'revenues months', 'sales', 'sales months',
              'net income', 'net revenue', 'net revenues', 'net sales', 'no', 'no customer', 'no customer accounted', 'cost revenue', 'fiscal', 'following', 'following table',
              'follows', 'gross', 'table', 'accounted', 'accounted approximately', 'accounted total',
              'customers', 'customers accounted', 'represented', 'percent', 'foreign', 'country', 'product service',
              'escrow', 'contracts', 'contract', 'properties', 'equity', 'cost']'''
              
    stopwords = ['a', 'about', 'above','across','after','afterwards','again','against','all','almost','alone','along',
    'already','also','although','always','am','among','amongst','amoungst','amount','an','and','another','any','anyhow','anyone','anything','anyway','anywhere','are','around','as','at'
    'back','be','became','because','become','becomes','becoming','been','before','beforehand','behind','being','below','beside',
    'besides','between','beyond','bill','both','bottom','but','by','call','can','cannot','cant','co','con','could','couldnt',
    'cry','de','describe','detail','do','done','down','due','during','each','eg','eight','either','eleven','else','elsewhere',
    'empty','enough','etc','even','ever','every','everyone','everything','everywhere','except','few','fifteen','fify','fill',
    'find','fire','first','five','for','former','formerly','forty','found','four','from','front','full','further','get',
    'give','go','had','has','hasnt','have','he','hence','her','here','hereafter','hereby','herein','hereupon','hers','herself',
    'him','himself','his','how','however','hundred','i','ie','if','in','inc','indeed','interest','into','is','it','its','itself',
    'keep','last','latter','latterly','least','less','ltd','made','many','may','me','meanwhile','might','mill','mine','more',
    'moreover','most','mostly','move','much','must','my','myself','name','namely','neither','never','nevertheless','next',
    'nine','nobody','none','noone','nor','not','non','nothing','now','nowhere','of','off','often','on','once','one','only',
    'onto','or','other','others','otherwise','our','ours','ourselves','out','over','own','part','per','perhaps','please','put','rather',
    're''same','see','seem','seemed','seeming','seems','serious','several','she','should','show','side','since','sincere','six',
    'sixty','so','some','somehow','someone','something','sometime','sometimes','somewhere','still','such','system','take','ten',
    'than','that','the','their','them','themselves','then','thence','there','thereafter','thereby','therefore','therein','thereupon',
    'these','they','thick','thin','third','this','those','though','three','through','throughout','thru','thus','to','together',
    'too','top','toward','towards','twelve','twenty','two','un','under','until','up','upon','us','very','via','was','we',
    'well','were','what','whatever','when','whence','whenever','where','whereafter','whereas','whereby','wherein','whereupon',
    'wherever','whether','which','while','whither','who','whoever','whole','whom','whose','why','will','with','within','without',
    'would','yet','you','your','yours','yourself','yourselves','000','year','states','tax','taxes','100','january','jan','february',
    'feb','march','april','may','june','jun','july','jul','august','september','sept','october','oct','november','nov','december','dec',
    'equity','ended','accounts','cash','consolidated','period','periods','liabilities','customer','accounting''11''12','13',
    '14','15','16','17','18','19','20','2013','2014','2015','23','24','25','26','27','28','30','31']
              
    
    
    #--------------------Cleaning the data---------------------#
    
    for i in range(len(words)):
        words[i] = re.sub('\d+', '', words[i])
        
    for i in range(len(words_test)):
        words_test[i] = re.sub('\d+', '', words_test[i])
        
    for i in range(len(yes_words)):
        yes_words[i] = re.sub('\d+', '', yes_words[i])
        
    for i in range(len(no_words)):
        no_words[i] = re.sub('\d+', '', no_words[i])
    
    
    #-------------------Training the model--------------------#        
            
    model = svm.SVC(kernel = 'linear', C = 100, gamma = 2, probability = True)
    
    '''Creating the feature set from the training data'''
    
    vect_yes = CountVectorizer(stop_words = stopwords, ngram_range = (1, 2), max_features = 25)
    vect_no =  CountVectorizer(stop_words = stopwords, ngram_range = (1, 2), max_features = 100)
    vect_yes.fit_transform(yes_words)
    vect_no.fit_transform(no_words)
    
    vocab = vocab + vect_yes.get_feature_names()
    vocab = vocab + vect_no.get_feature_names()
    vocab = list(set(vocab))
    
    del df_yes, df_no, yes_words, no_words
    
    '''Vectorizing the training data'''
        
    vect = CountVectorizer(stop_words = stopwords, ngram_range = (1, 2), vocabulary = vocab, max_features = 100)
    idfArray = vect.fit_transform(words).toarray()
    
    '''Traning the model'''
    model.fit(idfArray, indArray)
    
    '''Vectorizing the test data'''
    
    vect_test = CountVectorizer(stop_words = stopwords, ngram_range = (1, 2), vocabulary = vocab)
    testArray = vect_test.fit_transform(words_test).toarray()
    
    '''Testing the model'''
    
    testInd = model.predict(testArray)
    
    
    #--------------Updating the test data------------------------------#
    
    
    df_model['SVM Indicator'] = testInd.tolist()
    df_model = df_model.reset_index(drop = True)
    df_model.to_csv('C:/Users/U505118/Desktop/P/SVMTestData.csv', index = False)
    
    '''Calculating proabilities of desired event fro AUCROC'''
    
    prob = model.predict_proba(testArray).tolist()
    prob_temp = []
    for x in prob:
        prob_temp.append(x[1])
        
    prob = np.asarray(prob_temp)
    del prob_temp
    
    
    #----------------Confusion Matrix---------------------------------#
    
    '''Declaring necessary variables'''
    
    TP = 0.0    #True Positive
    TN = 0.0    #True Negative
    FP = 0.0    #False Positive
    FN = 0.0    #False Negative
    sensitivity = 0.0    #Also known as Recall
    specificity = 0.0    #Also known as Recall
    precision = 0.0    #Also known as Postive Predictive Value
    NPV = 0.0    #Negative Predictive Value
    accuracy = 0.0
    
    for i in range(len(df_model)):
        if df_model.loc[i, 'Indicator'] == 'Yes':
            if df_model.loc[i, 'SVM Indicator'] == 'Yes':
                TP = TP + 1
            elif df_model.loc[i, 'SVM Indicator'] == 'No':
                FN = FN + 1
        elif df_model.loc[i, 'Indicator'] == 'No':
            if df_model.loc[i, 'SVM Indicator'] == 'Yes':
                FP = FP + 1
            elif df_model.loc[i, 'SVM Indicator'] == 'No':
                TN = TN + 1            
                   
    '''Calculating metrics'''
            
    sensitivity = (TP/(TP + FN))*100.0
    specificity = (TN/(TN + FP))*100.0
    precision = (TP/(TP + FP))*100.0
    NPV = (TN/(TN + FN))*100.0
    accuracy = (TP + TN)/(TP + TN + FP + FN)
    
    '''Printing the Confusion Matrix'''
    
    print '\n\n\n\t\t\t---------Confusion Matrix---------\n'
    print '\t\t\t\t     Predicted\n'
    print '\t\t\t\tYes\t\tNo'
    print '\t\t\t---------------------------------'
    print '\t\t\t|\t\t|\t\t|' 
    print '\t\tYes\t|\t' + str(TP) + '\t|\t' + str(FN) + '\t|\tPrecision : %f' %precision
    print '\t\t\t|\t\t|\t\t|'
    print '      Actual\t\t---------------------------------'
    print '\t\t\t|\t\t|\t\t|'       
    print '\t\tNo\t|\t'+ str(FP)+ '\t|\t' + str(TN) + '\t|\tNPV : %f' %NPV
    print '\t\t\t|\t\t|\t\t|'
    print '\t\t\t---------------------------------\n\n'
    print ('\t\tSensitivity : %f\t\tSpecificity : %f\n\n' %(sensitivity, specificity))
    print'\t\t\t\tAccuracy : %f' %accuracy
    
    
    
    #-----------------ROC Curve-------------------------#
    
    '''Calculating actual number of positive cases'''
    
    actual = []
    for x in df_test['Indicator']:
        if x == 'Yes':
            actual.append(1)
        elif x == 'No':
            actual.append(0)
            
    actualvalArray = np.asarray(actual)
    del actual
    
    '''Calculating FPR, TPR and AUCROC'''
    
    FPR, TPR, thresholds = roc_curve(actualvalArray, prob)
    roc_auc = roc_auc_score(actualvalArray, prob)
    
    print("Area under the ROC curve : %f" % roc_auc)
    
    '''Plotting the AUCROC'''
    
    pl.clf()
    pl.plot(FPR, TPR, label='ROC curve')
    pl.plot([0, 1], [0, 1], 'k--')
    pl.xlim([0.0, 1.0])
    pl.ylim([0.0, 1.0])
    pl.xlabel('False Positive Rate')
    pl.ylabel('True Positive Rate')
    pl.title('Receiver operating characteristic')
    pl.legend(loc='lower right')
    pl.show()
    
    #---------------Gain and Lift Chart------------------#
    
    '''Declaring necessary variables'''    
    
    gain_model = [0]
    gain_random = [0]
    random_cumul = 0.0
    model_cumul = 0.0
    df_test = df_test.sample(n = len(df_test))
    df_model['Probability'] = prob
    df_model.sort(columns = 'Probability', inplace = True, ascending = False)
    df_model = df_model.reset_index(drop = True)
    df_GL = pd.DataFrame([],columns  = ['Decile', 'Random', 'Model'])
    
    '''Dividing the data set into deciles and calculating gain'''    
    
    for i in range(10):
        df_GL.loc[i, 'Decile'] = str(i + 1)
        random = 0.0
        model = 0.0
        for k in range(i*78, (i*78) + 78):
            if df_model.loc[k, 'Indicator'] == 'Yes':
                model = model + 1
            if df_test.loc[k, 'Indicator'] == 'Yes':
                random = random + 1
        random_cumul = random_cumul + random
        model_cumul = model_cumul + model
        df_GL.loc[i, 'Random'] = str(random_cumul)
        df_GL.loc[i, 'Model'] = str(model_cumul)
        gain_model.append(((model_cumul)/(TP + FN))*100.00)
        gain_random.append(((random_cumul)/(TP + FN))*100.00)

    '''Plotting the cumulative gain chart'''
    
    percent_pop = range(0,110, 10)
    
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
    
    #-------------Sensitivity vs Specificity Curve---------#
    
    '''Calculating specificity from FPR calculated in AUROC'''    
    
    TNR = FPR
    for i in range(len(FPR)):    
       TNR[i] = 1 - FPR[i]
    
    '''Plotting sensitivity vs specificity curve'''    
    
    pl.clf()
    pl.plot(thresholds, TPR, label='Sensitivity')
    pl.plot(thresholds, TNR, label='Specificity')
    pl.xlim([0.0, 1.0])
    pl.xlabel('Probability')
    pl.title('Sensitivity vs Specificity')
    pl.legend(loc='lower right')
    pl.show()   
    

SVM_Parse('C:/Users/U505118/Desktop/P/Final_SVM.csv')