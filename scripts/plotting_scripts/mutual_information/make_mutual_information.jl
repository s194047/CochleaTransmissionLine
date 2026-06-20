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
            :help => "JLD2 file containing CTL data.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
        ["--output-file", "-o"], Dict(
            :help => "JLD2 file to store the calculated mutual information.",
            :arg_type => String,
            :metavar => "PATH",
            :required => true,
        ),
    )

    parse_args(arg_defs)
end

function main()
    parsed_args = parse_commandline()

    # JLD2 file with CTL data to load
    println(stderr, "Loading solution from $(parsed_args["input-file"])")
    u, metadata = load(parsed_args["input-file"], "u", "metadata")

    # Stack `u` to have a Matrix{Float64} rather than Vector{Vector{Float64}}
    u = stack(u, dims=1)

    # Extract the displacement and velocity from the solution.
    y = @view u[:, 1:2:end]
    v = @view u[:, 2:2:end]

    # Calculate the mutual information between oscillators of y and v.
    M_y = mutual_information_matrix(y)
    M_v = mutual_information_matrix(v)

    output_file = parsed_args["output-file"]
    mkpath(dirname(output_file))
    jldsave(
        output_file,
        ;
        M_y,
        M_v,
        metadata,
    )
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
