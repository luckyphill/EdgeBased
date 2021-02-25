#!/bin/bash 
#SBATCH -p batch 
#SBATCH -N 1 
#SBATCH -n 1 
#SBATCH --mem=4GB
# NOTIFICATIONS
#SBATCH --mail-type=ALL
#SBATCH --mail-user=phillip.j.brown@adelaide.edu.au

paramFile=$1

module load arch/haswell
module load matlab

export EDGEDIR='/hpcfs/users/a1738927/Research/EdgeBased'

echo "array_job_index: $SLURM_ARRAY_TASK_ID"

i=1 
found=0 

while IFS=, read a b c d e f g h i
do 
	if [ $i = $SLURM_ARRAY_TASK_ID ]; then
		echo "Running $simName with [$a, $b, $c, $d, $e, $f, $g, $h, $i]"
		found=1 

		break 
	fi 
	i=$((i + 1)) 
done < $paramFile

if [ $found = 1 ]; then
	echo "matlab -nodisplay -nodesktop -r cd ../../; addpath(genpath(pwd)); obj = CryptStroma($a, $b, $c, $d, $e, $f, $g, $h, $i, 1); obj.RunToTime(300); quit()"
	matlab -nodisplay -nodesktop -r "cd ../../; addpath(genpath(pwd)); obj = CryptStroma($a, $b, $c, $d, $e, $f, $g, $h, $i, 1); obj.RunToTime(300); quit()"
else 
  echo "SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID is outside range of input file $paramFile" 
fi