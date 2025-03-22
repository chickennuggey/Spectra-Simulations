{\rtf1\ansi\ansicpg1252\cocoartf2639
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red0\green0\blue0;}
{\*\expandedcolortbl;;\csgray\c0;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx560\tx1120\tx1680\tx2240\tx2800\tx3360\tx3920\tx4480\tx5040\tx5600\tx6160\tx6720\pardirnatural\partightenfactor0

\f0\fs22 \cf2 \CocoaLigature0 #!/bin/sh \
\
cd `dirname $0`\
SAMPLE_DIR=`pwd`\
\
X_INPUT="$1"\
NAME="$\{X_INPUT%.xspectra.in\}"\
\
echo -e "\\n###### This script will run xspectra.x for $X_INPUT given that SCF has been calculated ###########\\n"\
\
\
echo -e "\\n\\nXSpectra input is $X_INPUT"\
echo -e "Name of material is $NAME \\n\\n"\
\
\
echo -e "\\n########### Loading in necessary variables and checking data #####################\\n"\
\
\
echo -e "\\nLoading in environment variables..."\
. ../../environment_variables \
echo -e "Done.\\n"\
\
BIN_DIR="$SAMPLE_DIR/../../bin/"\
RESULTS_DIR="$SAMPLE_DIR/results"\
TMP_DIR="$SAMPLE_DIR/results/tmp"\
\
echo -e "\\nChecking directories..."\
for DIR in "$BIN_DIR" "$TMP_DIR" "$RESULTS_DIR" ; do\
    if test ! -d $DIR ; then\
        echo -e "ERROR: $DIR not existent or not a directory"\
        echo -e "Aborting..."\
        exit 1\
    fi\
done\
echo -e "Done.\\n"\
\
echo -e "\\nChecking for xspectra.x..."\
if test ! -x $BIN_DIR/xspectra.x ; then\
    echo -e "ERROR: $BIN_DIR/pw.x not existent or not executable"\
    echo -e "Aborting..."\
    !exit 1\
fi\
echo -e "Done.\\n"\
\
echo -e "\\n############## Running calculations #######################\\n"\
\
\
X_COMMAND="$PARA_PREFIX $BIN_DIR/xspectra.x $PARA_POSTFIX"\
\
cd $RESULTS_DIR\
\
echo -e "\\n\\nPerforming XSpectra calculations on $X_INPUT..."\
$X_COMMAND < $X_INPUT > $NAME.xspectra.out\
check_failure $?\
mv xanes.dat $NAME.xspectra.dat\
echo -e "Done.\\n"\
\
echo -e "\\nXSpectra output file located in $RESULTS_DIR \\n"}