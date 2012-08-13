#ifndef CONFLICT_GRAPH_H
#define CONFLICT_GRAPH_H

#define MAXLINE 1024

#define MIN(x,y) ((x) < (y) ? (x) : (y))
#define MAX(x,y) ((x) > (y) ? (x) : (y))


/* network node -- protocol model */
class node {
public:
	static int numNodes;
	static double defaultTXrange;
	static double defaultIFrange;
	static int defaultNumChannels;
	static bool defaultMultipleRadios;
	static double defaultCapacity;
protected:
	int nodeID;
	double x, y;
	double TXrange; /* transmit range */
	double IFrange; /* interference range */
	double capacity; /* capacity of any link emanating from this node */
public:
	node() {};
	node(int _nodeID, double _x, double _y, double _TXrange, double _IFrange);
	node(char *buf);
	int getNodeID() {return nodeID;}
	double getCapacity() {return capacity;}
	double distance(class node *ptr);
	bool withinTXrange(class node *ptr); 
	bool withinIFrange(class node *ptr);
	void display() {printf("%3d ", nodeID);}
	void display(FILE *fout) {fprintf(fout, "%3d ", nodeID);}
	static void processPreamble(char *buf);
};

/* network node -- physical model */
class phyNode : public node {
	static double defaultTXpower;
	static double defaultDecay;
	static double defaultNoise;
	static double defaultSIRthresh;
	double TXpower; /* transmit power */
	double decay; /* decay exponent */
	double noise; /* ambient noise */
	double SIRthresh; /* signal-to-interference threshold for successful communication */
public:
	phyNode(int _nodeID, double _x, double _y, double _TXpower, double _decay, double _noise, double _SIRthresh);
	phyNode(char *buf);
	double SS(class phyNode *ptr);
	double maxIFallowed(double SSatRX);
	double normalizedIF(double SSatRX, double IF);
	static void processPreamble(char *buf);
};

/* network link = node in the conflict graph */
template <class nodeType>
class link {
protected:
	int linkID;
	nodeType *nodePtr1, *nodePtr2;
	int channel;
	bool multipleRadios;
	double capacity;
public:
	link(int _linkID, nodeType *_nodePtr1, nodeType *_nodePtr2, int _channel); 
	nodeType *getNodePtr1() {return nodePtr1;}
	nodeType *getNodePtr2() {return nodePtr2;}
	int getChannel() {return channel;}
	void display();
	void display(FILE *fout);
	bool nodeInCommon(link<nodeType> *ptr);
	virtual int checkConflict(link<nodeType> *ptr);
	static bool withinRange(class node *_nodePtr1, class node *_nodePtr2);
};

/* 
 * a link where successful communication in one direction depends on the successful communication
 * in the opposite direction too (e.g., because of the need for link-layer ACKs)
 */
template <class nodeType>
class bidirecLink : public link<nodeType> {
public:
	bidirecLink(int _linkID, nodeType *_nodePtr1, nodeType *_nodePtr2, int _channel); 
	virtual int checkConflict(link<nodeType> *ptr);
	static bool withinRange(class node *_nodePtr1, class node *_nodePtr2);
//	virtual bool checkConflictTX(link<nodeType> *ptr);
//	virtual bool checkConflictRX(link<nodeType> *ptr);
};



/* network link -- physical model */
class phyLink : public link<phyNode> {
protected:
	double SSatRX; /* transmitter's signal strength at the receiver */
public:
	phyLink(int _linkID, phyNode *_nodePtr1, phyNode *nodePtr2, int _channel);
	double checkConflict(phyLink *ptr);
	static bool withinRange(class phyNode *_nodePtr1, class phyNode *_nodePtr2);
};

/* bidirectional network link -- physical model */
class bidirecPhyLink : public phyLink {
	double SSatTX; /* receiver's signal strength at the transmitter */
public:
	bidirecPhyLink(int _linkID, phyNode *_nodePtr1, phyNode *nodePtr2, int _channel);
	double checkConflictAtRX(bidirecPhyLink *ptr);
	double checkConflictAtTX(bidirecPhyLink *ptr);
	static bool withinRange(class phyNode *_nodePtr1, class phyNode *_nodePtr2);
};


