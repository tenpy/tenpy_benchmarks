#!/bin/bash
#SBATCH --job-name={jobname}
#SBATCH --chdir=./
#SBATCH --output=./{jobname}.%J.out  # %J=jobid.step, %N=node.
#
# To support getting emails, adjust the following two lines and remove the `# `,i.e. make them start with `#SBATCH `
# #SBATCH --mail-type fail  # or `fail,end`, but it's not recommended
# #SBATCH --mail-user your.email@tum.de  # adjust...
# NOTE: use ONLY YOUR UNIVERSITY EMAIL, DON'T USE/FORWARD EMAIL to other email providers like gmail.com!
# You can get a lot of emails from the cluster, and other email providers then sometimes mark the whole university as sending spam.
# This might results in your professor not being able to write emails to his friends anymore...
{requirements}

set -e  # abort whole script if any command fails

# === prepare the environement as necessary ===
# module load python/3.7
# conda activate tenpy
{environment_setup}


ORIG_DIR=$(pwd)

echo "SLURM_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK"
for NTHREADS in 64 32 16 8 4 2 1
do 
	if [[ $(($NTHREADS * 2)) -le $SLURM_CPUS_PER_TASK  ]]
	then
		export OMP_NUM_THREADS=$NTHREADS  # number of CPUs per node, total for all the tasks below.
		export MKL_DYNAMIC=FALSE
		export MKL_NUM_THREADS=$NTHREADS  # number of CPUs per node, total for all the tasks below.

		RUN_DIR="$ORIG_DIR/nthreads_$NTHREADS"
		mkdir -p "$RUN_DIR"
		cd "$RUN_DIR"

		echo -e "Running task {task_id}\nspecified in {config_file} on $HOSTNAME at $(date) with $NTHREADS threads\nin folder $RUN_DIR"
		echo "TENPY_OPTIMIZE=$TENPY_OPTIMIZE"
		echo "MKL_NUM_THREADS=$MKL_NUM_THREADS"
		echo "OMP_NUM_THREADS=$OMP_NUM_THREADS"
		python "{cluster_jobs_module}" run "$ORIG_DIR/{config_file}" {task_id}
		#     &> "{jobname}.task_{task_id}.out"
		# if you want to redirect output to file, you can append the following to the line above:
		echo "finished at $(date)"
	fi
done
