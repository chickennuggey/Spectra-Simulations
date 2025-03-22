# Code Scripts

## Python 

### vasp_to_input.py

**Purpose**: Contains list of functions needed to prepare input files for scf (pw.x) and XANES calculations (xspectra.x) along with additional functions to plot spectra data from .dat files. 

## Bash Executables

### scf.sh

**Function**: perform SCF calculations 

Arguments:
- 1st argument is scf.in file (make sure the directories in the scf.in match)
- 2nd argument is pseudofile

Instructions:
1. Create a new directory to store your data for a specific material (qe-7.3.1/XSpectra/material)
2. Place this script in this directory (qe-7.3.1/XSpectra/material) and make it executable
3. Create subdirectories named results (qe-7.3.1/XSpectra/material/results) and pseudo (qe-7.3.1/XSpectra/material/pseudo) in this directory 
4. Create subdirectory named tmp in results (qe-7.3.1/XSpectra/material/results/tmp)
5. Place scf.in and xspectra.in in results (qe-7.3.1/XSpectra/material/results)
6. Place pseudofiles in pseudo (qe-7.3.1/XSpectra/material/results/pseudo)
7. Execute the following command: ./scf material.scf.in pseudofile
8. Main outputs will be located in results including scf.out and .cfw
9. Additional outputs needed for xanes calculation will be located in tmp 

### xanes.sh

**Function**: generate XANES spectra data (.dat) from SCF calculation

Arguments:
- 1st argument is xspectra.in file (make sure the directories in xspectra.in match)

Instructions:
1. Make sure you have followed the instructions given above (creating directories, etc.)
2. Make sure you have run scf properly and you have scf.out and .cfw in the results directory and additional outputs in tmp directory 
3. Place this script in qe-7.3.1/XSpectra/material and make it executable
4. Place xspectra.in in results (qe-7.3.1/XSpectra/material/results)
5. Execute the following command: ./xanes material.xspectra.in
6. Main outputs will be located in results including xspectra.out and .dat

### job.sh

**Function**: used to run scf or xanes calculations with higher performance

Instructions:
1. Adjust the input arguments for ./scf in the script
2. Can add xanes calculation as well, but xspectra.x usually runs pretty fast and doesn't need a lot of memory 
