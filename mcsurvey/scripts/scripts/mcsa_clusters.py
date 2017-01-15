# -*- coding: utf-8 -*-
"""
Created on Mon Jun  8 17:36:04 2015

@author: vh
"""
import csv, sys
import numpy as np
import networkx as nx
from mcsa_w2v import mcW2V
from sklearn import cluster
import matplotlib.pyplot as plt
from collections import defaultdict

csv.field_size_limit(sys.maxsize)

class mcClusters(object):
    '''
    '''
    def __init__(self, w2vobj):
        '''
        '''
        self.w2v = w2vobj
        
    def makeClusters(self, toks, cnts, rootName = 'ROOT',saveSimMat=None):
        '''
        '''
        S = self.w2v.getSimMat(toks)
        
        if(saveSimMat):
            file_iter=open(saveSimMat,"wb")
            logger=file_iter.write
            logger("word|%s\n"%("|".join(toks)))
            for ind,tok in enumerate(toks): 
                list_toks=[str(round(k,3)) for k in S[ind]]
                str_join="|".join((tok,"|".join((list_toks))))
                logger("%s\n"%str_join)
            file_iter.close()
        
        ctable = []
        n = len(toks)
        x = range(n)
        ntoks = np.array(toks)
        ncnts = np.array(cnts, dtype='float')
        ncnts = ncnts/ncnts.sum()    
        k = 0
        while (True):
            Sk = S[np.ix_(x,x)]
            ntoks = ntoks[x]
            ncnts = ncnts[x]    
            xk, labels = cluster.affinity_propagation(Sk) 
            n_labels = labels.max()
            for i in xrange(n_labels + 1):
                cidx = labels == i
                ctoks = ntoks[cidx]
                ccnts = ncnts[cidx]
                pidx = ccnts.argsort()[::-1][0]
                cname = ntoks[xk[i]] #cluster center
                clname = ctoks[pidx] #most frequent node in cluster
                #temp = {'LEVEL':k, 'CLUSTER': (i+1), 'CENTER': cname, 'NAME': ' '.join(clname[:-2].split('_NG_')), 'MEMBERS': ctoks}
                temp = {'LEVEL':k, 'CLUSTER': (i+1), 'CENTER': cname, 'NAME': ' '.join(cname[:-2].split('_NG_')), 'MEMBERS': ctoks}
                ctable.append(temp)
            k+=1
            #break
            x = xk
            if len(xk) <= 3:
                break
            
        self.ctable = ctable
        self.G = self.ctable2G_()
                
        return ctable
       
    def load(self, cfname, sep = '\t'):
        '''
        '''
        ctable = []
        with open(cfname) as f:
            reader = csv.DictReader(f, delimiter=sep)
            for row in reader:
                row['MEMBERS'] = row['MEMBERS'].split('|')
                ctable.append(row)
                
        self.ctable = ctable
        self.G = self.ctable2G_()
        return ctable
            
    def save(self, logger, sep = '\t'):
        '''
        '''
        logger('%s\n' % sep.join(['LEVEL','CLUSTER','CENTER','NAME','MEMBERS']))    
        for row in self.ctable:
            r = [row['LEVEL'], row['CLUSTER'], row['CENTER'], row['NAME'], '|'.join(list(row['MEMBERS']))]
            logger('%s\n' % sep.join(map(str, r)))
            
    def ctable2G_(self):
        '''
        '''
        G = nx.DiGraph()
        for row in self.ctable:
            lid = int(row['LEVEL'])
            cid = int(row['CLUSTER'])
            rtoks = ['%d_%s' % (lid, tok) for tok in row['MEMBERS']]
            pkey = '%d_%s' % (lid+1, row['CENTER'])
            for rtok in rtoks:
                G.add_edge(pkey, rtok)
                G.node[pkey]['CLUSTER'] = cid
                G.node[pkey]['LEVEL'] = lid+1
                G.node[pkey]['NAME'] = row['NAME']
                G.node[pkey]['CENTER'] = row['CENTER']
        return G
        
    def getTopNodes(self):
        '''
        '''
        #top nodes        
        G = self.G
        preds = G.pred
        topnodes = []
        for node in preds:
            if not preds[node]:
                topnodes.append(node)
        
        return topnodes
        
        #add Root
        
    def parentClusters(self, node):
        '''
        '''
        parents = []
        rtok = node
        G = self.G
        while(True):
            pars = G.predecessors(rtok)
            if not pars:
                break
            else:
                rtok = pars[0]
                parents.append(rtok)
        return parents
        
    def getLeafNodes(self, returnToks = True):
        '''
        '''
        G = self.G
        if returnToks:
            return ['_'.join(node.split('_')[1:]) for node in G.succ if not G.succ[node]]
        return [{'NODE':node, 'TOKEN':'_'.join(node.split('_')[1:])}  for node in G.succ if not G.succ[node]]
        
    def getHierarchy(self):
        '''
        '''
        G = self.G
        leafNodes = self.getLeafNodes(returnToks=False)
        ancestory = {}
        for leaf in leafNodes:
            pars = self.parentClusters(leaf['NODE'])
            anc = [{'LEVEL': int(par.split('_')[0]), 'CENTER': G.node[par]['CENTER'], 'NAME': G.node[par]['NAME']} for par in pars]
            ancestory[leaf['TOKEN']] = anc
        return ancestory
        
    def getClusterMembers(self):
        '''
        '''
        G = self.G
        topnodes = [node for node in G.pred if not G.pred[node]]
        clusterMembers = defaultdict(list)
        for tnode in topnodes:
            dfs = nx.dfs_successors(G, tnode)
            for node in dfs:
                for mem in dfs[node]:
                    if int(mem.split('_')[0]) == 0:
                        clusterMembers[tnode].append(mem)
        return clusterMembers
    
    def getRootNode(self):
        '''
        '''
        #root node in graph
        G = self.G
        for node in G.nodes():
            pars = G.predecessors(node)
            if not pars:
                rootNode = node
                return rootNode
                break
            
    def plot(self, pnode = None, pname = 'ROOT', dfs=12, deg=25):
        '''
        Cluster Graph Plotter
        G graph
        dfs font size
        deg default label orientation
        return figure handle
        '''
        G = self.G
        if not pnode:
            topnodes = self.getTopNodes()
            
