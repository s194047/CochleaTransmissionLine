module CochleaTransmissionLine

include("model.jl")
export CochleaTransmissionLineConstants
export CochleaModelParams
export makeCochleaModelParams
export cochlea_transmission_line!

include("data_analysis.jl")
export get_solution_samples
export instantaneous_rotation

include("util.jl")
export amplitude_from_filename
export load_stimulus
export SolverParams
export load_paramters

end # module CochleaTransmissionLine
