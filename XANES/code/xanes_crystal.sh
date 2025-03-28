#!/bin/sh

total_start=`date +%s` 

echo -e "\n##### This script will run pw.x and xspectra.x calculations for all atoms #####"

# check all inputted data
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

# save arguments
SCF_INPUT="$1"
PSEUDO_INPUT="$2"
XSPECTRA_INPUT="$3"
NAME="${XSPECTRA_INPUT%.xspectra.in}"

TEMP_FILE=$(mktemp)
cp results/$SCF_INPUT $TEMP_FILE

# output arguments (debugging)
echo -e "\nSCF input is $SCF_INPUT"
echo -e "Pseudofile input is $PSEUDO_INPUT"
echo -e "XSpectra input is $XSPECTRA_INPUT"
echo -e "Name of material is $NAME\n"

absorbing_atom=$(awk '/ATOMIC_SPECIES/{flag=1} /ATOMIC_POSITIONS/{flag=0} flag && $1 ~ /_h$/ {print substr($1, 1, length($1)-2); exit}' "results/$SCF_INPUT")
atoms=($(awk '/ATOMIC_POSITIONS/{flag=1; next} /K_POINTS/{flag=0} flag {print $1}' "results/$SCF_INPUT"))
num_atoms=${#atoms[@]}

# output important cell information
echo -e "Cell Information"
echo -e "Absorbing Atom Type: $absorbing_atom"
echo -e "Number of Atoms: $num_atoms"
echo -e

echo "______________________________________________________________________"

echo -e "\nTesting absorbing atom 1...\n"

echo -e "Performing SCF calculations on $SCF_INPUT...\n"
./scf "$SCF_INPUT" "$PSEUDO_INPUT"
echo -e "Done.\n"

echo -e "Performing XSpectra calculations on $XSPECTRA_INPUT..."
./xanes "$XSPECTRA_INPUT"
mv results/$NAME.xspectra.dat results/${NAME}1.xspectra.dat
echo -e "Done.\n"

echo "______________________________________________________________________"

# loop through the rest of the atoms 
for ((i=0; i<num_atoms-1; i++)); do
    atoms=($(awk '/ATOMIC_POSITIONS/{flag=1; next} /K_POINTS/{flag=0} flag {print $1}' "results/$SCF_INPUT"))
    positions=($(awk '/ATOMIC_POSITIONS/{flag=1; next} /K_POINTS/{flag=0} flag {print $2, $3, $4}' "results/$SCF_INPUT"))

    echo -e "\nTesting absorbing atom $((i+2))...\n"

    # check if atom is absorbing atom 
    if [[ "${atoms[i]}" == *_h ]]; then

       x=$(echo ${positions[i*3]} | awk '{print $1}')
       y=$(echo ${positions[i*3+1]} | awk '{print $1}')
       z=$(echo ${positions[i*3+2]} | awk '{print $1}')
       
       echo "Atom Type: ${atoms[i]}"
       echo "X-coordinate: $x"
       echo "Y-coordinate: $y"
       echo "Z-coordinate: $z"
        
        next_atom_index=$((i+1))
        # check if next atom is within bounds and is the same atom type
        if [[ $next_atom_index -lt $num_atoms && "${atoms[next_atom_index]}" == "${atoms[i]%_h}" ]]; then
            echo -e "\nModifying $SCF_INPUT..."
            awk -v idx="$i" -v next_idx="$next_atom_index" 'BEGIN {found = 0; count = 0}
            /ATOMIC_POSITIONS/ {print; found = 1; next} 
            /K_POINTS/ {found = 0}
            found && count == idx {print substr($1, 1, length($1)-2), $2, $3, $4; count++; next}
            found && count == next_idx {print $1 "_h", $2, $3, $4; count++; next}
            found {count++}
            {print}
            ' "results/$SCF_INPUT" > temp_file && mv temp_file "results/$SCF_INPUT"
            echo -e "Done.\n"
        else
            echo -e "Finished testing all absorbing atoms" 
            exit 0
        fi
        echo -e "Performing SCF calculations on $SCF_INPUT..."
        ./scf "$SCF_INPUT" "$PSEUDO_INPUT"
        echo -e "Done."

        echo -e "\nPerforming XSpectra calculations on $XSPECTRA_INPUT..."
        ./xanes "$XSPECTRA_INPUT"
        mv results/$NAME.xspectra.dat results/${NAME}$((i+2)).xspectra.dat
        echo -e "Done.\n" 
    fi
    echo "______________________________________________________________________"
done

mv $TEMP_FILE results/$SCF_INPUT

total_end=`date +%s`
total_runtime=$((total_end - total_start))

hour=$((total_runtime / 3600))
minute=$(( (total_runtime % 3600) / 60 ))
second=$(( (total_runtime % 3600) % 60 ))

echo -e "\nTotal Runtime: $hour:$minute:$second (hh:mm:ss)"
