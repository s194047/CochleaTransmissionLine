# Plot similar to Epp et al. 2010, Fig. 3
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

    # Get all filenames and sort them by the amplitude
    filenames = readdir(data_dir)
    filenames_sorted = sort(filenames, by=amplitude_from_filename)

    ignore_idxs = 50

    characteristic_idx = nothing
    input_amplitude_db_spl_values = []
    v_cp_db_values = []
    for (i, data_filename) in enumerate(filenames_sorted)
        full_data_path = joinpath(data_dir, data_filename)
        println("Processing file: $full_data_path")
        t, u, metadata = load(full_data_path, "t", "u", "metadata")

        input_amplitude = metadata["stimulus"]["amplitude"]
        input_amplitude_db_spl = amp2db(input_amplitude / input_amplitude_spl_ref)

        u = stack(u, dims=1)
        v = u[:,2:2:end]

        t_analysis_start = t[end] - evaluation_period
        analysis_start_idx = findfirst(t .>= t_analysis_start)

        v_analysis = v[analysis_start_idx:end, :]

        v_amplitudes = maximum(v_analysis, dims=1)[:]

        v_amplitudes_db = amp2db.(v_amplitudes ./ v_ref)

        osc_idxs = 0:size(v, 2) - 1
        max_osc_idx = osc_idxs[end]

        if i == 1
            # Find the characteristic place of the sine stimulus as the peak place of the lowest level
            println("Finding the characteristic place from $full_data_path")
            characteristic_idx = argmax(v_amplitudes_db[ignore_idxs:end-ignore_idxs]) + ignore_idxs - 1
            characteristic_place_mm = x_apex_mm * (characteristic_idx / max_osc_idx)
            println("Characteristic place for stimulus: $characteristic_place_mm mm")
        end

        v_cp_db = v_amplitudes_db[characteristic_idx]

        push!(input_amplitude_db_spl_values, input_amplitude_db_spl)
        push!(v_cp_db_values, v_cp_db)
    end

    p = plot(
        title="I/O function: velocity amplitude",
        xlabel="input level (dB SPL)",
        ylabel="velocity amplitude (dB re $v_ref_string)",
        leg=false,
        ylims=(-20, 90),
        yticks=-20:20:90,
        xlims=(0 - 5, 120 + 5),
        xticks=0:20:120,
    )

    plot!(
        p,
        input_amplitude_db_spl_values,
        v_cp_db_values,
        linestyle=:solid,
        marker=:circle,
        color=:black
    )

    # Calculate 1 dB/dB lines for the first and last points
    x_line = [input_amplitude_db_spl_values[1], input_amplitude_db_spl_values[end]]
    y_line_low = [v_cp_db_values[1], v_cp_db_values[1] + (x_line[2] - x_line[1])]
    y_line_high = [v_cp_db_values[end] - (x_line[2] - x_line[1]), v_cp_db_values[end]]

    plot!(p, x_line, y_line_low, linestyle=:dash, color=:gray)
    plot!(p, x_line, y_line_high, linestyle=:dash, color=:gray)

    # Calculate compression input dynamic range in dB
    # Here, we are using the fact that the lines have slope 1 dB/dB,
    # so the horizontal and vertical distances are equal.
    compression_dynamic_range_db = y_line_low[1] - y_line_high[1]
    println("Compression input dynamic range: $compression_dynamic_range_db dB")

    # Add a horizontal line to the plot at 0 dB SPL input level to show the compression between the two 1 dB/dB lines
    plot!(
        p,
        [x_line[1], x_line[1] + compression_dynamic_range_db],
        [y_line_low[1], y_line_low[1]],
        linestyle=:dash,
        color=:gray,
        arrow=:both,
    )
    annotate!(
        p,
        x_line[1] + compression_dynamic_range_db / 2,
        y_line_low[1] - 5,
        text("$(round(compression_dynamic_range_db, digits=1)) dB", :center, 10, :gray)
    )

    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

main()
# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
