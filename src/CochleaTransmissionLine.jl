module CochleaTransmissionLine

include("model.jl")
export CochleaTransmissionLineConstants
export CochleaSolverInputParams
export makeCochleaSolverInputParams
export cochlea_transmission_line!

include("data_analysis.jl")
export get_solution_samples
export instantaneous_rotation

end # module CochleaTransmissionLine
