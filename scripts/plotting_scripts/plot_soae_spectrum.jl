using CochleaTransmissionLine

using TimeZones
using JLD2
using ArgParse
using PythonPlot
using FFTW

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
            :help => "Where to save the plot. Type is inferred from file extension.",
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
    t, u = load(parsed_args["input-file"], "t", "u")

    # Stack `u` to have a Matrix{Float64} rather than Vector{Vector{Float64}}
    u = stack(u, dims=1)
    v = u[1:end-1, 2:2:end]
    t = t[1:end-1]

    fs = 1/(t[2] - t[1])
    f = fftfreq(length(t), fs)
    V = fft(v, 1)

    figure()
    plot(f[1:20000], abs.(V[1:20000, 5]))
    PythonPlot.show()

    exit(0)

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
