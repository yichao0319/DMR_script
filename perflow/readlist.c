#include "readlist.h"

void readInfo (char *llfn, struct LinkList *ll, struct Problem *prob) 
{
	FILE *fp;

	// open the file
	if ((fp = fopen (llfn, "r")) == NULL) {
		printf ("Can't open file %s for reading\n", llfn);
		exit(-1);
	}
	
	// interference model
	fscanf (fp, "%d", &(ll->ifmodel));
	
	// mac 
	fscanf (fp, "%d", &(ll->mac));

	// read number of nodes
	fscanf (fp, "%d", &(ll->nn));

	readLinks (fp, ll); 

	readConflictMatrix (fp, ll); 

	readSDPairs(fp, prob); 

	fclose(fp);
}

void readLinks (FILE *fp, struct LinkList *ll)
{
	int i, index; 

	// read number of links
	fscanf (fp, "%d", &(ll->nl));

	// memory for holding the list of links
	if ((ll->l = (Link *) calloc (ll->nl, sizeof(struct Link))) == NULL) {
		printf ("can't allocate memory to hold link list\n");
		exit(-1);
	}
	
	// read the list of links
	for (i = 0 ; i < ll->nl; i++) {
		fscanf (fp, "%d %d %d %d %lf", 
			     	&index, 
			     	&(ll->l[i].from), &(ll->l[i].to), 
			     	&(ll->l[i].channel),
			     	&(ll->l[i].capacity));
		/*printf ("%d %d %d %d %lf\n", 
				index, 
				ll->l[i].from, ll->l[i].to, 
				ll->l[i].channel,
				ll->l[i].capacity);*/
	}
}

void readConflictMatrix (FILE *fp, struct LinkList *ll)
{
	if (ll->ifmodel == IFMODEL_PROTO) {
			readProtoConflictMatrix (fp, ll);
	} else {
		if ((ll->ifmodel == IFMODEL_PHY) && (ll->mac == MAC_UNI)) {
				readPhyUniConflictMatrix (fp, ll);
		} else {
			if ((ll->ifmodel == IFMODEL_PHY) && (ll->mac == MAC_BI)) {
					readPhyBiConflictMatrix (fp, ll);
			} else {
				printf ("can't handle this ifmodel and/or mac\n");
				exit(-1);
			}
		}
	}
}

void readProtoConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j;

	// for now, the size of conflict graph is nxn. 
	if ((ll->conflict = (int **)calloc(ll->nl, sizeof (int *))) == NULL) {
		printf ("can't allocate conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->conflict[i] = (int *)calloc(ll->nl, sizeof(int))) == NULL) {
			printf ("can't allocate conflict graph memory %d\n", i);
			exit(-1);
		}
	}
	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			fscanf (fp, "%d", &(ll->conflict[i][j]));
			//printf ("%d ", ll->conflict[i][j]);
		}
		//printf ("Row %d read \n", i);
	}
}

void readPhyUniConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j; 

	// for now, the size of phy_conflict graph is nxn. 
	if ((ll->phy_conflict = (double **)calloc(ll->nl, sizeof (double *))) == NULL) {
		printf ("can't allocate phy_conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->phy_conflict[i] = (double *)calloc(ll->nl, sizeof(double))) == NULL) {
			printf ("can't allocate phy_conflict graph memory %d\n", i);
			exit(-1);
		}
	}
	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			fscanf (fp, "%lf", &(ll->phy_conflict[i][j]));
			//printf ("%lf ", ll->phy_conflict[i][j]);
		}
		printf ("\n");
	}
}

void readPhyBiConflictMatrix (FILE *fp, struct LinkList *ll)
{
	int i, j, k; 

	// for now, the size of phy_bi_conflict graph is nxnx2. 
	if ((ll->phy_bi_conflict = (double ***)calloc(ll->nl, sizeof (double **))) == NULL) {
		printf ("can't allocate phy_bi_conflict graph memory -1\n");
		exit(-1);
	}
	for (i = 0 ; i < ll->nl; i++) {
		if ((ll->phy_bi_conflict[i] = (double **)calloc(ll->nl, sizeof(double *))) == NULL) {
			printf ("can't allocate phy_bi_conflict graph memory %d\n", i);
			exit(-1);
		}
		for (j = 0; j < ll->nl; j++) {
			if ((ll->phy_bi_conflict[i][j] = (double *)calloc(2, sizeof(double))) == NULL) {
				printf ("can't allocate phy_bi_conflict graph memory %d %d\n", i, j);
				exit(-1);
			}
		}
	}

	// read data from file
	for (i = 0 ; i < ll->nl; i++) {
		for (j = 0 ; j < ll->nl; j++) {
			for (k = 0; k < 2; k++) {
				fscanf (fp, "%lf", &(ll->phy_bi_conflict[i][j][k]));
				//printf ("%lf ", ll->phy_bi_conflict[i][j][k]);
			}
		}
		printf ("\n");
	}
}

void readSDPairs (FILE *fp, struct Problem *prob) 
{
	int i; 

	// # of flows, and single.multiptah
	fscanf (fp, "%d %d", &(prob->ncon), &(prob->multipath)); 

	// memory for holding the list of connections 
	if ((prob->con = (Connection*) calloc (prob->ncon, sizeof(struct Connection))) == NULL) {
		printf ("can't allocate memory to hold connection list\n");
		exit(-1);
	}
	
	// read in soure-destination pairs
	for (i = 0; i < prob->ncon; i++) {
          fscanf(fp, "%lf %d %d", &(prob->con[i].demand), &(prob->con[i].s), &(prob->con[i].d));
		//printf("%d %d\n", prob->con[i].s, prob->con[i].d);
	}

}
