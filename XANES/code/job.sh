#!/bin/bash -l\
\
#$ -cwd\
#$ -l nodes=1\
#$ -binding linear:8\
#$ -l h_rt=2:00:00\
#$ -l highp\
#$ -N TEST\
#$ -o test-$JOB_ID.out\
#$ -e test-$JOB_ID.err\
\
##$ -l h_data=1G\
\
./scf C20.scf.in C.UPF
./xanes C20.xspectra.in
