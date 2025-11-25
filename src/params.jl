@kwdef struct CochleaTransmissionLineParam
    n # Number of discrete segments
    x::Vector{Float64} # Longitudinal coordinate
    m::Float64 # Membrane mass per unit area
    d::Function # Membrane damping. Function from vector of membrane y position to vector of membrane damping.
    s::Vector{Float64} # Feedback stiffness
    #inv_M
    #β
    #drive
    #apex
end
