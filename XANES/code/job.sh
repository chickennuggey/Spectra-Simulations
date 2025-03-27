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

# import functions
source ./xanes_utils.sh

# runtime vs number of atoms
nat=(10 20 50 100 261)
for n in "$nat[@]"; do
    # save name
    prefix="aC1_$n"
    # copy and modifiy aC1 scf file
    update_input results/aC1.scf.in nat $n results/$prefix.scf.in
    update_input results/$prefix.scf.in prefix "'$prefix'"
    # copy and modify aC1 xspectra file
    update_input results/aC1.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
    update_input results/$prefix.xspectra.in filecore "'$prefix.wfc'"
    # run calculations
    ./scf $prefix.scf.in C_PBE_TM_2pj.UPF
    ./xanes $prefix.xspectra.in
done

# diamond vs xgamma 
./scf diamond.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1)
for x in "$xgamma[@]"; do
    prefix="diamond_$x"
    update_input results/diamond.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
    ./xanes $prefix.xspectra.in
done  

# carbon vs xgamma 
./scf aC.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1.5 2 3)
for x in "$xgamma[@]"; do
    prefix="aC_$x"
    update_input_new results/aC.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
    xanes $prefix.xspectra.in
done 

# average carbon 
xgamma=(0.8 1.5 2)
for x in "$xgamma[@]"; do
    prefix="avg_aC_$x"
    update_input results/aC.scf.in prefix "'$prefix'" results/$prefix.scf.in
    update_input results/aC.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
    ./xanes_amorphous $prefix.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
done 

# average diamond 
prefix="avg_diamond_0.8"
update_input results/diamond.scf.in prefix "'$prefix'" results/$prefix.scf.in
update_input results/diamond.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
./xanes_crystal $prefix.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
