# -*- coding: utf-8 -*-
"""
Created on Fri Jul 11 04:28:43 2014

@author: vh
"""
from collections import defaultdict
from config import PTKEY_TOKENS, PTKEY_TAGS, PTKEY_TAGCONF
import re
import unicodedata
from bs4 import BeautifulSoup as bs

pattern_1=re.compile(r"@[a-z0-9]+|#[a-z0-9]+",re.I)
pattern_2=re.compile(r"^&[a-z0-9]+",re.I)

def replace_all(text, repl):
    for i in repl:
        text = re.sub(i[0],i[1],text, flags=re.I)
    return text
   
def clean_tags(text_json):
    len_text=text_json['tokens'].__len__()
    for i,k in enumerate(text_json['tokens']):
        if(i<len_text):
            if(pattern_2.match(text_json['tokens'][i]) and pattern_1.match(text_json['tokens'][i-1]) ):
	        text_json["tokens"][i-1]=''.join([text_json["tokens"][i-1],text_json["tokens"][i]])
		text_json["tokens"].pop(i)
		text_json["tags"].pop(i)
        
#def ptNormalize2(txts):
#    """
#    pre-processing
#    """
#    #    repl_basic = [(r"'''",""), (r"\r|\n|\t", ""), (r"&#(\d{1,4});" , ""), (r"&amp;", r"&")]
#    repl_basic = [(u"\\xc2", ' ')]
#    repl_smiley = [(r"☺|☻|✌|♡|♥|❤|😁|😂|😃|😄|😅|😆|😇|😊|😋|😌|😍|😎|😏|😘|😚|😜|😝",r":)"),(r"☹|😒|😞|😒|😠|😡|😢|😣|😩|😭",r" :( ")]
#    #repl_att = [(r"((?i)\b((att)|(a tt)|(at t))\b)",r"AT&T",)]
#    #repl_att = [(r"((?i)\b((att)|(a tt)|(at t))\b)",r"AT&T",)]
#    repl_att = [(r"(\b((att&t)|(att)|(a tt)|a[t]+[\s]+t+|a[t]*&[t]+|(at[7|n]t)|(a[\W|_]*t[\W|_]*[&]*t)|(at t(\s+)))\b)", "AT&T ")]
#    repl_tmob = [(r"\b^(\s)*t\s*([[:punct:]])*mobil[e]*|(\s)+t\s*mobil[e]*|\s+t[[:punct:]]mobil[e]*|\s+t(\s*)\\(\s*)mobil[e]*\b"," t-mobile")]
#    repl_vzw = [(r"\b(ver[i|z|s]*o[n]+)|(\bvz[w]*\b)\b", "verizon")]
#    repl_iphone = [(r"(?i)(\b(i(\s?)phone(\s?))\b)",r"iPhone "),("(\s+)"," ")]
#    repl_wifi = [(r"\b(wifi)\b", "wi-fi")]
#    repl_uverse = [(r"\b(u verse)\b|(u-verse)\b", "UVerse")]
#    repl_mbps = [(r"mb/s|megs\b", "mpbs")]
#    for k, txt in enumerate(txts):
#       #txts[k] = replace_all(txts[k],repl_basic)
#       #txts[k] = txts[k].strip() 
#       #print 'a%s' % txts[k] 
#       txts[k] = bs(txts[k], "lxml").get_text(strip=True)
#       #print 'b%s' % txts[k]
#       txts[k] = replace_all(txts[k],repl_basic)
#       #print 'c', txts[k]
#       txts[k] = replace_all(txts[k],repl_smiley)
#       txts[k] = replace_all(txts[k],repl_att)
#       txts[k] = replace_all(txts[k],repl_tmob)
#       txts[k] = replace_all(txts[k],repl_vzw) 
#       txts[k] = replace_all(txts[k], repl_wifi)
#       txts[k] = replace_all(txts[k], repl_uverse)
#       txts[k] = replace_all(txts[k],repl_iphone)
#       txts[k] = replace_all(txts[k], repl_mbps)
#       if isinstance(txts[k], unicode):
#           #print '2', txts[k]
#           #a = unicodedata.normalize('NFKD',txts[k])
#           #print a
#           txts[k] = unicodedata.normalize('NFKD',txts[k]).encode('ascii','ignore') 
#           #txts[k] = a.encode('ascii','ignore')
#       else:
#           txts[k] = unicodedata.normalize('NFKD',unicode(txts[k],'UTF-8')).encode('ascii','ignore')               
#          
#    return txts
#"doesn't", "ain't", "ai'nt", "aint", , "can't", "ca'nt", "cant", "couldn't", "could'nt", "couldnt", "cudn't", "cud'nt", "cudnt", "didn't", "did'nt", "didnt", "don't", "do'nt", "dont", "hadn't", "had'nt", "hadnt", "hasn't", "has'nt", "hasnt", "haven't", "have'nt", "havent", "isn't", "is'nt", "isnt", "'nt", "nor", "shan't", "sha'nt", "shouldn't", "should'nt", "shudn't", "shud'nt", "wasn't", "was'nt", "wasnt", "weren't", "were'nt", "won't", "wo'nt", "wont", "wouldn't", "would'nt", "wouldnt", "wud'nt", "wudnt"


