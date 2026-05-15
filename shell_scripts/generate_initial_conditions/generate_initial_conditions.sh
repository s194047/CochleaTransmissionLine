#!/usr/bin/env zsh

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/initial_conditions/initial_conditions_template.yaml
: "${OUTPUT_DIR:=data/initial_conditions}"

>&2 echo "cwd: $(pwd)"
>&2 echo "OUTPUT_DIR: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

initial_conditions_ctl() {
    (
        local ROUGHNESS=$1
        local INITIAL_LENGTH_SECS=${2}s
        export INITIAL_LENGTH_FLOAT=${2}.000
        local OUTPUT_FILE=$OUTPUT_DIR/initial_conditions_${INITIAL_LENGTH_SECS}_${ROUGHNESS}.jld2

        echo "#### New run" >> "$OUTPUT_FILE.log"
        date >> "$OUTPUT_FILE.log"

        unbuffer julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_${ROUGHNESS}.yaml \
            --solver-params-file =(envsubst < "$SOLVER_PARAMS_TEMPLATE_FILE") \
            --stimulus-zero \
            --only-save-last-interval \
            --output-file "$OUTPUT_FILE" \
            &>> "$OUTPUT_FILE.log"
    )
}

for roughness in rough no_rough; do
    for initial_length in 5 20 100; do
        initial_conditions_ctl "$roughness" "$initial_length" &
    done
done

wait
