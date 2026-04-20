#!/bin/zsh
julia --project=. scripts/run_ctl.jl \
    --model-constants-file model_constants.yaml --solver-params-file params/solver_params/solver_params_1s.yaml \
    --stimulus-audio-file /Users/sofus/Documents/DTU/MSc_project/speech_commands_v0.01/up/0a7c2a8d_nohash_0.wav \
    --stimulus-audio-spl-target 70 --stimulus-audio-spl-reference 1e-3 \
    --output-file data/audio_test.jld2
