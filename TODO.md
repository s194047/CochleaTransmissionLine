# TO DO
- Figure out a smart way to handle many audio files.
  - This is via a system such as make.
  - We need a way to not have to generate one YAML file for every audio stimulus file. i.e., we can run the simulation with a single YAML file for running an audio stimulus and then passing an argument to choose which audio file to run.
- Management of parameter files, input audio files, output data files.
- Pretty plots and a good way to save figures in a vector graphics format.
- Replace calls to `println` with a wrapper function `diag` and `error` which prints to `stderr` and the latter exits.
- Sine SPL target and ref as arguments just like for audio
