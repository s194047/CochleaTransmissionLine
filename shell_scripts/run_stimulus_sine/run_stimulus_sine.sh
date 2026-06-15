#!/usr/bin/env zsh
set -euo pipefail

# Root for data to be processed and for writing the output.
: "${DATA_ROOT:=data}"

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/template.yaml

: "${OUTPUT_DIR:=${DATA_ROOT}/stimulus_sine}"
: "${IC_DURATION:=100}"
: "${ROUGHNESS:=rough}"
: "${INITIAL_CONDITIONS_FILE:=${DATA_ROOT}/initial_conditions/initial_conditions_${IC_DURATION}s_${ROUGHNESS}.jld2}"
: "${FREQUENCY:=1000}"
: "${DURATION:=1.000}"
: "${ONSET_RAMP_TIME:=0.000}"
: "${SAVEAT:=2e-5}"

RUN_ID="frequency-${FREQUENCY}__duration-${DURATION}__onset_ramp_time-${ONSET_RAMP_TIME}__ic_duration-${IC_DURATION}__roughness-${ROUGHNESS}__saveat-${SAVEAT}"

>&2 echo "cwd: $(pwd)"
>&2 echo "OUTPUT_DIR: $OUTPUT_DIR"
>&2 echo "INITIAL_CONDITIONS_FILE: $INITIAL_CONDITIONS_FILE"

mkdir -p "$OUTPUT_DIR"

stimulus_sine_1000_ctl() {
    (
        local AMPLITUDE=$1
        local OUTPUT_FILE=$OUTPUT_DIR/${RUN_ID}/${RUN_ID}__amplitude-${AMPLITUDE}.jld2
        export INITIAL_CONDITIONS_FILE
        export SAVEAT
        export DURATION

        echo "#### New run" >> "$OUTPUT_FILE.log"
        cat =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) >> "$OUTPUT_FILE.log"
        date >> "$OUTPUT_FILE.log"

        unbuffer julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_rough.yaml \
            --solver-params-file =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) \
            --stimulus-sine-frequency "$FREQUENCY" --stimulus-sine-amplitude "$AMPLITUDE" \
            --stimulus-onset-ramp-time "$ONSET_RAMP_TIME" \
            --output-file "$OUTPUT_FILE" \
            &>> "$OUTPUT_FILE.log"
    )
}

for exp_x2 in {-6..6}; do
    amplitude=$(awk "BEGIN {print 10^($exp_x2/2)}")
    stimulus_sine_1000_ctl "$amplitude" &
done

wait
