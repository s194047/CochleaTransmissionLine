#!/usr/bin/env zsh

# Check that required variables are defined.
: "${SUB_DIR:?ERROR: Must specify subdirectory to process}"
: "${TOTAL_FILES:?ERROR: Must specify total number of files to process}"
: "${PARALLELISM:?ERROR: Must specify number of parallel processes}"

# Locate the run_script.py program.
# Assume the script is in PATH as default.
: "${RUN_SCRIPT_PY:=run_script.py}"

# Parameters
# (Paremeters expanded in subshell must be exported.)
: "${SPL_TARGET:=60.0}"
: "${SPL_REFERENCE=0.001}"
: "${IC_DURATION=100}"
: "${ROUGHNESS=rough}"
export SAVEAT="${SAVEAT:-2e-5}"

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/1s/1s_template.yaml

# Root for data to be processed and for writing the output.
: "${DATA_ROOT:=data}"

: "${INITIAL_CONDITIONS_DIR:=${DATA_ROOT}/initial_conditions}"
INITIAL_CONDITIONS_FILENAME="initial_conditions_${IC_DURATION}s_${ROUGHNESS}.jld2"
export INITIAL_CONDITIONS_FILE="${INITIAL_CONDITIONS_DIR}/${INITIAL_CONDITIONS_FILENAME}"

MODEL_CONSTANTS_FILE=model_constants_${ROUGHNESS}.yaml

# Root for speech command input and output.
: "${SPEECH_COMMANDS_ROOT:=${DATA_ROOT}/speech_commands_v0.01_up_down_yes_no}"

# Construct name for run dir containing all parameters in the name.
SAVEAT_NAME="${SAVEAT:-no}"
RUN_ID="spl_target-${SPL_TARGET}__spl_ref-${SPL_REF}__ic_duration-${IC_DURATION}__roughness-${ROUGHNESS}__saveat-${SAVEAT_NAME}"

# Directories for input, output and logs.
: "${INPUT_DIR:="$SPEECH_COMMANDS_ROOT/input/$SUB_DIR"}"
: "${OUTPUT_ROOT:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/ctl"}"
: "${OUTPUT_DIR:="$OUTPUT_ROOT/data/$SUB_DIR"}"
: "${LOG_DIR:="$OUTPUT_ROOT/log/$SUB_DIR"}"

# Log parameters to stderr.


# Run the run_script.py program
"$RUN_SCRIPT_PY" -i "$INPUT_DIR" -g "*.wav" -o "$OUTPUT_DIR" -O jld2 -L "$LOG_DIR" \
    -S "$RUN_ID" -p "$PARALLELISM" -T "$TOTAL_FILES" -- \
    julia --project=. scripts/run_ctl.jl \
    --model-constants-file "$MODEL_CONSTANTS_FILE" \
    --solver-params-file =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) \
    --stimulus-audio-file {i} \
    --stimulus-spl-target ${SPL_TARGET} \
    --stimulus-spl-reference ${SPL_REFERENCE} \
    --output-file {o}
