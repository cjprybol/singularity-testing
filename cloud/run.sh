#!/bin/bash

# This is a very simple running script to execute a single container workflow.
# It will install Singularity, pull a container, and use it to run a series of scripts. 
# It was developed to run on Ubuntu 16.04 LTS, in a cloud environment, meaning we have
# sudo permissions to install dependencies, and will use Docker and Singularity
# For the HPC workflow, see the run.sh in the folder hpc


#########################################################################################
# Setup and Installation
#########################################################################################

# This is the Github repo with analysis
cd $HOME
git clone https://www.github.com/vsoch/singularity-scientific-example
cd singularity-scientific-example
export BASE=$HOME/singularity-scientific-example

# We assume if we are on local cluster, scratch exists
if [ -z "$SCRATCH" ]
then
    export SCRATCH=/scratch
fi

if [[ ! -d "$SCRATCH/data" ]]; then
    sudo mkdir -p $SCRATCH/data
    sudo chown $USER -R $SCRATCH
fi

# This will be our output/data directory
export WORKDIR=/scratch/data

# Let's export the working directory to return to later
export RUNDIR=$BASE

# Let's also make a logs directory to keep
mkdir $SCRATCH/logs

# Set max memory to use
export MEM=32g
export NUMCORES=4
export THREADS=8

# Setup of time and recording of other analysis data (see TIME.md)
export TIME_LOG=$SCRATCH/logs/stats.log
export TIME='%C\t%E\t%K\t%I\t%M\t%O\t%P\t%U\t%W\t%X\t%e\t%k\t%p\t%r\t%s\t%t\t%w\n'
echo -e 'COMMAND\tELAPSED_TIME_HMS\tAVERAGE_MEM\tFS_INPUTS\tMAX_RES_SIZE_KB\tFS_OUTPUTS\tPERC_CPU_ALLOCATED\tCPU_SECONDS_USED\tW_TIMES_SWAPPED\tSHARED_TEXT_KB\tELAPSED_TIME_SECONDS\tNUMBER_SIGNALS_DELIVERED\tAVG_UNSHARED_STACK_SIZE\tSOCKET_MSG_RECEIVED\tSOCKET_MSG_SENT\tAVG_RESIDENT_SET_SIZE\tCONTEXT_SWITCHES' > $TIME_LOG

# Run Singularity Analysis
bash $RUNDIR/scripts/runscript_singularity.sh

# Summarize Singularity results
bash $RUNDIR/scripts/summarize_results.sh /scratch/data > $SCRATCH/logs/singularity-files.log # Singularity
sed -i '/^$/d' $SCRATCH/logs/singularity-files.log

# Move data to different place, ready for Docker
sudo mv /scratch/data /scratch/singularity
# If more space is needed,we ran on 200GB drive
#sudo rm -rf /scratch/singularity/Fastq
#sudo rm -rf /scratch/singularity/Reference
#sudo rm -rf /scratch/singularity/Bam
#rm /scratch/singularity/RTG/HG*

mkdir -p /scratch/data

# Run Docker Analysis 
bash $RUNDIR/scripts/runscript_docker.sh

# Get hashes for all files in each directory
bash $RUNDIR/scripts/summarize_results.sh /scratch/data > $SCRATCH/logs/docker-files.log # Dockerfiles
sed -i '/^$/d' $SCRATCH/logs/docker-files.log
sed -i '/^$/d' $SCRATCH/logs/stats.log
