using CochleaTransmissionLine

using YAML
using DelayDiffEq
using JLD2
using DataInterpolations
using WAV

# TODO: Consider once more to save and load the solution
#       rather than t and u with interpolations for better accuracy.

# TODO: Test that sinusoidal and audio stimuli work as intended.

# TODO: Consider splitting up model parameters and run-specific parameters into different YAML files.

function load_stimulus(stimulus::Dict)
    if stimulus["type"] == "zero"
        println("No stimulus")
        (::Float64) -> 0.0
    elseif stimulus["type"] == "sine"
        frequency = stimulus["frequency"]
        amplitude = stimulus["amplitude"]
        println("Sinusoidal stimulus with frequency: $frequency and amplitude: $amplitude")
        (t::Float64) -> amplitude * sin(2π * frequency * t)
    elseif stimulus["type"] == "audio"
        filename = stimulus["filename"]
        gain = get(stimulus, "gain", 1.0)
        println("Loading stimulus from audio file: $filename")
        y, fs = wavread(filename)
        n_channels = size(y, 2)
        if n_channels > 1
            println("Audio file is stereo with $n_channels channels. Taking first channel only.")
        end
        y = y[:, 1] # Make sure y is a vector (take first channel if stereo)
        y .= gain .* y
        println("Applied gain of $gain to audio signal.")
        duration = length(y) / fs
        println("Audio file sample rate: $fs Hz, duration: $duration seconds")
        t_audio = LinRange(0, duration, length(y))
        interpolator = CubicSpline(y[:, 1], t_audio)
        (t::Float64) -> interpolator(t)
    else
        error("Unknown stimulus type: $(stimulus["type"])")
    end
end

@kwdef struct SolverParams
    u0_value::Union{Vector{Float64}, Nothing}
    previous_solution_filename::Union{String, Nothing}
    tspan::Vector{Float64}
    saveat::Union{Float64, Vector{Any}}
end

function load_paramters(config_filename::String)
    cfg = YAML.load_file(config_filename)

    # Load model constants from separate file
    if !haskey(cfg, "model_constants_filename")
        println("Error: model_constants_filename must be specified in the config file.")
        exit(1)
    end
    model_constants_path = cfg["model_constants_filename"]
    println("Loading model constants from: $model_constants_path")
    ctl_constants_dict = YAML.load_file(model_constants_path)

    # Extract sections of config file.
    stimulus_section = cfg["stimulus"]
    solver_params_section = cfg["solver_params"]
    data_section = cfg["data"]

    # Read the cochlea transmission line constants.
    ctl_constants = CochleaTransmissionLineConstants(
        ;
        (Pair(Symbol(k), v) for (k, v) in ctl_constants_dict)...
    )

    # Read the stimulus function type.
    stimulus = load_stimulus(stimulus_section)

    solver_params = SolverParams(
        # Read initial state if given.
        u0_value = get(solver_params_section, "u0_value", nothing),

        # Read previous solution if given.
        previous_solution_filename = get(solver_params_section, "previous_solution_filename", nothing),

        # Read the time span of simulation.
        tspan = solver_params_section["tspan"],

        # Read sample rate to be used by the solver. If not found, an empty array is used to not sample.
        saveat = get(solver_params_section, "saveat", []),
    )

    # Read data filename for saving results.
    data_filename = data_section["data_filename"]

    (ctl_constants, stimulus, solver_params, data_filename)
end

function main()
    # Read config filename from command line arguments.
    if length(ARGS) < 1
        println("Pass parameter YAML file as first argument.")
        exit(1)
    end
    config_filename = ARGS[1]

    # Load parameters from config file.
    println("Loading parameters from config file: $config_filename")
    ctl_constants, stimulus, solver_params, data_filename = load_paramters(config_filename)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    # Define the initial state and history function.
    # Ensure that either u0_value or previous_solution_filename is provided.
    if isnothing(solver_params.u0_value) && isnothing(solver_params.previous_solution_filename)
        println("Pass either u0 value or previous solution filename.")
        exit(1)
    end
    if !isnothing(solver_params.u0_value)
        println("u0 value specified: $(solver_params.u0_value)")
        println("Setting all CP initial conditions and histories to this value.")
        u0 = repeat(solver_params.u0_value, outer=ctl_constants.n+1)
        u0_history = (::CochleaModelParams, ::Float64; idxs=nothing) ->
            if isnothing(idxs)
                u0
            else
                u0[idxs]
            end
    else
        println("No u0 value specified. Loading previous solution from $(solver_params.previous_solution_filename).")
        if !isfile(solver_params.previous_solution_filename)
            println("Previous solution file not found: $(solver_params.previous_solution_filename)")
            exit(1)
        end
        previous_t, previous_u = load(solver_params.previous_solution_filename, "t", "u")
        println("Setting u0 to the last state in the previous solution.")
        u0 = previous_u[end]
        u0_history = let
            println("Previous solution timespan: ($(previous_t[1]), $(previous_t[end]))")
            println("Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
            t_offset = solver_params.tspan[1] - previous_t[end]
            println("Shifting previous solution by $t_offset seconds to align with the current simulation.")
            previous_t_shifted = previous_t .+ t_offset
            interpolator = CubicSpline(previous_u, previous_t_shifted)
            println("Defining history function using interpolation of the previous solution.")
            (::CochleaModelParams, t::Float64; idxs=nothing) ->
                if isnothing(idxs)
                    interpolator(t)
                else
                    interpolator(t)[idxs]
                end
        end
    end

    # Define the DDE problem.
    problem = DDEProblem(
        cochlea_transmission_line!,
        u0,
        u0_history,
        solver_params.tspan,
        model_params,
    )

    # Choose the solver algorithm.
    algorithm = MethodOfSteps(Tsit5())

    # Run the simulation and log the time taken.
    println("Starting simulation...")
    simulation_time = @elapsed solution = solve(problem, saveat=solver_params.saveat, algorithm)
    println("Simulation completed in $(simulation_time) seconds.")

    # Save the solution to disk.
    println("Saving solution to $data_filename...")
    mkpath(dirname(data_filename))
    jldsave("$data_filename"; solution.t, solution.u)
    println("Solution saved successfully.")
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