/* edge in the conflict graph */
template <class linkType>
class edge {
	linkType *linkPtr1, *linkPtr2;
        int type;
public:
        edge(linkType *_linkPtr1, linkType *_linkPtr2) {linkPtr1 = _linkPtr1; linkPtr2 = _linkPtr2; type = 1; }
	edge(linkType *_linkPtr1, linkType *_linkPtr2, int _type) {linkPtr1 = _linkPtr1; linkPtr2 = _linkPtr2; type = _type;}
	virtual void display();
	virtual void display(FILE *fout) {fprintf(fout, "%d ", type);}
	static void noDisplay(FILE *fout) {fprintf(fout, "0 ");}
	static int checkConflict(linkType *_linkPtr1, linkType *_linkPtr2);
};

/* edge in the conflict graph in the physical model */
class phyEdge : public edge<phyLink> {
protected:
	double weightAtRX;
        int type;
public:
	phyEdge(phyLink *_linkPtr1, phyLink *_linkPtr2);
        phyEdge(phyLink *_linkPtr1, phyLink *_linkPtr2, int _type);
	virtual void display();
	virtual void display(FILE *fout) {fprintf(fout, "%.3f ", weightAtRX);}
	static void noDisplay(FILE *fout) {fprintf(fout, "%.3f ", 0);}
	static int checkConflict(phyLink *_linkPtr1, phyLink *_linkPtr2);
};


class bidirecPhyEdge : public phyEdge {
	double weightAtTX;
        int type;
public:
	bidirecPhyEdge(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2);
        bidirecPhyEdge(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2, int _type);
	virtual void display();
	virtual void display(FILE *fout) {fprintf(fout, "%.3f %.3f ", weightAtRX, weightAtTX);}
	static void noDisplay(FILE *fout) {fprintf(fout, "%.3f %.3f ", 0, 0);}	
	static int checkConflict(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2);
};


/* a linked list node */
template <class nodeType>
class linkedListNode {
	nodeType *ptr;
	linkedListNode<nodeType> *next;
public:
	linkedListNode() {ptr = NULL; next = NULL;}
	linkedListNode(nodeType *_ptr) {ptr = _ptr; next = NULL;}
	void setNext(linkedListNode<nodeType> *ptr) {next = ptr;}
	linkedListNode<nodeType> *getNext() {return next;}
	nodeType *getPtr() {return ptr;}
	void display() {ptr->display();}
	void display(FILE *fout) {ptr->display(fout);}
};

/* a linked list  */
template <class nodeType>
class linkedList {
	linkedListNode<nodeType> *head;
	linkedListNode<nodeType> *tail;
	linkedListNode<nodeType> *cur;
public:
	linkedList() {head  = NULL; tail = NULL;}
	void insert(nodeType *ptr);
	linkedListNode<nodeType> *getHead() {return head;}
	linkedListNode<nodeType> *getTail() {return tail;}
	linkedListNode<nodeType> *getCur() {return cur;}
	linkedListNode<nodeType> *resetCur() {cur = head; return cur;}
	linkedListNode<nodeType> *getNext() {if (cur) cur = cur->getNext(); return cur;}
};

/* a network of nodes, links, and edges */
template <class nodeType, class linkType, class edgeType>
class network {
	int numNodes;
	int numChannels;
	int numLinks;
	nodeType **nodeArray;
	//class node **nodeArray;
	linkedList<linkType> linkList;
	linkedList<edgeType> edgeList;
public:
	void readTopology(char *topologyFile, FILE *fin);
	void computeGraph(FILE *fout);
	void computeConflictGraph(FILE *fout);
	void copyOverFlowInfo(FILE *fin, FILE *fout);
	void process(char *topologyFile, FILE *fin, FILE *out);
};



#endif /* CONFLICT_GRAPH_H */
