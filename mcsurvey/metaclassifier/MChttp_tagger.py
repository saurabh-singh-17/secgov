# -*- coding: utf-8 -*-
import httplib,base64
import json
#import pipes, urllib

class Tagger(object):
    def __init__(self):
        """
        """
	
    def getTags(self, txt):
        """ """
        conn=httplib.HTTPConnection("localhost", 8000)
#        txt1 = pipes.quote(txt)
#        txt2 = '%r' % txt1
        txt2 = base64.urlsafe_b64encode(txt)
        conn.request("POST", "/file", txt2) #base64.b64encode(txt2))
        response = conn.getresponse()
        #print response
        data=response.read()
        conn.close()
        return json.loads(data)
        
if __name__ == "__main__":
    import utils_gen as ug
    txts = ug.readlines('/home/vh/bmtests/data/merged.stxts')
    t = Tagger()
    for n, txt in enumerate(txts): #txts[1745:1746]):
        print n
        try:
            results = t.getTags(txt)
        except Exception, e:
            print n, e
            print txt
            print '-------'
                
    
    
