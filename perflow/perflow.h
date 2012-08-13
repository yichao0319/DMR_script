#include "common.h"
#include "readlist.h"
#include "lpcom.h"
#include "lpsolve.h"

struct Variable {
  int x;         //X#
  int flow;      //flow#
  int flow_S;    //flow source
  int flow_D;    //flow destination
  int link;      //link#
  int link_from;      //link source
  int link_to;        //link dest
  int channel;   //link channel
  float capacity;  //link capacity
  float load;      //flow load assigned on this link
  float flow_t; //total flow throughput, may use multiple path
};

struct FlowInfo{
  int S;
  int D;
  float flow_t;
};
