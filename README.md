# How to generate plots for the report

## Generate initial conditions
We generate initial conditions for two sets of model constants, both based on Epp2010 model parameters with only this difference:
* Without roughness
* With roughness

For those two sets of model constants, we run a simulation with initial conditions set to $[y, v] = [10^{-9}, 0]$ for all oscillators for 5, 20 and 100 seconds.

### Run locally
To run the simulations locally:
```console
$ ./shell_scripts/generate_initial_conditions/generate_initial_conditions.sh
```
The output data is put in the relative path `data/initial_conditions`.

### Run on HPC
Login with `ssh` to `login1.gbar.dtu.dk`:
```
sofus@sofus-mba cochleatransmissionline.jl % ssh gbar

When connecting from _outside_ of DTU (and not using DTU-VPN) one is
required to authenticate with a ssh-key + ssh-key-keyphrase + DTU-password.

From inside of DTU (or connecting via DTU-VPN) one can also connect
with password or ssh-key.

Info page on SSH: https://www.hpc.dtu.dk/?page_id=4317

---
For ThinLinc users:
Please make sure that your TL client is at least version 4.16 - else you
cannot connect to this system!

This is not an error-message, it's just a way to give you some information.
Click 'Close' to continue ...
---

Info page on the system update 08/2024: https://www.hpc.dtu.dk/?page_id=5209

---

s194047@login1.gbar.dtu.dk's password:
Last login: Thu May 14 10:40:09 2026 from 2a05:f6c7:3674:0:f5ee:73b4:dcc9:2042

****************************************************************************
*                 Welcome to the G-databar/HPC at DTU                      *
*              General information: https://www.hpc.dtu.dk                 *
*                User support: support@hpc.dtu.dk                          *
****************************************************************************


Loaded module: latex/TexLive24
s194047@gbarlogin1 ~ $
```

You are now logged in to a *login node*.

Remember to switch to an *application node* before submitting the job:
```
s194047@gbarlogin1 ~ $ linuxsh
qsub: waiting for job 663979.hnode41 to start
qsub: job 663979.hnode41 ready

-bash: ulimit: open files: cannot modify limit: Invalid argument

****************************************************************************
*                 Welcome to the G-databar/HPC at DTU                      *
*              General information: https://www.hpc.dtu.dk                 *
*                User support: support@hpc.dtu.dk                          *
****************************************************************************


Loaded module: latex/TexLive24
s194047@n-62-27-18 ~ $
```

To run the simulations on LSF on HPC:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ pwd
/zhome/26/f/146732/MSc_project/cochleatransmissionline.jl
s194047@n-62-27-21 cochleatransmissionline.jl $ bsub < shell_scripts/generate_initial_conditions/generate_initial_conditions_hpc.sh
Job <28428586> is submitted to queue <hpc>.
```

Check that the job is running with `bstat`:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ bstat
JOBID      USER    QUEUE      JOB_NAME   NALLOC STAT  START_TIME      ELAPSED
28428586   s194047 hpc        *onditions     16 RUN   May 14 11:38    0:00:21
```

