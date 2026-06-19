using CochleaTransmissionLine

using TimeZones
using JLD2
using PythonPlot
using DSP
using ArgParse

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
    )
    parse_args(arg_defs)
end

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

function amplitude_from_filename(filename::String)
    parse(Float64, match(r"amplitude-([\d.e\+-]+)\.", filename::String).captures[1])
end

function main()
    parsed_args = parse_commandline()
    input_folder = parsed_args["input-folder"]
    output_file = parsed_args["output-file"]

    println("Processing folder: $input_folder")

    v_ref = 1e-6

    x_apex = 0.035 # meters
    x_apex_mm = x_apex * 1e3 # mm

    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio

    fig = figure(figsize=(fig_width_in, fig_height_in))

    filenames = filter(f -> endswith(f, ".jld2"), readdir(input_folder))
    filenames_sorted = sort(filenames, by=amplitude_from_filename)
    for data_filename in filenames_sorted
        full_data_path = joinpath(input_folder, data_filename)
        u = load(full_data_path, "u")
        u = stack(u, dims=1)
        v = u[:,2:2:end]

        v_amplitudes = (maximum(v, dims=1) .- minimum(v, dims=1))[:] ./ 2

        v_amplitudes_db = amp2db.(v_amplitudes ./ v_ref)

        osc_idxs = 0:size(v, 2) - 1
        max_osc_idx = osc_idxs[end]
        x_values_mm = x_apex_mm * (osc_idxs ./ max_osc_idx)

        plot(x_values_mm, v_amplitudes_db, color="C1", linestyle="-")
    end
    ylim(-20, 90)

    xlabel(raw"distance from stapes / mm")
    ylabel(raw"velocity / dB\,re\,$10^{-6}$\,m/s")

    mkpath(dirname(output_file))
    fig.savefig(output_file)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
