#!/usr/bin/env bash

trap 'kill $(jobs -p)' EXIT

run_script.py \
--parallelism 2 \
--input-folder /Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01_yes_no_up_down/yes \
--input-glob "*.wav" \
--output-folder /Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01_yes_no_up_down_processed/yes \
--output-extension jld2 -- \
julia --project=. scripts/run_ctl.jl \
--model-constants-file model_constants.yaml \
--solver-params-file params/solver_params_1s_wav.yaml \
--stimulus-audio-file {i} \
--output-file {o}
