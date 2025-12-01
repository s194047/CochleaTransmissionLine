@kwdef struct CochleaTransmissionLineParam
    # Meta Parameters
    n::Int64                # Number of discrete segments
    x::Vector{Float64}      # Longitudinal coordinate

    # Cochlear Partition (CP) Paramters
    m::Float64              # Membrane mass per unit area
    d::Function             # Membrane damping: (x, v) -> d
    s::Function             # Feedback stiffness: x -> s
    c::Function             # Feedback stiffness term: (x, v) -> d
    τ::Vector{Float64}      # Delay of feedback stiffness

    # Fluid Coupling Parameters
    β::Float64              # Fluid mass to CP mass ratio
    inv_M::Matrix{Float64}  # Inverse coupling matrix
    stimulus::Function      # Stapedial stimulus: t -> stimulus
end
