using CochleaTransmissionLine

using Plots
using Statistics
using JLD2

# Include the parameters for CTL
include("ctl_test_setup.jl")

simulation_time = @elapsed solution = solve(problem, algorithm)

@save data_filename solution
