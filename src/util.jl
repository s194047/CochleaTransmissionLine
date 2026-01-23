"""
    Calculate half cosine onset ramp-up function

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

function load_stimulus(stimulus::Dict)
    if stimulus["type"] == "zero"
        println("No stimulus")
        (::Float64) -> 0.0
    elseif stimulus["type"] == "sine"
        frequency = stimulus["frequency"]
        amplitude = stimulus["amplitude"]
        onset_ramp_time = get(stimulus, "onset_ramp_time", 0.0)
        println("Sinusoidal stimulus with frequency: $frequency and amplitude: $amplitude")
        if onset_ramp_time > 0.0
            println("Applying onset ramp time of $onset_ramp_time seconds")
            (t::Float64) -> amplitude * onset_ramp(t, onset_ramp_time) * sin(2π * frequency * t)
        else
            println("No onset ramp time applied")
            (t::Float64) -> amplitude * sin(2π * frequency * t)
        end
    elseif stimulus["type"] == "audio"
        filename = stimulus["filename"]
        gain = get(stimulus, "gain", 1.0)
        onset_ramp_time = get(stimulus, "onset_ramp_time", 0.0)
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
        t_audio = LinRange(0, duration - 1/fs, length(y))
        interpolator = CubicSpline(y[:, 1], t_audio)
        if onset_ramp_time > 0.0
            println("Applying onset ramp time of $onset_ramp_time seconds")
            (t::Float64) -> onset_ramp(t, onset_ramp_time) * interpolator(t)
        else
            println("No onset ramp time applied")
            (t::Float64) -> interpolator(t)
        end
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
    data_section = parameters["data"]

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

    # Read data filename for saving results.
    data_filename = data_section["data_filename"]

    metadata = Dict(
        "parameters_filename" => parameters_filename,
        "model_constants_filename" => model_constants_filename,
        "model_constants" => model_constants_dict,
        "stimulus" => stimulus_section,
        "solver_params" => solver_params_section,
    )

    (ctl_constants, stimulus, solver_params, data_filename, metadata)
end
