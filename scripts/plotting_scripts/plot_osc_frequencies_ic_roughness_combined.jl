using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using Glob
using NaturalSort
using PythonPlot

# Load Matplotlib RC file.
matplotlib.style.use("../paper.mplstyle")

# Read base size from rc.
base_ms = matplotlib.rcParams["lines.markersize"]

# Define greys and sizes.
const ms_factors = [2.0, 1.5, 1.0]
const marker_sizes_s = (base_ms .* ms_factors) .^ 2

# widths from the LaTeX document.
const column_width_pt = 221.0
const text_width_pt = 452.0

# Conversion factor: 72.27 LaTeX points per 72 Makie (PostScript) points.
const latex_pt_per_pt = 72.27 / 72
const latex_pt_per_in = 72.27

# Aspect ratio of plot.
const figure_aspect_ratio = 4 / 3

# Define text padding.
const text_pad_pt = 4

const letters = [raw"\textbf{" * c * "}" for c in 'A':'Z']

const n = 1000
const x_apex_value = 0.035

function parse_commandline()::Dict
    arg_defs = ArgParseSettings()
    add_arg_table(arg_defs,
        ["--input-folder", "-i"], Dict(
            :help => "Folder with JLD2 files containing CTL data.",
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
        ["--orientation", "-O"], Dict(
            :help => "Stack subplots horizontally or vertically.",
            :arg_type => String,
            :metavar => "{horizontal,vertical}",
            :range_tester => ∈(["horizontal", "vertical"]),
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

    if parsed_args["orientation"] == "horizontal"
        fig_width_in = text_width_pt / latex_pt_per_in
        fig_height_in = column_width_pt / latex_pt_per_in / figure_aspect_ratio
        fig, axs = subplots(1, 2, sharex=true, sharey=true, figsize=(fig_width_in, fig_height_in))
    else # parsed_args["orientation"] == "vertical"
        fig_width_in = column_width_pt / latex_pt_per_in
        fig_height_in = column_width_pt / latex_pt_per_in / figure_aspect_ratio * 2
        fig, axs = subplots(2, 1, sharex=true, sharey=true, figsize=(fig_width_in, fig_height_in))
    end

    frequency_functions::Dict{String, Function} = Dict(
        "winding" => oscillator_winding_frequency,
        "rotation" => oscillator_rotation_frequency,
    )
    frequency_function = frequency_functions[parsed_args["frequency-type"]]

    if parsed_args["x-type"] == "length"
        x = LinRange(0, x_apex_value, n + 1) .* 1000
        x_label = "distance from stapes / mm"
    else # parsed_args["x-type"] == "index"
        x = 0:n
        x_label = "oscillator index"
    end

    text_offset = matplotlib.transforms.ScaledTranslation(-text_pad_pt / latex_pt_per_in, -text_pad_pt / latex_pt_per_in, fig.dpi_scale_trans)

    glob_patterns = ["*s_no_rough.jld2", "*s_rough.jld2"]
    for (i, glob_pattern) in enumerate(glob_patterns)
        ax = axs[i - 1]
        input_files = sort(glob(glob_pattern, parsed_args["input-folder"]), lt=natural)

        for input_file ∈ input_files
            # JLD2 file with CTL data to load
            t, u = load(input_file, "t", "u")

            # Stack `u` to have a Matrix{Float64} rather than Vector{Vector{Float64}}
            u = stack(u, dims=1)

            ax.scatter(
                x,
                abs.(frequency_function(t, u)) ./ (2π),
            )
            # ax.grid(true)
            ax.set_yscale("log", base=10)
            ax.set_xlim(0.0, x_apex_value .* 1000)
            ax.set_ylim(1e0, 3e4)
            ax.text(
                1.0, 1.0,
                letters[i],
                horizontalalignment="right",
                verticalalignment="top",
                transform=ax.transAxes + text_offset,
            )
        end
    end

    fig.supxlabel(x_label)
    fig.supylabel("$(lowercase(parsed_args["frequency-type"])) frequency / Hz")

    input_files = sort(glob(glob_patterns[1], parsed_args["input-folder"]), lt=natural)
    durations = sort([
        parse(Int, m[1])
        for f in input_files
        for m in [match(r"_(\d+)s_", f)]
        if m !== nothing
    ])
    labels = ["$(d)\\,s" for d in durations]
    fig.legend(labels, loc="outside upper center", ncols=3)

    if !isnothing(parsed_args["title"])
        fig.suptitle(parsed_args["title"])
    end

    mkpath(dirname(parsed_args["output-file"]))
    fig.savefig(parsed_args["output-file"])
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
