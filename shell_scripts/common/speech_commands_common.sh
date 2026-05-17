# Source this into scripts processing speech commands.

: "${TOTAL_FILES:?ERROR: Must specify total number of files to process}"
: "${PARALLELISM:?ERROR: Must specify number of parallel processes}"

# Locate the run_script.py program.
# Assume the script is in PATH as default.
: "${RUN_SCRIPT_PY:=run_script.py}"

# Parameters
# (Parameters expanded in subshell must be exported.)
: "${SPL_TARGET:=60.0}"
: "${SPL_REFERENCE:=0.001}"
: "${IC_DURATION:=100}"
: "${ROUGHNESS:=rough}"
: "${SAVEAT:=2e-5}"

# Root for data to be processed and for writing the output.
: "${DATA_ROOT:=data}"

# Root for speech command input and output.
: "${SPEECH_COMMANDS_ROOT:=${DATA_ROOT}/speech_commands_v0.01_up_down_yes_no}"

# Construct name for run dir containing all parameters in the name.
RUN_ID="spl_target-${SPL_TARGET}__spl_reference-${SPL_REFERENCE}__ic_duration-${IC_DURATION}__roughness-${ROUGHNESS}__saveat-${SAVEAT}"
