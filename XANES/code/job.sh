#!/bin/bash -l

#$ -cwd
#$ -l nodes=1
#$ -binding linear:8
#$ -l h_rt=2:00:00
#$ -l highp
#$ -N TEST
#$ -o test-$JOB_ID.out
#$ -e test-$JOB_ID.err

##$ -l h_data=1G

# runtime of vs number of atoms
# nat = 10
./scf aC1_10.scf.in
./xanes aC1_10.scf.in
# nat = 20
./scf aC1_20.scf.in
./xanes aC1_20.scf.in
# nat = 30
./scf aC1_50.scf.in
./xanes aC1_50.scf.in
# nat = 100
./scf aC1_100.scf.in
./xanes aC1_100.scf.in
# nat = 261
./scf aC1_261.scf.in
./xanes aC1_261.scf.in

# diamond vs xgamma
# xgamma = 0.4
./scf diamond_0.4.scf.in C_PBE_TM_2pj.UPF
./xanes diamond_0.4.xspectra.in
# xgamma = 0.8
./scf diamond_0.8.scf.in C_PBE_TM_2pj.UPF
./xanes diamond_0.8.xspectra.in
# xgamma = 1
./scf diamond_1.scf.in C_PBE_TM_2pj.UPF
./xanes diamond_1.xspectra.in

# carbon vs xgamma 
# xgamma = 0.4
./scf aC_0.4.scf.in C_PBE_TM_2pj.UPF
./xanes aC_0.4.xspectra.in
# xgamma = 0.8
./scf aC_0.8.scf.in C_PBE_TM_2pj.UPF
./xanes aC_0.8.xspectra.in
# xgamma = 1.5
./scf aC_1.5.scf.in C_PBE_TM_2pj.UPF
./xanes aC_0.4.xspectra.in
# xgamma = 2
./scf aC_2.scf.in C_PBE_TM_2pj.UPF
./xanes aC_2.xspectra.in
# xgamma = 3
./scf aC_3.scf.in C_PBE_TM_2pj.UPF
./xanes aC_3.xspectra.in

# average carbon 
# xgamma = 0.8
./xanes_amorphous a-C.scf.in C_PBE_TM_2pj.UPF a-C.xspectra.in
# xgamma = 1.5
./change a-C.xspectra.in xgamma 1.5
./xanes_amorphous a-C.scf.in C_PBE_TM_2pj.UPF a-C.xspectra.in
# xgamma = 2
./change a-C.xspectra.in xgamma 2
./xanes_amorphous a-C.scf.in C_PBE_TM_2pj.UPF a-C.xspectra.in

# average diamond
# xgamma = 0.8
./xanes_crystal diamond.scf.in C_PBE_TM_2pj.UPF diamond.xspectra.in
