/* -*-  Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */
// ConflictGraph.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "ConflictGraph.h"

int node::numNodes;
double node::defaultTXrange;
double node::defaultIFrange;
int node::defaultNumChannels;
bool node::defaultMultipleRadios;
double node::defaultCapacity;
double phyNode::defaultTXpower;
double phyNode::defaultDecay;
double phyNode::defaultNoise;
double phyNode::defaultSIRthresh;

char seps[] = " \n";

/* member functions of class node */

node::node(int _nodeID, double _x, double _y, double _TXrange, double _IFrange) 
: nodeID(_nodeID), x(_x), y(_y), TXrange(_TXrange), IFrange(_IFrange)
{}

node::node(char *buf) {
	char *str;

	if ((str = strtok(buf, seps)))
		nodeID = atoi(str);
	else {
		/* XXX does this ever happen. Doesn't see so even for a blank line */
		nodeID = -1;
		return;
	}
	if ((str = strtok(NULL, seps)))
		x = (double) atof(str);
	else
		x = -1;
	if ((str = strtok(NULL, seps)))
		y = (double) atof(str);
	else
		y = -1;
	if ((str = strtok(NULL, seps)))
		capacity = (double) atof(str);
	else
		capacity = defaultCapacity;
	if ((str = strtok(NULL, seps)))
		TXrange = (double) atof(str);
	else 
		TXrange = defaultTXrange;
	if ((str = strtok(NULL, seps)))
		IFrange = (double) atof(str);
	else
		IFrange = defaultIFrange;
}

double node::distance(class node *ptr) {

	return(sqrt(pow(x-ptr->x, 2) + pow(y-ptr->y, 2)));
}

bool node::withinTXrange(class node *ptr) {

	if (distance(ptr) <= TXrange)
		return true;
	else
		return false;
}


bool node::withinIFrange(class node *ptr) {

	if (distance(ptr) <= IFrange)
		return true;
	else
		return false;
}

void node::processPreamble(char *buf) {
	char *str;

	node::numNodes = atoi(strtok(buf, seps));
	if ((str = strtok(NULL, seps)))
		defaultNumChannels = atoi(str);
	else
		defaultNumChannels = 1;
	if ((str = strtok(NULL, seps))) {
		if (atoi(str) == 1)
			defaultMultipleRadios = true;
		else
			defaultMultipleRadios = false;
	} else
		defaultMultipleRadios = false;
	if ((str = strtok(NULL, seps)))
		defaultCapacity = (double) atof(str);
	else
		defaultCapacity = 1;
	if ((str = strtok(NULL, seps)))
		defaultTXrange = (double) atof(str);
	else 
		defaultTXrange = 0;
	if ((str = strtok(NULL, seps)))
		defaultIFrange = (double) atof(str);
	else 
		defaultIFrange = 0;
}

/* member functions of class phyNode */

phyNode::phyNode(int _nodeID, double _x, double _y, double _TXpower, double _decay, double _noise, double _SIRthresh)
: node(_nodeID, _x, _y, 0, 0), TXpower(_TXpower), decay(_decay), noise(_noise), SIRthresh(_SIRthresh)
{}

phyNode::phyNode(char *buf) 
: node()
{
	char *str;

	if ((str = strtok(buf, seps)))
		nodeID = atoi(str);
	else 
		nodeID = -1;
	if ((str = strtok(NULL, seps)))
		x = (double) atof(str);
	else
		x = -1;
	if ((str = strtok(NULL, seps)))
		y = (double) atof(str);
	else
		y = -1;
	if ((str = strtok(NULL, seps)))
		capacity = (double) atof(str);
	else
		capacity = defaultCapacity;
	if ((str = strtok(NULL, seps)))
		TXpower = (double) atof(str);
	else
		TXpower = defaultTXpower;
	if ((str = strtok(NULL, seps)))
		decay = (double) atof(str);
	else
		decay = defaultDecay;
	if ((str = strtok(NULL, seps)))
		noise = (double) atof(str);
	else
		noise = defaultNoise;
	if ((str = strtok(NULL, seps)))
		SIRthresh = (double) atof(str);
	else
		SIRthresh = defaultSIRthresh;
}


