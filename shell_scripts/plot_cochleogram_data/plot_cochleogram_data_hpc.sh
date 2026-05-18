#!/bin/sh
### General options
### -- specify queue --
#BSUB -q hpc
### -- set the job Name --
#BSUB -J plot_cochleogram_data
### -- ask for number of cores (default: 1) --
#BSUB -n 32
### -- specify that the cores must be on the same host --
#BSUB -R "span[hosts=1]"
### -- specify that we need 4GB of memory per core/slot --
#BSUB -R "rusage[mem=4GB]"
### -- specify that we want the job to get killed if it exceeds 5 GB per core/slot --
#BSUB -M 5GB
### -- set walltime limit: hh:mm --
#BSUB -W 24:00
### -- set the email address --
# please uncomment the following line and put in your e-mail address,
# if you want to receive e-mail notifications on a non-default address
##BSUB -u your_email_address
### -- send notification at start --
#BSUB -B
### -- send notification at completion --
#BSUB -N
### -- Specify the output and error file. %J is the job-id --
### -- -o and -e mean append, -oo and -eo mean overwrite --
#BSUB -o Output_%J.out
#BSUB -e Output_%J.err

### Get environment variables
#BSUB -env "TOTAL_FILES,PARALLELISM,IC_DURATION,ROUGHNESS,SAVEAT"

# Load modules needed by the application
module load python3/3.14.2

# Change directory to the cochleatransmissionline.jl directory
cd ~/MSc_project/cochleatransmissionline.jl

# Overriding the location of the run_script.py program.
export RUN_SCRIPT_PY=~/MSc_project/run_script/run_script.py

# Overriding locations to data root on scratch space.
export DATA_ROOT=/work3/s194047/data

zsh -e shell_scripts/plot_cochleogram_data/plot_cochleogram_data.sh
