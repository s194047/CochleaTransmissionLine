#!/bin/sh

INPUT_DIR=params/solver_params/initial_conditions
OUTPUT_BASE_DIR=data/initial_conditions/jld2
LOG_BASE_DIR=data/initial_conditions/log

ROUGH_SUFFIX=rough
NO_ROUGH_SUFFIX=no_rough

run_script.py -i $INPUT_DIR -g generate_initial_conditions*.yaml \
    -o $OUTPUT_BASE_DIR/$ROUGH_SUFFIX -O jld2 -L $LOG_BASE_DIR/$ROUGH_SUFFIX \
    -S $ROUGH_SUFFIX -p 3 -- \
    julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGH_SUFFIX.yaml \
        --solver-params-file {i} \
        --stimulus-zero \
        --only-save-last-interval \
        --output-file {o} &

run_script.py -i $INPUT_DIR -g generate_initial_conditions*.yaml \
    -o $OUTPUT_BASE_DIR/$NO_ROUGH_SUFFIX -O jld2 -L $LOG_BASE_DIR/$NO_ROUGH_SUFFIX \
    -S $ROUGH_SUFFIX -p 3 -- \
    julia --project=. scripts/run_ctl.jl --model-constants-file model_constants_$ROUGH_SUFFIX.yaml \
        --solver-params-file {i} \
        --stimulus-zero \
        --only-save-last-interval \
        --output-file {o} &

wait