double phyNode::SS(class phyNode *ptr) {

	/* signal strength = TX power / (distance ^ decay exponent) */
	return (TXpower/(pow(distance(ptr),decay)));
}

double phyNode::maxIFallowed(double SSatRX) {
	return (SSatRX/SIRthresh - noise);
}

double phyNode::normalizedIF(double SSatRX, double IF) {

	if (maxIFallowed(SSatRX) > 0)
		return (MIN(IF/maxIFallowed(SSatRX),1));
	else
		return 1;
}

void phyNode::processPreamble(char *buf) {
	char *str;

	numNodes = atoi(strtok(buf, seps));
	if ((str = strtok(NULL, seps)))
		defaultNumChannels = atoi(str);
	else
		defaultNumChannels = 1;
	if ((str = strtok(NULL, seps))) {
		if (atoi(str) == 1)
			defaultMultipleRadios = true;
		else
			defaultMultipleRadios = false;
	} else
		defaultMultipleRadios = false;
	if ((str = strtok(NULL, seps)))
		defaultCapacity = (double) atof(str);
	else
		defaultCapacity = 1;
	if ((str = strtok(NULL, seps)))
		defaultTXpower = (double) atof(str);
	else
		defaultTXpower = 0;
	if ((str = strtok(NULL, seps)))
		defaultDecay = (double) atof(str);
	else
		defaultDecay = 0;
	if ((str = strtok(NULL, seps)))
		defaultNoise = (double) atof(str);
	else
		defaultNoise = -1;
	if ((str = strtok(NULL, seps)))
		defaultSIRthresh = (double) atof(str);
	else
		defaultSIRthresh = -1;
}

/* member functions of class link */

template <class nodeType>
link<nodeType>::link(int _linkID, nodeType *_nodePtr1, nodeType *_nodePtr2, int _channel) 
: linkID(_linkID), nodePtr1(_nodePtr1), nodePtr2(_nodePtr2), channel(_channel)
{
	multipleRadios = node::defaultMultipleRadios;
	capacity = nodePtr1->getCapacity();
}

template <class nodeType>
void link<nodeType>::display() {
	printf("%4d: ", linkID);
	nodePtr1->display(); 
	printf("--->"); 
	nodePtr2->display();
	printf("%d ", channel);
	printf("%.2f ", capacity);
}

template <class nodeType>
void link<nodeType>::display(FILE *fout) {
	fprintf(fout, "%4d ", linkID);
	nodePtr1->display(fout);
	nodePtr2->display(fout);
	fprintf(fout, "%d ", channel);
	fprintf(fout, "%.2f ", capacity);
}

template <class nodeType>
bool link<nodeType>::nodeInCommon(link<nodeType> *ptr) {
	if (nodePtr1 == ptr->getNodePtr1() || nodePtr1 == ptr->getNodePtr2() ||
		nodePtr2 == ptr->getNodePtr1() || nodePtr2 == ptr->getNodePtr2()) 
		return true;
	else
		return false;
}

template <class nodeType>
int link<nodeType>::checkConflict(link<nodeType> *ptr) {
	/* 
	 * if both links are on the same channel and either receiver is within the interefence range of 
	 * the other link's transmitter OR each node only has a single radio and the links have a node
	 * in common, there is a conflict 
	 */
	if (((channel == ptr->getChannel()) && 
		(nodePtr1->withinIFrange(ptr->getNodePtr2()) || ptr->getNodePtr1()->withinIFrange(nodePtr2))) ||
		(!multipleRadios && nodeInCommon(ptr)))
		return 1;
	else
		return 0;
}

template <class nodeType>
bool link<nodeType>::withinRange(class node *_nodePtr1, class node *_nodePtr2) {
	return _nodePtr1->withinTXrange(_nodePtr2);
}

