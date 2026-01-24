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
        println("Pass index as second argument.")
        exit(1)
    end
    osc_idx = parse(Int64, ARGS[2])
    if length(ARGS) < 3
        println("Pass sampling frequency as third argument.")
        exit(1)
    end
    fs = parse(Float64, ARGS[3])

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
    V = abs.(fft(v_resampled[:, osc_idx]))

    V_db = 20 * log10.(V ./ v_ref)

    p = plot(
        f[1:N ÷ 2],
        V_db[1:N ÷ 2],
        xlim=(0, maximum(f)/2),
        xlabel="Frequency (Hz)",
        ylabel="Velocity Magnitude (dB re $v_ref_string)",
        title="Spectrum of Oscillator $(osc_idx)"
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
