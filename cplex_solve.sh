rm res
/usr/bin/nice  cplex << END
read $1
lp
optimize
write res sol
quit
END
CPLEX2lp_solve.py res $2 