To follow the progress, tail the log files:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ tail -f /work3/s194047/data/initial_conditions/*.jld2.log
==> /work3/s194047/data/initial_conditions/initial_conditions_100s_no_rough.jld2.log <==
Loading solver parameters from: /tmp/zsh3yBta1
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 100.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 1000 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/initial_conditions/initial_conditions_100s_rough.jld2.log <==
Loading solver parameters from: /tmp/zshPC3n1x
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 100.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 1000 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/initial_conditions/initial_conditions_20s_no_rough.jld2.log <==
Loading solver parameters from: /tmp/zsh4lAgc0
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 20.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 200 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/initial_conditions/initial_conditions_20s_rough.jld2.log <==
Loading solver parameters from: /tmp/zshDmOssH
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 20.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 200 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/initial_conditions/initial_conditions_5s_no_rough.jld2.log <==
Loading solver parameters from: /tmp/zshMbrKEH
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 5.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 50 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/initial_conditions/initial_conditions_5s_rough.jld2.log <==
Loading solver parameters from: /tmp/zsh44Buyz
No stimulus
u0 value specified: [1.0e-9, 0.0]
Setting all CP initial conditions and histories to this value.
Current simulation timespan: (0.0, 5.0)
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 50 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...
```

To follow the output of the job script itself, we look for the latest `bsub` stderr log file:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ ls -rt *.err | tail -1 | xargs tail -f
Loaded module: julia/1.12.6
cwd: /zhome/26/f/146732/MSc_project/cochleatransmissionline.jl
OUTPUT_DIR: /work3/s194047/data/initial_conditions
```

The output data will end up in `/work3/s194047/data/initial_conditions` when the job is done.
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ tree /work3/s194047/data/initial_conditions/
/work3/s194047/data/initial_conditions/
├── initial_conditions_100s_no_rough.jld2
├── initial_conditions_100s_no_rough.jld2.log
├── initial_conditions_100s_rough.jld2
├── initial_conditions_100s_rough.jld2.log
├── initial_conditions_20s_no_rough.jld2
├── initial_conditions_20s_no_rough.jld2.log
├── initial_conditions_20s_rough.jld2
├── initial_conditions_20s_rough.jld2.log
├── initial_conditions_5s_no_rough.jld2
├── initial_conditions_5s_no_rough.jld2.log
├── initial_conditions_5s_rough.jld2
└── initial_conditions_5s_rough.jld2.log

0 directories, 12 files
```

After run, write-protect the data files:
```console
s194047@n-62-9-41 ~ $ tree -p /work3/s194047/data/initial_conditions
/work3/s194047/data/initial_conditions
├── [-rw-r--r--]  initial_conditions_100s_no_rough.jld2
├── [-rw-r--r--]  initial_conditions_100s_no_rough.jld2.log
├── [-rw-r--r--]  initial_conditions_100s_rough.jld2
├── [-rw-r--r--]  initial_conditions_100s_rough.jld2.log
├── [-rw-r--r--]  initial_conditions_20s_no_rough.jld2
├── [-rw-r--r--]  initial_conditions_20s_no_rough.jld2.log
├── [-rw-r--r--]  initial_conditions_20s_rough.jld2
├── [-rw-r--r--]  initial_conditions_20s_rough.jld2.log
├── [-rw-r--r--]  initial_conditions_5s_no_rough.jld2
├── [-rw-r--r--]  initial_conditions_5s_no_rough.jld2.log
├── [-rw-r--r--]  initial_conditions_5s_rough.jld2
└── [-rw-r--r--]  initial_conditions_5s_rough.jld2.log

0 directories, 12 files
s194047@n-62-9-41 ~ $ chmod -w -R /work3/s194047/data/initial_conditions
s194047@n-62-9-41 ~ $ tree -p /work3/s194047/data/initial_conditions
/work3/s194047/data/initial_conditions
├── [-r--r--r--]  initial_conditions_100s_no_rough.jld2
├── [-r--r--r--]  initial_conditions_100s_no_rough.jld2.log
├── [-r--r--r--]  initial_conditions_100s_rough.jld2
├── [-r--r--r--]  initial_conditions_100s_rough.jld2.log
├── [-r--r--r--]  initial_conditions_20s_no_rough.jld2
├── [-r--r--r--]  initial_conditions_20s_no_rough.jld2.log
├── [-r--r--r--]  initial_conditions_20s_rough.jld2
├── [-r--r--r--]  initial_conditions_20s_rough.jld2.log
├── [-r--r--r--]  initial_conditions_5s_no_rough.jld2
├── [-r--r--r--]  initial_conditions_5s_no_rough.jld2.log
├── [-r--r--r--]  initial_conditions_5s_rough.jld2
└── [-r--r--r--]  initial_conditions_5s_rough.jld2.log

0 directories, 12 files
```

## Generate zero stimulus 1s data
For each version of the initial conditions, we run a 1s simulation with zero stimulus.

### Run locally
To run the simulations locally:
```console
$ ./shell_scripts/roughness_and_ic_demo/make_roughness_and_ic_demo_data.sh
```
The output data is put in the relative path `data/initial_conditions`.

### Run on HPC
Login with `ssh` to `login1.gbar.dtu.dk`:
```
sofus@sofus-mba cochleatransmissionline.jl % ssh gbar
... (like above)
s194047@gbarlogin1 ~ $
```

You are now logged in to a *login node*.

Remember to switch to an *application node* before submitting the job:
```
s194047@gbarlogin1 ~ $ linuxsh
...
s194047@n-62-27-18 ~ $
```

To run the simulations on LSF on HPC:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ pwd
/zhome/26/f/146732/MSc_project/cochleatransmissionline.jl
s194047@n-62-27-21 cochleatransmissionline.jl $ bsub < shell_scripts/roughness_and_ic_demo/make_roughness_and_ic_demo_data_hpc.sh
Job <28428697> is submitted to queue <hpc>.
```

To check that the job is running, use `bstat` and check the `STAT` column for value `RUN`:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ bstat
JOBID      USER    QUEUE      JOB_NAME   NALLOC STAT  START_TIME      ELAPSED
28428697   s194047 hpc        *demo_data      0 PEND       -          0:00:00
s194047@n-62-27-21 cochleatransmissionline.jl $ bstat
JOBID      USER    QUEUE      JOB_NAME   NALLOC STAT  START_TIME      ELAPSED
28428697   s194047 hpc        *demo_data     16 RUN   May 14 12:15    0:00:00
```
Tail the log files to follow progress:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ tail -f /work3/s194047/data/stimulus_zero/*.log
==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_100s_no_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (99.9, 100.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -100.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_100s_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (99.9, 100.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -100.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_20s_no_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (19.9, 20.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -20.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_20s_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (19.9, 20.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -20.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_5s_no_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (4.9, 5.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -5.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...

==> /work3/s194047/data/stimulus_zero/stimulus_zero_initial_5s_rough.jld2.log <==
Setting all CP initial conditions to the last state in the previous solution.
Previous solution timespan: (4.9, 5.0)
Current simulation timespan: (0.0, 1.0)
Shifting previous solution by -5.0 seconds to align with the current simulation.
Defining history function using interpolation of the previous solution.
Maximum delay in system: 0.08721137827142772 seconds.
Maximum run time per segment: 0.1 seconds.
Divided total timespan into 10 intervals of 0.1 seconds each.
Running simulation for interval: (0.0, 0.1)
Starting simulation...
```

To follow the output of the job script itself, we look for the latest `bsub` stderr log file:
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ ls -rt *.err | tail -1 | xargs tail -f
Loaded module: julia/1.12.6
cwd: /zhome/26/f/146732/MSc_project/cochleatransmissionline.jl
OUTPUT_DIR: /work3/s194047/data/stimulus_zero
INITIAL_CONDITIONS_DIR: /work3/s194047/data/initial_conditions
```

The output data will end up in `/work3/s194047/data/initial_conditions` when the job is done.
```console
s194047@n-62-27-21 cochleatransmissionline.jl $ tree /work3/s194047/data/stimulus_zero/
/work3/s194047/data/stimulus_zero/
├── stimulus_zero_initial_100s_no_rough.jld2
├── stimulus_zero_initial_100s_no_rough.jld2.log
├── stimulus_zero_initial_100s_rough.jld2
├── stimulus_zero_initial_100s_rough.jld2.log
├── stimulus_zero_initial_20s_no_rough.jld2
├── stimulus_zero_initial_20s_no_rough.jld2.log
├── stimulus_zero_initial_20s_rough.jld2
├── stimulus_zero_initial_20s_rough.jld2.log
├── stimulus_zero_initial_5s_no_rough.jld2
├── stimulus_zero_initial_5s_no_rough.jld2.log
├── stimulus_zero_initial_5s_rough.jld2
└── stimulus_zero_initial_5s_rough.jld2.log

0 directories, 12 files
```

After run, write-protect the data files:
```console
s194047@n-62-9-41 ~ $ tree -p /work3/s194047/data/stimulus_zero/
/work3/s194047/data/stimulus_zero/
├── [-rw-r--r--]  stimulus_zero_initial_100s_no_rough.jld2
├── [-rw-r--r--]  stimulus_zero_initial_100s_no_rough.jld2.log
├── [-rw-r--r--]  stimulus_zero_initial_100s_rough.jld2
├── [-rw-r--r--]  stimulus_zero_initial_100s_rough.jld2.log
├── [-rw-r--r--]  stimulus_zero_initial_20s_no_rough.jld2
├── [-rw-r--r--]  stimulus_zero_initial_20s_no_rough.jld2.log
├── [-rw-r--r--]  stimulus_zero_initial_20s_rough.jld2
├── [-rw-r--r--]  stimulus_zero_initial_20s_rough.jld2.log
├── [-rw-r--r--]  stimulus_zero_initial_5s_no_rough.jld2
├── [-rw-r--r--]  stimulus_zero_initial_5s_no_rough.jld2.log
├── [-rw-r--r--]  stimulus_zero_initial_5s_rough.jld2
└── [-rw-r--r--]  stimulus_zero_initial_5s_rough.jld2.log

0 directories, 12 files
s194047@n-62-9-41 ~ $ chmod -w -R /work3/s194047/data/stimulus_zero/
s194047@n-62-9-41 ~ $ tree -p /work3/s194047/data/stimulus_zero/
/work3/s194047/data/stimulus_zero/
├── [-r--r--r--]  stimulus_zero_initial_100s_no_rough.jld2
├── [-r--r--r--]  stimulus_zero_initial_100s_no_rough.jld2.log
├── [-r--r--r--]  stimulus_zero_initial_100s_rough.jld2
├── [-r--r--r--]  stimulus_zero_initial_100s_rough.jld2.log
├── [-r--r--r--]  stimulus_zero_initial_20s_no_rough.jld2
├── [-r--r--r--]  stimulus_zero_initial_20s_no_rough.jld2.log
├── [-r--r--r--]  stimulus_zero_initial_20s_rough.jld2
├── [-r--r--r--]  stimulus_zero_initial_20s_rough.jld2.log
├── [-r--r--r--]  stimulus_zero_initial_5s_no_rough.jld2
├── [-r--r--r--]  stimulus_zero_initial_5s_no_rough.jld2.log
├── [-r--r--r--]  stimulus_zero_initial_5s_rough.jld2
└── [-r--r--r--]  stimulus_zero_initial_5s_rough.jld2.log

0 directories, 12 files
```

# FIXME anything below


## Plots for showing roughness vs. no roughness as well as the effect of initial condition length

### Make plots

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
