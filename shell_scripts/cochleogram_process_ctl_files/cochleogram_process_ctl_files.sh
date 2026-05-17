#!/usr/bin/env zsh -e

# Source common definitions for speech command processing scripts.
SCRIPT_DIR=${0:a:h}
. "$SCRIPT_DIR/../common/speech_commands_common.sh"

# Set parameters for analysis window.
: "${WINDOW_LENGTH_SECONDS:=0.020}"
: "${WINDOW_HOP_SECONDS:=0.010}"

# Directories for input, output and logs.
: "${INPUT_DIR:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/ctl/data"}"
: "${OUTPUT_ROOT:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/cochleogram"}"
: "${OUTPUT_DIR:="$OUTPUT_ROOT/data"}"
: "${LOG_DIR:="$OUTPUT_ROOT/log"}"

WINDOW_PARAMS_SUFFIX="__window_length-${WINDOW_LENGTH_SECONDS}s__window_hop-${WINDOW_HOP_SECONDS}s"

# Optional resampling.
SAMPLE_RATE_ARGS=()
if [[ "$SAVEAT" == "no" ]]; then
    SAMPLE_RATE_ARGS+=(--sample-rate 50000)
fi

# Run the run_script.py program
"$RUN_SCRIPT_PY" -i "$INPUT_DIR" -g "*.jld2" -o "$OUTPUT_DIR" -O hdf5 -L "$LOG_DIR" \
    -S "$WINDOW_PARAMS_SUFFIX" -p "$PARALLELISM" -T "$TOTAL_FILES" -- \
    julia --project=. scripts/make_cochleogram_data.jl \
    --input-file {i} \
    --output-file {o} \
    "${SAMPLE_RATE_ARGS[@]}" \
    --window-length-seconds ${WINDOW_LENGTH_SECONDS} \
    --window-hop-seconds ${WINDOW_HOP_SECONDS}
