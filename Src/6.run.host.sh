#!/bin/bash
#SBATCH --partition euan,owners
#SBATCH --cpus-per-task 16
#SBATCH --mem 64G
#SBATCH --time 2-00:00:00
#SBATCH --export ALL
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user cjprybol@stanford.edu
#SBATCH --output slurm-6.host.out

/bin/bash 6.bwa_align.sh 126 host