/* member functions of class bidirecLink */

template <class nodeType>
bidirecLink<nodeType>::bidirecLink(int _linkID, nodeType *_nodePtr1, nodeType *_nodePtr2, int _channel)
:link<nodeType>(_linkID, _nodePtr1, _nodePtr2, _channel)
{}

// Lili code start
template <class nodeType>
int bidirecLink<nodeType>::checkConflict(link<nodeType> *ptr) {
	/* 
	 * if both links are on the same channel and if the first link's receiver or transmitter is within 
	 * the interefence range of the other link's transmitter or receiver OR each node only has a 
	 * single radio and the links have a node in common, there is a conflict 
	 */
	int type = 0;
	if (channel == ptr->getChannel()) {
		if (!multipleRadios && nodePtr1 == ptr->getNodePtr1())
			// share the same sender
			type |= 1;
		else {
			double distIF, distTX, decay, SINRthresh;
			distTX = nodePtr2->distance(nodePtr1);
			distIF = nodePtr2->distance(ptr->getNodePtr1());
			decay  = 2.0; // free space decay factor
			SINRthresh = 2.5; // 2.5db (see our mobicomm paper)
			// 2nd link causes loss on 1st link (the SINR analysis
			// below ignores thermal noise (i.e. N) and is thus conservative
			if ((10*log10(distIF/distTX)*decay < SINRthresh) ||
			    (ptr->getNodePtr1()->withinIFrange(nodePtr2)))
				type |= 2;
			// 1st sender can carrier sense 2nd sender
			if (ptr->getNodePtr1()->withinTXrange(nodePtr1))
				type |= 4;
			// 2nd sender can carrier sense 1st sender
			if (nodePtr1->withinTXrange(ptr->getNodePtr1()))
				type |= 8;
		}
	}
	return type;
}
// Lili code end

template <class nodeType>
bool bidirecLink<nodeType>::withinRange(class node *_nodePtr1, class node *_nodePtr2) {
	return (_nodePtr1->withinTXrange(_nodePtr2) && _nodePtr2->withinTXrange(_nodePtr1));
}


/* member functions of class phyLink */

phyLink::phyLink(int _linkID, phyNode *_nodePtr1, phyNode *_nodePtr2, int _channel)
:link<phyNode>(_linkID, _nodePtr1, _nodePtr2, _channel)
{
	SSatRX = nodePtr1->SS(nodePtr2);
}

double phyLink::checkConflict(phyLink *ptr) {
	double IF;

	/* if only a single radio and there is a node in common, then conflict weight = 1 */
	if (!multipleRadios && nodeInCommon(ptr))
		return 1;
	/* otherwise of links are on same channel, compute normalized interference */
	else if (channel == ptr->getChannel()) {
		IF = nodePtr1->SS(ptr->getNodePtr2());
		return (ptr->getNodePtr2()->normalizedIF(ptr->SSatRX, IF));
	} else 
		return 0;
}

bool phyLink::withinRange(class phyNode *_nodePtr1, class phyNode *_nodePtr2) {
	if (_nodePtr2->maxIFallowed(_nodePtr1->SS(_nodePtr2)) >= 0)
		return true;
	else
		return false;
}

/* member functions of class bidirecPhyLink */

bidirecPhyLink::bidirecPhyLink(int _linkID, phyNode *_nodePtr1, phyNode *_nodePtr2, int _channel)
:phyLink(_linkID, _nodePtr1, _nodePtr2, _channel)
{
	SSatTX = nodePtr2->SS(nodePtr1);
}

