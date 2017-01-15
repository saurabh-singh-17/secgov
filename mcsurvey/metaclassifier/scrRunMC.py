# -*- coding: utf-8 -*-
"""
Created on Mon Feb  9 09:54:36 2015

@author: vh
"""

from os import sys, path
home = path.dirname(path.dirname(path.abspath(__file__)))
sys.path.append(home)
dhome = path.join(home, 'data')
print dhome

