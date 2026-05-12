using YAML
using WAV
using DataInterpolations
using JLD2

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

function load_stimulus_audio_file(
    filename::String,
    gain::Union{Float64, Nothing},
    spl_target::Union{Float64, Nothing},
    spl_reference::Union{Float64, Nothing},
    onset_ramp_time::Float64,
)
    # Read WAV file and make sure the signal is mono.
    println(stderr, "Loading stimulus from audio file: $filename")
    y, fs::Float64 = wavread(filename)

    n_channels = size(y, 2)
    if n_channels > 1
        println(stderr, "Audio file has $n_channels channels. Using first channel only.")
    end

    if !isnothing(gain)
        println(stderr, "Specified gain: $gain")
    elseif !isnothing(spl_target) # The argument validation makes sure spl_reference is given as well
        println(stderr, "SPL target and reference specified.")
        println(stderr, "Target: $spl_target dB SPL, Reference: $spl_reference")
        y_rms = rms(y[:, 1]) # Use first channel if stereo
        println(stderr, "Calculated RMS of audio signal: $y_rms")
        target_rms = spl_reference * 10.0^(spl_target / 20.0) / sqrt(2) # Convert from SPL to RMS assuming sine was used for calibration
        println(stderr, "Calculated target RMS for desired SPL: $target_rms")
        gain = target_rms / y_rms
        println(stderr, "Calculated gain: $gain")
    else
        println(stderr, "No gain or SPL target specified. Defaulting to unity gain")
        gain = 1.0
    end

    # Apply gain to the audio signal.
    y_vector_scaled = y[:, 1] .* gain # Make sure y is a vector (take first channel if stereo)
    println(stderr, "Applied gain of $gain to audio signal.")

    duration = length(y_vector_scaled) / fs
    println(stderr, "Audio file sample rate: $fs Hz, duration: $duration seconds")

    t_audio = LinRange(0, duration - 1/fs, length(y_vector_scaled))

    println(stderr, "Applying onset ramp time of $onset_ramp_time seconds")
    onset_ramp_values = onset_ramp.(t_audio, onset_ramp_time)
    y_vector_scaled_windowed = y_vector_scaled[:, 1] .* onset_ramp_values

    t_audio_zero_padded = [t_audio[1] - 1/fs; t_audio; t_audio[end] + 1/fs]
    y_vector_scaled_windowed_zero_padded = [0.0; y_vector_scaled_windowed; 0.0]
    interpolator = CubicSpline(
        y_vector_scaled_windowed_zero_padded,
        t_audio_zero_padded,
        cache_parameters=true,
        extrapolation=ExtrapolationType.Constant
    )

    (t::Float64) -> interpolator(t)
end

"""
    load_stimulus(stimulus)

Load a stimulus given a dictionary definition.

Returns a function `stimulus(t::Float64) -> Float64`, where `t` is time in seconds.
"""
function load_stimulus(stimulus_dict::Dict)
    if stimulus_dict["type"] == "zero"
        println(stderr, "No stimulus")

        stimulus = (::Float64) -> 0.0

    elseif stimulus_dict["type"] == "sine"
        frequency = stimulus_dict["frequency"]
        amplitude = get(stimulus_dict, "amplitude", nothing)
        spl_target = get(stimulus_dict, "spl_target", nothing)
        spl_reference = get(stimulus_dict, "spl_reference", nothing)
        onset_ramp_time = get(stimulus_dict, "onset_ramp_time", 0.0)

        if isnothing(amplitude)
            if isnothing(spl_target) || isnothing(spl_reference)
                error("Must specify either amplitude or SPL target and reference.")
            end
            println(stderr, "Specified SPL target: $spl_target and reference: $spl_reference")
            amplitude = spl_reference * 10^(spl_target / 20)
        end

        println(stderr, "Sinusoidal stimulus with frequency: $frequency and amplitude: $amplitude")

        if onset_ramp_time > 0.0
            println(stderr, "Applying onset ramp time of $onset_ramp_time seconds")
            stimulus = (t::Float64) -> amplitude * onset_ramp(t, onset_ramp_time) * sin(2π * frequency * t)
        else
            println(stderr, "No onset ramp time applied")
            stimulus = (t::Float64) -> amplitude * sin(2π * frequency * t)
        end

    elseif stimulus_dict["type"] == "audio"
        filename = stimulus_dict["filename"]
        gain = stimulus_dict["gain"]
        spl_target = stimulus_dict["spl_target"]
        spl_reference = stimulus_dict["spl_reference"]
        onset_ramp_time = stimulus_dict["onset_ramp_time"]
        stimulus = load_stimulus_audio_file(
            filename,
            gain,
            spl_target,
            spl_reference,
            onset_ramp_time,
        )
    else
        error("Unknown stimulus type: $(stimulus_dict["type"])")
    end

    stimulus
end

function load_model_constants(model_constants_filename::String) :: NamedTuple
    println(stderr, "Loading model constants from: $model_constants_filename")
    model_constants_dict = YAML.load_file(model_constants_filename)

    # Read the cochlea transmission line constants.
    ctl_constants = CochleaTransmissionLineConstants(
        ;
        (Pair(Symbol(k), v) for (k, v) in model_constants_dict)...
    )

    (; ctl_constants=ctl_constants, model_constants_dict=model_constants_dict)
end

@kwdef struct SolverParams
    u0_value::Union{Vector{Float64}, Nothing}
    previous_solution_filename::Union{String, Nothing}
    tspan::Vector{Float64}
    saveat::Union{Float64, Vector{Any}}
end

