#!/usr/bin/env zsh -e

# Check that required variables are defined.
: "${SUB_DIR:?ERROR: Must specify subdirectory to process}"

# Source common definitions for speech command processing scripts.
SCRIPT_DIR=${0:a:h}
. "$SCRIPT_DIR/../common/speech_commands_common.sh"

# SAVEAT needs to be exported to be available in subshell running envsubst.
[[ "$SAVEAT" == "no" ]] && { echo "ERROR: invalid SAVEAT value of 'no'"; exit 1; }
export SAVEAT

# Setup solver parameter file.
SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/1s/1s_template.yaml

# Setup solver initial conditions file.
: "${INITIAL_CONDITIONS_DIR:=${DATA_ROOT}/initial_conditions}"
INITIAL_CONDITIONS_FILENAME="initial_conditions_${IC_DURATION}s_${ROUGHNESS}.jld2"
export INITIAL_CONDITIONS_FILE="${INITIAL_CONDITIONS_DIR}/${INITIAL_CONDITIONS_FILENAME}"

# Setup solver model constants file.
MODEL_CONSTANTS_FILE=model_constants_${ROUGHNESS}.yaml

# Directories for input, output and logs.
: "${INPUT_DIR:="$SPEECH_COMMANDS_ROOT/input/$SUB_DIR"}"
: "${OUTPUT_ROOT:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/ctl"}"
: "${OUTPUT_DIR:="$OUTPUT_ROOT/data/$SUB_DIR"}"
: "${LOG_DIR:="$OUTPUT_ROOT/log/$SUB_DIR"}"

# Run the run_script.py program
"$RUN_SCRIPT_PY" -i "$INPUT_DIR" -g "*.wav" -o "$OUTPUT_DIR" -O jld2 -L "$LOG_DIR" \
    -S "__$RUN_ID" -p "$PARALLELISM" -T "$TOTAL_FILES" -- \
    julia --project=. scripts/run_ctl.jl \
    --model-constants-file "$MODEL_CONSTANTS_FILE" \
    --solver-params-file =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) \
    --stimulus-audio-file {i} \
    --stimulus-spl-target ${SPL_TARGET} \
    --stimulus-spl-reference ${SPL_REFERENCE} \
    --output-file {o}
