# Plot similar to Epp et al. 2010, Fig. 2
using CochleaTransmissionLine

using JLD2
using Plots
using DSP

function main()
    # Read data directory
    if length(ARGS) < 1
        println("Pass directory containing JLD2 data files as first argument.")
        exit(1)
    end
    data_dir = ARGS[1]
    if length(ARGS) < 2
        println("Pass evaluation period as second argument.")
        exit(1)
    end
    evaluation_period = parse(Float64, ARGS[2])

    v_ref = 1e-6
    v_ref_string = "1 µm/s"

    # Input amplitude 0 dB SPL reference
    # This value is read rather crudely by comparing the
    # `plot_excitation_pattern_stack` graph with Epp et al. 2010, Fig 2.
    input_amplitude_spl_ref = 0.001

    x_apex = 0.035 # meters
    x_apex_mm = x_apex * 1e3 # mm

    # TODO: Make amplitudes available as metadata in JLD2 files.
    #       Use amplitudes to display in legend.
    #       Use x_apex_values to label x-axis with distance from stapes.
    p = plot(
        title="excitation pattern: velocity amplitude",
        xlabel="distance from stapes (mm)",
        ylabel="velocity amplitude (dB re $v_ref_string)",
        leg=true,
        ylims=(-20, 90),
        yticks=-20:20:90,
        xlims=(0, x_apex_mm),
        xticks=0:5:x_apex_mm,
    )

    filenames = readdir(data_dir)
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

        input_amplitude = metadata["stimulus"]["amplitude"]
        input_amplitude_db_spl = amp2db(input_amplitude / input_amplitude_spl_ref)

        plot!(p, x_values_mm, v_amplitudes_db, label="$(input_amplitude_db_spl) dB SPL")
    end

    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
