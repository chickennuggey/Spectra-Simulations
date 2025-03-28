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
source ./utils

# runtime vs number of atoms
nat=(10 20 50 100 261)
for n in "${nat[@]}"; do
    # save name
    prefix="aC1_$n"
    # copy and modifiy aC1 scf file
    update_input results/aC1.scf.in nat $n results/$prefix.scf.in
    update_input results/$prefix.scf.in prefix "'$prefix'"
    # copy and modify aC1 xspectra file
    update_input results/aC1.xspectra.in prefix "'$prefix'" results/$prefix.xspectra.in
    update_input results/$prefix.xspectra.in filecore "'$prefix.wfc'"
    update_input results/$prefix.xspectra.in x_save_file "'$prefix.sav'"
    # run calculations
    ./scf $prefix.scf.in C_PBE_TM_2pj.UPF
    ./xanes $prefix.xspectra.in
done

# diamond vs xgamma (GOOD)
./scf diamond.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1 1.5)
for x in "${xgamma[@]}"; do
    prefix="diamond_$x"
    update_input results/diamond.xspectra.in xgamma "$x" results/$prefix.xspectra.in
    ./xanes $prefix.xspectra.in
done  

# average diamond (GOOD)
xgamma=(0.8 1 1.5)
for x in "${xgamma[@]}"; do
    prefix="avg_diamond_$x"
    update_input results/diamond.xspectra.in xgamma $x results/$prefix.xspectra.in
    ./xanes_crystal diamond.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
done 

# carbon (aC) vs xgamma (GOOD)
./scf aC.scf.in C_PBE_TM_2pj.UPF
xgamma=(0.4 0.8 1 1.5)
for x in "${xgamma[@]}"; do
    prefix="aC_$x"
    update_input results/aC.xspectra.in xgamma "$x" results/$prefix.xspectra.in
    ./xanes $prefix.xspectra.in
done 

# average carbon (aC) (GOOD)
xgamma=(0.8 1 1.5)
for x in "${xgamma[@]}"; do
    prefix="avg_aC_$x"
    update_input results/aC.xspectra.in xgamma $x results/$prefix.xspectra.in
    ./xanes_amorphous aC.scf.in C_PBE_TM_2pj.UPF $prefix.xspectra.in
done 

# carbon (aC1)
./scf aC1.scf.in C_PBE_TM_2pj.UPF
update_input results/aC1.xspectra.in xgamma "1" results/aC1_1.xspectra.in
./xanes aC1_1.xspectra.in

# carbon (aC2)
./scf aC2.scf.in C_PBE_TM_2pj.UPF
update_input results/aC2.xspectra.in xgamma "1" results/aC2_1.xspectra.in
./xanes aC2_1.xspectra.in

# carbon (aC3)
./scf aC3.scf.in C_PBE_TM_2pj.UPF
update_input results/aC3.xspectra.in xgamma "1" results/aC3_1.xspectra.in
./xanes aC3_1.xspectra.in

# carbon (aC4)
./scf aC4.scf.in C_PBE_TM_2pj.UPF
update_input results/aC4.xspectra.in xgamma "1" results/aC4_1.xspectra.in
./xanes aC4_1.xspectra.in

# carbon (aC5)
./scf aC5.scf.in C_PBE_TM_2pj.UPF
update_input results/aC5.xspectra.in xgamma "1" results/aC5_1.xspectra.in
./xanes aC5_1.xspectra.in


