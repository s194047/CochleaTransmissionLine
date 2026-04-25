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

### Get environment variables
#BSUB -env "SUB_DIR,TOTAL_FILES,PARALLELISM"
# Check that variables are defined
: "${SUB_DIR:?ERROR: Must specify subdirectory to process}"
: "${TOTAL_FILES:?ERROR: Must specify total number of files to process}"
: "${PARALLELISM:?ERROR: Must specify number of parallel processes}"

# Load modules needed by the application
module load python3/3.14.2
module load julia/1.12.6

# Change directory to the cochleatransmissionline.jl directory
cd ~/MSc_project/cochleatransmissionline.jl

# Locate the run_script.py program
RUN_SCRIPT_PY=~/MSc_project/run_script/run_script.py

# Parameters
SPL_TARGET="60.0"
SPL_REFERENCE="0.001"

# Define the input and output directories
INPUT_DIR=/work3/s194047/speech_commands_v0.01_up_down_yes_no/input/$SUB_DIR
OUTPUT_DIR=/work3/s194047/speech_commands_v0.01_up_down_yes_no/output/jld2/$SUB_DIR
LOG_DIR=/work3/s194047/speech_commands_v0.01_up_down_yes_no/output/log/$SUB_DIR

# Run the run_script.py program
$RUN_SCRIPT_PY -i $INPUT_DIR -g "*.wav" -o $OUTPUT_DIR -O jld2 -L $LOG_DIR \
    -S spl_target_${SPL_TARGET}dB_ref_${SPL_REFERENCE} -p $PARALLELISM -T $TOTAL_FILES -- \
    julia --project=. scripts/run_ctl.jl \
    --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/solver_params_1s.yaml \
    --stimulus-audio-file {i} \
    --stimulus-audio-spl-target ${SPL_TARGET} \
    --stimulus-audio-spl-reference ${SPL_REFERENCE} \
    --output-file {o}
