using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using PythonPlot

matplotlib.use("pdf")
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
            :help => "JLD2 file containing mutual information matrices.",
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
        ["--x-type", "-x"], Dict(
            :help => "Whether to plot x as oscillator index or length.",
            :arg_type => String,
            :metavar => "{index,length}",
            :range_tester => ∈(["index", "length"]),
            :required => true,
        ),
    )

    parse_args(arg_defs)
end

function create_figure(M::AbstractMatrix{Float64}, output_file::String, x_label::String, x_extent::Tuple{Float64, Float64})
    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio

    fig = figure(figsize=(fig_width_in, fig_height_in))
    imshow(
        M,
        origin="lower",
        extent=[x_extent[1], x_extent[2], x_extent[1], x_extent[2]],
    )

    xlabel(x_label)
    ylabel(x_label)

    ticker() = matplotlib.ticker.MaxNLocator(5)
    gca().xaxis.set_major_locator(ticker())
    gca().yaxis.set_major_locator(ticker())

    mkpath(dirname(output_file))
    fig.savefig(output_file)
end


function main()
    parsed_args = parse_commandline()
    input_file = parsed_args["input-file"]
    output_file = parsed_args["output-file"]
    x_type = parsed_args["x-type"]

    # Load precomputed mutual information matrices
    println(stderr, "Loading mutual information from $(input_file)")
    M_y, M_v, metadata = load(input_file, "M_y", "M_v", "metadata")

    n = metadata["model_constants"]["n"]
    if x_type == "length"
        x_apex_value = metadata["model_constants"]["x_apex_value"] * 1000
        x_label = "distance from stapes / mm"
        dx = x_apex_value / n
        x_extent = (0.0 - 0.5 * dx, x_apex_value + 0.5 * dx)
    else # x_type == "index"
        x_label = "oscillator index"
        x_extent = (-0.5, n + 0.5)
    end


    (output_base, output_extension) = splitext(output_file)
    output_prefix = output_base * "__x_type-$(x_type)"
    output_file_y = "$(output_prefix)__y$(output_extension)"
    output_file_v = "$(output_prefix)__v$(output_extension)"

    create_figure(M_y, output_file_y, x_label, x_extent)
    create_figure(M_v, output_file_v, x_label, x_extent)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