double bidirecPhyLink::checkConflictAtRX(bidirecPhyLink *ptr) {
	double IFduetoTX, IFduetoRX, normalizedIFduetoTX, normalizedIFduetoRX;

	/* if only a single radio and there is a node in common, then conflict weight = 1 */
	if (!multipleRadios && nodeInCommon(ptr))
		return 1;
	/* otherwise of links are on same channel, compute normalized interference */
	else if (channel == ptr->getChannel()) {
		IFduetoTX = nodePtr1->SS(ptr->getNodePtr2());
		normalizedIFduetoTX = ptr->getNodePtr2()->normalizedIF(ptr->SSatRX, IFduetoTX);
		IFduetoRX = nodePtr2->SS(ptr->getNodePtr2());
		normalizedIFduetoRX = ptr->getNodePtr2()->normalizedIF(ptr->SSatRX, IFduetoRX);
		return MAX(normalizedIFduetoTX, normalizedIFduetoRX);
	} else 
		return 0;
}

double bidirecPhyLink::checkConflictAtTX(bidirecPhyLink *ptr) {
	double IFduetoTX, IFduetoRX, normalizedIFduetoTX, normalizedIFduetoRX;

	/* if only a single radio and there is a node in common, then conflict weight = 1 */
	if (!multipleRadios && nodeInCommon(ptr))
		return 1;
	/* otherwise of links are on same channel, compute normalized interference */
	else if (channel == ptr->getChannel()) {
		IFduetoTX = nodePtr1->SS(ptr->getNodePtr1());
		normalizedIFduetoTX = ptr->getNodePtr1()->normalizedIF(ptr->SSatTX, IFduetoTX);
		IFduetoRX = nodePtr2->SS(ptr->getNodePtr1());
		normalizedIFduetoRX = ptr->getNodePtr1()->normalizedIF(ptr->SSatTX, IFduetoRX);
		return MAX(normalizedIFduetoTX, normalizedIFduetoRX);
	} else
		return 0;
}

bool bidirecPhyLink::withinRange(class phyNode *_nodePtr1, class phyNode *_nodePtr2) {
	if (_nodePtr2->maxIFallowed(_nodePtr1->SS(_nodePtr2)) >= 0 &&
		_nodePtr1->maxIFallowed(_nodePtr2->SS(_nodePtr2)) >= 0)
		return true;
	else
		return false;
}



/* member functions of template class edge */

template <class linkType>
void edge<linkType>::display() {
	linkPtr1->display(); 
	printf("   "); 
	linkPtr2->display();
}

template <class linkType>
int edge<linkType>::checkConflict(linkType *_linkPtr1, linkType *_linkPtr2) {
	return _linkPtr1->checkConflict(_linkPtr2);
}

/* member functions of class phyEdge */

phyEdge::phyEdge(phyLink *_linkPtr1, phyLink *_linkPtr2) 
:edge<phyLink>(_linkPtr1, _linkPtr2)
{
	weightAtRX = _linkPtr1->checkConflict(_linkPtr2);
}

phyEdge::phyEdge(phyLink *_linkPtr1, phyLink *_linkPtr2, int _type)
  :edge<phyLink>(_linkPtr1, _linkPtr2, _type)
{
  weightAtRX = _linkPtr1->checkConflict(_linkPtr2);
}

void phyEdge::display() {
	edge<phyLink>::display();
	printf(" %.3f ", weightAtRX);
}

int phyEdge::checkConflict(phyLink *_linkPtr1, phyLink *_linkPtr2) {
	if (_linkPtr1->checkConflict(_linkPtr2) > 0)
		return 1;
	else 
		return 0;
}

/* member functions of class bidirecPhyEdge */

bidirecPhyEdge::bidirecPhyEdge(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2) 
:phyEdge(_linkPtr1, _linkPtr2)
{
	weightAtRX = _linkPtr1->checkConflictAtRX(_linkPtr2);
	weightAtTX = _linkPtr1->checkConflictAtTX(_linkPtr2);
}

bidirecPhyEdge::bidirecPhyEdge(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2, int _type)
  :phyEdge(_linkPtr1, _linkPtr2, _type)
{
  weightAtRX = _linkPtr1->checkConflictAtRX(_linkPtr2);
  weightAtTX = _linkPtr1->checkConflictAtTX(_linkPtr2);
}

