# -*- coding: utf-8 -*-
"""
Created on Sun Oct 19 07:25:49 2014

@author: vh
"""
import feature_lib as featuresModule

MC_CLASSIFIER_NLTK_MAXENT = 'NLTK'
MC_CLASSIFIER_SKLEARN_LR = 'SKLR'

def computeFeatures(procTxt, hr, features, returnFeatureValues=False):
    """
    Extract the bases for the selected Features.
    Output is a dictionary of bases.
    {
     featurename1: {basisName_1:val_1, basisName_2:val_2, ... basisName_N:val_N1},
     featurename2: {basisName_1:val_1, basisName_2:val_2, ... basisName_N:val_N2},
     ...
     featurenameK: {basisName_1:val_1, basisName_2:val_2, ... basisName_N:val_NK}
    }

    To get the Feature Values computed by the various analyses use returnFeatureValues=True
    """
    computedFeatures  = dict()
    fv = dict()
    for feature in features:
        featurefn = getattr(featuresModule, feature)
        fv, fs = featurefn(procTxt, hr, fv)
        computedFeatures[feature] = fs

    if returnFeatureValues:
        return (computedFeatures, fv)
    return computedFeatures

def extractBases(procTxt, hr, featureNames, returnFeatureValues=False):
    """
    Extract the bases for the selected Features.
    Output is a dictionary of bases.
    {basisName_1:val_11, basisName_2:val_12, ... basisName_N:val_1N}
    Note: The featture association of a basis is lost. i.e., we cannot identify
    which feature the basis belong to. Suggested that use this only for training.
    To get the Feature Values computed by the various analyses use returnFeatureValues=True
    """
    extractedBases  = dict()
    fv = {}
    for feature in featureNames:
        featurefn = getattr(featuresModule, feature)
        fv, fs = featurefn(procTxt, hr, fv)
        extractedBases.update(fs)

    if returnFeatureValues:
        return (extractedBases, fv)
    return extractedBases

def makeSKFormat(bases, returnBasisNames=False):
    """
    List of dictionaries to list of lists.
    MxN matrix. M = number of data, N = number of bases.
    Input:
    [
         {basisName_1:val_11, basisName_2:val_12, ... basisName_N:val_1N},  --> m = 1
         {basisName_1:val_21, basisName_2:val_22, ... basisName_N:val_2N},  --> m = 2
         ...
         {basisName_1:val_M1, basisName_2:val_M2, ... basisName_N:val_MN},  --> m = M
    ]
    Output:
    [
        [val_11, val_12, ... val_1N], --> m = 1
        [val_21, val_22, ... val_2N], --> m = 2
        ...
        [val_M1, val_M2, ... val_MN], --> m = M
    ]

    Assumptions:
    All M data points have the same basisNames as the basisNames of the first data point
    All vals can be converted as integers.
    """
    if not returnBasisNames:
        returnBasisNames = False

    #ntrn = len(bases)
    basisNames = sorted(bases[0].keys())
    nbases = len(basisNames)

    basisNames = {n:k for k, n in enumerate(basisNames)}
    basesList = []
    for base in bases:
       tbase = [0]*nbases
       for key, val in base.iteritems():
           tbase[basisNames[key]] = int(val)
       basesList.append(tbase)

    if returnBasisNames:
        return basesList, basisNames

    return basesList