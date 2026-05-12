#!/bin/sh
julia --project=. scripts/run_ctl.jl --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/solver_params_1s_initial_100s.yaml \
    --stimulus-zero \
    --output-file data/solver_params_1s_initial_100s.jld2
