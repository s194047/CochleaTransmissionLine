using CochleaTransmissionLine

using TimeZones
using JLD2
using CairoMakie
using ArgParse

function parse_commandline()::Dict
    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--input-file", "-i"], Dict(
            :help => "JLD2 file containing CTL data.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
        ["--output-file", "-o"], Dict(
            :help => "Where to save the plot. Type is inferred from file extension.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
        ["--frequency-type", "-f"], Dict(
            :help => "Whether to use winding or rotation frequency.",
            :arg_type => String,
            :metavar => "{winding,rotation}",
            :range_tester => ∈(["winding", "rotation"]),
            :required => true,
        ),
        ["--x-type", "-x"], Dict(
            :help => "Whether to plot x as oscillator index or length.",
            :arg_type => String,
            :metavar => "{index,length}",
            :range_tester => ∈(["index", "length"]),
            :required => true,
        ),
        ["--title", "-t"], Dict(
            :help => "Title of the plot",
            :arg_type => String,
            :metavar => "TITLE",
            :required => true,
        )
    )

    parse_args(arg_defs)
end

function main()
    parsed_args = parse_commandline()

    # JLD2 file with CTL data to load
    t, u, metadata = load(parsed_args["input-file"], "t", "u", "metadata")

    # Stack `u` to have a Matrix{Float64} rather than Vector{Vector{Float64}}
    u = stack(u, dims=1)

    frequency_functions::Dict{String, Function} = Dict(
        "winding" => oscillator_winding_frequency,
        "rotation" => oscillator_rotation_frequency,
    )
    frequency_function = frequency_functions[parsed_args["frequency-type"]]

    n = metadata["model_constants"]["n"]
    if parsed_args["x-type"] == "length"
        x_apex_value = metadata["model_constants"]["x_apex_value"]
        x = LinRange(0, x_apex_value, n + 1)
        xlabel = "BM position / m"
    else # parsed_args["x-type"] == "index"
        x = 0:n
        xlabel = "Oscillator Index"
    end
    f = Figure()
    ax = Axis(f[1, 1], yscale=log10)
    plot!(ax, x, (abs.(frequency_function(t, u)) ./ 2π))
    ax.xlabel = xlabel
    ax.ylabel = "$(uppercasefirst(parsed_args["frequency-type"])) frequency / Hz"
    ax.title = parsed_args["title"]

    mkpath(dirname(parsed_args["output-file"]))
    save(parsed_args["output-file"], f)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
