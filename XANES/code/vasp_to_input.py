
from striprtf.striprtf import rtf_to_text
import re
import matplotlib.pyplot as plt
import numpy as np

####################################################################################################
######################################### Helper Functions #########################################
####################################################################################################



def get_atomic_mass(element):

    # description: obtain atomic mass of given element 

    # arguments
    ## element: string abbreviation of element
    
    atomic_masses = {
        "H": 1.008, "He": 4.0026, "Li": 6.94, "Be": 9.0122, "B": 10.81, "C": 12.011, 
        "N": 14.007, "O": 15.999, "F": 18.998, "Ne": 20.180, "Na": 22.990, "Mg": 24.305,
        "Al": 26.982, "Si": 28.085, "P": 30.974, "S": 32.06, "Cl": 35.45, "Ar": 39.948,
        "K": 39.098, "Ca": 40.078, "Sc": 44.956, "Ti": 47.867, "V": 50.942, "Cr": 51.996,
        "Mn": 54.938, "Fe": 55.845, "Co": 58.933, "Ni": 58.693, "Cu": 63.546, "Zn": 65.38
        # Add more elements as needed
    }
    return atomic_masses.get(element, "Invalid element")


def get_atom_type(atom_index, atom_types, atom_counts):

    # description: obtains the atom type for a specific index in a VASP file 

    # arguments
    ## atom_index: index of target atom, numeric
    ## atom_types: list of atom types in VASP file, string
    ## atom_counts: list of atom counts per atom type in VASP file, string

    cumulative_count = 0  # Tracks the total number of atoms processed

    for i, count in enumerate(atom_counts):
        if atom_index < cumulative_count + count:
            return atom_types[i]  # found the correct element
        cumulative_count += count  # move to the next element group

    return None



####################################################################################################
###################################### Generate pw.x Input File ####################################
####################################################################################################


def scf_input(vasp_file, prefix, pseudofile_list, absorbing_atom_type, absorbing_atom_index, 
               ecutwfc = 30, pseudo_directory = '$PSEUDO_DIR/', out_directory = '$TMP_DIR/'):
    
    # description: converts VASP file into input for SCF calculations using pw.x for XANES
    # Notes: 
    ## VASP file must contain the following data: scaling factor, unscaled lattice vectors, 
    ## species names, ions per species and ion positions
    ## This function will work if also given more than one atom specie

    # arguments
    ## vasp_file: path to VASP file, string
    ## prefix: name of material, string
    ## pseudofile_list: list of pseudofiles, strings 
    ## absorbing_atom_type: the type of absorbing atom, string 
    ## absorbing_atom_index: the index of the absorbing atom in the coordinates beginning at 0, numeric
    ## ecutwfc: defines maximum kinetic energy cutoff for plane waves, numeric  
    ## pseudo_directory: location of pseudopotential, string
    ## out_directory: location of where to place output files from scf calculation, string

    lattice_vectors = ""
    coordinates = ""
    atom_types = []
    atom_counts = []
    atom_species = ""

    with open(vasp_file, "r") as file: 
        line_number = 1
        for line in file:
            values = line.split() 

            try: 
                n_values = list(map(float, values))
            except: 
                n_values = []

            if line_number == 2: # obtain scaling factor(s)
                scaling_factors = n_values
            elif line_number > 2 and line_number < 6: # store scaled lattice vectors 
                if len(scaling_factors) == 1: 
                    scaled_values = [v * scaling_factors[0] for v in n_values]
                else:
                    scaled_values = [n_values[i] * scaling_factors[i] for i in range(3)]
                lattice_vectors += f"{' '.join(map(str, scaled_values))}\n"
            elif line_number == 6: # obtain atom types and number of each atom type
                atom_types = values
                number_atom_types = f"{len(values) + 1}"
            elif line_number == 7: # obtain total number of atoms in the system
                atom_counts = list(map(int, values))
                number_atoms = f"{sum(n_values)}"
            elif line_number == 8: # determine coordinate type
                if values[0] == "Direct":
                    position_type = "crystal"
                else:
                    position_type = "angstrom"
            elif line_number > 8: # store atomic position coordinates in proper format
                atom_number = line_number - 9
                atom = get_atom_type(atom_number, atom_types, atom_counts)

                # label the correct absorbing atom 
                if atom_number == absorbing_atom_index:
                    if atom == absorbing_atom_type:
                        atom = atom + '_h'
                    else:
                        raise ValueError("Invalid index for absorbing atom.")

                if position_type == "angstrom":
                    if len(scaling_factors) == 1: # scale coordinates 
                        scaled_values = [v * scaling_factors[0] for v in n_values]
                    else:
                        scaled_values = [n_values[i] * scaling_factors[i] for i in range(3)]
                    coordinates += f"{atom} {' '.join(map(str, scaled_values))}\n"
                else:   
                    coordinates += f"{atom} {' '.join(map(str, n_values))}\n"
            line_number +=1
            
        # check if valid index for absorbing atom 
        if (line_number - 10) < absorbing_atom_index:
            raise ValueError("Invalid index for absorbing atom.")

    # match pseudofiles to atom type
    pseudo_dict = dict(zip(atom_types, pseudofile_list))

    # create atomic species with atom type, atomic mass and pseudofiles 
    for index, atom in enumerate(atom_types):
        atomic_mass = get_atomic_mass(atom)
        atom_pseudofile = pseudo_dict[atom]
        atom_species += atom + f" {atomic_mass} " + atom_pseudofile + "\n"

    atom_species += absorbing_atom_type + '_h' + f" {get_atomic_mass(absorbing_atom_type)} " + pseudo_dict[absorbing_atom_type] + "\n"
    
    control = " &control\n    calculation='scf',\n    pseudo_dir='" + pseudo_directory + "',\n    outdir='" + out_directory + "',\n    prefix='" + prefix + "',\n /\n"
    system = " &system\n    ibrav=0,\n    nat=" + number_atoms + ",\n    ntyp=" + number_atom_types + ",\n    ecutwfc=" + f"{ecutwfc}" + ",\n /\n" 
    electrons = " &electrons\n /\n"
    atomic_species = "ATOMIC_SPECIES\n" + atom_species 
    atomic_positions = "ATOMIC_POSITIONS " + position_type +"\n" + coordinates 
    k_points = "K_POINTS gamma\n"
    cell_parameters = "CELL_PARAMETERS angstrom\n" + lattice_vectors
    
    scf_input = control + system + electrons + atomic_species + atomic_positions + k_points + cell_parameters

    output_file = prefix + ".scf.in"
    
    with open(output_file, 'w') as file:
        file.write(scf_input)