function load_solver_params(solver_params_filename::String) :: NamedTuple
    println(stderr, "Loading solver parameters from: $solver_params_filename")
    solver_params_dict = YAML.load_file(solver_params_filename)

    solver_params = SolverParams(
        # Read initial state if given.
        u0_value = get(solver_params_dict, "u0_value", nothing),

        # Read previous solution if given.
        previous_solution_filename = get(solver_params_dict, "previous_solution_filename", nothing),

        # Read the time span of simulation.
        tspan = solver_params_dict["tspan"],

        # Read sample rate to be used by the solver. If not found, an empty array is used to not sample.
        saveat = get(solver_params_dict, "saveat", []),
    )

    (; solver_params=solver_params, solver_params_dict=solver_params_dict)
end

function make_metadata(
    model_constants_filename::String,
    solver_params_filename::String,
    stimulus_params_filename::Union{String, Nothing},
    model_constants_dict::Dict,
    stimulus_dict::Dict,
    solver_params_section::Dict,
)
    Dict(
        "model_constants_filename" => model_constants_filename,
        "solver_params_filename" => solver_params_filename,
        "stimulus_params_filename" => stimulus_params_filename,
        "model_constants" => model_constants_dict,
        "stimulus" => stimulus_dict,
        "solver_params" => solver_params_section,
    )
end

function make_parameters_tuple(
    model_constants_filename::String,
    solver_params_filename::String,
    stimulus_params_filename::Union{String, Nothing},
    model_constants_dict::Dict,
    stimulus_dict::Dict,
    solver_params_section::Dict,
    ctl_constants::CochleaTransmissionLineConstants,
    stimulus::Function,
    solver_params::SolverParams,
)
    metadata = make_metadata(
        model_constants_filename,
        solver_params_filename,
        stimulus_params_filename,
        model_constants_dict,
        stimulus_dict,
        solver_params_section,
    )

    (
        ctl_constants=ctl_constants,
        stimulus=stimulus,
        solver_params=solver_params,
        metadata=metadata,
    )
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
function load_parameters(
    model_constants_filename::String,
    solver_params_filename::String,
    stimulus_params_filename::String,
)
    # Load parameter files.
    (; ctl_constants, model_constants_dict) = load_model_constants(model_constants_filename)
    (; solver_params, solver_params_dict) = load_solver_params(solver_params_filename)
    stimulus_dict = YAML.load_file(stimulus_params_filename)
    stimulus = load_stimulus(stimulus_dict)

    make_parameters_tuple(
        model_constants_filename,
        solver_params_filename,
        stimulus_params_filename,
        model_constants_dict,
        stimulus_dict,
        solver_params_dict,
        ctl_constants,
        stimulus,
        solver_params,
    )
end

function load_parameters(
    model_constants_filename::String,
    solver_params_filename::String,
    stimulus_dict::Dict,
)
    # Load parameter files.
    (; ctl_constants, model_constants_dict) = load_model_constants(model_constants_filename)
    (; solver_params, solver_params_dict) = load_solver_params(solver_params_filename)
    stimulus = load_stimulus(stimulus_dict)

    make_parameters_tuple(
        model_constants_filename,
        solver_params_filename,
        nothing,
        model_constants_dict,
        stimulus_dict,
        solver_params_dict,
        ctl_constants,
        stimulus,
        solver_params,
    )
end

"""
    make_initial_conditions(solver_params)

Make initial conditions `u0` and history function `u_history` for the DDE problem.
"""
function make_initial_conditions(solver_params::SolverParams, n::Int64) :: Tuple{Vector{Float64}, UHistory}
    # Ensure that either u0_value or previous_solution_filename is provided.
    if isnothing(solver_params.u0_value) && isnothing(solver_params.previous_solution_filename)
        println(stderr, "Pass either u0 value or previous solution filename.")
        exit(1)
    end

    if !isnothing(solver_params.u0_value)
        println(stderr, "u0 value specified: $(solver_params.u0_value)")
        println(stderr, "Setting all CP initial conditions and histories to this value.")
        u0 = repeat(solver_params.u0_value, outer=n+1)
        u_history_lambda = (::Float64; idxs=nothing) ->
        if isnothing(idxs)
            u0
        else
            u0[idxs]
        end
        println(stderr, "Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
    else
        println(stderr, "No u0 value specified. Loading previous solution from $(solver_params.previous_solution_filename).")
        if !isfile(solver_params.previous_solution_filename)
            println(stderr, "Previous solution file not found: $(solver_params.previous_solution_filename)")
            exit(1)
        end
        previous_t, previous_u = load(solver_params.previous_solution_filename, "t", "u")
        if length(previous_u[1]) ÷ 2 != n + 1
            println(stderr, "Error: Previous solution size $(length(previous_u[1])) does not match the current size $(n + 1).")
            exit(1)
        end
        println(stderr, "Setting all CP initial conditions to the last state in the previous solution.")
        u0 = previous_u[end]
        u_history_lambda = let
            println(stderr, "Previous solution timespan: ($(previous_t[1]), $(previous_t[end]))")
            println(stderr, "Current simulation timespan: ($(solver_params.tspan[1]), $(solver_params.tspan[2]))")
            t_offset = solver_params.tspan[1] - previous_t[end]
            println(stderr, "Shifting previous solution by $t_offset seconds to align with the current simulation.")
            previous_t_shifted = previous_t .+ t_offset
            interpolator = CubicSpline(previous_u, previous_t_shifted, cache_parameters=true)
            println(stderr, "Defining history function using interpolation of the previous solution.")
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
