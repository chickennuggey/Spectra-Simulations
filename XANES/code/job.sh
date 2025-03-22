{\rtf1\ansi\ansicpg1252\cocoartf2639
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red0\green0\blue0;}
{\*\expandedcolortbl;;\csgray\c0;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx560\tx1120\tx1680\tx2240\tx2800\tx3360\tx3920\tx4480\tx5040\tx5600\tx6160\tx6720\pardirnatural\partightenfactor0

\f0\fs22 \cf2 \CocoaLigature0 #!/bin/bash -l\
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
