# TODO: Implement a way to choose stimulus functions (e.g., sinusoidal, impulse, audio-file).
const stimulus(t::Float64) :: Float64 = 0.0

# TODO: Consider if it's more efficient to implement d and c to work on a vector
# Damping
const d_impl(
    ;
    x_index,
    v_db,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    δ_sat_values,
    δ_neg_values,
    sqrt_m_times_s_values,
) = let
        δ_sat = δ_sat_values[x_index+1];
        δ_neg = δ_neg_values[x_index+1];
        δ = δ_sat - δ_neg;
        sqrt_m_times_s = sqrt_m_times_s_values[x_index+1];

        (
            (1 - γ) * δ * ( 1 - 1 / (1 + exp((v_db - α) / μ_α)) ) +
            γ       * δ * ( 1 - 1 / (1 + exp((v_db - β) / μ_β)) ) +
            δ_neg
        ) * sqrt_m_times_s
end

# Feedback stiffness
const c_impl(
    ;
    x_index,
    v_db,
    α,
    μ_α,
    β,
    μ_β,
    γ,
    σ_zweig_values,
) = let
        σ_zweig = σ_zweig_values[x_index+1];

        (1 - γ) * σ_zweig * ( 1 / (1 + exp((v_db - α) / μ_α)) ) +
        γ       * σ_zweig * ( 1 / (1 + exp((v_db - β) / μ_β)) )
end
