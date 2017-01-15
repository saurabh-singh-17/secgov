# -*- coding: utf-8 -*-
"""
Created on Sat Oct 11 06:34:19 2014

@author: vh
"""
KEY_POLARITY_POSITIVE = 'positive'
KEY_POLARITY_NEGATIVE = 'negative'
KEY_POLARITY_NEUTRAL = 'neutral'
KEY_NEGATION = 'negation'

PTKEY_TOKENS = "tokens"
PTKEY_TAGS = "tags"
PTKEY_TAGCONF = "tag conf"
PTKEY_SENTENCES = "sentences"
PTKEY_CHUNKEDSENTENCES = "chunkedSentences"
PTKEY_PRECHUNK = "preChunkedS"
PTKEY_CLAUSES = "clausedSentences"
PTKEY_CHUNKEDCLAUSES = 'chunksInClauses'
PTKEY_CHUNKTYPE_NONE = 'NONE'

#POS TAGS....
POSKEY_NOUN = 'N'
POSKEY_PRONOUN = 'O'
POSKEY_PRPNOUN = '^'
POSKEY_INTJ = '!'

POSKEY_ADJ = 'A'
POSKEY_ADV = 'R'
POSKEY_VRB = 'V'
POSKEY_DET = 'D'
POSKEY_PREP = 'P'
POSKEY_CC = '&'
POSKEY_PUNC = ','
POSKEY_EMOT = 'E'
POSKEY_URL = 'U'
POSKEY_DM = '~'
POSKEY_HASH = '#'


POSKEY_verb_tag= ["VB","VBD","VBG","VBN","VBP","VBZ"]
POSKEY_noun_tag= ["NN","NNS","NNP","NNPS"]
POSKEY_NOUNPHRASE = "NP"
POSKEY_VERBPHRASE = "VP"
