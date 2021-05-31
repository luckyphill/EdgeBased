#!/bin/bash 
#SBATCH -p batch 
#SBATCH -N 1 
#SBATCH -n 1 
#SBATCH --mem=4GB
#SBATCH --array=1-20
#SBATCH --time=08:00:00
# NOTIFICATIONS
#SBATCH --mail-type=ALL
#SBATCH --mail-user=phillip.j.brown@adelaide.edu.au

module load matlab

echo "array_job_index: $SLURM_ARRAY_TASK_ID"

echo "matlab -nodisplay -nodesktop -r cd ../../; addpath(genpath(pwd)); obj = TumourInMembrane(5, 9, 9, 40, 0.9, 0.5, $SLURM_ARRAY_TASK_ID); obj.RunToTime(200); quit()"
matlab -nodisplay -nodesktop -r "cd ../../; addpath(genpath(pwd)); obj = TumourInMembrane(5, 9, 9, 40, 0.9, 0.5, $SLURM_ARRAY_TASK_ID); obj.RunToTime(200); quit()"
