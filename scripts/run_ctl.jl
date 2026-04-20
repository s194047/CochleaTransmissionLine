using CochleaTransmissionLine

using ArgParse
using DelayDiffEq
using JLD2
using DataInterpolations
using TimeZones

function argparse_error(arg_defs::ArgParseSettings, message::String)
    println(stderr, "$message")
    println(stderr, usage_string(arg_defs))
    exit(1)
end

function parse_commandline()::Dict
    stimulus_params_file_opt = "stimulus-params-file"
    stimulus_audio_file_opt = "stimulus-audio-file"
    stimulus_audio_gain_opt = "stimulus-audio-gain"
    stimulus_audio_onset_ramp_time_opt = "stimulus-audio-onset-ramp-time"

    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--model-constants-file", "-m"], Dict(
            :help => "YAML file containing model constants",
            :arg_type => String,
            :metavar => "FILENAME",
            :required => true,
        ),
        ["--solver-params-file", "-s"], Dict(
            :help => "YAML file containing solver parameters",
            :arg_type => String,
            :metavar => "FILENAME",
            :required => true,
        ),
        "--$stimulus_params_file_opt", Dict(
            :help => "YAML file containing stimulus configuration",
            :arg_type => String,
            :metavar => "FILENAME",
        ),
        "--$stimulus_audio_file_opt", Dict(
            :help => "WAV file containing stimulus audio",
            :arg_type => String,
            :metavar => "FILENAME",
        ),
        "--$stimulus_audio_gain_opt", Dict(
            :help => "Stimulus gain if an audio file is passed",
            :arg_type => Float64,
            :metavar => "FLOAT",
        ),
        "--$stimulus_audio_onset_ramp_time_opt", Dict(
            :help => "Stimulus onset ramp time if an audio file is passed",
            :arg_type => Float64,
            :metavar => "FLOAT",
        ),
        ["--output-file", "-o"], Dict(
            :help => "Output JLD2 file containing time series data of the simulation",
            :arg_type => String,
            :metavar => "FILENAME",
            :required => true,
        )
    )

    parsed_args = parse_args(arg_defs)

    # Validate arguments
    if isnothing(parsed_args[stimulus_params_file_opt]) && isnothing(parsed_args[stimulus_audio_file_opt])
        argparse_error(arg_defs, "either --$stimulus_params_file_opt or --$stimulus_audio_file_opt must be given")
    end
    if !isnothing(parsed_args[stimulus_params_file_opt]) && !isnothing(parsed_args[stimulus_audio_file_opt])
        argparse_error(arg_defs, "options --$stimulus_params_file_opt and --$stimulus_audio_file_opt are mutually exclusive")
    end
    if !isnothing(parsed_args[stimulus_audio_gain_opt]) && isnothing(parsed_args[stimulus_audio_file_opt])
        argparse_error(arg_defs, "cannot specify --$stimulus_audio_gain_opt when not specifying --$stimulus_audio_file_opt")
    end
    if !isnothing(parsed_args[stimulus_audio_onset_ramp_time_opt]) && isnothing(parsed_args[stimulus_audio_file_opt])
        argparse_error(arg_defs, "cannot specify --$stimulus_audio_onset_ramp_time_opt when not specifying --$stimulus_audio_file_opt")
    end

    if isnothing(parsed_args[stimulus_audio_gain_opt])
        parsed_args[stimulus_audio_gain_opt] = 1.0
    end
    if isnothing(parsed_args[stimulus_audio_onset_ramp_time_opt])
        parsed_args[stimulus_audio_onset_ramp_time_opt] = 0.0
    end

    return parsed_args
end

