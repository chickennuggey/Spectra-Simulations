#!/bin/sh 

start_time=`date +%s` 

# check inputs 
if [ -z "$1" ]; then
    echo "Error: Please enter a xspectra.x input file."
    exit 1
fi

cd `dirname $0`
SAMPLE_DIR=`pwd`

# save inputs
X_INPUT="$1"
NAME="${X_INPUT%.xspectra.in}"

echo -e "###### This script will run xspectra.x for $X_INPUT ##########"

echo -e "\nXSpectra input is $X_INPUT"
echo -e "Name of material is $NAME\n"

echo -e "########### Loading in necessary variables and checking data #####################"

echo -e "\nLoading in environment variables..."
. ../../environment_variables 
echo -e "Done."

BIN_DIR="$SAMPLE_DIR/../../bin/"
RESULTS_DIR="$SAMPLE_DIR/results"
TMP_DIR="$SAMPLE_DIR/results/tmp"

echo -e "Checking directories..."
for DIR in "$BIN_DIR" "$TMP_DIR" "$RESULTS_DIR" ; do
    if test ! -d $DIR ; then
        echo -e "ERROR: $DIR not existent or not a directory"
        echo -e "Aborting..."
        exit 1
    fi
done
echo -e "Done."

echo -e "Checking for xspectra.x..."
if test ! -x $BIN_DIR/xspectra.x ; then
    echo -e "ERROR: $BIN_DIR/pw.x not existent or not executable"
    echo -e "Aborting..."
    !exit 1
fi
echo -e "Done.\n"

echo -e "############## Running calculations #######################"


X_COMMAND="$PARA_PREFIX $BIN_DIR/xspectra.x $PARA_POSTFIX"

cd $RESULTS_DIR

echo -e "\nPerforming XSpectra calculations on $X_INPUT..."
$X_COMMAND < $X_INPUT > $NAME.xspectra.out
check_failure $?
mv xanes.dat $NAME.xspectra.dat
echo -e "Done.\n"

end_time=`date +%s`
runtime=$((end_time - start_time))
hours=$((runtime / 3600))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( (runtime % 3600) % 60 ))

echo "XSpectra Runtime: $hours:$minutes:$seconds (hh:mm:ss)"

echo -e "XSpectra output file (.xspectra.out, .xspectra.dat) located in $RESULTS_DIR "
