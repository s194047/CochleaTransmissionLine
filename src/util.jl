"""
    Get the amplitude as `Float64` from a filename

The amplitude can be used to sort parameter or data files by the amplitude.
"""
function amplitude_from_filename(filename::String)
    parse(Float64, match(r"a_([\d.e\+-]+)", filename::String).captures[1])
end
