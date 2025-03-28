# Code Scripts

# Bash

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

| Bash Scripts | Description | Arguments  | 
| --- | --- | --- |
| `utils` | `update_input`: modifies parameter values in existing input file or new file | `update_input`<br/>1. input file<br/>2. parameter<br/>3.new value<br/>4. new file (optional)|
| `scf` | performs SCF calculations | 1. pw.x input file (.scf.in)<br/>2. pseudofile |
| `xanes` | performs XANES calculations | 1. xspectra.x input file (.xspectra.in)|
| `xanes_crystal` | performs SCF & XANES calculations for all atoms | 1. pw.x input file(.scf.in)<br/>2. pseudofile<br/>3. xspectra.x input file (.xspectra.in)|
| `xanes_amorphous` (NOT DONE) | performs SCF & XANES calculations for central atoms within 3 Å | 1. pw.x input file(.scf.in)<br/>2. pseudofile<br/>3. xspectra.x input file (.xspectra.in) |

**Additional Notes**
* `xanes_amorphous` currently only works with lattice parameter, A
* Always ensure there is output from `scf` before using `xanes` 
* The first atom should be labeled as the absorbing atom in `xanes_amorphous` and `xanes_crystal` to ensure all atoms are looped through and checked

## Python 

### vasp_to_input.py

| Function | Description |
| --- | --- | 
| `get_atomic_mas` | Returns atomic mass of given element symbol |
| `get_atom_type` | Returns atom type for a specific index in a VASP file |
| `scf_input` | Converts VASP file into a pw.x input file (.scf.in) |
| `xspectra_input` | Generates xspectra.x input file(.xspectra.in) |
| `xps_input` (NOT DONE) | Generates molecularnexafs input file (.molecularnexafs.in) |
| `extract_spectra_data` | Extracts energy and intensity from .dat file |
| `normalize_intensity` | Normalizes intensity to allow comparison of spectras |
| `plot_spectra` | Plots a single spectra from a single .dat file |
| `average_spectra` | Averages the intensity of multiple .dat files |

