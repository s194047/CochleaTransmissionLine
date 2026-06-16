using CochleaTransmissionLine

using TimeZones
using JLD2
using PythonPlot
using DSP

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
    parse(Float64, match(r"amplitude_([\d.e\+-]+)\.", filename::String).captures[1])
end

function epp_2010_fig_2(output_file::String)
    data_dir = "data/stimulus_sine"

    evaluation_period = 0.100

    v_ref = 1e-6

    x_apex = 0.035 # meters
    x_apex_mm = x_apex * 1e3 # mm

    fig_width_in = column_width_pt / latex_pt_per_in
    fig_height_in = fig_width_in / figure_aspect_ratio

    fig = figure(figsize=(fig_width_in, fig_height_in))

    filenames = filter(f -> endswith(f, ".jld2"), readdir(data_dir))
    filenames_sorted = sort(filenames, by=amplitude_from_filename)
    for data_filename in filenames_sorted
        full_data_path = joinpath(data_dir, data_filename)
        println("Processing file: $full_data_path")
        t, u, metadata = load(full_data_path, "t", "u", "metadata")
        u = stack(u, dims=1)
        v = u[:,2:2:end]

        t_analysis_start = t[end] - evaluation_period
        analysis_start_idx = findfirst(t .>= t_analysis_start)

        v_analysis = v[analysis_start_idx:end, :]

        v_amplitudes = maximum(v_analysis, dims=1)[:]

        v_amplitudes_db = amp2db.(v_amplitudes ./ v_ref)

        osc_idxs = 0:size(v, 2) - 1
        max_osc_idx = osc_idxs[end]
        x_values_mm = x_apex_mm * (osc_idxs ./ max_osc_idx)

        plot(x_values_mm, v_amplitudes_db, color="#999999", linestyle="-")
    end
    ylim(-20, 90)
    mkpath(dirname(output_file))
    fig.savefig(output_file)
end

function epp_2010_fig_3()

end

function main()
    epp_2010_fig_2("data/figures/epp_2010/fig_2.pdf")
    epp_2010_fig_3()
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
