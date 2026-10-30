using FFTW
using PythonPlot

fs = 50000
t = 0:1/fs:1-1/fs
f = fftfreq(length(t), fs)
freqs = stack((100:150:1000)')
s = sin.(2π*freqs .* t)

figure()
imshow(s[1:500,:], aspect="auto", interpolation="none")

S = fft(s, 1)

@show size(S[:,1])
figure()
plot(fftshift(f), abs.(fftshift(S[:,5])))
xlim(-(freqs[5] * 1.05), (freqs[5] * 1.05))

PythonPlot.show()
