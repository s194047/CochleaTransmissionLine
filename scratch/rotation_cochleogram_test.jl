using TimeZones
using JLD2
using Plots
using Statistics

using CochleaTransmissionLine

# t, u, metadata = load("data/test3.jld2", "t", "u", "metadata")
# (; t_values, u_values, du_values) = interpolate_signal(t, u, 44100.0, compute_derivative=true, ignore_seconds_start=0.001, ignore_seconds_end=0.001)

t, u, metadata = load("data/excitation_patterns/sine_f_1e3_a_1e1_rise_time_0.010.jld2", "t", "u", "metadata")
(; t_values, u_values, du_values) = interpolate_signal(t, u, 44100.0, compute_derivative=true, ignore_seconds_start=0.300, ignore_seconds_end=0.001)

# t, u, metadata = load("data/spontaneous_activity.jld2", "t", "u", "metadata")
# (; t_values, u_values, du_values) = interpolate_signal(t, u, 44100.0, compute_derivative=true, ignore_seconds_start=0.200, ignore_seconds_end=0.001)
# plot(t_values, u_values[:, 1001])


f_values = let
    model_constants = metadata["model_constants"]
    x_indices = 0:model_constants["n"];
    x_norm_positions = x_indices / model_constants["n"];
    x_apex_value = model_constants["x_apex_value"]
    x_positions = x_norm_positions * x_apex_value;
    A::Float64 = model_constants["A"];
    λ::Float64 = model_constants["λ"];
    κ::Float64 = model_constants["κ"];
    CochleaTransmissionLine.calculate_frequencies(x_positions = x_positions, A = A, λ = λ, κ = κ)
end

u_values_scaled = u_values
du_values_scaled = du_values

u_values_scaled[:, 2:2:end] .= u_values[:, 2:2:end] ./ 2π * f_values
du_values_scaled[:, 2:2:end] .= du_values[:, 2:2:end] ./ 2π * f_values
ρ_inst_values = instantaneous_rotation(u_values_scaled, du_values_scaled)
#ρ_inst_values = instantaneous_rotation(u_values, du_values)

begin
    t_idxs = 1:15
    osc_idxs = [501]
    heatmap(t_values[t_idxs], osc_idxs, (ρ_inst_values[t_idxs, osc_idxs]), clims=(0, 10000))
    # heatmap(t_values, 0:1000, log10.(ρ_inst_values))
end

ρ_mean = mean(ρ_inst_values, dims=1)
plot(100:900, ρ_mean[100:900])

begin
    t_idxs = 50:5000
    osc_idx = 340
    plot(u_values[t_idxs, osc_idx*2 + 1], u_values[t_idxs, osc_idx*2 + 2])
end

begin
    mean_rotation_values = mean_rotation(collect(t_values), u_values, scale_by_rms=true)

    n = metadata["model_constants"]["n"]
    x_apex_value = metadata["model_constants"]["x_apex_value"]
    x_values = (0:1/n:1) * x_apex_value

    xlims = (x_values[1], x_values[end])
    #xlims = (0.002, 0.005)
    ylims = (0, 1e4)

    plot(x_values, -mean_rotation_values / 2π, xlims=xlims, ylims=ylims)
end

# Cochleogram
begin
    y_values = u_values[:, 1:2:end]
    v_values = u_values[:, 2:2:end]
    osc_idxs = 0:1000
    heatmap(t_values, osc_idxs, v_values[:, osc_idxs .+ 1])
end
