# -*- coding: utf-8 -*-
"""
Created on Tue Feb  4 11:43:02 2014

@author: vh
"""
import sys
from collections import defaultdict

def countInstances(instances):
    """
    """
    count = defaultdict(int)
    for inst in instances:
        count[inst] += 1
    return count

class ClassifierMetrics(object):
    def __init__(self, classlabels):
        if type(classlabels) != list and type(classlabels) != set:
          msg1 = "Creating Classifier Metrics: Cannot handle class label type:"
          msg2 = str(type(classlabels))
          raise Exception(msg1 + msg2)

        self._idx2cl = list(classlabels)
        self._cl2idx = dict()
        self._nc = len(self._idx2cl)
        for n, lbl in enumerate(self._idx2cl):
            self._cl2idx[lbl] = n

    def __computeCM(self, ya, yp):
        if len(ya) != len(yp):
            raise Exception("Compute Confusion Matrix: ya, yp must be same length")

        cm = [[0 for m in xrange(self._nc)] for n in xrange(self._nc)]
        for n in xrange(len(ya)):
            cm[self._cl2idx[ya[n]]][self._cl2idx[yp[n]]] += 1

        self.__cm = cm

    def __computeByClassCM(self):
        cm = self.__cm
        nc = self._nc
        clbls = self._idx2cl

        self._tp = list()
        self._fn = list()
        self._fp = list()
        self._tn = list()
        for k in xrange(nc):
            self._tp.append(0.); self._fn.append(0.);
            self._fp.append(0.); self._tn.append(0.);
            for m in xrange(nc):
                for n in xrange(nc):
                    if m == k and n == k:
                        self._tp[k] = float(cm[m][n])
                    if m == k and n != k:
                        self._fn[k] += cm[m][n]
                    if m !=k and n == k:
                        self._fp[k] += cm[m][n]
                    if m!= k and n != k:
                        self._tn[k] += cm[m][n]



    def __bcAccuracy(self, tp, fn, fp, tn):
        s = float(tp + tn + fn + fp)
        if s == 0: return 0
        return float(tp + tn)/s

    def __bcPrecision(self, tp, fn, fp, tn):
        s = float(tp+fp)
        if s == 0: return 0
        return float(tp)/s

    def __bcRecall(self, tp, fn, fp, tn):
        s = float(tp+fn)
        if s == 0: return 0
        return float(tp)/s

    def __bcSpecificity(self, tp, fn, fp, tn):
        s = float(fp+tn)
        if s == 0: return 0
        return float(tn)/s

    def __bcFscore(self, tp, fn, fp, tn):
        P = self.__bcPrecision(tp, fn, fp, tn)
        R = self.__bcRecall(tp, fn, fp, tn)
        s = P + R
        if s == 0: return 0
        return 2*(P*R)/(P+R)

    def __bcAUC(self, tp, fn, fp, tn):
        R = self.__bcRecall(tp, fn, fp, tn)
        S = self.__bcSpecificity(tp, fn, fp, tn)
        s = R + S
        if s == 0: return 0
        return 0.5*s

    def __Accuracy(self):
        acc = [self.__bcAccuracy(self._tp[k], self._fn[k], self._fp[k], self._tn[k]) for k in xrange(self._nc)]
        return sum(acc)/len(acc)

    def __ErrorRate(self):
        er = []
        for k in xrange(self._nc):
            a = [self._fp[k], self._fn[k], self._tp[k], self._tn[k]]
            er.append((a[0] + a[1])/sum(a))
        return sum(er)/len(er)

    def computeMetrics(self, ya, yp):
        self.__computeCM(ya, yp)
        self.__computeByClassCM()
        metrics = {'ConfusionMatrix': self.__cm, 'Accuracy': self.__Accuracy(), 'ErrorRate':self.__ErrorRate()}
        aa = sum([ sum(a) for a in self.__cm]) #sum([sum(self._tp), sum(self._fn), sum(self._fp), sum(self._tn)])
        tpr = sum(self._tp)/float(aa)
        metrics['TPR'] = tpr
        for k in xrange(self._nc):
            clname = self._idx2cl[k]
            metrics[clname] = dict()
            metrics[clname]['Accuracy']    = self.__bcAccuracy(self._tp[k], self._fn[k], self._fp[k], self._tn[k])
            metrics[clname]['Fscore']      = self.__bcFscore(self._tp[k], self._fn[k], self._fp[k], self._tn[k])
            metrics[clname]['Precision']   = self.__bcPrecision(self._tp[k], self._fn[k], self._fp[k], self._tn[k])
            metrics[clname]['Recall']      = self.__bcRecall(self._tp[k], self._fn[k], self._fp[k], self._tn[k])
            metrics[clname]['Specificity'] = self.__bcSpecificity(self._tp[k], self._fn[k], self._fp[k], self._tn[k])
            metrics[clname]['AUC']         = self.__bcAUC(self._tp[k], self._fn[k], self._fp[k], self._tn[k])

        self.__metrics = metrics
        return metrics

    def __print_data_stats(self, logger = None):
        if not logger:
            logger = sys.stdout.write

        #logger("\nConfusion Matrix\n-Overall\n")
        logger("\nConfusion Matrix\n")
        logger("%s" % "ACT\PRD ")
        lsum = [sum(a) for a in self.__cm]
        tsum = sum(lsum)
        for m in xrange(self._nc):
            logger("\t%s\t%d\t%f\n" % (self._idx2cl[m], lsum[m], lsum[m]/float(tsum)))
        logger("\n")

    def __printCM(self, logger = None):
        if not logger:
            logger = sys.stdout.write
        #logger("\nConfusion Matrix\n-Overall\n")
        logger("\nConfusion Matrix\n")
        logger("%s" % "ACT\PRD ")
        lsum = [sum(a) for a in self.__cm]
        tsum = sum(lsum)

        #Header
        for m in xrange(self._nc):
            logger("\t%s" % self._idx2cl[m])
        logger('\tCOUNT\tFRAC\n')

        for m in xrange(self._nc):
            logger("%s" % self._idx2cl[m])
            for n in xrange(self._nc):
                logger("\t%d" % self.__cm[m][n])
            logger('\t%d\t%3.2f' % (lsum[m], lsum[m]/float(tsum)))
            logger("\n")

        #logger("\n-By Class\n")
        #print 'True  +ves: ', self._tp
        #print 'False -ves: ', self._fn
        #print 'Flase +ves: ', self._fp
        #print 'True  -ves: ', self._tn


    def printMetrics(self, logger=None, simplified = False):
        if not logger:
            logger = sys.stdout.write
        try:
            metrics = self.__metrics
        except:
            raise Exception ("Call cm.computeMetrics(y_true, y_pred) before print")

        aa = sum([ sum(a) for a in self.__cm]) #sum([sum(self._tp), sum(self._fn), sum(self._fp), sum(self._tn)])
        tpr = sum(self._tp)/float(aa)

        if simplified == True:
            logger("%3s, %3s, %3s, %3s, %3s\n" %  ( 'Cls', 'ACC', 'FSC', 'PRE', 'REC'))
            logger("%3s, %3s, %3s, %3s\n" %  ( 'Cls', 'FSC', 'PRE', 'REC'))
            acc = 0; fsc = 0; pre = 0; rec = 0;
            dv = 0
            for k in xrange(self._nc):
                clname = self._idx2cl[k]
                if not all([ a == 0 for a in self.__cm[k]]):
                    logger("%3s, "   % clname[0:3].upper())
                    #logger("%4.2f, " % metrics[clname]['Accuracy'])
                    logger("%4.2f, " % metrics[clname]['Fscore'])
                    logger("%4.2f, " % metrics[clname]['Precision'])
                    logger("%4.2f, \n" % metrics[clname]['Recall'])
                    acc += metrics[clname]['Accuracy']
                    fsc += metrics[clname]['Fscore']
                    pre += metrics[clname]['Precision']
                    rec += metrics[clname]['Recall']
                    dv += 1
            logger('%3s %4.2f %4.2f %4.2f %4.2f \n' % ('AVG', acc/dv, fsc/dv, pre/dv, rec/dv))
            logger("True Positive Rate %4.2f\n" % metrics['TPR'])
            return


        logger("TPR\t%6.4f\n" % metrics['TPR'])
        #logger("ACC %4.2f\n" % metrics['Accuracy'])
        #logger("Error Rate %4.2f\n" % metrics['ErrorRate'])
        #logger("%s\t%s\t%6s\t%6s\t%6s\n" %  ( 'Class', 'ACC', 'FSC', 'PRE', 'REC'))
        logger("%s\t%6s\t%6s\t%6s\n" %  ( 'Class', 'FSC', 'PRE', 'REC'))
        acc = 0; fsc = 0; pre = 0; rec = 0;
        dv = 0
        for k in xrange(self._nc):
            clname = self._idx2cl[k]
            logger('%s' % clname)
            #logger("\t%6.4f" % metrics[clname]['Accuracy'])
            logger("\t%6.4f" % metrics[clname]['Fscore'])
            logger("\t%6.4f" % metrics[clname]['Precision'])
            logger("\t%6.4f\n" % metrics[clname]['Recall'])
            #logger("%6.2f " % metrics[clname]['Specificity'])
            #logger("%6.2f \n" % metrics[clname]['AUC'])
            acc += metrics[clname]['Accuracy']
            fsc += metrics[clname]['Fscore']
            pre += metrics[clname]['Precision']
            rec += metrics[clname]['Recall']
            dv += 1
        #logger("AVG\t%6.4f\t%6.4f\t%6.4f\t%6.4f\n" % (acc/dv, fsc/dv, pre/dv, rec/dv))
        logger("AVG\t%6.4f\t%6.4f\t%6.4f\n" % (fsc/dv, pre/dv, rec/dv))
        self.__printCM()

if __name__ == "__main__":
    clabels = [0,1]
    cm = ClassifierMetrics(clabels)
    yt = [1,1,1,1,1,1,1,1, 0,0,0,0, 0,0,0,0]
    yp = [1,1,1,1,1,1,1,1, 0,0,0,0, 0,0,0,0]
    cm.computeMetrics(yt, yp)
    cm.printMetrics()
#def debugCM():
#    from sklearn.metrics import confusion_matrix
#    classLabels = [2,0,1]
#    y_pred = [0, 0, 2, 2, 0, 2]
#    y_true = [2, 0, 2, 2, 0, 1]
#    computeCM(y_true, y_pred, classLabels)
#    print confusion_matrix(y_true,y_pred, classLabels)
#
#debugCM()
