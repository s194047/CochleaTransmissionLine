#!/bin/sh
julia --project=. scripts/run_ctl.jl --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/solver_params_1s_initial_20s.yaml \
    --stimulus-zero \
    --output-file data/solver_params_1s_initial_20s.jld2
