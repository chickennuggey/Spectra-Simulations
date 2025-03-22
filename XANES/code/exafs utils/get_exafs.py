#!/usr/bin/env python
#SBATCH --exclude=agate-17,agate-41,agate-42,agate-10,agate-16,agate-18,agate-19,agate-26,agate-28,agate-29,agate-40,agate-43
#SBATCH --nodes=1 --partition=med
#SBATCH --ntasks-per-node=16
#SBATCH --ntasks-per-core=1
#SBATCH --threads-per-core=1
#SBATCH --output=job.out
#SBATCH --error=job.err
#SBATCH --time=198:00:00
#SBATCH --verbose

import os, sys
from copy import copy, deepcopy
from ase.neighborlist import natural_cutoffs, NeighborList, mic
from ase.io import read, write
from ase.db import connect
import traceback
import pickle
import time
import larch
from ase.visualize import view
from numpy import gradient, ndarray, diff, where, arange, argmin
import matplotlib.pyplot as plt
from larch.wxlib import plotlabels as plab
from larch.fitting import guess, group2params, param_group, param
from larch.xafs import feffrunner, feffpath, feff6l, feff8l
from larch.xafs import feffit, TransformGroup, FeffitDataSet, feffit_report, feffit_transform, pre_edge
from larch.xafs import feffdat, ff2chi, path2chi, xftf
import numpy as np
from scipy.interpolate import CubicSpline
import similaritymeasures
from larch.io import read_athena
from larch import Group, isNamedClass, Parameter
from larch.xafs import FeffPathGroup
from larch.xafs.feffit import (TransformGroup, FeffitDataSet, feffit, feffit_report)
from lmfit import Parameters, Parameter as param, Minimizer
from larch.xafs import feffrunner, feffpath, feff6l, feff8l
from larch.xafs import autobk
import matplotlib.pyplot as plt
from wxmplot.interactive import plot
import wx
from larch.wxlib.xafsplots import plot_chifit
import glob
import re
import matplotlib.pylab as pylab
from itertools import islice
sys.path.insert(0, '/home/gjw123/MoS3_amorphous/EXAFS')
from atoms2feff_adv import atoms2cluster, cluster2feffinp, edge2hole

params = {'legend.fontsize': 'x-large',
         'axes.labelsize': 'x-large',
         'axes.titlesize':'x-large',
         'xtick.labelsize':'x-large',
         'ytick.labelsize':'x-large',
         'axes.linewidth': 1.5}
pylab.rcParams.update(params)

def read_experimental_data(filename, verbose=False, plot_expt=False):
    project = read_athena(filename)
    expt_data = {}
    renaming_group_map = {}
    group_count = 0    
    for name, data in project._athena_groups.items():
        autobk(data.energy, data.mu, group=data, rbkg=0.8, kweight=2, kmax=10) 
        expt_data[name] = data
    if verbose:
        for attr in dir(data):
            print(attr, type(getattr(data, attr)))
    if plot_expt:
        plt.plot(data.k, data.chi*data.k**3, label='$\chi$')
        plt.xlabel(r'$k\, ({\rm\AA})^{-1}$')
        plt.ylabel(r'$k^3\chi, ({\rm\AA})^{-2}$')
        plt.legend()
        plt.show()
    return expt_data


def get_center_atom_index(atom_type, atoms):
    atom_index = [a.index for a in atoms if a.symbol == atom_type]
    cop = np.mean(atoms.positions, 0) 
    
    dist_list = []
    for index in atom_index:
        dist_list.append(mic(atoms[index].position - cop, atoms.cell))
    dist_list = np.linalg.norm(dist_list, axis=1)
    return atom_index[np.argmin(dist_list)]