void bidirecPhyEdge::display() {
	edge<phyLink>::display();
	printf(" %.3f %.3f ", weightAtRX, weightAtTX);
}

int bidirecPhyEdge::checkConflict(bidirecPhyLink *_linkPtr1, bidirecPhyLink *_linkPtr2) {
	if (_linkPtr1->checkConflictAtRX(_linkPtr2) > 0 || _linkPtr1->checkConflictAtTX(_linkPtr2) > 0)
		return 1;
	else 
		return 0;
}


/* member functions of template class linkedList */

template <class nodeType>
void linkedList<nodeType>::insert(nodeType *ptr) {
	linkedListNode<nodeType> *nodePtr;

	nodePtr = new linkedListNode<nodeType>(ptr);
	if (!tail) {
		head = tail = nodePtr;
	} else {
		tail->setNext(nodePtr);
		tail = nodePtr;
	}
}

/* member functions of template class network */

/* read in physical layout info and populate nodeArray */
template <class nodeType, class linkType, class edgeType>
void network<nodeType,linkType,edgeType>::readTopology(char *topologyFile, FILE *fin) {
	char buf[MAXLINE];
	int nodeIndex;

		/* process preamble, which contains default info for all nodes */
	if (!fgets(buf, MAXLINE, fin)) {
		printf("missing preamble in %s\n", topologyFile);
		return;
	} else {
		nodeType::processPreamble(buf);
		/* create node array of numNodes size */
		numNodes = node::numNodes;
		numChannels = node::defaultNumChannels;
		nodeArray = (nodeType **) malloc(numNodes*sizeof(nodeType *));
	}
	/* now process the entries corresponding to each node */
	nodeIndex = 0;
	while (fgets(buf, MAXLINE, fin)) {
		/* create a new node and add it to nodeArray */
		nodeArray[nodeIndex] = new nodeType(buf);
		if (nodeArray[nodeIndex]->getNodeID() < 0)
			delete nodeArray[nodeIndex];
		else
			nodeIndex++;
		/* don't read the flow info that lies beyond */
		if (nodeIndex >= numNodes)
			break;
	}
}

/* compute the physical connectivity graph */
template <class nodeType, class linkType, class edgeType>
void network<nodeType,linkType,edgeType>::computeGraph(FILE *fout) {
	int i, j, k;
	linkType *linkPtr;
	linkedListNode<linkType> *linkNodePtr;

	numLinks = 0;
	/* for every pair of nodes (i,j), check if j is within TX range of i */
	for (i=0; i<numNodes; i++) {
		for (j=0; j<numNodes; j++) {
			if (j==i)
				continue;
			for (k=0; k<numChannels; k++) {
				if (linkType::withinRange(nodeArray[i], nodeArray[j])) {
					linkPtr = new linkType(numLinks, nodeArray[i], nodeArray[j], k);
					linkList.insert(linkPtr);
					numLinks++;
				}
			}
		}
	}
	/* first print out the number of nodes and links */
	printf("numnodes: %d\nnumlinks: %d\n", numNodes, numLinks);
	fprintf(fout, "%d\n%d\n", numNodes, numLinks);
	/* print out the list of links */
	printf("list of links:\n");
	linkNodePtr = linkList.getHead();
	while (linkNodePtr) {
		linkNodePtr->display();
		printf("\n");
		linkNodePtr->display(fout);
		fprintf(fout, "\n");
		linkNodePtr = linkNodePtr->getNext();
	}
}

