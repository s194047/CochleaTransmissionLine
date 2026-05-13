#!/usr/bin/env zsh

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/1s/1s_initial_template.yaml
: "${OUTPUT_DIR:=data/stimulus_zero}"
: "${INITIAL_CONDITIONS_DIR:=data/initial_conditions}"

>&2 echo "cwd: $(pwd)"
>&2 echo "OUTPUT_DIR: $OUTPUT_DIR"
>&2 echo "INITIAL_CONDITIONS_DIR: $INITIAL_CONDITIONS_DIR"

mkdir -p "$OUTPUT_DIR"

stimulus_zero_ctl() {
    (
        local ROUGHNESS=$1
        local INITIAL_LENGTH=$2
        local OUTPUT_FILE=$OUTPUT_DIR/stimulus_zero_initial_${INITIAL_LENGTH}_$ROUGHNESS.jld2
        export INITIAL_CONDITIONS_FILE="$INITIAL_CONDITIONS_DIR/initial_conditions_${INITIAL_LENGTH}_${ROUGHNESS}.jld2"

        echo "#### New run" >> "$OUTPUT_FILE.log"
        cat =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) >> "$OUTPUT_FILE.log"
        date >> "$OUTPUT_FILE.log"

        unbuffer julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGHNESS.yaml \
            --solver-params-file =(envsubst < $SOLVER_PARAMS_TEMPLATE_FILE) \
            --stimulus-zero \
            --output-file "$OUTPUT_FILE" \
            &>> "$OUTPUT_FILE.log"
    )
}

for roughness in rough no_rough; do
    for initial_length in 5s 20s 100s; do
        stimulus_zero_ctl "$roughness" "$initial_length" &
    done
done

wait