function run_simulation(
    differential_equation::Function,
    u0::Vector{Float64},
    u_history::UHistory,
    tspan::Union{Tuple{Float64, Float64}, Vector{Float64}},
    model_params::CochleaModelParams,
    solver_params::SolverParams,
)
    # Define the DDE problem.
    problem = DDEProblem(
        differential_equation,
        u0,
        u_history,
        tspan,
        model_params,
    )

    # Choose the solver algorithm.
    algorithm = MethodOfSteps(Tsit5())

    # Run the simulation and log the time taken.
    println("Starting simulation...")
    start_timestamp = now(localzone())
    duration_seconds = @elapsed solution = solve(problem, saveat=solver_params.saveat, algorithm)
    println("Simulation completed in $(duration_seconds) seconds.")

    (solution, start_timestamp, duration_seconds)
end

function load_parameters_from_parsed_args(parsed_args::Dict)
    if isnothing(parsed_args["stimulus-audio-file"])
        load_parameters(
            parsed_args["model-constants-file"], # TODO constants!
            parsed_args["solver-params-file"],
            parsed_args["stimulus-params-file"],
        )
    else
        load_parameters(
            parsed_args["model-constants-file"], # TODO constants!
            parsed_args["solver-params-file"],
            parsed_args["stimulus-audio-file"],
            parsed_args["stimulus-audio-gain"],
            parsed_args["stimulus-audio-onset-ramp-time"],
        )
    end
end

function main()
    parsed_args = parse_commandline()
    data_filename = parsed_args["output-file"] # TODO: Move name from string literal to constant.

    # Load parameters from config file.
    (; ctl_constants, stimulus, solver_params, metadata) = load_parameters_from_parsed_args(parsed_args)
    model_params = makeCochleaModelParams(
        ctl_constants,
        stimulus,
    )

    # Define the initial state and history function.
    u0, u_history = make_initial_conditions(solver_params, ctl_constants.n)

    # Determine the maximum run time based on the maximum delay in the system.
    max_delay = maximum(model_params.ctl_params.τ_values)
    max_run_time = ceil(max_delay, digits=1)
    println("Maximum delay in system: $max_delay seconds.")
    println("Maximum run time per segment: $max_run_time seconds.")

    # Divide the timespan into segments to avoid excessive memory usage.
    intervals = let
        t0, t1 = solver_params.tspan;
        edges = collect(t0:max_run_time:t1);
        edges[end] < t1 && push!(edges, t1);
        [(edges[i], edges[i+1]) for i in 1:length(edges)-1]
    end
    println("Divided total timespan into $(length(intervals)) intervals of $max_run_time seconds each.")

    # Initialize empty arrays for solution t and u and for simulation info metadata.
    # TODO: Consider zipping t and u to named tuples.
    t = Vector{Float64}()
    u = Vector{Vector{Float64}}()
    metadata["duration_seconds_values"] = Vector{Float64}()
    metadata["start_timestamp_values"] = Vector{ZonedDateTime}()

    # Run the simulation in segments.
    for interval in intervals
        println("Running simulation for interval: $interval")
        # Run the simulation for the current interval.
        solution, start_timestamp, duration_seconds = run_simulation(
            cochlea_transmission_line!,
            u0,
            u_history,
            interval,
            model_params,
            solver_params,
        )

        # Append the results to the overall solution.
        if isempty(t) || solution.t[1] > t[end]
            # This is the first segment or (not expected) the new segment does not start exactly where the previous ended.
            append!(t, solution.t)
            append!(u, solution.u)
        else
            # Avoid duplicating the initial time point of the new segment.
            append!(t, solution.t[2:end])
            append!(u, solution.u[2:end])
        end

        # Clear the reference to the previous solution to release the memory between iterations.
        forget_history_function(u_history)

        # Update initial conditions and history function for the next interval.
        println("Updating initial conditions for next interval.")
        u0 = solution.u[end]
        u_history = UHistory(solution)

        # Record simulation info metadata.
        push!(metadata["duration_seconds_values"], duration_seconds)
        push!(metadata["start_timestamp_values"], start_timestamp)
    end

    # Save the solution to disk.
    println("Saving solution to $data_filename...")
    mkpath(dirname(data_filename))
    jldsave(
        "$data_filename";
        t,
        u,
        metadata,
    )
    println("Solution saved successfully.")
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
