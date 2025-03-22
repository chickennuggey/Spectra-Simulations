#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Math and data structures
import math
import numpy as np

# Crystalography modules
import ase
from ase.visualize import view
from ase.io import read, write
# X-ray modules
import larch
from xraylib import EdgeEnergy, SymbolToAtomicNumber


def atoms2cluster(atoms, absorbing_atom_index, distance_cutoff, is_DFT = True, DFT_rep = [2,2,1]):
    '''
    This atoms2cluster function creates a bigger cluster from a cif input file
    used in conjunction wiht cluster2feffinp

    Parameters
    ----------
    atoms : str
        atoms object in cif file format
    absorbing_atom_index : str
        index of atom in the atoms input that is the "core"
    distance_cutoff : float
        longest distance that an atom should be from the center of the cluster

    Returns
    -------
    atoms_cluster : ASE Atoms
        Atoms type of all atoms in the cluster defined by distance_cutoff.
    absorbing_atom_index : int
        index of the absorbing [core] atom in the atoms_cluster

    ''' 
    if is_DFT == True: 
        atoms2 = atoms#.repeat(DFT_rep) 
        cen_atom = atoms2[absorbing_atom_index].position # coordinates of central atom
        print('the input structure is DFT optimizied')
    else:    
        # repeat the unit cell to the nearest even repeat such that the the unit cell lenghts are at least 2x distance_cutoff
        rep = max([math.ceil(distance_cutoff/atoms.cell[0][0])*2, 
               math.ceil(distance_cutoff/atoms.cell[1][1])*2, 
               math.ceil(distance_cutoff/atoms.cell[2][2])*2])
        
        print(f"Crystal repeated {rep} time")
    
        # expand the unit cell
        atoms2 = atoms.repeat(rep)
        #view(atoms2)
    
        # define the center of the expanded unit cell
        cen_rep = [rep/2, rep/2, rep/2]
        #print(cen_rep)
    
        # define the center atom position of the unit cell
        cen_atom = np.sum(np.multiply(atoms.cell, cen_rep), axis = 0) + atoms[absorbing_atom_index].position
        print(f"Absorbing Atom Position: {cen_atom}")
    
    # Find new absorbing atom index
    absorbing_atom_index= [a.index for a in atoms2 if np.array_equal(a.position, cen_atom)]
    #print(f"Index of Absorbing Atom: {absorbing_atom_index}")

    # Remove atoms from model that are at a distance greater than distance_cutoff from the indexed atom
    atoms_cluster = atoms2[[a.index for a in atoms2 if atoms2.get_distance(absorbing_atom_index, a.index, mic=True) < distance_cutoff]]
    #view(atoms_cluster)

    
    # Update new absorbing atom index
    absorbing_atom_index= [a.index for a in atoms_cluster if np.array_equal(a.position, cen_atom)]
    print(f"Index of Absorbing Atom: {absorbing_atom_index}")
    
    
    return atoms_cluster, absorbing_atom_index[0]


