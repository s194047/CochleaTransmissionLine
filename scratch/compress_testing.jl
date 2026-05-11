using JLD2
using TimeZones

# Define original uncompressed file.
uncompressed_filename = "data/audio_test.jld2"

# Load data from a solution.
t, u, metadata = load(uncompressed_filename, "t", "u", "metadata")

# Save the solution without compression to get a baseline save time.
println("")
uncompressed_test_filename = replace(uncompressed_filename, ".jld2" => "_uncompressed.jld2")
println("Saving uncompressed solution to $uncompressed_test_filename...")
mkpath(dirname(uncompressed_test_filename))
uncompressed_save_time = @elapsed jldsave(
    uncompressed_test_filename,
    ;
    t,
    u,
    metadata,
)
println("Time to save uncompressed file: $(round(uncompressed_save_time, digits=2)) seconds")

# Compress with different methods and levels.
methods = [Deflate(5), Deflate(9), ZstdFilter(3), ZstdFilter(9), ZstdFilter(22)]
for method in methods
    for shuffling in [true, false]
        compressed_filename = replace(uncompressed_filename, ".jld2" => "_$(method)_shuffle_$(shuffling).jld2")
        println("Saving compressed solution to $compressed_filename with method $method and shuffling $shuffling...")
        mkpath(dirname(compressed_filename))
        filters = shuffling ? [Shuffle(), method] : method
        save_time = @elapsed jldsave(
            compressed_filename,
            filters,
            ;
            t,
            u,
            metadata,
        )
        println("Time to save compressed file: $(round(save_time, digits=2)) seconds")
        println("Compression time increase compared to uncompressed: $(round(save_time / uncompressed_save_time, digits=2))x")
    end
end

# Compare the file sizes of the the original and compressed files.
original_size = filesize(uncompressed_filename)
println("Original file size: $(original_size / 1e6) MB")
for method in methods
    for shuffling in [true, false]
        compressed_filename = replace(uncompressed_filename, ".jld2" => "_$(method)_shuffle_$(shuffling).jld2")
        compressed_size = filesize(compressed_filename)
        println("Compressed file size with method $method and shuffling $shuffling: $(compressed_size / 1e6) MB (compression ratio: $(round(original_size / compressed_size, digits=2)))")
    end
end
