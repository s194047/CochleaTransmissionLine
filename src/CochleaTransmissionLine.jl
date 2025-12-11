module CochleaTransmissionLine

include("params.jl")
export CochleaTransmissionLineConstants
export CochleaSolverInputParams
export makeCochleaSolverInputParams

include("model.jl")
export cochlea_transmission_line!

include("data_analysis.jl")
export get_solution_samples
export instantaneous_rotation

export default_ctl_constants
export default_u0_value

end # module CochleaTransmissionLine
