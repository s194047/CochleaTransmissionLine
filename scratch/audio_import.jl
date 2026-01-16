using WAV
using Plots

y, fs = wavread("audio/hejsa_stereo.wav")

t_max = (length(y) - 1) / fs

t = 0:1/fs:t_max
