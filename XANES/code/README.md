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
| `utils` | contains useful functions | `update_input`<br/>1. input file<br/>2. parameter<br/>3.new value<br/>4. new file (optional)|
| `scf` | performs SCF calculations | 1. pw.x input file (.scf.in)<br/>2. pseudofile |
| `xanes` | performs XANES calculations | 1. xspectra.x input file (.xspectra.in)|
| `xanes_crystal` | performs SCF & XANES calculations for all atoms | 1. pw.x input file(.scf.in)<br/>2. pseudofile<br/>3. xspectra.x input file (.xspectra.in)|
| `xanes_amorphous` | performs SCF & XANES calculations for central atoms within 3 Å | 1. pw.x input file(.scf.in)<br/>2. pseudofile<br/>3. xspectra.x input file (.xspectra.in) |

**Additional Notes**
* Always ensure there is output from `scf` before using `xanes` 
* The first atom should be labeled as the absorbing atom in `xanes_amorphous` and `xanes_crystal` to ensure all atoms are looped through and checked

### job.sh

**Function**: used to run scf or xanes calculations with higher performance in cluster
