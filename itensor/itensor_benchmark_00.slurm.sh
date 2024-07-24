#!/bin/bash
#SBATCH --job-name=itensor_benchmark_00
#SBATCH --chdir=./
#SBATCH --output=./itensor_benchmark_00.%A_%3a.out  # %J=jobid.step, %N=node.
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
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mail-type=FAIL
#SBATCH --nodelist=anderson[01-24]

set -e  # abort whole script if any command fails

# === prepare the environement as necessary ===
# module load python/3.7
# conda activate tenpy


# When requesting --cpus-per-task 32 on nodes with CPU hyperthreading,
# slurm will allocate the job 32 threads = 16 cores x 2 threads per core.
# For numerical applications, e.g MKL functions like BLAS/LAPACK functions, it is better to ignore
# hyperthreading and rather set NUM_THREADS to the number of physical cores.
# Hence we divide by 2 here:
export OMP_NUM_THREADS=$(($SLURM_CPUS_PER_TASK / 2 ))  # number of CPUs per node, total for all the tasks below.
export MKL_DYNAMIC=FALSE
export MKL_NUM_THREADS=$(( $SLURM_CPUS_PER_TASK / 2 ))  # number of CPUs per node, total for all the tasks below.
export NUMBA_NUM_THREADS=$(( $SLURM_CPUS_PER_TASK / 2))

echo "Running task 1 2 3 4 specified in itensor_benchmark_00.config.yml on $HOSTNAME at $(date)"
python /space/ga93non/postdoc/2024-05-TeNPy_v1_paper/benchmarks/cluster_jobs.py run itensor_benchmark_00.config.yml 1 2 3 4
# if you want to redirect output to file, you can append the following to the line above:
#     &> "itensor_benchmark_00.task_1 2 3 4.out"
echo "finished at $(date)"
