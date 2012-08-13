#include "clique.h"

// Lili added start
void readCliques(char *clique_inputFile, struct LinkList ll, struct SetCliques *scl)
{
  int *v;
  double *w;
  FILE *fd;
  int num_cliques, num_vertices;
  
  // scratch memory for holding cliques as they form
  // v's maximum size is # links (ll.nl)
  if ((v = (int *) calloc (ll.nl, sizeof(int))) == NULL) {
    printf("can't allocate v\n");
    exit(-1);
  }  
  if ((w = (double *) calloc (ll.nl, sizeof(double))) == NULL) {
    printf("can't allocate w\n");
    exit(-1);
  }

  if ((fd = fopen(clique_inputFile,"r")) == NULL) {
    printf("Unable to open clique_inputFile %s\n", clique_inputFile);
    exit(-1);
  }

  fscanf(fd, "%d", &num_cliques);

  if ((scl->cl = (Clique *) calloc(num_cliques, sizeof(struct Clique))) == NULL) {
    printf("can't allocate scl->cl\n");
    exit(-1);
  }
  scl->n = 0;
  
  for (int i = 0; i < num_cliques; i++) {
    struct Clique cl;

    cl.n = 0;

    fscanf(fd, "%d", &num_vertices);
    
    for (int j = 0; j < num_vertices; j++) {
      fscanf(fd, "%d", &v[cl.n]);
      fscanf(fd, "%lf", &w[cl.n]);
      cl.n++;
    }

    // Do NOT sort the clique!!
    // qsort ((void *)v, cl.n, sizeof(int), Compare);

    // allocate memory to hold the v array
    if ((cl.v = (int *)calloc(cl.n, sizeof(int)))== NULL) {
      printf ("can't allocate v memory\n");
      exit(-1);
    }
    memcpy ((void *)cl.v, v, cl.n*sizeof(int));

    // allocate memory to hold the w array
    if ((cl.w = (double *)calloc(cl.n, sizeof(double)))== NULL) {
      printf ("can't allocate w memory\n");
      exit(-1);
    }
    memcpy ((void *)cl.w, w, cl.n*sizeof(double));

    fscanf(fd,"%lf", &cl.max_util);
    
    InsertClique(scl, cl);

  }

  fclose(fd);

  // printCliques(*scl);
}
// Lili added end

void findCliques (struct LinkList ll, struct SetCliques *scl, int attempts) 
{
	int i; 
	struct Clique cl; 
	int *nodelist; 
	int *v;

	// first, allocate memory for permutaion fo nodelist. 
	if ((nodelist = (int *) calloc (ll.nl, sizeof(int))) == NULL) {
		printf("can't allocate nodelist\n");
		exit(-1);
	}
	
	for (i = 0 ; i < ll.nl; i++) {
		nodelist[i] = i; 
	}

	// scratch memory for holding cliques as they form
	if ((v = (int *) calloc (ll.nl, sizeof(int))) == NULL) {
		printf("can't allocate v\n");
		exit(-1);
	}

	// allocate space for max cliques we may find
	// we can't possibly find more than "attempts" ...
	if ((scl->cl = (Clique *) calloc (attempts, sizeof(struct Clique))) == NULL) {
		printf("can't allocate scl->cl\n");
		exit(-1);
	}

	// start looking for cliques 
	scl->n = 0;
	for (i = 0; i < attempts; i++) {
		Permute(nodelist, ll.nl);	
		// find a random indepenent set 
		cl = GetClique (ll, nodelist, v);
		// insert it into the set of independet sets
		// the insert function takes care of duplicates
		InsertClique(scl, cl);
		printf ("attempt %d cliques %d size of last clique %d\n", i, scl->n, scl->cl[scl->n-1].n);
	}
	
}

struct Clique GetClique (struct LinkList ll, int *nodelist, int *v) 
{
	int i, nextnode;
	struct Clique cl; 

	// generate a random permutation of the nodelist
	
	// look for independent set 
	// add the first node to the independent set
	i = 0;
	cl.n = 0;
	v[cl.n++] = nodelist[i];
	for (i = 1 ; i < ll.nl; i++) {
		nextnode = nodelist[i];
		// add next node if the set still remains "schedulable". 
		if (canAdd (ll, v, cl.n, nextnode) == 1) {
			v[cl.n++] = nextnode;
		}
	}
	// sort the independent set, for the benefit of the insertion algorithm
	qsort ((void *)v, cl.n, sizeof(int), Compare);

	// allocate memory to hold the v array
	if ((cl.v = (int *)calloc(cl.n, sizeof(int)))== NULL) {
		printf ("can't allocate v memory\n");
		exit(-1);
	}
	memcpy ((void *)cl.v, v, cl.n*sizeof(int));

        // Lili added start
        if ((cl.w = (double *)calloc(cl.n, sizeof(double)))== NULL) {
		printf ("can't allocate w memory\n");
		exit(-1);
	}
        for (i = 0; i < cl.n; i++) {
        	cl.w[i] = 1.0;
        }
        cl.max_util = 1;
        // Lili added end
        
	return cl;
}

void InsertClique (struct SetCliques *scl, struct Clique cl)
{
	int i;
	int insert = 1; 
	
	for (i = 0 ; i < scl->n; i++) {
		if (AreEqualCliques(scl->cl[i], cl) == 1) {
			insert = 0;
			break;
		}
	}
	if (insert == 1) {
		scl->cl[scl->n++] = cl;
	}
}

int AreEqualCliques (struct Clique a, struct Clique b)
{
	int i; 
	if (a.n != b.n) {
		return 0; 
	}
	for (i = 0 ; i < a.n ; i++) {
		if (a.v[i] != b.v[i]) {
			return 0;
		}
                // Lili added starts
                if (a.w[i] != b.w[i]) {
                	return 0;
                }
                // Lili added ends
	}
        return 1;
}

void printCliques (struct SetCliques scl) 
{
	int i, j; 

        printf("printCliques\n");
	printf ("%d\n", scl.n);
	for (i = 0; i < scl.n ; i++) {
		for (j = 0 ; j < scl.cl[i].n; j++) {
			printf ("%d %.3f ", scl.cl[i].v[j], scl.cl[i].w[j]);
		}
		printf ("\n");
	}
}

int canAdd (struct LinkList ll, int *v, int vlen, int nextnode) 
{
	int add; 

	if (ll.ifmodel == IFMODEL_PROTO) {
		add = canAddProto (ll, v, vlen, nextnode);
	} else {
		printf ("physical model not implemented yet\n");
		exit(1);
	}

	return add; 
}

int canAddProto (struct LinkList ll, int *v, int vlen, int nextnode) 
{
	int i; 

	for (i = 0; i < vlen ; i++) {
		// if the next node is not in conflict with any of 
		// the existing nodes, return 0
		if ((ll.conflict[v[i]][nextnode]==0) || (ll.conflict[nextnode][v[i]]==0)) {
			return 0; 
		}
	}

	return 1; 
}

