#!/bin/zsh
julia --project=. scripts/run_ctl.jl --model-constants-file model_constants.yaml \
    --solver-params-file params/solver_params/solver_params_1s.yaml \
    --stimulus-params-file params/stimulus_params/zero_stimulus.yaml \
    --output-file data/zero_stimulus_1s.jld2
