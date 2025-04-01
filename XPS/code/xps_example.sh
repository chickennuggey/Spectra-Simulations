#!/bin/sh 

# pyridine
../src/molecularnexafs.x < pyridine.xps.in > pyridine.xps.out 2> pyridine.xps.err
# diamond
../src/molecularnexafs.x < diamond.xps.in > diamond.xps.out 2> diamond.xps.err
# amorphous carbon
