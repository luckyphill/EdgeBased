#!/bin/bash 
#SBATCH -p batch 
#SBATCH -N 1 
#SBATCH -n 1 
#SBATCH --mem=4GB
#SBATCH --time=12:00:00
# NOTIFICATIONS
#SBATCH --mail-type=ALL
#SBATCH --mail-user=phillip.j.brown@adelaide.edu.au

module load matlab/2020b

echo "matlab -nodisplay -nodesktop -r cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = BucklingModes(); obj.LoadSimulationData(0); obj.PlotData; quit()"
matlab -nodisplay -nodesktop -r "cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = BucklingModes(); obj.LoadSimulationData(0); obj.PlotData; quit()"

