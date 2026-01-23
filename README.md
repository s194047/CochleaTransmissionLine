# Cochlea Transmission Line

This repo is a MWE implementation of the Epp 2010 cochlea model for experimenting with the final implementation.

## Running the model

To run the model, execute the script `scripts/run_ctl.jl`. The script takes one positional argument for a configuration file.
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