####################################################################################################
################################## Generate xspectra.x Input File ##################################
####################################################################################################



def xspectra_input(cwf_file, prefix, out_directory = '$TMP_DIR/', absorbing_atom_index = 1, kpoints = '1 1 1 0 0 0', edge = 'K', 
                   xnepoint = 100, xemax = 10, xemin = 0, cut_occ_states = '.false.'):
    
    # description: create xspectra.x input file from calculated SCF data

    # arguments
    ## cwf_file: name of core wavefunction file, string 
    ## prefix: name of material, string
    ## out_directory: location of where to place output files, string 
    ## absorbing_atom_index: index of the ATOM TYPE of the absorbing atom from ATOMIC_SPECIES in scf.in file beginning at 1, numeric
    ## kpoints: specify grid of k-points as string containing 6 integers (ex. '1 1 1 0 0 0'), string
    ## edge: specify the edge to be calculated ('K', 'L2', 'L3', 'L23'), string
    ## xnepoint: number of energy points in XAS spectra, numeric
    ## xemax: maximum energy (eV) for XAS spectra, numeric
    ## xemin: minimum energy (eV) for XAS spectra, numeric
    ## cut_occ_states: determines whether to visualize occupied states ('.false.') or to cut out occupied states ('.true.'), string
    
    save_file = prefix + ".xspectra.sav"
    
    input_xspectra = " &input_xspectra\n    calculation='xanes_dipole',\n    edge='" + edge + "',\n    prefix='" + prefix + "',\n    outdir='" + out_directory + "',\n    x_save_file='" + save_file + "',\n    xiabs=" + f"{absorbing_atom_index},\n" + " /\n"
    plot = " &plot\n    xnepoint=" + f"{xnepoint}" + ",\n    xemin=" + f"{xemin}" + ",\n    xemax=" + f"{xemax}" + ",\n    cut_occ_states=" + f"{cut_occ_states}" + ",\n /\n"
    pseudos = " &pseudos\n    filecore='" + cwf_file + "',\n"
    cut_occ = " &cut_occ\n /\n"
    
    xspectra_input = input_xspectra + plot + pseudos + cut_occ + kpoints

    output_file = prefix + ".xspectra.in"
    
    with open(output_file, 'w') as file:
        file.write(xspectra_input)



####################################################################################################
###################################### Plot .dat spectra data ######################################
####################################################################################################



def extract_spectra_data(dat_file):

    # description: extracts energy and sigma data from a single dat_file

    # arguments
    ## dat_file: name of spectra data file, string 

    with open(dat_file, "r") as file:
        content = file.read()
        lines = content.splitlines()
        data = lines[3:]
        data = "\n".join(data)

    energy_values = []
    sigma_values = []

    for line in data.splitlines():
        match = re.match(r"([-]?\d+\.\d+)\s+(\d+\.\d+)", line.strip())
        if match:
            energy, sigma = map(float, match.groups())  # Convert to float
            energy_values.append(energy)
            sigma_values.append(sigma)
    
    return(energy_values, sigma_values)


def normalize_intensity(sigma):

    # description: normalize intensity to allow different spectras to be compared 

    normalized_intensity = sigma / np.max(sigma)
    return(normalized_intensity)


def plot_spectra(dat_file, prefix, E_core):
    
    # description: plots spectra data given a single dat_file

    # arguments
    ## dat_file: name of spectra data file, string 
    ## prefix: name of material, string
    ## E_core: energy to convert relative energy to photon energy, numeric 

    with open(dat_file, "r") as file:
        content = file.read()
        lines = content.splitlines()
        data = lines[3:]
        data = "\n".join(data)

    energy_values = []
    sigma_values = []

    for line in data.splitlines():
        match = re.match(r"([-]?\d+\.\d+)\s+(\d+\.\d+)", line.strip())
        if match:
            energy, sigma = map(float, match.groups())  # Convert to float
            energy_values.append(energy)
            sigma_values.append(sigma)

    energy_values = [x + E_core for x in energy_values]

    plt.plot(energy_values, sigma_values, linestyle='-', color='k')

    plt.xlabel("Energy (eV)", fontsize=12)
    plt.ylabel("Sigma", fontsize=12)
    plt.title("XANES Spectrum for " + f"{prefix}", fontsize=14)
    plt.legend()

    plt.show()