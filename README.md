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
- Save metadata in JLD2 files for better handling when analysing and plotting data. Consider saving:
    - Model Constants Filename
    - Stimulus
    - Solver Params
- Make recipes, julia scripts or shell scripts for the plots that I want to use in the report.
- Decide whether it's possible to serialize a callable `ODESolution` object.
- Look into a more flexible way to simulate long timespans by splitting up the original timespan into shorter chunks and solving sequentially (without saving and reloading solutions, just keeping them as variables).
