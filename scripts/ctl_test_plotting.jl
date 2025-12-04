using JLD2
using Plots
using FFTW

using CochleaTransmissionLine

# Include the parameters for CTL
include("ctl_test_setup.jl")

@load data_filename solution

fs = 1e6 # Sampling rate (Hz)

t, u = get_solution_samples(solution, fs)
_, du = get_solution_samples(solution, fs, Val{1})
y, v = @views u[:, 1:2:end], u[:, 2:2:end]
dy, dv = @views du[:, 1:2:end], du[:, 2:2:end]

# TODO: Consider putting the scaling into a function in data analysis
ω_R = 2π * stack([f_R.(x)], dims=1)
u_scaled = copy(u)
du_scaled = copy(du)
v_scaled = @view u_scaled[:, 2:2:end]
dv_scaled = @view du_scaled[:, 2:2:end]
v_scaled .= v ./ ω_R
dv_scaled .= dv ./ ω_R

ρ_inst = instantaneous_rotation(u_scaled, du_scaled)

begin
    osc_idx_range = 1:1000
    t_min = 0.09500
    t_max = 0.10000
    t_idx_range = Int(floor(t_min * fs)) + 1:Int(floor(t_max * fs)) + 1
    heatmap(osc_idx_range, t[t_idx_range], y[t_idx_range, osc_idx_range])
end

Y = fftshift(fft(y, 1), 1)
freqs =  fftshift(fftfreq(length(t), fs))

begin
    plot(freqs, abs.(Y[:,500]), xlims=(1e1, 3e4), xscale=:log10, leg=false)
end


# Analyze the data
# ================

fs = 1e6 # Sampling rate (Hz)

t, u = get_solution_samples(solution, fs)
_, du = get_solution_samples(solution, fs, Val{1})
y, v = @views u[:, 1:2:end], u[:, 2:2:end]
dy, dv = @views du[:, 1:2:end], du[:, 2:2:end]

# TODO: Consider putting the scaling into a function in data analysis
ω_R = 2π * stack([f_R.(x)], dims=1)
u_scaled = copy(u)
du_scaled = copy(du)
v_scaled = @view u_scaled[:, 2:2:end]
dv_scaled = @view du_scaled[:, 2:2:end]
v_scaled .= v ./ ω_R
dv_scaled .= dv ./ ω_R

ρ_inst = instantaneous_rotation(u_scaled, du_scaled)

begin
    osc_idx_range = 1:500
    t_min = 0.09500
    t_max = 0.10000
    t_idx_range = Int(floor(t_min * fs)) + 1:Int(floor(t_max * fs)) + 1
    heatmap(osc_idx_range, t[t_idx_range], v[t_idx_range, osc_idx_range])
end
begin
    osc_idx_range = 500:1000
    t_min = 0.09000
    t_max = 0.10000
    t_idx_range = Int(floor(t_min * fs)) + 1:Int(floor(t_max * fs)) + 1
    heatmap(osc_idx_range, t[t_idx_range], v[t_idx_range, osc_idx_range])
end

begin
    osc_idx_range = 250:255
    t_min = 0.01000
    t_max = 0.01100
    t_idx_range = Int(floor(t_min * fs)):Int(floor(t_max * fs))
    plot(t[t_idx_range], v[t_idx_range, osc_idx_range], leg=false)
end

begin
    osc_idx_range = 1:1000
    t_min = 0.01000
    t_max = 0.01100
    t_idx_range = Int(floor(t_min * fs)):Int(floor(t_max * fs))
    ρ_mean = vec(mean(ρ_inst[t_idx_range, osc_idx_range], dims=1))
    scatter(osc_idx_range, ρ_mean, leg=false)
    ylims!(0, 30_000)
end

# begin
    #     x = 0.000
#     v = logrange(1e-9, 1e-2, 100)
#     plot()
#     plot!(Λ.(v), d.(x, v) / sqrt(m * s(x)))
#     plot!(Λ.(v), c.(x, v))
#     ylims!(-.2, .5)
#     xlims!(-60, 80)
# end
