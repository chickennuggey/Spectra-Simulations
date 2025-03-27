# Code Scripts

## Python 

### vasp_to_input.py

**Purpose**: Contains list of functions needed to prepare input files for scf (pw.x) and XANES calculations (xspectra.x) along with additional functions to plot spectra data from .dat files. 

## Bash

**Instructions to Setup**:
1. Create a new directory to store your data for a specific material (qe-7.3.1/XSpectra/material)
2. Place these scripts in this directory (qe-7.3.1/XSpectra/material) and make it executable
3. Create subdirectories named results (qe-7.3.1/XSpectra/material/results) and pseudo (qe-7.3.1/XSpectra/material/pseudo) in this directory 
4. Create subdirectory named tmp in results (qe-7.3.1/XSpectra/material/results/tmp)
5. Place scf.in and xspectra.in in results (qe-7.3.1/XSpectra/material/results)
6. Place pseudofiles in pseudo (qe-7.3.1/XSpectra/material/results/pseudo)
7. Execute any of the following executables
8. Main outputs will be located in results directory
9. Additional outputs needed for xanes calculation will be located in tmp 

| Bash Scripts | Function | Arguments  | 
| --- | --- | --- |
| utils | contains useful functions | update_input<br/>1. input file\2. parameter\n3.new value\4. new file (optional)|
| scf | performs SCF calculations | |
| xanes | performs XANES calculations | |
| xanes_crystal | performs SCF & XANES calculations for all atoms | |
| xanes_amorphous | performs SCF & XANES calculations for central atoms within 3 Å | |

### scf.sh

**Function**: perform SCF calculations 

**Arguments**:
1. scf.in (pw.x input file)
2. .UPF (pseudofile)

### xanes.sh

**Function**: generate XANES spectra data (.dat) from SCF calculation

**Arguments**:
1. xspectra.in (xspectra.x input file)

**NOTE**: MAKE SURE YOU HAVE RAN pw.x BEFOREHAND

### xanes_crystal.sh

**Function**: generate XANES spectra data for all absorbing atoms

**Arguments**:
1. scf.in (pw.x input file)
2. .UPF (pseudofile)
3. xspectra.in (xspectra.x input file)

**NOTE**: MAKE SURE THE FIRST ATOM IS THE ABSORBING ATOM (to ensure all atoms are looped through)

### xanes_amorphous.sh

**Function**: generate XANES spectra data for central absorbing atoms within 3 Angstroms of the boundary

**Arguments**:
1. scf.in (pw.x input file)
2. .UPF (pseudofile)
3. xspectra.in (xspectra.x input file)

**NOTE**: MAKE SURE THE FIRST ATOM IS THE ABSORBING ATOM (to ensure all atoms are looped through)

### job.sh

**Function**: used to run scf or xanes calculations with higher performance in cluster
