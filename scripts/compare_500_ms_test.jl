using JLD2
using Plots

# Load the 500 ms test
t_500ms, u_500ms = load("data/500_ms_test/500_ms_test.jld2", "t", "u")

# Load the five 100 ms tests
t_100ms_1, u_100ms_1 = load("data/500_ms_test/5x_100_ms_test_1.jld2", "t", "u")
t_100ms_2, u_100ms_2 = load("data/500_ms_test/5x_100_ms_test_2.jld2", "t", "u")
t_100ms_3, u_100ms_3 = load("data/500_ms_test/5x_100_ms_test_3.jld2", "t", "u")
t_100ms_4, u_100ms_4 = load("data/500_ms_test/5x_100_ms_test_4.jld2", "t", "u")
t_100ms_5, u_100ms_5 = load("data/500_ms_test/5x_100_ms_test_5.jld2", "t", "u")

# Concatenate the five 100 ms runs
# Adjust keys/fields based on your actual data structure
t_combined_100ms = vcat(t_100ms_1, t_100ms_2[2:end], t_100ms_3[2:end], t_100ms_4[2:end], t_100ms_5[2:end])  # Avoid duplicating the overlapping time points
u_combined_100ms = vcat(u_100ms_1, u_100ms_2[2:end, :], u_100ms_3[2:end, :], u_100ms_4[2:end, :], u_100ms_5[2:end, :])  # Adjust slicing as needed


# Compare results
println("500 ms test shape: ", size(u_500ms))
println("Combined 100 ms test shape: ", size(u_combined_100ms))

u_500ms_stacked = stack(u_500ms, dims=1)
u_combined_100ms_stacked = stack(u_combined_100ms, dims=1)
plot_idx = 2001
# Plot the two results for visual comparison
plot(t_500ms, u_500ms_stacked[:, plot_idx], label="500 ms test", xlabel="Time (s)", ylabel="Displacement (m)", title="Comparison of 500 ms test\nand combined 100 ms tests")
plot!(t_combined_100ms, u_combined_100ms_stacked[:, plot_idx], label="Combined 100 ms tests", linestyle=:dash)
