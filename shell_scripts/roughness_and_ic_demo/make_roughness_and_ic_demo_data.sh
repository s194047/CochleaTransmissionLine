#!/usr/bin/env zsh

SOLVER_PARAMS_TEMPLATE_FILE=params/solver_params/1s/1s_initial_template.yaml
: "${OUTPUT_DIR:=data/stimulus_zero}"

>&2 echo "OUTPUT_DIR: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

stimulus_zero_ctl() {
    (
        export ROUGHNESS=$1
        export INITIAL_LENGTH=$2
        export OUTPUT_FILE=$OUTPUT_DIR/stimulus_zero_initial_${INITIAL_LENGTH}_$ROUGHNESS.jld2
        julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGHNESS.yaml \
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
