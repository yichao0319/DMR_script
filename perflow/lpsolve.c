#include "lpsolve.h"
int readLpsolveRes (char *lpfn, struct lpsolveResult *lpr)
{
  FILE *fp;
  char buf[512];
  int i, j;
  float v;
  int res = -1;
  
  //open the file
  if ((fp = fopen(lpfn, "r")) == NULL) {
    printf("Can't open file %s for reading\n", lpfn);
    exit(-1);
  }

  //memory for holding the list of variables
  if ((lpr->x = (float *) calloc (lpr->nv, sizeof(float))) == NULL) {
    printf ("can't allocate memory to hold variants");
    exit(-1);
  }
  
  i = 0;

  //read lpsolve result
  while((! feof(fp)) && (i < lpr->nv ))
    {
      //get one line
      fgets(buf, 512, fp); 

      //if it starts with x, assume it is the value of variant
      if (buf[0] == 'x')
	{
	  
	  //read variant index 
	  sscanf((const char *)(buf+1), "%d%f", &j, &v);

	  //only get the variants correlated to flows
	  if (j < lpr->nv)
	    {
	      lpr->x[j] = v;
	      i ++;

	      printf("x[%d]=%f\n", j, lpr->x[j]);
	    }
	  res = 1;
	}
    }
  fclose(fp);
  return res;
}
