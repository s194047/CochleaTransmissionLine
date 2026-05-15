#!/bin/sh
julia --project=. scripts/run_ctl.jl \
    --model-constants-file model_constants_rough.yaml --solver-params-file params/solver_params/solver_params_1s.yaml \
    --stimulus-sine-frequency 1000 \
    --stimulus-spl-target 60 --stimulus-spl-reference 1e-3 \
    --output-file data/test.jld2
