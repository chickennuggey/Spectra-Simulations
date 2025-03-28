#!/bin/sh

start_time=`date +%s` 

# Check if there are required inputs
if [ -z "$1" ]; then
    echo "Error: Please enter a pw.x input file."
    exit 1
fi
if [ -z "$2" ]; then
    echo "Error: Please enter a pseudofile."
    exit 1
fi

cd `dirname $0`
SAMPLE_DIR=`pwd`

# save inputs
SCF_INPUT="$1"
PSEUDO_INPUT="$2"
NAME="${SCF_INPUT%.scf.in}"

echo -e "\n############ This script will run pw.x for $SCF_INPUT ############"

echo -e "\nSCF input is $SCF_INPUT"
echo -e "Pseudofile input is $PSEUDO_INPUT"
echo -e "Name of material is $NAME\n"

echo -e "########## Loading in necessary variables and checking data ###############"

echo -e "\nLoading in environment variables..."
. ../../environment_variables 
echo -e "Done."

BIN_DIR="$SAMPLE_DIR/../../bin"
PSEUDO_DIR="$SAMPLE_DIR/pseudo"
RESULTS_DIR="$SAMPLE_DIR/results"
TMP_DIR="$SAMPLE_DIR/results/tmp"

echo "BIN_DIR is set to: $BIN_DIR"
echo "PSEUDO_DIR is set to: $PSEUDO_DIR"
echo "RESULTS_DIR is set to: $RESULTS_DIR"
echo "TMP_DIR is set to: $TMP_DIR"

# check existing bin and pseudo directory
echo -e "Checking directories..."
for DIR in "$BIN_DIR" "$PSEUDO_DIR" ; do
    if test ! -d $DIR ; then
        echo -e
        echo -e "ERROR: $DIR not existent or not a directory"
        echo -e "Aborting"
        exit 1
    fi
done
echo -e "Done."

# check for pw.x in bin directory
echo -e "Checking for pw.x..."
if test ! -x $BIN_DIR/pw.x ; then
    echo -e "ERROR: $BIN_DIR/pw.x not found or not executable"
    echo -e "Aborting..."
    exit 1
fi
echo -e "Done."

# check pseudofile in pseudo bin
echo -e "Checking for pseudofiles..."
for FILE in $PSEUDO_INPUT ; do
    if test ! -r $PSEUDO_DIR/$FILE ; then
        echo -e "ERROR: $PSEUDO_DIR/$FILE not existent or not readable"
        echo -e "Aborting..."
        exit 1
    fi
done
echo -e "Done."

# remove all contents in tmp directory
echo -e "Cleaning temporary directory..."
rm -rf $TMP_DIR/*
echo -e "Done.\n"

echo -e "################### Running calculations ########################"

cd $RESULTS_DIR

PW_COMMAND="$PARA_PREFIX $BIN_DIR/pw.x $PARA_POSTFIX"

echo -e "\nExtracting core wavefunctions from pseudofile..."
$SAMPLE_DIR/../tools/upf2plotcore.sh $PSEUDO_DIR/$PSEUDO_INPUT > $NAME.wfc
echo -e "Done."

echo -e "Performing SCF calculations on $SCF_INPUT..."
$PW_COMMAND < $SCF_INPUT > $NAME.scf.out
check_failure $?
echo -e "Done.\n"

end_time=`date +%s`
runtime=$((end_time - start_time))
hours=$((runtime / 3600))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( (runtime % 3600) % 60 ))

echo "SCF Runtime: $hours:$minutes:$seconds (hh:mm:ss)"

echo -e "SCF output (scf.out) and core wavefunction (.cfw) file located in $RESULTS_DIR "
