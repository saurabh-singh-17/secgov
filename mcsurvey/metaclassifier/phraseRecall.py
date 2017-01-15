# -*- coding: utf-8 -*-
"""
Created on Sat Jun  7 17:59:23 2014

@author: vh
"""
# -*- coding: utf-8 -*-
"""
Created on Sat Jun  7 17:59:23 2014

@author: vh
"""

def phraseRecall(tru,prd):
    '''
    Recall = prd contains all toks in tru
    Precision = prd contains only the toks in tru
    '''
    rec = sum([tok in prd for tok in tru])/float(len(tru))
    pre = 1.0 - sum([tok not in tru for tok in prd])/float(len(prd))    
#    print 'Labeled  : %s' % tru
#    print 'Predicted: %s' % prd
#    print 'PRE: %6.4f' % pre
#    print 'REC: %6.4f' % rec
    return (pre, rec)
    
#def phrasePrecision(tru, prd):
#    ''' prd contains only the toks in tru'''
#    pre = 1.0 - sum([tok not in prd for tok in prd])/len(prd)    
#    print 'Labeled: %s' % tru
#    print 'Predict: %s' % prd
#    print 'Precision: %6.4f' % pre
#    return pre

if __name__ == "__main__":
    import csv
    import numpy as np
    import matplotlib.pyplot as plt

    fname = 'logs/problem_context_500.csv'
    sep = '|'
    rows = []
    with open(fname, 'rb') as csvfile: 
        reader = csv.reader(csvfile, delimiter=sep, quotechar = '"')
        pre = []
        rec = []
        for row in reader:
            tw = row[0]
            tru = row[1].split() 
            prd = row[2].split()
            if not tru: tru = ['__EMPTY__']
            if not prd: prd = ['__EMPTY__']    
            p, r = phraseRecall(tru, prd)
            pre.append(p)
            rec.append(r)
            rows.append([tw, tru, prd])
    plt.close('all')
#    fig, ax = plt.subplots()        
#    bins  = np.linspace(0,1,11)
#    npre, bins, patches = plt.hist(pre, bins, histtype='bar', rwidth=0.8)
#    plt.xlabel('Precision')
#    plt.grid()
#    fig, ax = plt.subplots()
#    bins  = np.linspace(0,1,11)
#    nrec, bins, patches = plt.hist(rec, bins, histtype='bar', rwidth=0.8)
#    plt.xlabel('Recall')
#    plt.grid()

    fs = [(p+r)/2 for p,r in zip(pre, rec)]

    fig, ax = plt.subplots()
    bins  = np.linspace(0,1,11)
    nrec, bins, patches = plt.hist(rec, bins, histtype='bar', rwidth=0.8)
    plt.xlabel('PR Averages')
    plt.grid()
    
    print 'Precision Avg: %6.4f' % np.mean(pre)
    print 'Recall Avg: %6.4f' % np.mean(rec)
    print 'Favg', np.mean(fs) 
    
    
#    N = 1
#    menMeans = (np.mean(pre))
#    womenMeans =   (np.mean(rec))
#
#    ind = np.arange(N)  # the x locations for the groups
#    width = 0.25       # the width of the bars
#
#    fig, ax = plt.subplots()
#    rects1 = ax.bar(0.15, menMeans, width, color='b')
#    rects2 = ax.bar(0.15 + width+0.1, womenMeans, width, color='g')
#    ax.set_xticks([.25, 0.65])
#    ax.set_xticklabels( ('Precision', 'Recall'), fontsize=16 )
#    #ax.legend( (rects1[0], rects2[0]), ('Precision', 'Recall') )
#    plt.xlim([0,0.95])
#    plt.ylim([0,1])
#    plt.grid()

    #errors
    f = open('logs/PPDErrors.txt','w')
    myprint = f.write 
    
    n = 0
    for k, (p, r, row) in enumerate(zip(pre,rec, rows)):
        if p == 0 and r  == 0:
            n += 1
            print('TweetNo %d' % (k))
            print('%s' % row[0])
            print row[1], row[2]
    
    print n
    
    tru = 'service text messages call'.split()
    prd = 'service text messages'.split()
    p, r = phraseRecall(tru, prd)
    print p,r