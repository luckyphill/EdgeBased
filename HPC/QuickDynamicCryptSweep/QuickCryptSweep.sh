#!/bin/bash 
#SBATCH -p batch 
#SBATCH -N 1 
#SBATCH -n 1 
#SBATCH --mem=4GB
#SBATCH --array=1-14
#SBATCH --time=24:00:00
# NOTIFICATIONS
#SBATCH --mail-type=ALL
#SBATCH --mail-user=phillip.j.brown@adelaide.edu.au

module load arch/haswell
module load matlab

export EDGEDIR='/hpcfs/users/a1738927/Research/EdgeBased'

echo "array_job_index: $SLURM_ARRAY_TASK_ID"

i=1 
found=0 

while IFS=, read a b c d e f g h j
do 
	if [ $i = $SLURM_ARRAY_TASK_ID ]; then
		echo "Running with [$a, $b, $c, $d, $e, $f, $g, $h, $j]"
		found=1 

		break 
	fi 
	i=$((i + 1)) 
done < QuickCryptSweep.txt

if [ $found = 1 ]; then
	echo "matlab -nodisplay -nodesktop -r cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = DynamicCrypt($a, $b, $c, $d, $e, $f, $g, $h, $j, 1); obj.RunToTime(300); v = Visualiser(obj); v.ProduceMovie([],[],'Motion JPEG AVI'); quit()"
	matlab -nodisplay -nodesktop -r "cd ../../; addpath(genpath([pwd,'/src']));addpath(genpath([pwd,'/HPC']));addpath(genpath([pwd,'/analysis'])); obj = DynamicCrypt($a, $b, $c, $d, $e, $f, $g, $h, $j, 1); obj.RunToTime(300); v = Visualiser(obj); v.ProduceMovie([],[],'Motion JPEG AVI'); quit()"
else 
  echo "SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID is outside range of input file" 
fi