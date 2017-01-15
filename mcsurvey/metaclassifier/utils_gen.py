# -*- coding: utf-8 -*-
"""
Created on Thu Mar 20 17:08:01 2014

@author: vh
"""
def readlines(fname):
    lines = open(fname,'r').readlines()
    lines = [line.strip() for line in lines]
    return lines

def writelines(lines, fname):   
    with open(fname, 'w') as out_file: 
        for k, line in enumerate(lines):
            out_file.write("%s\n" % line)
