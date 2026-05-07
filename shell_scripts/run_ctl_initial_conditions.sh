#!/bin/sh
julia --project=. scripts/run_ctl.jl --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/generate_initial_conditions.yaml \
    --stimulus-zero \
    --only-save-last-interval \
    --output-file data/initial_conditions.jld2