def get_path_details():
    path_dict = {}
    with open('./paths.dat', 'r') as texts:
        lines = [line.strip() for line in texts]
        for i, line in enumerate(lines):
            if 'index, nleg, degeneracy' in line:
                path, nleg = [int(x) for x in line.split()[0:2]]
                reff = float(line.split()[-1])
                # print(path, nleg, reff)

                details = []
                for sub_line in lines[ i+2 : i+2 + nleg ]:
                    label = sub_line.split()[4][1:]
                    rleg = float(sub_line.split()[6])
                    details.append([label, rleg])
                    # print(label, rleg)
                path_dict[path] = {'nleg': nleg, 'reff': reff, 'details': details}
    return path_dict


def atoms2report(atoms, atom_type, center_atom_index=None):
    edge, title, output_fname = 'K', 'EXAFS', 'feff.inp'
    if center_atom_index is None:
        center_atom_index = get_center_atom_index(atom_type, atoms) 
    atoms_cluster, center_atom_index = atoms2cluster(atoms, center_atom_index, distance_cutoff=8.0)
    cluster2feffinp(atoms_cluster, atom_type, center_atom_index, title, edge, output_fname) 
    
    copy_cluster = deepcopy(atoms_cluster)
    copy_cluster[center_atom_index].symbol = 'Na' # symbol of center atom changed 
    write('cluster.traj', copy_cluster) # write file for new cluster 

    hole = edge2hole(edge) # where missing electron 
    feff6l(feffinp='./feff.inp') # run FEFF calculation  # NEED TO CHANGE THIS 
    
    # path_dict = get_path_details()
    paths = []
    for path_name in glob.glob('./feff*.dat'):
        paths.append(feffpath(path_name)) # obtain scattering paths 
    
    data = paths[0]
    ff2chi(paths, group=data, kstep=0.01) # convert paths to chi data (EXAF signal)
    xftf(k=data.k, chi=data.chi, group=data) # fourier transform to obtain information
    
    data_dict = {'k': data.k, 'r': data.r, 'chi': data.chi, 'chir': data.chir, 'chir_im': data.chir_im} # save dictionary with data 
    with open('data_raw.pickle', 'wb') as f: # open file for writing 
        pickle.dump(data_dict, f) # saves data to file 

    """
    fig, ax = plt.subplots(2, 1, figsize=(6, 6))
    ax[0].plot([0, 20], [0, 0], ':', color='gray', alpha=0.5)
    ax[0].plot(data.k, data.chi*data.k**2, color='black', label='|data|')
    ax[0].set_xlim([0, 20])
    ax[0].set_xlabel(r' $ k \rm\, (\AA^{-1})$')
    ax[0].set_ylabel(r'$ k^2\chi(k)$')
    ax[0].legend()

    ax[1].plot([0, 5], [0, 0], ':', color='gray', alpha=0.5)
    # ax[1].plot(data.r, [abs(x) for x in data.chir], color='blue', label='Re|data|')
    # ax[1].plot(data.r, [abs(x) for x in data.chir_im], '--', color='green', label='Im|data|', alpha=0.5)
    ax[1].plot(data.r, data.chir, color='blue', label='Re|data|')
    ax[1].plot(data.r, data.chir_im, '--', color='green', label='Im|data|', alpha=0.5)
    ax[1].set_xlabel(plab.r)
    ax[1].set_ylabel(plab.chir.format(4))
    ax[1].set_xlim([0, 5])
    ax[1].legend()
    
    plt.tight_layout()
    # plt.savefig('R-space.svg')
    plt.show()
    """


######################################################################################################################
wd = os.getcwd()
atoms = read('start.traj', '0')
index_Si = [a.index for a in atoms if a.symbol == 'Si'] 
index_O = [a.index for a in atoms if a.symbol == 'O']

for index in index_Si[::10] + index_O[::10]:
    symbol = atoms[index].symbol
    os.system(f'mkdir {index:04d}_{symbol}')
    os.chdir(f'{index:04d}_{symbol}')
    atoms2report(deepcopy(atoms), atom_type=symbol, center_atom_index=index)
    os.chdir(wd)








