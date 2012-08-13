#include "common.h"

void Permute (int *nodelist, int size) 
{
	// generate a random permutation of nodelist
	int i, j, temp; 
	double k; 

	for (i = 0; i < size ; i++) {
		k = (double)rand()/(double)RAND_MAX;
		k = floor(k*(size-1) + 0.5); 
		j = (int)k;
		if ((j < 0) || (j > (size-1))) {
			printf ("error: %d %f\n", j, k);
			exit(-1);
		}
		temp = nodelist[i]; 
		nodelist[i] = nodelist[j];
		nodelist[j] = temp;
	}
}

int Compare( const void *arg1, const void *arg2 )
{
   if ((*(int *)arg1) > (*(int *)arg2)) 
	   return 1; 
	else 
		return -1;
}

FILE *OpenFileToWrite (char *fnam) 
{
    FILE *fp = fopen (fnam, "w"); 
    if (fp == NULL) {
	printf ("could not open file :%s: for writing\n", fnam); 
	exit(-1);
    }
    return fp; 
}

void OpenFiles (struct FP *fp, int opform, char *fnam) 
{
    char fn[MAX_FILENAME];

    switch (opform) {
	case OPFORM_MATLAB_SPARSE:
	    sprintf (fn, "%s.sz", fnam);
		fp->sz = OpenFileToWrite(fn);
		// fall through
	case OPFORM_MATLAB:
		sprintf(fn, "%s.obj", fnam);
		fp->obj = OpenFileToWrite(fn);
		sprintf(fn, "%s.lb", fnam);
		fp->lb = OpenFileToWrite(fn);
		sprintf(fn, "%s.ub", fnam);
		fp->ub = OpenFileToWrite(fn);
		sprintf(fn, "%s.A", fnam);
		fp->A = OpenFileToWrite(fn);
		sprintf(fn, "%s.b", fnam);
		fp->b = OpenFileToWrite(fn);
		sprintf(fn, "%s.Aeq", fnam);
		fp->Aeq = OpenFileToWrite(fn);
		sprintf(fn, "%s.beq", fnam);
		fp->beq = OpenFileToWrite(fn);
		break; 
	case OPFORM_LPSOLVE: 
	case OPFORM_CPLEX_LP: 
		fp->lp = OpenFileToWrite(fnam);
		break;
	default: 
		printf ("incorrect format\n");
		exit(-1);
	}
}

void CloseFiles (struct FP *fp, int opform) 
{
    switch (opform) {
	case OPFORM_MATLAB_SPARSE:
	    fclose(fp->sz);
		// fall through.
	case OPFORM_MATLAB:
		fclose(fp->obj);
		fclose(fp->lb);
		fclose(fp->ub);
		fclose(fp->A);
		fclose(fp->b);
		fclose(fp->Aeq);
		fclose(fp->beq);
		break; 
	case OPFORM_CPLEX_LP:
		fprintf (fp->lp, "end\n");
		// fall through.
	case OPFORM_LPSOLVE: 
		fclose(fp->lp);
		break;
	default: 
		printf ("incorrect format\n");
		exit(-1);
	}
}
