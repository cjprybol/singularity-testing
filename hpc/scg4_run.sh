#!/bin/bash

# This is a very simple running script to execute a single container workflow.
# It will install Singularity, pull a container, and use it to run a series of scripts.
# It was developed to run on an HPC SGE cluster, scg4.stanford.edu at Stanford

#########################################################################################
# Setup and Installation
#########################################################################################

# This is the Github repo with analysis
cd $HOME
# git clone https://www.github.com/vsoch/singularity-scientific-example
# cd singularity-scientific-example
git clone git@github.com:cjprybol/singularity-testing.git
cd singularity-testing
export BASE=$PWD
export RUNDIR=$BASE/hpc

# for scg4 at stanford
module load singularity/jan2017master

# Analysis parameters
THREADS=16
MEM=64G

# We have to specify out output directory on scratch
# Defined the following in ~/.bashrc
# SCRATCH=/srv/gsfs0/scratch/cjprybol
mkdir $SCRATCH/data

# This will be our output/data directory
export WORKDIR=$SCRATCH/data

# Let's also make a logs directory to keep
mkdir $SCRATCH/logs

# Setup of time and recording of other analysis data (see TIME.md)
# Setup of time and recording of other analysis data (see TIME.md)
export TIME_LOG=$SCRATCH/logs/stats.log
export TIME='%C\t%E\t%K\t%I\t%M\t%O\t%P\t%U\t%W\t%X\t%e\t%k\t%p\t%r\t%s\t%t\t%w\n'
echo -e 'COMMAND\tELAPSED_TIME_HMS\tAVERAGE_MEM\tFS_INPUTS\tMAX_RES_SIZE_KB\tFS_OUTPUTS\tPERC_CPU_ALLOCATED\tCPU_SECONDS_USED\tW_TIMES_SWAPPED\tSHARED_TEXT_KB\tELAPSED_TIME_SECONDS\tNUMBER_SIGNALS_DELIVERED\tAVG_UNSHARED_STACK_SIZE\tSOCKET_MSG_RECEIVED\tSOCKET_MSG_SENT\tAVG_RESIDENT_SET_SIZE\tCONTEXT_SWITCHES' > $TIME_LOG

# Download the container to rundir
cd $SCRATCH/data
singularity pull shub://vsoch/singularity-scientific-example
image=$(ls *.img)
mv $image analysis.img
chmod u+x analysis.img

single=$(qsub -S /bin/sh -j y -R y -V -w e -m bea -M cjprybol@stanford.edu -l h_vmem=4 -pe shm 1 -l h_rt=48:00:00)
multithread=$(qsub -S /bin/sh -j y -R y -V -w e -m bea -M cjprybol@stanford.edu -l h_vmem=$MEM -pe shm $THREADS -l h_rt=48:00:00)

one=$($single singularity exec -B $SCRATCH:/scratch $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/1.download_data.sh /scratch/data)
echo $one
two=$($single -W depend=afterok:$one singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/2.simulate_reads.sh /scratch/data)
echo $two
three=$($single -W depend=afterok:$two singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/3.generate_transcriptome_index.sh /scratch/data)
echo $three
four=$($multithread -W depend=afterok:$three singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/4.quantify_transcripts.sh /scratch/data $THREADS)
echo $four
five=$($single -W depend=afterok:$four singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/5.bwa_index.sh /scratch/data)
echo $five
six=$($multithread -W depend=afterok:$five singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/6.bwa_align.sh /scratch/data $THREADS)
echo $six
seven=$($single -W depend=afterok:$six singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/7.prepare_rtg_run.sh /scratch/data)
echo $seven
eight=$($multithread -W depend=afterok:$seven singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/8.map_trio.sh /scratch/data $MEM $THREADS)
echo $eight
nine=$($multithread -W depend=afterok:$eight singularity exec -B $SCRATCH/data:/scratch/data $SCRATCH/data/analysis.img /usr/bin/time -a -o $TIME_LOG bash $BASE/scripts/9.family_call_variants.sh /scratch/data $MEM $THREADS)
echo $nine
ten=$($single -W depend=afterok:$nine bash $RUNDIR/scripts/summarize_results.sh /scratch/data > $SCRATCH/logs/singularity-files.log)
echo $ten
eleven=$($single -W depend=afterok:$ten sed -i '/^$/d' $SCRATCH/logs/singularity-files.log)
echo $eleven
