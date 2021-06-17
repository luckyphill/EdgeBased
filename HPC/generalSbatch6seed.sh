#!/bin/bash 
#SBATCH -p batch 
#SBATCH -N 1 
#SBATCH -n 1 
#SBATCH --mem=4GB
# NOTIFICATIONS
#SBATCH --mail-type=ALL
#SBATCH --mail-user=phillip.j.brown@adelaide.edu.au

simName=$1 
paramFile=$2

# module load arch/haswell
# module load matlab

module load matlab/2020b

# export EDGEDIR='/hpcfs/users/a1738927/Research/EdgeBased'

echo "array_job_index: $SLURM_ARRAY_TASK_ID"

i=1 
found=0 
while IFS=, read a b c d e f seed
do 
    if [ $i = $SLURM_ARRAY_TASK_ID ]; then
        echo "Running $simName with [$a, $b, $c, $d, $e, $f] seed $seed"
        found=1 

        break 
    fi 
    i=$((i + 1)) 
done < $paramFile

if [ $found = 1 ]; then
	echo "matlab -nodisplay -nodesktop -r cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = $simName($a, $b, $c, $d, $e, $f, $seed); obj.GenerateSimulationData(); quit()"
    matlab -nodisplay -nodesktop -r "cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = $simName($a, $b, $c, $d, $e, $f, $seed); obj.GenerateSimulationData(); quit()"
else 
  echo "SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID is outside range of input file $paramFile" 
fi