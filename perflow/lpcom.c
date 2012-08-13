#include "lpcom.h"

double *alloc1D (int num, char *err)
{
	double *x; 
	if ((x = (double *)calloc (num, sizeof (double))) == NULL) {
		printf ("error callocating memory %s\n", err); 
		exit(-1);
	}
	return x; 
}

void allocMemory (struct LinProg *lp) 
{
	lp->F = alloc1D (lp->nv, "OBJ");
	lp->lb = alloc1D (lp->nv, "LB");
	lp->ub = alloc1D (lp->nv, "UB");
	lp->A = alloc1D (lp->nv, "A"); 
	lp->b = alloc1D (1, "b"); 
	lp->Aeq = alloc1D (lp->nv, "Aeq"); 
	lp->beq = alloc1D (1, "beq"); 
}

void printLinProg (struct LinProg lp, int lpPart) 
{
	switch (lp.opform) {
		case OPFORM_MATLAB_SPARSE:
			printMATLABSparse (lp, lpPart); 
			break; 
		case OPFORM_MATLAB:
			printMATLAB (lp, lpPart); 
			break; 
		case OPFORM_LPSOLVE:
			printLP(lp, lpPart);
			break; 
		case OPFORM_CPLEX_LP:
			printCPLEX(lp, lpPart);
			break; 
		default: 
			fprintf (stderr, "Incorrect op format\n");
			exit(-1);
			break; 
	}
}

void printMATLABSparse (struct LinProg lp, int lpPart)
{
	switch (lpPart) {
		case SIZE: 
			fprintf (lp.fp.sz, "%d\n%d\n%d\n", lp.nv, lp.neq, lp.nineq);
			break;
		case OBJ: 
			printColumnMatrix(lp.nv, lp.F, lp.fp.obj);
			break;
		case LB: 
			printColumnMatrix(lp.nv, lp.lb, lp.fp.lb);
			break; 
		case UB:
			printColumnMatrix(lp.nv, lp.ub, lp.fp.ub);
			break;
		case INEQ:
			printSparseRowMatrix(lp.ec, lp.nv, lp.A, lp.fp.A);
			printColumnMatrix(1, lp.b, lp.fp.b);
			break;
		case EQ:
			printSparseRowMatrix(lp.ec, lp.nv, lp.Aeq, lp.fp.Aeq);
			printColumnMatrix(1, lp.beq, lp.fp.beq);
			break; 
		case INT:
			fprintf (stderr, "Ommiting integer cnstraints. Not solvable in matlab\n");
			exit(-1);
			break;
		default: 
			printf ("incorrect lpPart option\n");
			exit(-1);
	}
}

void printSparseColumnMatrix (int cid, int rows, double *m, FILE *fp) 
{
	// print a sparse column - coulmn number is in cid
	int i;
	for (i = 0; i < rows; i++) {
		if (fabs(m[i]) > 0) {
			fprintf (fp, "%d %d %f\n", i+1, cid+1, m[i]);
		}
	}
}

void printSparseRowMatrix (int rid, int cols, double *m, FILE *fp) 
{
	// print a sparse row - row number is in rid
	int i;
	for (i = 0; i < cols; i++) {
		if (fabs(m[i]) > 0) {
			fprintf (fp, "%d %d %f\n", rid+1, i+1, m[i]);
		}
	}
}

void printMATLAB (struct LinProg lp, int lpPart)
{
	switch (lpPart) {
		case OBJ: 
			printColumnMatrix(lp.nv, lp.F, lp.fp.obj);
			break;
		case LB: 
			printColumnMatrix(lp.nv, lp.lb, lp.fp.lb);
			break; 
		case UB:
			printColumnMatrix(lp.nv, lp.ub, lp.fp.ub);
			break;
		case INEQ:
			printRowMatrix(lp.nv, lp.A, lp.fp.A);
			printColumnMatrix(1, lp.b, lp.fp.b);
			break;
		case EQ:
			printRowMatrix(lp.nv, lp.Aeq, lp.fp.Aeq);
			printColumnMatrix(1, lp.beq, lp.fp.beq);
			break; 
		case INT:
			fprintf (stderr, "Ommiting integer cnstraints. Not solvable in matlab\n");
			exit(-1);
			break;
		default: 
			printf ("incorrect lpPart option\n");
			exit(-1);
	}
}

