#!/bin/sh
### General options
### -- specify queue --
#BSUB -q hpc
### -- set the job Name --
#BSUB -J run_script_py
### -- ask for number of cores (default: 1) --
#BSUB -n 4
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

# Load modules needed by the application
module load julia/1.12.6

# Change directory to the cochleatransmissionline.jl directory
cd ~/MSc_project/cochleatransmissionline.jl

# Locate the run_script.py program
export RUN_SCRIPT_PY=~/MSc_project/run_script/run_script.py

# Define the input and output directories
export INPUT_DIR=~/MSc_project/speech_commands_v0.01
export OUTPUT_DIR=~/MSc_project/speech_commands_v0.01_processed

# Run the run_script.py program
$RUN_SCRIPT_PY -i $INPUT_DIR -o $OUTPUT_DIR -O jld2 -p 16 -n -- \
    julia --project=. scripts/run_ctl.jl \
    --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/solver_params_1s.yaml \
    --stimulus-audio-file {i} \
    --stimulus-audio-spl-target 60.0 \
    --stimulus-audio-spl-reference 0.001 \
    --output-file {o}
