#!/bin/sh

total_start=`date +%s` 

echo -e "\n##### This script will run pw.x and xspectra.x calculations for central atoms #####"
echo -e "##### By default, this will consider all atoms within 3 angstroms #####"

# check inputs 
if [ -z "$1" ]; then
    echo "Error: Please enter a pw.x input file."
    exit 1
fi
if [ -z "$2" ]; then
    echo "Error: Please enter a pseudofile."
    exit 1
fi
if [ -z "$3" ]; then
    echo "Error: Please enter a xspectra.x input file."
    exit 1
fi

# save inputs
SCF_INPUT="$1"
PSEUDO_INPUT="$2"
XSPECTRA_INPUT="$3"
NAME="${SCF_INPUT%.scf.in}"

TEMP_FILE=$(mktemp)
cp results/$SCF_INPUT $TEMP_FILE

echo -e "\nSCF input is $SCF_INPUT"
echo -e "Pseudofile input is $PSEUDO_INPUT"
echo -e "XSpectra input is $XSPECTRA_INPUT"
echo -e "Name of material is $NAME\n"

# save cell information
cutoff=3.0 # can change this (if desired)
absorbing_atom=$(awk '/ATOMIC_SPECIES/{flag=1} /ATOMIC_POSITIONS/{flag=0} flag && $1 ~ /_h$/ {print substr($1, 1, length($1)-2); exit}' "results/$SCF_INPUT")
A=$(awk '/^ *A *=/ {print $3}' "results/$SCF_INPUT") 
num_atoms=$(awk '/^ *nat *=/ {print $3}' "results/$SCF_INPUT")

# output cell information
echo "Cell Information:"
echo "Cutoff distance: $cutoff"
echo "Absorbing Atom Type: $absorbing_atom"
echo "Cell Boundary: $A"
echo "Number of Atoms: $num_atoms"
echo -e

echo "______________________________________________________________________"

# loop through every atom 
for ((i=0; i<num_atoms; i++)); do
    echo -e "\nTesting absorbing atom $((i+1))...\n" 
    atoms=($(awk '/ATOMIC_POSITIONS/{flag=1; next} /K_POINTS/{flag=0} flag {print $1}' "results/$SCF_INPUT"))
    positions=($(awk '/ATOMIC_POSITIONS/{flag=1; next} /K_POINTS/{flag=0} flag {print $2, $3, $4}' "results/$SCF_INPUT"))

    # check if atom is absorbing atom
    if [[ "${atoms[i]}" == *_h ]]; then 
        # check if its positions are within boundaries
        x=$(echo ${positions[i*3]} | awk '{print $1}')
        y=$(echo ${positions[i*3+1]} | awk '{print $1}')
        z=$(echo ${positions[i*3+2]} | awk '{print $1}')
	
       echo "Atom Type: ${atoms[i]}"
       echo "X-coordinate: $x"
       echo "Y-coordinate: $y"
       echo "Z-coordinate: $z"

       echo -e
       echo -e "Checking if atom is within cutoff boundaries..."

        # check if atom is within boundary conditions
        if [[ $(echo "$x > $cutoff" | bc) -eq 1 && $(echo "$x < $A - $cutoff" | bc) -eq 1 ]] && \
           [[ $(echo "$y > $cutoff" | bc) -eq 1 && $(echo "$y < $A - $cutoff" | bc) -eq 1 ]] && \
           [[ $(echo "$z > $cutoff" | bc) -eq 1 && $(echo "$z < $A - $cutoff" | bc) -eq 1 ]]; then
           
           echo -e "Atom is within cutoff boundaries."
           echo -e "\nPerforming SCF calculations on $SCF_INPUT...\n"
           ./scf "$SCF_INPUT" "$PSEUDO_INPUT"
           echo -e "Done.\n"

           echo -e "\nPerforming XSpectra calculations on $XSPECTRA_INPUT...\n"
           ./xanes "$XSPECTRA_INPUT"
           mv results/$NAME.xspectra.dat results/${NAME}$((i+1)).xspectra.dat
           echo -e "Done.\n" 
        else 
           echo -e "Atom is not within cutoff boundaries.\n"
        fi

        # update the input file so the next appropriate atom is the absorbing atom
	next_atom_index=$((i+1))
        # check if next atom is within bounds and is the same atom type
        if [[ $next_atom_index -lt $num_atoms && "${atoms[next_atom_index]}" == "${atoms[i]%_h}" ]]; then
            echo -e "Moving on to the next absorbing atom..."
            awk -v idx="$i" -v next_idx="$next_atom_index" 'BEGIN {found = 0; count = 0}
            /ATOMIC_POSITIONS/ {print; found = 1; next} 
            /K_POINTS/ {found = 0}
            found && count == idx {if ($1 ~ /_h$/) print substr($1, 1, length($1)-2), $2, $3, $4; else print; count++; next}
  	        found && count == next_idx {if ($1 !~ /_h$/) print $1 "_h", $2, $3, $4; else print; count++; next}
            found {count++}
            echo -e "Modifying $SCF_INPUT..."
            ' "results/$SCF_INPUT" > temp_file && mv temp_file "results/$SCF_INPUT"
            echo -e "Done."
        else
            echo -e "Finished testing all absorbing atoms"
            exit 0
        fi   
    fi
    echo -e "\n________________________________________________________________________\n"
done

mv $TEMP_FILE results/$SCF_INPUT

total_end=`date +%s`
total_runtime=$((total_end - total_start))

hour=$((total_runtime / 3600))
minute=$(( (total_runtime % 3600) / 60 ))
second=$(( (total_runtime % 3600) % 60 ))

echo -e "Total Runtime: $hour:$minute:$second (hh:mm:ss)"
