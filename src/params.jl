@kwdef struct CochleaTransmissionLineParam
    n # Number of discrete segments
    x#::Vector{Float64} # Longitudinal coordinate
    m#::Float64 # Membrane mass per unit area
    d#::Function # Membrane damping.
    s#::Vector{Float64} # Feedback stiffness
    c # Feedback stiffness term
    τ # Delay of feedback stiffness
end
