#!/bin/sh
### General options
### -- specify queue --
#BSUB -q hpc
### -- set the job Name --
#BSUB -J run_script_py
### -- ask for number of cores (default: 1) --
#BSUB -n 16
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
module load python3/3.14.2
module load julia/1.12.6

# Change directory to the cochleatransmissionline.jl directory
cd ~/MSc_project/cochleatransmissionline.jl

# Locate the run_script.py program
RUN_SCRIPT_PY=~/MSc_project/run_script/run_script.py

INPUT_DIR=params/solver_params/initial_conditions
OUTPUT_BASE_DIR=/work3/s194047/initial_conditions/jld2
LOG_BASE_DIR=/work3/s194047/initial_conditions/log

ROUGH_SUFFIX=rough
NO_ROUGH_SUFFIX=no_rough

$RUN_SCRIPT_PY -i $INPUT_DIR -g generate_initial_conditions*.yaml \
    -o $OUTPUT_BASE_DIR/$ROUGH_SUFFIX -O jld2 -L $LOG_BASE_DIR/$ROUGH_SUFFIX \
    -S $ROUGH_SUFFIX -p 3 -- \
    julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGH_SUFFIX.yaml \
        --solver-params-file {i} \
        --stimulus-zero \
        --only-save-last-interval \
        --output-file {o} &

$RUN_SCRIPT_PY -i $INPUT_DIR -g generate_initial_conditions*.yaml \
    -o $OUTPUT_BASE_DIR/$NO_ROUGH_SUFFIX -O jld2 -L $LOG_BASE_DIR/$NO_ROUGH_SUFFIX \
    -S $ROUGH_SUFFIX -p 3 -- \
    julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGH_SUFFIX.yaml \
        --solver-params-file {i} \
        --stimulus-zero \
        --only-save-last-interval \
        --output-file {o} &

wait
