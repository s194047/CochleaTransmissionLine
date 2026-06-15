#!/usr/bin/env bash
set -euo pipefail
set -x

export IC_DURATION=100
export FREQUENCY=1000

for roughness in rough no_rough; do
    for onset_ramp_time in 0.000 0.100; do
        for duration in 1 10 100; do
            ROUGHNESS=$roughness DURATION=$duration ONSET_RAMP_TIME=$onset_ramp_time \
            bsub < shell_scripts/run_stimulus_sine/run_stimulus_sine_hpc.sh
        done
    done
done