repls = [
    (u"\\xc2", ' '),
    (r"☺|☻|✌|♡|♥|❤|😁|😂|😃|😄|😅|😆|😇|😊|😋|😌|😍|😎|😏|😘|😚|😜|😝",r":)"),
    (r"☹|😒|😞|😒|😠|😡|😢|😣|😩|😭",r" :( "),
    (r"(\b((att&t)|(att)|(a tt)|a[t]+[\s]+t+|a[t]*&[t]+|(at[7|n]t)|(a[\W|_]*t[\W|_]*[&]*t)|(at t(\s+)))\b)", "AT&T "),
    (r"\b^(\s)*t\s*([[:punct:]])*mobil[e]*|(\s)+t\s*mobil[e]*|\s+t[[:punct:]]mobil[e]*|\s+t(\s*)\\(\s*)mobil[e]*\b"," t-mobile"),
    (r"\b(ver[i|z|s]*o[n]+)|(\bvz[w]*\b)\b", "verizon"),
    (r"(\b((AT&T .com)|(AT&T.com)|(AT&T [\s]+.com))\b)", "AT&Tcom "),
    (r"(\b((AT&T .net)|(AT&T.net)|(AT&T [\s]+.net))\b)", "AT&Tnet "),
    (r"(?i)(\b(i(\s?)phone(\s?))\b)",r"iPhone "),
    ("(\s+)"," "),
    (r"\b(wifi)\b", "wi-fi"),
    (r"\b(u verse)\b|(u[^a-zA-Z.]verse)", "UVerse"),
    (r"mb/s|megs\b", "mbps"),
    (r"mbs speed\b", "mbps speed"),
    (r"mega b[i|y]tes\b|megs\b", 'mb'),
    (r"mega b[i|y]tes\b", 'mb'),
    (r"\baint|ai'nt\b", "ain't"),
    (r"\b[0-9]g[-|/]*[lte|tle]+", "4glte"),
    (r"\bdirecttv\b|\bdirect tv\b", "DIRECTV"),
    (r"television|t\.v\.", "tv"),
    (r"\bre-", "re")
]
 
_mods = ["are", "ca", "can", "could", "cud", "did", "do", "does", "had", "has", "have", "is", "sha", "shall", "should", "was", "were", "wo", "would", "wud"] 
_rmods = {k:k for k in _mods}
_rmods["ca"] = "can"
_rmods["cud"] = "could" 
_rmods["sha"] = "shall"
_rmods["wo"] = "would"
_rmods["wud"] = "would"
for mod in _mods:
    s = r"\b%s[']*n[']*t\b" % mod
    r = "%s not" % (_rmods[mod])
    repls.append((s, r))     


    
def ptNormalize(txts):
    """
    pre-processing
    """
    for k, txt in enumerate(txts):
        txts[k] = bs(txts[k], "lxml").get_text(strip=True)
        for repl in repls:
            txts[k] = re.sub(repl[0],repl[1],txts[k], flags=re.I)

        if isinstance(txts[k], unicode):
            txts[k] = unicodedata.normalize('NFKD',txts[k]).encode('ascii','ignore') 
        else:
            txts[k] = unicodedata.normalize('NFKD',unicode(txts[k],'UTF-8')).encode('ascii','ignore')               
          
    return txts
    
if __name__ == "__main__":
    print ptNormalize(['Özil'])
    print ptNormalize(['tmobile'])
    print ptNormalize(['t-mobile'])
    print ptNormalize(['i hate t-mobile'])
    print ptNormalize(['i att at tomsville'])
    print ptNormalize(['i at&t at tomsville'])
    print ptNormalize(['i ate at at tomsville'])
    print ptNormalize(['i ate at t at tomsville'])
    print ptNormalize(['i ate a tt at tomsville'])
    print ptNormalize(['i ate at t at tomsville'])
    print ptNormalize(['i ate at7t at tomsville'])
    print ptNormalize(['i ate a&tt at tomsville'])
    print ptNormalize(['i ate atnt at tomsville'])
    print ptNormalize(['i ate a_t_t at tomsville'])
    print ptNormalize(['i ate a_t_&_t at tomsville'])
    print ptNormalize(['i ate a.t.t at tomsville'])
    print ptNormalize(['ever verisoning son'])
    print ptNormalize(['ever verissonn son'])
    print ptNormalize(['ever vz son'])
    print ptNormalize(['ever vzw son'])
    print ptNormalize(['ever vzwvzw son'])
    print ptNormalize(['ever vzw son'])
    print ptNormalize(['ever verizion son'])
    print ptNormalize(['meg ryan megs 2megs mb/s 2mb/s'])
    print ptNormalize(["cpmplaint complai'nt aint ai'nt"])
    print ptNormalize(["carent arent are'nt arent aren't"])
    print ptNormalize(["wudnt wud'nt wudnt wudn't"])
    print ptNormalize(["cant can'nt can't"])
    print ptNormalize(["effective"])
    pass
#    txts = ["IM Windows Live&trade;", "&amp;"]
#    print ptNormalize(txts)
#    
#    buggyTxts = ['\xc2\xa0 \xc2\xa0\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', 'Service that is avalible in regions that arent avalible to t-mobile, Verizon, sprint\xc2\xa0\n', 'I like all the services that I get with Att and the way that handle the problems that occur. I would like it to be just a little better priced.\xc2\xa0\n', '\xc2\xa0\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n', '\xc2\xa0\n']
#    for bt in buggyTxts[3:4]:
#        print ptNormalize([bt])
        
#    dname = "/home/vh/surveyresults/volte_rel_20150130.csv"
#    oname = open("/home/vh/surveyresults/volte_norm_check.txt",'w')
#    logger = oname.write
#    with open(dname, 'r') as fname:
#        for n, line in enumerate(fname):
#            if n == 0:
#                continue
#            else:
#                if (n % 100) == 0:
#                    print n
#                datas = line.split('|')
#                txt = datas[2]
#                logger('%d\n' % n)
#                logger('%s\n' % [txt])
#                logger('%s\n--' % ptNormalize([txt])[0])
#    oname.close()                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    