#! /usr/bin/env python
import sys, os

QUALNETRate = 0;

def usage():
    print 'Usage:', sys.argv[0], '<res_file> <flow_rate_file> <qulanet_static_route_file> <rate> <payload> <epsilon>'

class Variable:
    """
    Variable information
    """
    def __init__(self):
        self.x = -1;
        self.flow = -1;
        self.flow_S = -1;
        self.flow_D = -1;
        self.link = -1;
        self.link_from = -1;
        self.link_to = -1;
        self.channel = -1;
        self.capacity = 0.0;
        self.load = 0.0;
        self.flow_t = 0.0;

class FlowInfo:
    """
    flow information
    """
    def __init__(self):
        self.S = -1;
        self.D = -1;
        self.flow_t = 0.0;
        self.Path = {};
        self.vs = [];
        self.multipath = 0;
        self.nPath = 0;

    def GetPath(self):
        if self.multipath == 0:
            P = [];
            self.nPath = 1;
            link_from = self.S;
            P.append(link_from);
            while link_from != self.D:
                for v in self.vs:
                    if v.link_from == link_from:
                        break
                if v.link_from != link_from:
                    print `self.S`+' '+`self.D`+" ERROR"
                    sys.exit(0)
                P.append(v.link_to)
                link_from = v.link_to
            self.Path[self.nPath] = P;

    def PrintPath_min_max(self, ff):
        if self.multipath == 0:
            p_len = len(self.Path[self.nPath]);
            if p_len == 0:
                print "EMPTY FLOW"
                sys.exit(0)
            hops = p_len - 1;
            ff.write(`self.S`+' '+`self.D`+' '+`self.flow_t`+' '+ `hops`);
            for p in self.Path[self.nPath]:
                ff.write(' '+`p`)
            ff.write('\n');
            
    def PrintPath(self, fid, ff, qf, max_rate):
        if self.multipath == 0:
            p_len = len(self.Path[self.nPath]);
            if p_len == 0:
                print "EMPTY FLOW"
                sys.exit(0)
            hops = p_len - 1;
            print self.Path[self.nPath]
            print self.flow_t
            interval = 1.0/(self.flow_t * QUALNETRate);
            #qualnet id starts from 1
            print >> ff, `self.S`+'\t'+`self.D`+'\t'+`self.flow_t`+'\t'+`interval`
            qf.write(`fid`+' 0.0.0.'+`self.S+1`+' 0.0.0.'+`self.D+1`+' '+`hops`);
            for p in self.Path[self.nPath]:
                qf.write(' 0.0.0.'+`p+1`+' 0 '+`max_rate`) # assume power 0 

            qf.write('\n');
        
if __name__ == '__main__':
    if len(sys.argv) < 7:
        usage()
        sys.exit(0)

    rawdatafilename = sys.argv[1];
    flowratefilename = sys.argv[2];
    qualnetroutefilename = sys.argv[3];
    
    max_rate = float(sys.argv[4]); # in Mbps
    payload = int(sys.argv[5]);    # in bytes
    epsilon = float(sys.argv[6]);  # threshold
    QUALNETRate = max_rate*1000000.0/payload/8; # in pkts/sec
    
    datafile = open(rawdatafilename, 'r');
    ff = open(flowratefilename, 'w');
    qf = open(qualnetroutefilename, 'w');
    min_maxf = open("min_max_flows1.txt", 'w');
    
    samples = datafile.readlines()

    vs = {};
    flows = {};
    for sample in samples:
        #print sample
        #try:
        if 1==1:
            v = Variable();
            words = sample.split()
            v.x = int(words[0]);
            v.flow = int(words[1]);
            v.flow_S = int(words[2]);
            v.flow_D = int(words[3]);
            v.link = int(words[4]);
            v.link_from = int(words[5]);
            v.link_to = int(words[6]);
            v.channel = int(words[7]);
            v.capacity = float(words[8]);
            v.load = float(words[9]);
            v.flow_t = float(words[10]);
            if v.load < epsilon:
                pass;  
            if vs.has_key(v.x):
                print 'ERROR!'
                sys.exit(0);
            else:
                vs[v.x] = v;
            if flows.has_key(v.flow):
                pass;
                # fInfo.flow_t = fInfo.flow_t + v.flow_t;
                # print 'fInfo.flow_t = '+`fInfo.flow_t` 
            else:
                fInfo = FlowInfo();
                fInfo.S = v.flow_S;
                fInfo.D = v.flow_D;
                fInfo.flow_t = v.flow_t;
                flows[v.flow] = fInfo;
            if v.load >= epsilon:
                #print v.load
                flows[v.flow].vs.append(v);
                print `v.link_from`+'\t'+`v.link_to`+'\t'+`v.load`
        #except:
        #    print sample
        #    pass

    print >> min_maxf, len(flows.values());

    fid = 0;
    for f in flows.values():
        print `f.flow_t`
        f.GetPath();
        f.PrintPath(fid,ff,qf,max_rate);
        f.PrintPath_min_max(min_maxf);
        fid = fid + 1;

    ff.close()
    qf.close()
