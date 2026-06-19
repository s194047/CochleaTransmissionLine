#!/usr/bin/env bash
set -euo pipefail

export IC_DURATION=100
export FREQUENCY=1000

: "${DATA_DIR:=data}"
: "${FIGURE_DIR:=${DATA_DIR}/figures}"

for roughness in rough no_rough; do
    for onset_ramp_time in 0.000 0.100; do
        for duration in 1 10 100; do
            SUFFIX="duration-${duration}__onset_ramp_time-${onset_ramp_time}__ic_duration-${IC_DURATION}__roughness-${roughness}__saveat-2e-5__only_save_last_interval"

            julia --project=. scripts/plotting_scripts/plot_epp_2010_fig2.jl \
            -i "${DATA_DIR}/stimulus_sine/frequency-${FREQUENCY}__${SUFFIX}" \
            -o "${FIGURE_DIR}/epp_2010/fig_2__${SUFFIX}.pdf" &

            julia --project=. scripts/plotting_scripts/plot_epp_2010_fig3.jl \
            -i "${DATA_DIR}/stimulus_sine/frequency-${FREQUENCY}__${SUFFIX}" \
            -r 0.001 \
            -s 540 \
            -e 140 \
            -o "${FIGURE_DIR}/epp_2010/fig_3__${SUFFIX}.pdf" &
        done
    done
done

wait
