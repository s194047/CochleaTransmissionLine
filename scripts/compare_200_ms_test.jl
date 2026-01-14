using JLD2
using Plots

# Load the 200 ms test
t_200ms, u_200ms = load("data/200_ms_test/200_ms_test.jld2", "t", "u")

# Load the two 100 ms tests
t_100ms_1, u_100ms_1 = load("data/200_ms_test/2x_100_ms_test_1.jld2", "t", "u")
t_100ms_2, u_100ms_2 = load("data/200_ms_test/2x_100_ms_test_2.jld2", "t", "u")

# Concatenate the two 100 ms runs
# Adjust keys/fields based on your actual data structure
t_combined_100ms = vcat(t_100ms_1, t_100ms_2[2:end])  # Avoid duplicating the overlapping time point
u_combined_100ms = vcat(u_100ms_1, u_100ms_2[2:end, :])  # Adjust slicing as needed


# Compare results
println("200 ms test shape: ", size(u_200ms))
println("Combined 100 ms test shape: ", size(u_combined_100ms))

u_200ms_stacked = stack(u_200ms, dims=1)
u_combined_100ms_stacked = stack(u_combined_100ms, dims=1)
plot_idx = 1
# Plot the two results for visual comparison
plot(t_200ms, u_200ms_stacked[:, plot_idx], label="200 ms test", xlabel="Time (s)", ylabel="Displacement (m)", title="Comparison of 200 ms test\nand combined 100 ms tests")
plot!(t_combined_100ms, u_combined_100ms_stacked[:, plot_idx], label="Combined 100 ms tests", linestyle=:dash)
