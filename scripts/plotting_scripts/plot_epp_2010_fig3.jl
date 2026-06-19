using CochleaTransmissionLine

using TimeZones
using JLD2
using PythonPlot
using PythonCall
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
        ["--spl-reference", "-r"], Dict(
            :help => "Amplitude corresponding to 0 dB SPL.",
            :arg_type => Float64,
            :metavar => "AMPLITUDE",
            :required => true,
        ),
        ["--ignore-idxs-start", "-s"], Dict(
            :help => "Number of indices to ignore from the start to find the characteristic place.",
            :arg_type => Int64,
            :metavar => "NUM",
            :required => true,
        ),
        ["--ignore-idxs-end", "-e"], Dict(
            :help => "Number of indices to ignore from the end to find the characteristic place.",
            :arg_type => Int64,
            :metavar => "NUM",
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
    spl_reference = parsed_args["spl-reference"]
    ignore_idxs_start = parsed_args["ignore-idxs-start"]
    ignore_idxs_end = parsed_args["ignore-idxs-end"]
    output_file = parsed_args["output-file"]

    println("Processing folder: $input_folder")

    v_ref = 1e-6

    x_apex = 0.035 # meters
    x_apex_mm = x_apex * 1e3 # mm

    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio

    filenames = filter(f -> endswith(f, ".jld2"), readdir(input_folder))
    filenames_sorted = sort(filenames, by=amplitude_from_filename)

    characteristic_idx = nothing
    input_amplitude_db_spl_values = []
    v_cp_db_values = []
    for (i, data_filename) in enumerate(filenames_sorted)
        full_data_path = joinpath(input_folder, data_filename)
        u = load(full_data_path, "u")
        u = stack(u, dims=1)
        v = u[:,2:2:end]

        input_amplitude = amplitude_from_filename(data_filename)
        input_amplitude_db_spl = amp2db(input_amplitude / spl_reference)

        v_amplitudes = (maximum(v, dims=1) .- minimum(v, dims=1))[:] ./ 2

        v_amplitudes_db = amp2db.(v_amplitudes ./ v_ref)

        osc_idxs = 0:size(v, 2) - 1
        max_osc_idx = osc_idxs[end]

        if i == 1
            # Find the characteristic place of the sine stimulus as the peak place of the lowest level
            println("Finding the characteristic place from $full_data_path")
            characteristic_idx = argmax(v_amplitudes_db[ignore_idxs_start:end-ignore_idxs_end]) + ignore_idxs_start - 1
            characteristic_place_mm = x_apex_mm * ((characteristic_idx - 1) / max_osc_idx)
            println("Characteristic place for stimulus: $characteristic_place_mm mm")
        end

        v_cp_db = v_amplitudes_db[characteristic_idx]
        push!(input_amplitude_db_spl_values, input_amplitude_db_spl)
        push!(v_cp_db_values, v_cp_db)
    end
    fig = figure(figsize=(fig_width_in, fig_height_in))

    plot_margin = 0.05
    margins(plot_margin)

    plot(
        input_amplitude_db_spl_values,
        v_cp_db_values,
        marker="o",
        linestyle="-",
        color="C2",
        zorder=3,
    )
    py_xlim = gca().get_xlim()
    jl_xlim = pyconvert(Tuple{Float64,Float64}, py_xlim)

    # Calculate 1 dB/dB lines for the first and last points
    x_line = [input_amplitude_db_spl_values[1], input_amplitude_db_spl_values[end]]
    y_line_low = [v_cp_db_values[1], v_cp_db_values[1] + (x_line[2] - x_line[1])]
    y_line_high = [v_cp_db_values[end] - (x_line[2] - x_line[1]), v_cp_db_values[end]]

    x_line_disp = [jl_xlim[1], jl_xlim[2]]
    y_line_disp_low = [
        v_cp_db_values[1],
        v_cp_db_values[1] + (x_line_disp[2] - x_line_disp[1]),
    ] .+ (x_line_disp[1] - x_line[1])
    y_line_disp_high = [
        v_cp_db_values[end] - (x_line_disp[2] - x_line_disp[1]),
        v_cp_db_values[end],
    ] .+ ((x_line_disp[2] - x_line[2]))

    plot(x_line_disp, y_line_disp_low, linestyle="--", color="C0")
    plot(x_line_disp, y_line_disp_high, linestyle="--", color="C0")

    # Calculate compression input dynamic range in dB
    # Here, we are using the fact that the lines have slope 1 dB/dB,
    # so the horizontal and vertical distances are equal.
    compression_dynamic_range_db = y_line_low[1] - y_line_high[1]
    println("Compression input dynamic range: $compression_dynamic_range_db dB")

    # Add a horizontal line to the plot at 0 dB SPL input level to show the compression between the two 1 dB/dB lines
    plot(
        [x_line[1], x_line[1] + compression_dynamic_range_db],
        [y_line_low[1], y_line_low[1]],
        linestyle=":",
        color="C0",
    )
    text(
        x_line[1] + compression_dynamic_range_db / 2,
        y_line_low[1] - 5,
        "$(round(compression_dynamic_range_db, digits=1)) dB",
        color="C0",
        horizontalalignment="center",
        verticalalignment="top",
        #transform=ax.transAxes + text_offset,
    )

    xlim(py_xlim)
    ylim(-45, 85)

    xlabel(raw"input level / dB\,SPL")
    ylabel(raw"output level / dB\,re\,$10^{-6}$\,m/s")

    mkpath(dirname(output_file))
    fig.savefig(output_file)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
