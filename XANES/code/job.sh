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
nat=(10 20 50 100 261)
for n in "$nat[@]"; do
    # save name
    prefix="aC1_$n"
    # copy and modifiy aC1 scf file
    cp results/aC1.scf.in results/$prefix.scf.in
    ./change results/$prefix.scf.in nat $n 
    ./change results/$prefix.scf.in prefix "'$prefix'"
    # copy and modify aC1 xspectra file
    cp results/aC1.xspectra.in results/$prefix.xspectra.in
    ./change results/$prefix.xspectra.in prefix "'$prefix'"
    ./change results/$prefix.xspectra.in filecore "'$prefix.wfc'"
    # run calculations
    ./scf $prefix.scf.in C_PBE_TM_2pj.UPF
    ./xanes $prefix.xspectra.in
done

# diamond vs xgamma 
scf diamond.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1)
for x in "$xgamma[@]"; do
    prefix="diamond_$x"
    cp results/diamond.xspectra.in results/$prefix.xspectra.in
    ./change results/$prefix.xspectra.in prefix "'$prefix'"
    ./xanes $prefix.xspectra.in
done  

# carbon vs xgamma 
scf aC.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1.5 2 3)
for x in "$xgamma[@]"; do
    prefix="aC_$x"
    cp results/aC.xspectra.in results/$prefix.xspectra.in
    ./change results/$prefix.xspectra.in prefix "'$prefix'"
    ./xanes $prefix.xspectra.in
done 

# average carbon 
xgamma=(0.8 1.5 2)
for x in "$xgamma[@]"; do
    prefix="avg_aC_$x"
    cp results/aC.scf.in results/$prefix.scf.in
    ./change results/$prefix.scf.in prefix "'$prefix'"
    cp results/aC.xspectra.in results/$prefix.xspectra.in
    ./change results/$prefix.xspectra.in prefix "'$prefix'"
    ./xanes_amorphous $prefix.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
done 

# average diamond 
prefix="avg_diamond_0.8"
cp results/diamond.scf.in results/$prefix.scf.in
./change results/$prefix.scf.in prefix "'$prefix'"
cp results/diamond.xspectra.in results/$prefix.xspectra.in
./change results/$prefix.xspectra.in prefix "'$prefix'"
./xanes_crystal $prefix.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
