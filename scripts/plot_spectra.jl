using JLD2
using Plots
using FFTW
using DataInterpolations

function main()
    # Read data filename.
    if length(ARGS) < 1
        println("Pass JLD2 data file as first argument.")
        exit(1)
    end
    data_filename = ARGS[1]
    if length(ARGS) < 2
        println("Pass first index as second argument.")
        exit(1)
    end
    osc_idx_first = parse(Int64, ARGS[2]) + 1
    if length(ARGS) < 3
        println("Pass last index as third argument.")
        exit(1)
    end
    osc_idx_last = parse(Int64, ARGS[3]) + 1
    if length(ARGS) < 4
        println("Pass sampling frequency as fourth argument.")
        exit(1)
    end
    fs = parse(Float64, ARGS[4])

    v_ref = 1e-6
    v_ref_string = "1 µm/s"

    t, u = load(data_filename, "t", "u")

    interpolator = CubicSpline(u, t)
    t_resampled = collect(t[1]:1/fs:t[end])
    u_resampled = interpolator(t_resampled)

    u_resampled = stack(u_resampled, dims=1)
    v_resampled = u_resampled[:,2:2:end]

    N = length(t_resampled)
    f = fftfreq(N, fs)
    V = abs.(fft(v_resampled, 1))

    V_db = 20 * log10.(V ./ v_ref)

    p = plot(
        f[1:N ÷ 2],
        V_db[1:N ÷ 2, osc_idx_first:osc_idx_last],
        xlim=(0, maximum(f)/2),
        xlabel="Frequency (Hz)",
        ylabel="Velocity Magnitude (dB re $v_ref_string)",
        title="All Oscillator Spectra"
    )
    display(p)
    println("Press enter to exit...")
    readline()
    exit(0)
end

# Only run if script is executed directly.
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
