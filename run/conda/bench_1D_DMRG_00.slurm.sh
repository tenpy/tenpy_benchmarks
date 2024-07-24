#!/bin/bash
#SBATCH --job-name=bench_1D_DMRG_00
#SBATCH --chdir=./
#SBATCH --output=./bench_1D_DMRG_00.%J.out  # %J=jobid.step, %N=node.
#
# To support getting emails, adjust the following two lines and remove the `# `,i.e. make them start with `#SBATCH `
# #SBATCH --mail-type fail  # or `fail,end`, but it's not recommended
# #SBATCH --mail-user your.email@tum.de  # adjust...
# NOTE: use ONLY YOUR UNIVERSITY EMAIL, DON'T USE/FORWARD EMAIL to other email providers like gmail.com!
# You can get a lot of emails from the cluster, and other email providers then sometimes mark the whole university as sending spam.
# This might results in your professor not being able to write emails to his friends anymore...
#SBATCH --time=0-12:00:00
#SBATCH --mem=30G
#SBATCH --partition=cpu
#SBATCH --qos=normal
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mail-type=FAIL
#SBATCH --nodelist=anderson[01-24]

set -e  # abort whole script if any command fails

# === prepare the environement as necessary ===
# module load python/3.7
# conda activate tenpy
eval "$(micromamba shell hook --shell bash )"
micromamba activate "${PROJECT_DIR}/env_conda"
# export TENPY_OPTIMIZE=3



ORIG_DIR=$(pwd)

for NTHREADS in 64 32 16 8 4 2 1
do 
	if [[ $NTHREADS -le $SLURM_CPUS_PER_TASK  ]]
	then
		export OMP_NUM_THREADS=$NTHREADS  # number of CPUs per node, total for all the tasks below.
		export MKL_DYNAMIC=FALSE
		export MKL_NUM_THREADS=$NTHREADS  # number of CPUs per node, total for all the tasks below.

		RUN_DIR="$ORIG_DIR/nthreads_$NTHREADS"
		mkdir -p "$RUN_DIR"
		cd "$RUN_DIR"

		echo -e "Running task 1\nspecified in bench_1D_DMRG_00.config.yml on $HOSTNAME at $(date) with $NTHREADS threads\nin folder $RUN_DIR"
		echo "TENPY_OPTIMIZE=$TENPY_OPTIMIZE"
		python "/space/ga93non/postdoc/2024-05-TeNPy_v1_paper/benchmarks/cluster_jobs.py" run "$ORIG_DIR/bench_1D_DMRG_00.config.yml" 1
		#     &> "bench_1D_DMRG_00.task_1.out"
		# if you want to redirect output to file, you can append the following to the line above:
		echo "finished at $(date)"
	fi
done
