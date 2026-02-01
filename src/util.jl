using YAML
using WAV
using DataInterpolations
using JLD2

"""
    amplitude_from_filename(filename)

Get the amplitude as `Float64` from a filename, which can be used to sort parameter or data files by the amplitude.
"""
function amplitude_from_filename(filename::String)
    parse(Float64, match(r"a_([\d.e\+-]+)", filename::String).captures[1])
end

"""
    onset_ramp(t, onset_ramp_time)

Calculate half cosine onset ramp-up function.

Make it possible to ramp up the amplitude of the stimulus to lower onset artifacts.
"""
function onset_ramp(t::Float64, onset_ramp_time::Float64)
    if t < 0.0
        return 0.0
    elseif t >= onset_ramp_time
        return 1.0
    else
        return 0.5 * (1.0 - cos(π * t / onset_ramp_time))
    end
end

"""
    load_stimulus(stimulus)

Load a stimulus given a dictionary definition.

Returns a function `stimulus(t::Float64) -> Float64`, where `t` is time in seconds.
"""
function load_stimulus(stimulus_dict::Dict)
    if stimulus_dict["type"] == "zero"
        println("No stimulus")

        stimulus = (::Float64) -> 0.0

    elseif stimulus_dict["type"] == "sine"
        frequency = stimulus_dict["frequency"]
        amplitude = stimulus_dict["amplitude"]
        onset_ramp_time = get(stimulus_dict, "onset_ramp_time", 0.0)

        println("Sinusoidal stimulus with frequency: $frequency and amplitude: $amplitude")

        if onset_ramp_time > 0.0
            println("Applying onset ramp time of $onset_ramp_time seconds")
            stimulus = (t::Float64) -> amplitude * onset_ramp(t, onset_ramp_time) * sin(2π * frequency * t)
        else
            println("No onset ramp time applied")
            stimulus = (t::Float64) -> amplitude * sin(2π * frequency * t)
        end

    elseif stimulus_dict["type"] == "audio"
        filename = stimulus_dict["filename"]
        gain = get(stimulus_dict, "gain", 1.0)
        onset_ramp_time = get(stimulus_dict, "onset_ramp_time", 0.0)

        println("Loading stimulus from audio file: $filename")
        y, fs::Float64 = wavread(filename)

        n_channels = size(y, 2)
        if n_channels > 1
            println("Audio file has $n_channels channels. Using first channel only.")
        end

        y_vector_gained = y[:, 1] .* gain # Make sure y is a vector (take first channel if stereo)
        println("Applied gain of $gain to audio signal.")

        duration = length(y_vector_gained) / fs
        println("Audio file sample rate: $fs Hz, duration: $duration seconds")

        t_audio = LinRange(0, duration - 1/fs, length(y_vector_gained))

        println("Applying onset ramp time of $onset_ramp_time seconds")
        onset_ramp_values = onset_ramp.(t_audio, onset_ramp_time)
        y_vector_gained_windowed = y_vector_gained[:, 1] .* onset_ramp_values

        t_audio_zero_padded = [t_audio[1] - 1/fs; t_audio; t_audio[end] + 1/fs]
        y_vector_gained_windowed_zero_padded = [0.0; y_vector_gained_windowed; 0.0]
        interpolator = CubicSpline(
            y_vector_gained_windowed_zero_padded,
            t_audio_zero_padded,
            cache_parameters=true,
            extrapolation=ExtrapolationType.Constant
        )
        stimulus = (t::Float64) -> interpolator(t)
    else
        error("Unknown stimulus type: $(stimulus_dict["type"])")
    end

    stimulus
end

@kwdef struct SolverParams
    u0_value::Union{Vector{Float64}, Nothing}
    previous_solution_filename::Union{String, Nothing}
    tspan::Vector{Float64}
    saveat::Union{Float64, Vector{Any}}
end

"""
    load_parameters(parameters_filename)

Load parameters for running a simulation from a YAML file.

Returns a named tuple with fields:
- `ctl_constants`: constants for the cochlea transmission line model
- `stimulus`: stimulus definition
- `solver_params`: solver configuration
- `metadata`: metadata containing information about the loaded parameters and simulation info
"""
function load_parameters(parameters_filename::String)
    parameters = YAML.load_file(parameters_filename)

    # Load model constants from separate file
    if !haskey(parameters, "model_constants_filename")
        println("Error: model_constants_filename must be specified in the config file.")
        exit(1)
    end
    model_constants_filename = parameters["model_constants_filename"]
    println("Loading model constants from: $model_constants_filename")
    model_constants_dict = YAML.load_file(model_constants_filename)

    # Extract sections of config file.
    stimulus_section = parameters["stimulus"]
    solver_params_section = parameters["solver_params"]

    # Read the cochlea transmission line constants.
    ctl_constants = CochleaTransmissionLineConstants(
        ;
        (Pair(Symbol(k), v) for (k, v) in model_constants_dict)...
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

    metadata = Dict(
        "parameters_filename" => parameters_filename,
        "model_constants_filename" => model_constants_filename,
        "model_constants" => model_constants_dict,
        "stimulus" => stimulus_section,
        "solver_params" => solver_params_section,
    )

    (
        ctl_constants=ctl_constants,
        stimulus=stimulus,
        solver_params=solver_params,
        metadata=metadata,
    )
end

"""
    make_initial_conditions(solver_params)

Make initial conditions `u0` and history function `u_history` for the DDE problem.
"""
function make_initial_conditions(solver_params::SolverParams, n::Int64) :: Tuple{Vector{Float64}, UHistory}
    # Ensure that either u0_value or previous_solution_filename is provided.
    if isnothing(solver_params.u0_value) && isnothing(solver_params.previous_solution_filename)
        println("Pass either u0 value or previous solution filename.")
        exit(1)
    end

    if !isnothing(solver_params.u0_value)
        println("u0 value specified: $(solver_params.u0_value)")
        println("Setting all CP initial conditions and histories to this value.")
        u0 = repeat(solver_params.u0_value, outer=n+1)
        u_history_lambda = (::Float64; idxs=nothing) ->
        if isnothing(idxs)
            u0
        else
            u0[idxs]
        end
        println("Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
    else
        println("No u0 value specified. Loading previous solution from $(solver_params.previous_solution_filename).")
        if !isfile(solver_params.previous_solution_filename)
            println("Previous solution file not found: $(solver_params.previous_solution_filename)")
            exit(1)
        end
        previous_t, previous_u = load(solver_params.previous_solution_filename, "t", "u")
        if length(previous_u[1]) ÷ 2 != n + 1
            println("Error: Previous solution size $(length(previous_u[1])) does not match the current size $(n + 1).")
            exit(1)
        end
        println("Setting all CP initial conditions to the last state in the previous solution.")
        u0 = previous_u[end]
        u_history_lambda = let
            println("Previous solution timespan: ($(previous_t[1]), $(previous_t[end]))")
            println("Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
            t_offset = solver_params.tspan[1] - previous_t[end]
            println("Shifting previous solution by $t_offset seconds to align with the current simulation.")
            previous_t_shifted = previous_t .+ t_offset
            interpolator = CubicSpline(previous_u, previous_t_shifted, cache_parameters=true)
            println("Defining history function using interpolation of the previous solution.")
            (t::Float64; idxs=nothing) ->
                if isnothing(idxs)
                    interpolator(t)
                else
                    interpolator(t)[idxs]
                end
        end
    end

    (u0, UHistory(u_history_lambda))
end
