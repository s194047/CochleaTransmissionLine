#================
Default constants
================#

const ρ_water = 1e3  # kg/m^3
const h_scala = 1e-3 # m
const m_BM = 0.375   # kg / m^2

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
    nonlin_scaling_taper = 0.5,
    γ = 0.12,
    α = 40,
    μ_α = 6,
    β = -10,
    μ_β = 5,
    fluid_CP_κ = 2 * ρ_water / (h_scala * m_BM),
)

const default_u0_value = [0.0, 0.0]

# TODO: Implement a way to choose stimulus functions (e.g., sinusoidal, impulse, audio-file).
const stimulus(t::Float64) :: Float64 = 10 * sin(2π * 1000 * t)
