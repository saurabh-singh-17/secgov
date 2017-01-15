# -*- coding: utf-8 -*-
"""
Created on Thu Apr 24 12:08:11 2014

@author: vh
"""
MC_HOME = '/home/vh/mc5/MC/meta.classifier/'
MC_PYHOME = MC_HOME + 'inst/python/'
MC_TAGGER_HOME = MC_HOME + 'inst/java/'
MC_MODELS_HOME = MC_PYHOME + 'models/'
MC_DATA_HOME = MC_PYHOME + 'dev/data/'
MC_LOGS_HOME = MC_PYHOME + 'dev/logs/'
MC_RESOURCES_HOME = MC_PYHOME + 'resources/'

MC_USE_PY_NORMALIZATION = False

#MODELS
DEFAULT_MODEL_SENTIMENT_CORE = 'models/semeval_2706_cv_core_ng.msmdl'
DEFAULT_MODEL_SENTIMENT_CORE_DOMAIN = 'models/semeval_2706_cv_core_ng_dom.msmdl'
DEFAULT_MODEL_PD = 'models/PDModelOnlyNewCU.msmdl'

#RESOURCES

#DEFAULT_RES_DIR = 'resources/'
#DEFAULT_HR_FILE = MC_RESOURCES_HOME + 'defaulthr.res'
#DEFAULT_POLARNGRAMS_FILE = MC_RESOURCES_HOME + 'ngDicts/'
#DEFAULT_NEGATORS_FILE = MC_RESOURCES_HOME + 'negation_words.csv'
#DEFAULT_SMILEYS_FILE = MC_RESOURCES_HOME + 'smileys.csv'
#DEFAULT_DOMAINMEMDICTS_FILE = MC_RESOURCES_HOME + 'telcomDicts/'
#DEFAULT_DOMAIN_NOUNS_FILE = MC_RESOURCES_HOME + 'domainNouns.csv'
#
#DEFAULT_POLAR_NOUNS_FILE = MC_RESOURCES_HOME + 'newDicts_N.csv'
#DEFAULT_POLAR_VERBS_FILE = MC_RESOURCES_HOME + 'newDicts_V.csv'
#DEFAULT_POLAR_ADJS_FILE = MC_RESOURCES_HOME + 'newDicts_A.csv' #adjectives.csv'
#DEFAULT_POLAR_ADVS_FILE = MC_RESOURCES_HOME + 'newDicts_R.csv'
#DEFAULT_POLAR_ANYP_FILE = MC_RESOURCES_HOME + 'newDicts__.csv'
#DEFAULT_INTERJECTIONS_FILE = MC_RESOURCES_HOME + 'interjections.csv'

#DEFAULT_HR_FILE = MC_RESOURCES_HOME + 'defaulthr.res'
DEFAULT_POLARNGRAMS_FILE = 'ngDicts/'
DEFAULT_NEGATORS_FILE = 'resources/negation_words.csv'
DEFAULT_SMILEYS_FILE = 'resources/smileys.csv'
DEFAULT_DOMAINMEMDICTS_FILE = 'resources/telcomDicts/'
DEFAULT_DOMAIN_NOUNS_FILE = 'resources/domainNouns.csv'

DEFAULT_POLAR_NOUNS_FILE = 'resources/newDicts_N.csv'
DEFAULT_POLAR_VERBS_FILE = 'resources/newDicts_V.csv'
DEFAULT_POLAR_ADJS_FILE = 'resources/newDicts_A.csv' #adjectives.csv'
DEFAULT_POLAR_ADVS_FILE = 'resources/newDicts_R.csv'
DEFAULT_POLAR_ANYP_FILE = 'resources/newDicts__.csv'
DEFAULT_INTERJECTIONS_FILE = 'resources/interjections.csv'

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
PTKEY_CHUNKTYPE_VP = 'VP'
PTKEY_CHUNKTYPE_NP = 'NP'

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

POSKEY_verb_tag= ["VB","VBD","VBG","VBN","VBP","VBZ"]
POSKEY_noun_tag= ["NN","NNS","NNP","NNPS"]
POSKEY_NOUNPHRASE = "NP"
POSKEY_VERBPHRASE = "VP"


#POSSET_ADJ_ADV_VRB = set([POSKEY_ADJ, POSKEY_ADV, POSKEY_VRB])
