using ArgParse

"""
    argparse_error(arg_defs, message)

Print an error message along with the arg usage and exit.
"""
function argparse_error(arg_defs::ArgParseSettings, message::String)
    println(stderr, "$message")
    println(stderr, usage_string(arg_defs))
    exit(1)
end