#            for tnode in topnodes:
            for node in topnodes:        
                k = int(node.split('_')[0])
                pnode = '%d_%s' % (k+1, pname)
                G.add_edge(pnode, node)
        
                G.node[pnode]['LEVEL'] = k+1
                G.node[pnode]['NAME'] = pname
                G.node[pnode]['CENTER'] = pname
    
        fig, ax = plt.subplots()
        
        #depth first traversal of G and layout for plotting.
        b = nx.dfs_tree(G,pnode)
        pos=nx.graphviz_layout(b,prog='twopi',args='')
        
        nx.draw_networkx_edges(b,pos, width=1,alpha=0.5, arrows=False)
        nx.draw_networkx_nodes(b,pos, node_size = 20, alpha=0.5)
    
        #code to orient labels --> avoid overlapping labels.    
        center = np.mean(pos.values(), 0)
        bbox_props = dict(boxstyle="square,pad=0", fc='w', ec="w", lw=0.5)
       
        for key in pos:
            tx, ty = pos[key]
            level = int(key.split('_')[0])
            pars = G.predecessors(key)
            rot = 0
                        
            ha = 'center'; va = 'center'
            bb = bbox_props
            if level == 0:
                bb = dict()
                px, py = pos[pars[0]]
                relx = px - center[0]
                rely = py - center[1]
                
                ha = 'right'
                if relx > 0:
                    ha = 'left'
                
                if relx > 0:
                    if rely > 0:
                        rot = deg; va = 'bottom'
                    else:
                        rot = -deg; va = 'top'
                else:
                    if rely > 0:
                        rot = -deg; va = 'bottom'
                    else:
                        rot = deg; va = 'top'
            
            if 'NAME' in G.node[key]:
                labels = G.node[key]['NAME']
            else:
                key="".join((key.split("**")[0],"".join(key.split("**")[2:])))
                labels = ' '.join('_'.join(key.split('_')[1:])[:-2].split('_NG_'))
            
            fs = round(dfs*1.2, 1)
            if level < 1:
                fs = dfs
            elif level == 1:
                rot = 0
                
            plt.text(tx, ty, labels, rotation = rot, fontsize=fs, ha=ha, va = va, bbox=bb)
        
        ax.set_xticks([]); ax.set_yticks([])
        fig.tight_layout()
        G.remove_node(pnode)#node[pnode]['CENTER'] = pname
        plt.savefig("/home/user/Desktop/images.png",dpi=200)
        return fig
        
if __name__ == "__main__":
    import os
    dataset_name = 'volte'        
    docid_cols = ['SRV_ACCS_ID']
    txt_cols = ['SRV_Q1B_WTR_WHY', 'SRV_Q1D_SAT_VALUE_ATT_WHY', 'SRV_Q1G_WHY_CHURN_6MOS', 'SRV_Q1G_WHY_STAY_6MOS', 'SRV_Q3B_SAT_DATA_WHY']
    col = 'SRV_Q2B_SAT_VOICE_WHY' #'SRV_Q1B_WTR_WHY' #['SRV_Q1D_SAT_VALUE_ATT_WHY']

#    dataset_name = 'UVERSE' 
#    docid_cols = ['DOCID'] #['PERIOD', 'WTR1_VIDEO', 'WTR2_1_INTERNET', 'WTR3_1_VOICE', 'WTR4_1_ATT', 'ACCT']
#    col = 'W4_NOT_WTR_ATT_WHY' #'U1A_SAT_TV_WHY' #'W4_NOT_WTR_ATT_WHY' #, 'U1A_SAT_TV_WHY', 'U2A_SAT_INTERNET_WHY']
#    
    tmp_home = "/home/vh/surveyAnalysis/tmp"          
    dhome = os.path.join(tmp_home, dataset_name)
        
    bname = os.path.join(dhome, col, col)
    modname = bname + '.w2vm'
    cfname = bname + '.ctable_temp.csv'

    plt.close('all')    
    w2vm = mcW2V(modname)
    mcc = mcClusters(w2vm)
    mcc.load(cfname)
    mcc.plot()
        

