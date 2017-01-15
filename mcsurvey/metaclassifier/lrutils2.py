# -*- coding: utf-8 -*-
"""
Created on Mon Oct  6 07:59:35 2014

@author: vh
"""

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