const default_ctl_constants = CochleaTransmissionLineConstants(
    n = 1000,
    x_apex_value = 0.035,
    m = 0.375,
    A = 20_832,
    λ = 60,
    κ = 145.5,
    v_ref = 1e-6,
    δ_sat_a = 0.2,
    δ_sat_k = 0.52,
    δ_neg_a = -0.12,
    δ_neg_k = -0.17,
    σ_zweig_a = 0.1416,
    σ_zweig_k = -0.17,
    γ = 0.12,
    α = 40,
    μ_α = 6,
    β = -10,
    μ_β = 5,
    fluid_CP_β = 6.53e-3,
)

const default_u0_value = [1e-9, 0.0]
