#!/usr/bin/env zsh -e

# Source common definitions for speech command processing scripts.
SCRIPT_DIR=${0:a:h}
. "$SCRIPT_DIR/../common/speech_commands_common.sh"

# Directories for input, output and logs.
: "${INPUT_DIR:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/cochleogram/data"}"
: "${OUTPUT_ROOT:="$SPEECH_COMMANDS_ROOT/output/$RUN_ID/cochleogram_figures"}"
: "${OUTPUT_DIR:="$OUTPUT_ROOT/data"}"
: "${LOG_DIR:="$OUTPUT_ROOT/log"}"

# Load the Python virtual environment.
. "$SCRIPT_DIR/../../.venv/bin/activate"

# Ensure that Python requirements are satisfied.
pip -q install -r "$SCRIPT_DIR/../../requirements.txt"

# Run the run_script.py program
"$RUN_SCRIPT_PY" -i "$INPUT_DIR" -g "*.hdf5" -o "$OUTPUT_DIR" -O pdf -L "$LOG_DIR" \
    -S "" -p "$PARALLELISM" -T "$TOTAL_FILES" -- \
    "$SCRIPT_DIR/../../scripts/plotting_scripts/plot_cochleogram_data.py" \
    --input-file {i} \
    --output-file {o} \
    --figure-width-pts 452
