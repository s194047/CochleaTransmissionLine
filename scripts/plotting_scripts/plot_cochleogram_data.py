#!/usr/bin/env python3

import h5py
import json
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import pathlib
import argparse
from typing import Final

matplotlib.use("Agg")

PT_PER_INCH: Final = 72.27
FIGURE_ASPECT_RATIO: Final = 4 / 3

def parse_args() -> argparse.Namespace:
    arg_parser = argparse.ArgumentParser()

    arg_parser.add_argument(
        "--input-file", "-i",
        type=pathlib.Path,
        metavar="PATH",
        required=True,
        help="Path to HDF5 file containing cochleogram derived data.",
    )
    arg_parser.add_argument(
        "--metadata-input-file", "-m",
        type=pathlib.Path,
        metavar="PATH",
        help="Path to JSON file with metadata. If not set, use `[--input-file].metadata.json`.",
    )
    arg_parser.add_argument(
        "--output-file", "-o",
        type=pathlib.Path,
        metavar="PATH",
        required=True,
        help="Path to output image file. Type is inferred by Matplotlib from the file's extension.",
    )
    arg_parser.add_argument(
        "--figure-width-pts", "-w",
        type=float,
        metavar="FLOAT",
        required=True,
        help="Width of generated image in LaTeX unit pt (1/72.27 in).",
    )

    parsed_args = arg_parser.parse_args()

    if parsed_args.metadata_input_file is None:
        parsed_args.metadata_input_file = parsed_args.input_file.with_name(parsed_args.input_file.name + ".metadata.json")

    return parsed_args

def main() -> None:
    parsed_args = parse_args()

    # Read HDF5 file
    with h5py.File(parsed_args.input_file, "r") as f:
        def get_dataset(key: str) -> h5py.Dataset:
            assert isinstance(f, h5py.File)
            dataset = f[key]
            assert isinstance(dataset, h5py.Dataset)
            return dataset

        n_samples_dataset                          = get_dataset("n_samples")
        window_length_samples_dataset              = get_dataset("window_length_samples")
        window_hop_samples_dataset                 = get_dataset("window_hop_samples")
        window_start_idxs_dataset                  = get_dataset("window_start_idxs")
        window_y_rms_values_dataset                = get_dataset("window_y_rms_values")
        window_v_rms_values_dataset                = get_dataset("window_v_rms_values")
        window_winding_frequency_values_dataset    = get_dataset("window_winding_frequency_values")
        window_rotation_frequency_values_dataset   = get_dataset("window_rotation_frequency_values")

        n_samples                           = n_samples_dataset[()]
        window_length_samples               = window_length_samples_dataset[()]
        window_hop_samples                  = window_hop_samples_dataset[()]
        window_start_idxs                   = window_start_idxs_dataset[:]
        window_y_rms_values                 = window_y_rms_values_dataset[:]
        window_v_rms_values                 = window_v_rms_values_dataset[:]
        window_winding_frequency_values     = window_winding_frequency_values_dataset[:]
        window_rotation_frequency_values    = window_rotation_frequency_values_dataset[:]

    # Read JSON file
    with open(parsed_args.metadata_input_file) as f:
        metadata = json.load(f)

    # Calculate extent of the time axis (t).
    # We are displaying overlapping time windows as non-overlapping pixels.
    # The tick marks are at the beginning of a window.
    window_start_idxs_zeroindexed = window_start_idxs - 1
    sample_rate = metadata["fs"]
    window_start_times_seconds = window_start_idxs_zeroindexed / sample_rate
    window_hop_seconds = metadata["window_hop_seconds"]
    window_length_seconds = metadata["window_length_seconds"]
    first_time_tick = window_start_times_seconds[0]
    last_time_tick = window_start_times_seconds[-1] + window_length_seconds - window_hop_seconds

    # Calculate extent of the Basilar Membrane (BM) position axis (x).
    # There are n points, where the first is exactly at 0 and the last is exaclty at x_apex_value.
    # We calculate the distance between points, dx, since we need to align points with pixel centers.
    x_apex_value = metadata["ctl_metadata"]["model_constants"]["x_apex_value"]
    n = metadata["ctl_metadata"]["model_constants"]["n"]
    dx = x_apex_value / n

    # Combine extents to be used in plots.
    extent = [
        first_time_tick,
        last_time_tick,
        x_apex_value + 0.5 * dx,
        0.0 - 0.5 * dx
    ]

    # Calculate figure width and height in inches.
    fig_width_inches = parsed_args.figure_width_pts / PT_PER_INCH
    fig_height_inches = fig_width_inches / FIGURE_ASPECT_RATIO

    # Make four subplots.
    fig, axs = plt.subplots(2, 2, figsize=(fig_width_inches, fig_height_inches), sharex=True, sharey=True, layout="constrained")

    axs[0, 0].imshow(window_y_rms_values, aspect="auto", extent=extent)
    axs[0, 0].set_title("y RMS")

    axs[0, 1].imshow(window_v_rms_values, aspect="auto", extent=extent)
    axs[0, 1].set_title("v RMS")

    axs[1, 0].imshow(np.abs(window_winding_frequency_values / (2 * np.pi)), aspect="auto", extent=extent)
    axs[1, 0].set_title("Winding")

    axs[1, 1].imshow(np.abs(window_rotation_frequency_values / (2 * np.pi)), aspect="auto", extent=extent)
    axs[1, 1].set_title("Rotation")

    fig.supxlabel("time / s")
    fig.supylabel("distance from stapes / m")

    # Save figure.
    fig.savefig(parsed_args.output_file)

if __name__ == "__main__":
    main()