void printColumnMatrix (int rows, double *m, FILE *fp) 
{
	int i;
	for (i = 0; i < rows; i++) {
		fprintf (fp, "%f\n", m[i]);
	}
}

void printRowMatrix (int cols, double *m, FILE *fp) 
{
	int i;
	for (i = 0; i < cols; i++) {
		fprintf (fp, "%f ", m[i]);
	}
	fprintf (fp, "\n");	
}

void printLP(struct LinProg lp, int lpPart)
{
	FILE *fp = lp.fp.lp; 
	int i, j; 
	
	switch (lpPart) {
		case OBJ:
			// print objective function
			for (i = 0; i < lp.nv; i++) {
				// need to multiply by -1, as matlab minimizes
				if (fabs(lp.F[i]) > 0) {
					fprintf (fp, "%+.2f x%d ", -1*lp.F[i], i);
				}
			}
			fprintf (fp, ";\n");
			break;
		case LB:
			// print lower bounds
			for (i = 0; i < lp.nv; i++) {
				if (lp.lb[i] > 0) {
					// only print lower bounds > 0, 0 is default. 
					fprintf (fp, "x%d >= %+.2f;\n", i, lp.lb[i]);
				}
			}
			break;
		case UB: 
			// print upper bounds
			for (i = 0; i < lp.nv; i++) {
				fprintf (fp, "x%d <= %+.2f;\n", i, lp.ub[i]);
			}
			break;
		case INEQ:
			// print inequality constraints 
			for (j = 0; j < lp.nv; j++) {
				if (fabs(lp.A[j]) > 0) {
					fprintf (fp, "%+.2f x%d ", lp.A[j], j);
				}
			}
			fprintf (fp, "<= %+.2f;\n", lp.b[0]);
			break;
		case EQ:
			// print equality constraints 
			for (j = 0; j < lp.nv; j++) {
				if (fabs(lp.Aeq[j]) > 0) {
					fprintf (fp, "%+.2f x%d ", lp.Aeq[j], j);
				}
			}
			fprintf (fp, "= %+.2f;\n", lp.beq[0]);
			break;
		case INT:
			// print integer constraints, if any.
			if (lp.nint > 0) {
				for (i = lp.nv-lp.nint; i < lp.nv; i++) {
					fprintf (fp, "int x%d;\n", i);
				}
			}
			break;
		default: 
			printf ("incorrect llpart option\n");
			exit(-1);
	}
}

void printCPLEX(struct LinProg lp, int lpPart)
{
	FILE *fp = lp.fp.lp; 
	int i, j; 
	
	switch (lpPart) {
		case OBJ:
			// print objective function
			fprintf (fp, "maximize ");
			for (i = 0; i < lp.nv; i++) {
				// need to multiply by -1, as matlab minimizes
				if (fabs(lp.F[i]) > 0) {
					fprintf (fp, "%+.2f x%d ", -1*lp.F[i], i);
				}
			}
			fprintf (fp, "\n");
			fprintf (fp, "subject to ");
			break;
		case LB:
			// skip lower bounds for now. 
			// they are printed with upper bounbds.
			break;
		case UB: 
			// print lower and upper bounds
			fprintf (fp, "bounds\n");
			for (i = 0; i < lp.nv; i++) {
				fprintf (fp, "%+.2f <= x%d <= %+.2f\n", lp.lb[i], i, lp.ub[i]);
			}
			break;
		case INEQ:
			// print inequality constraints 
			for (j = 0; j < lp.nv; j++) {
				if (fabs(lp.A[j]) > 0) {
					fprintf (fp, "%+.2f x%d ", lp.A[j], j);
				}
			}
			fprintf (fp, "<= %+.2f\n", lp.b[0]);
			break;
		case EQ:
			// print equality constraints 
			for (j = 0; j < lp.nv; j++) {
				if (fabs(lp.Aeq[j]) > 0) {
					fprintf (fp, "%+.2f x%d ", lp.Aeq[j], j);
				}
			}
			fprintf (fp, "= %+.2f\n", lp.beq[0]);
			break;
		case INT:
			// print integer constraints, if any.
			if (lp.nint > 0) {
				fprintf (fp, "binaries\n"); 
				for (i = lp.nv-lp.nint; i < lp.nv; i++) {
					fprintf (fp, "x%d\n", i);
				}
			}
			break;
		default: 
			printf ("incorrect llpart option\n");
			exit(-1);
	}
}
