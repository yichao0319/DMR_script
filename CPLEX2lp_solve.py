#! /usr/bin/env python
from xml.sax import make_parser, SAXException
from xml.sax.handler import ContentHandler


def usage():
    print 'Usage:', sys.argv[0], '<Inputfile> <Outputfile>'

class CPLEXResultHandler(ContentHandler):
    object = None;
    xs = {};
    def startElement(self, name, attrs):
        if name == 'variable':
            xname = attrs.get('name')
            xvalue = attrs.get('value')
            self.xs[xname] = xvalue;
            # print xname+'\t'+xvalue
            
        elif name == 'header':
            self.object = attrs.get('objectiveValue')
            print object
        
        
        
if __name__ == '__main__':
    import sys
    if len(sys.argv) < 3:
        usage()
        sys.exit(0)

    cplexRFname = sys.argv[1];
    lpsolveRFname = sys.argv[2];
    handler = CPLEXResultHandler()
    parser = make_parser()
    parser.setContentHandler(handler)
    parser.parse(open(cplexRFname))

    lpsolveRF = open(lpsolveRFname, 'w')
    print >> lpsolveRF, 'Value of objective function: '+ handler.object +'\n'
    print >> lpsolveRF, 'Actual values of the variables:'
    for index in handler.xs.keys():
        print >> lpsolveRF, index +'\t'+handler.xs[index]
    lpsolveRF.close()
    
