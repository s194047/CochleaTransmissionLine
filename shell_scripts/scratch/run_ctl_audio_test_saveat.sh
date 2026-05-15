#!/bin/sh
julia --project=. scripts/run_ctl.jl \
    --model-constants-file model_constants.yaml --solver-params-file params/solver_params/solver_params_1s_saveat.yaml \
    --stimulus-audio-file /Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01/up/0a7c2a8d_nohash_0.wav \
    --stimulus-spl-target 60 --stimulus-spl-reference 1e-3 \
    --output-file data/audio_test_saveat.jld2
