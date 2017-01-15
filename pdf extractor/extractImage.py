# -*- coding: utf-8 -*-
"""
Created on Thu Nov 24 13:48:04 2016

@author: u472290
"""

from cStringIO import StringIO
from pdfminer.pdfinterp import PDFResourceManager, PDFPageInterpreter
from pdfminer.converter import TextConverter
from pdfminer.layout import LAParams
from pdfminer.pdfpage import PDFPage

def convert(fname, pages=None):
    if not pages:
        pagenums = set()
    else:
        pagenums = set(pages)

    output = StringIO()
    manager = PDFResourceManager()
    converter = TextConverter(manager, output, laparams=LAParams())
    interpreter = PDFPageInterpreter(manager, converter)

    infile = file(fname, 'rb')
    for page in PDFPage.get_pages(infile, pagenums):
        interpreter.process_page(page)
    infile.close()
    converter.close()
    text = output.getvalue()
    output.close
    return text 


def convert_pdf_to_txt(path):
    rsrcmgr = PDFResourceManager()
    retstr = StringIO()
    codec = 'utf-8'
    laparams = LAParams()
    device = TextConverter(rsrcmgr, retstr, codec=codec, laparams=laparams)
    fp = file(path, 'rb')
    interpreter = PDFPageInterpreter(rsrcmgr, device)
    password = ""
    maxpages = 0
    caching = True
    pagenos=set()

    for page in PDFPage.get_pages(fp, pagenos, maxpages=maxpages, password=password,caching=caching, check_extractable=True):
        interpreter.process_page(page)

    text = retstr.getvalue()

    fp.close()
    device.close()
    retstr.close()
    return text    
    


from PyPDF2 import PdfFileWriter, PdfFileReader 

def splitPDF(pathPDF):
    
    infile = PdfFileReader(open(pathPDF, 'rb'))

    for i in xrange(infile.getNumPages()):
        p = infile.getPage(i)
        outfile = PdfFileWriter()
        outfile.addPage(p)
        with open('page-%02d.pdf' % i, 'wb') as f:
            outfile.write(f)
   


from wand.image import Image
from PIL import Image as PI
import pyocr
import pyocr.builders
import io     
        
tool = pyocr.get_available_tools()[0]
lang = tool.get_available_languages()[1]

req_image = []
final_text = []

image_pdf = Image(filename="0761_0011.pdf", resolution=300)
image_jpeg = image_pdf.convert('jpeg')

for img in image_jpeg.sequence:
    img_page = Image(image=img)
    req_image.append(img_page.make_blob('jpeg'))
    
    
for img in req_image: 
    txt = tool.image_to_string(
        PI.open(io.BytesIO(img)),
        lang=lang,
        builder=pyocr.builders.TextBuilder()
    )
    final_text.append(txt)    
    
if __name__ == "__main__":
    pathPDF = 'D:/work/pdf extractor/0761_0011.pdf'
    convert_pdf_to_txt(pathPDF)
    

    splitPDF(pathPDF)    