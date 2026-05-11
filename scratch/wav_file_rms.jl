using Glob
using FilePaths
using WAV
using Statistics

# Load files containing CTL outputs
n_files = 5
speech_commands_processed_root = "/Users/sofus/Documents/DTU/MSc_project/no-backup/speech_commands_v0.01_up_down_yes_no"
subdir = "yes"
files_to_load = glob("*.wav", joinpath(speech_commands_processed_root, subdir))[1:n_files]
println(stderr, "List of files to load:")
for file in files_to_load
    println(stderr, "$file")
end

spl_target = 60.0
spl_reference = 0.001

println(stderr, "SPL target: $spl_target")
println(stderr, "SPL reference: $spl_reference")

for file in files_to_load
    println(stderr, "File to analyse: $file")
    y, fs = wavread(file)
    rms_value = sqrt(mean(y.^2))
    println(stderr, "RMS: $rms_value")

    gain = spl_reference * 10^(spl_target/20) / rms_value / sqrt(2)
    println(stderr, "Gain applied to signal: $gain")
end
