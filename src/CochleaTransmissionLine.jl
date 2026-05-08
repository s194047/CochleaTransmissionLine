module CochleaTransmissionLine

include("history.jl")
export UHistory
export forget_history_function

include("model.jl")
export CochleaTransmissionLineConstants
export CochleaModelParams
export makeCochleaModelParams
export cochlea_transmission_line!

include("data_analysis.jl")
export get_solution_samples
export instantaneous_rotation
export oscillator_rms
export oscillator_rotation_frequency
export oscillator_winding_frequency

include("util.jl")
export argparse_error
export load_stimulus
export SolverParams
export load_parameters
export make_initial_conditions

end # module CochleaTransmissionLine