/* compute the conflict graph */
template <class nodeType, class linkType, class edgeType>
void network<nodeType,linkType,edgeType>::computeConflictGraph(FILE *fout) {
	linkedListNode<linkType> *linkNodePtr1, *linkNodePtr2;
	linkType *linkPtr1, *linkPtr2;
	edgeType *edgePtr;
	linkedListNode<edgeType> *edgeNodePtr;
        int type;

	/* if there is a conflict between the two links then insert an edge into the conflict graph */
	linkNodePtr1 = linkList.getHead();
	while (linkNodePtr1) {
		linkPtr1 = linkNodePtr1->getPtr();
		linkNodePtr2 = linkList.getHead();
		while (linkNodePtr2) {
			linkPtr2 = linkNodePtr2->getPtr();
			/* a link is not considered to be in conflict with itself */
                        type = edgeType::checkConflict(linkPtr1, linkPtr2);
                        printf("debug: type = %d\n", type); 
			if ((linkPtr1 != linkPtr2) && type) {
				edgePtr = new edgeType(linkPtr1, linkPtr2, type);
				edgeList.insert(edgePtr);
				edgePtr->display(fout);
			} else {
				edgeType::noDisplay(fout);
			}
			linkNodePtr2 = linkNodePtr2->getNext();
		}
		fprintf(fout, "\n");
		linkNodePtr1 = linkNodePtr1->getNext();
	}

	/* display the edges in the conflict graph */
	printf("list of edges in the conflict graph:\n");
	edgeNodePtr = edgeList.getHead();
	while (edgeNodePtr) {
		edgeNodePtr->display();
		printf("\n");
		edgeNodePtr = edgeNodePtr->getNext();
	}
}

/* read the flow info from the tail of fin and dump it to the tail of fout */
template <class nodeType, class linkType, class edgeType>
void network<nodeType,linkType,edgeType>::copyOverFlowInfo(FILE *fin, FILE *fout) {
	char buf[MAXLINE];

	while (fgets(buf, MAXLINE, fin)) {
		fprintf(fout, "%s", buf);
	}
}


template <class nodeType, class linkType, class edgeType>
void network<nodeType,linkType,edgeType>::process(char *topologyFile, FILE *fin, FILE *fout) {
	readTopology(topologyFile, fin);
	computeGraph(fout);
	computeConflictGraph(fout);
	copyOverFlowInfo(fin,fout);
}

int main(int argc, char **argv) {
	char *topologyFile=NULL, *conflictFile=NULL;
	FILE *fin, *fout;
	char *config = NULL;

	if (argc < 2) {
		printf("Usage: ConflictGraph <topology file> [<conflict graph file>]\n");
		return -1;
	}
	topologyFile = argv[1];
	if (argc >= 3)
		conflictFile = argv[2];
	if (argc >= 4)
		config = argv[3];

	/* topologyFile describes the physical layout of the wireless nodes */
	if (!(fin = fopen(topologyFile, "r"))) {
		printf("error opening %s\n", topologyFile);
		return -1;
	}
	/* conflictFile contains the conflict graph and other information */ 
	if (!(fout = fopen(conflictFile, "w"))) {
		printf("Error: unable to open %s\n", conflictFile);
		return -1;
	}
	/* 
	 * first line in conflict file is 0 (protocol model) or 1 (physical model)
	 * second line in conflict file is 0 (unidirectional MAC) or 1 (bidirectional MAC)
	 */
	if (!config || !strcmp(config, "link")) {
		network<node, link<node>, edge<link<node> > > net;

		fprintf(fout, "0\n0\n");
		net.process(topologyFile, fin, fout);
	} else if (!strcmp(config, "bidireclink")) {
		network<node, bidirecLink<node>, edge<bidirecLink<node> > > net;

		fprintf(fout, "0\n1\n");
		net.process(topologyFile, fin, fout);
	} else if (!strcmp(config, "phylink")) {
		network<phyNode, phyLink, phyEdge> net;

		fprintf(fout, "1\n0\n");
		net.process(topologyFile, fin, fout);
	} else if (!strcmp(config, "bidirecphylink")) {
		network<phyNode, bidirecPhyLink, bidirecPhyEdge> net;

		fprintf(fout, "1\n1\n");
		net.process(topologyFile, fin, fout);
	} 

	fclose(fin);
	fclose(fout);
	return 0;
}

