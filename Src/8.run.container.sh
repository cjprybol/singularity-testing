#!/bin/bash
#SBATCH --partition euan,owners
#SBATCH --cpus-per-task 16
#SBATCH --mem 128G
#SBATCH --time 2-00:00:00
#SBATCH --export ALL
#SBATCH --mail-type BEGIN,END,FAIL
#SBATCH --mail-user cjprybol@stanford.edu
#SBATCH --output slurm-8.container.out

singularity exec v0.1.5.img bash 8.map_trio.sh 116 16 container