def cluster2feffinp(cluster, atom_type, absorber_index, title, edge, output_file_name, r_max=5.0):
        # atoms, absorbing_atom, absorbing_atom_index, edge, title, output_file_name, distance_cutoff = 8.0, is_DFT = False, DFT_rep = [2,2,1], r_max = 5.0):
    '''
    Takes an atoms cluster, often from a cif file, and saves an feff6 input file based upon a clsuter size wiht radial distance of "distance_cutoff"

    atoms : ase Atoms
        atoms object to generate cluster and feff input file on
    absorbing_atom_index : int
        index of atom in atoms to be used as the absorber and "center" of cluster
    edge : str
        X-ray edge that feff will run at, e.g. K, L1, L2...
    title : str
        what the title line will say in the feff inp file. could be ''
    output_file_name : str
        path to save file at
    distance_cutoff : float, optional
        longest range the cluster will simulate out to. passed to atoms2cluster 
        The default is 8.0.
    is_DFT : bool, optional
        True if the atoms object is to not be scaled in one or more direction. passed to atoms2cluster. 
        The default is False.
    DFT_rep : list/array, optional
        limits that a defiend crystal is to be scaled. used in conjunction with is_def.
        passed to atoms2cluster. The default is [2,2,1].
    r_max : float, optional
        sets range to define feff6 calcualtion in the inp file. The default is 5.0.

    Returns
    -------
    cluster : ASE atoms object
        atoms object containing all atoms inside the cluster
        
    atoms_list : list
        list fo xyz coordiantes, ipot, tag, and radial distance from center atom.
        equivalent to the atoms table in the feff output file

    '''
    core, hole = atom_type, edge2hole(edge) 
    edge_energy = EdgeEnergy(SymbolToAtomicNumber(core), hole-1) * 1000
    print(edge_energy)
    
    
    symbol_list = list(np.unique([atom.symbol for atom in cluster]))
    if len(symbol_list) == 1:
        tags = atom_type
    else:
        tags = [atom_type+'0', atom_type+'1'] + [s for s in symbol_list if s != atom_type]
    print(tags)

    # NEED TO AUTOMATE THIS!!!!!
    # use seperate tags for the center Mo, and other Mos
    """
    if atom_type == 'Mo':
        tags = ['Mo0', 'Mo1', 'S']
    elif atom_type == 'S':
        tags = ['S0', 'S1', 'Mo']
    else:
        return 
    """

    potentials = {}
    for i, tag in enumerate(tags):
        if atom_type in tag:
            potentials[tag] = [i, SymbolToAtomicNumber(atom_type), tag]
        else:
            potentials[tag] = [i, SymbolToAtomicNumber(tag), tag]
    print(potentials)

    atoms_list = []
    for atom in cluster:   
        my_position = cluster.get_distance(absorber_index, atom.index, vector=True, mic=True) # .tolist()        
        my_distance = cluster.get_distance(absorber_index, atom.index, mic= True)
        
        if my_distance == 0:
            my_tag = atom_type + '0'
        else:
            if atom.symbol == atom_type:
                my_tag = atom_type + '1'
            else:
                my_tag = atom.symbol 
        my_pot = potentials.get(my_tag)[0] 

        info_list = [*my_position, my_pot, my_tag, my_distance]
        atoms_list.append([*my_position, my_pot, my_tag, my_distance])
    
    atoms_list.sort(key = lambda x: x[-1])


    file_text = f" TITLE     {title}\n"
    file_text += f" COREHOLE      {hole}   1.0  *  FYI: ({core} {edge} edge @ {edge_energy} eV, 2nd number is S0^2)\n"
    file_text += f" *         mphase,mpath,mfeff,mchi\n CONTROL   1      1     1     1     1     1\n PRINT     1      0     0     0\n"  
    file_text += f" RMAX      {r_max:.1f}\n * POLARIZATION  0   0   0\n"
    file_text += f" POTENTIALS\n  * ipot   Z      label\n"
    
    for line in potentials.values():
        file_text += f"    {line[0]}       {line[1]}       {line[2]}\n"
        
    
    file_text += f" ATOMS                  * this list contains {len(cluster)} atoms\n"
    file_text += f" *  x              y        z      ipot    tag     distance\n"
    # CHANGE ATOMS 
    # NEED TO ADD XANES
    # NEED TO ADD SCF
    # NEED TO ADD FMS 

    for line in atoms_list:
        file_text += f"{float(line[0]):11.5f}{float(line[1]):11.5f}{float(line[2]):11.5f}{int(line[3]):3d}       {line[4]}       {float(line[5]):.5f}\n"
    file_text += "END\n"

    with open (output_file_name, 'w') as file:
        file.write(file_text)

    print('Finished atoms2feff_inp')
    

def edge2hole(edge):
    #  convert the edge string into hole integer for feff6
    edges = ['K', 
             'L1', 'L2', 'L3', 
             'M1', 'M2', 'M3', 'M4', 'M5',
             'N1', 'N2', 'N3', 'N4', 'N5', 'N6', 'N7',
             'O1', 'O2', 'O3', 'O4', 'O5',
             'P1', 'P2', 'P3']
    hole = edges.index(edge) + 1    
    return hole


