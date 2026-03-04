# Cochlea Transmission Line

This repo is a MWE implementation of the Epp 2010 cochlea model for experimenting with the final implementation.

## Running the model

To run the model, execute the script `scripts/run_ctl.jl`. The script takes arguments `--model-constants-file FILENAME` for a YAML file containing model constants, `--solver-params-file FILENAME` for a YAML file containing solver configuration and `-o, --output-file FILENAME` for the -o, --output-file FILENAME output JLD2 file containing time series data of the simulation.
```sh
usage: run_ctl.jl --model-constants-file FILENAME
                  --solver-params-file FILENAME
                  [--stimulus-params-file FILENAME]
                  [--stimulus-audio-file FILENAME]
                  [--stimulus-audio-gain FLOAT]
                  [--stimulus-audio-onset-ramp-time FLOAT] -o FILENAME
```

The configuration file defines the model parameters and solver parameters as well as a destination to save the data after a run.
See `params/test.yaml` for an example configuration file.
```sh
julia --project=. scripts/run_ctl.jl params/example.yaml
```

## To be implemented / investigated
- Make recipes, julia scripts or shell scripts for the plots that I want to use in the report.
    - Potentially, `make` is a good way to generate data and plots by tracking dependency of YAML, JLD2 and figures.
    - To reduce redundancy and to make running more flexible (especially with `make`), we should have the data output filename as a parameter rather than a field in the YAML file.
- Decide whether it's possible to serialize a callable `ODESolution` object.
- Look into a more flexible way to simulate long timespans by splitting up the original timespan into shorter chunks and solving sequentially (without saving and reloading solutions, just keeping them as variables).
- Update the `example.yaml` file to show all possible options and comment it as necessary.
    - Add a section to this README file to explain all features.
- Should we calculate the derivative inside the `run_ctl.jl`'s `main` function? This has the benefit that we can use the solver's interpolator rather than having to interpolate afterwards.
