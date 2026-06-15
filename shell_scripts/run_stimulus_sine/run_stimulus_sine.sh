#!/usr/bin/env zsh
set -euo pipefail

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/1s/1s_template.yaml
: "${OUTPUT_DIR:=data/stimulus_sine}"
: "${INITIAL_CONDITIONS_FILE:=data/initial_conditions/initial_conditions_100s_rough.jld2}"
: "${FREQUENCY:=1000}"

>&2 echo "cwd: $(pwd)"
>&2 echo "OUTPUT_DIR: $OUTPUT_DIR"
>&2 echo "INITIAL_CONDITIONS_FILE: $INITIAL_CONDITIONS_FILE"

mkdir -p "$OUTPUT_DIR"

stimulus_sine_1000_ctl() {
    (
        local AMPLITUDE=$1
        local OUTPUT_FILE=$OUTPUT_DIR/stimulus_sine_frequency_${FREQUENCY}_amplitude_${AMPLITUDE}.jld2
        export INITIAL_CONDITIONS_FILE
        export SAVEAT="2e-5"

        echo "#### New run" >> "$OUTPUT_FILE.log"
        cat =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) >> "$OUTPUT_FILE.log"
        date >> "$OUTPUT_FILE.log"

        unbuffer julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_rough.yaml \
            --solver-params-file =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) \
            --stimulus-sine-frequency $FREQUENCY --stimulus-sine-amplitude $AMPLITUDE \
            --output-file "$OUTPUT_FILE" \
            &>> "$OUTPUT_FILE.log"
    )
}


for exp_x2 in {-6..6}; do
    amplitude=$(awk "BEGIN {print 10^($exp_x2/2)}")
    stimulus_sine_1000_ctl "$amplitude" &
done

wait
