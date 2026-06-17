using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using PythonPlot

matplotlib.style.use("../paper.mplstyle")

# widths from the LaTeX document
const column_width_pt = 221.0
const text_width_pt = 452.0

# Conversion factor: 72.27 LaTeX points per 72 Makie (PostScript) points
const latex_pt_per_pt = 72.27 / 72
const latex_pt_per_in = 72.27

# Aspect ratio of plot
const figure_aspect_ratio = 4 / 3

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
            :required => false,
        ),
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
        x = LinRange(0, x_apex_value, n + 1) .* 1000
        x_label = "distance from stapes / mm"
    else # parsed_args["x-type"] == "index"
        x = 0:n
        x_label = "oscillator index"
    end

    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio

    fig = figure(figsize=(fig_width_in, fig_height_in))
    scatter(
        x,
        abs.(frequency_function(t, u)) ./ (2π),
        color="C2"
    )
    # grid(true)
    ax = fig.axes[0]
    ax.set_yscale("log", base=10)
    xlim(0.0, x_apex_value .* 1000)
    ylim(1e0, 3e4)
    xlabel(x_label)
    ylabel("$(lowercase(parsed_args["frequency-type"])) frequency / Hz")
    if !isnothing(parsed_args["title"])
        title(parsed_args["title"])
    end
    mkpath(dirname(parsed_args["output-file"]))
    fig.savefig(parsed_args["output-file"])
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
