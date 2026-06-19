# Taken from https://gitlab.gbar.dtu.dk/bepp/bsc_mikkel_berrig/

using KernelDensity
using Base.Threads

function surprise(p::Float64)
    x = -p*log2(p)
    return ifelse(isnan(x),0.,x)
end
function entropy(xs::AbstractVector{Float64})
    U = kde(xs[abs.(xs).<typemax(Int32)/2])
    A = U.x[2]-U.x[1]
    P = sum(U.density[:])*A
    return sum(surprise.(U.density[:]))*A/P
end
function joint_entropy(xs::AbstractVector{Float64}, ys::AbstractVector{Float64})
    U = kde((xs[abs.(xs).<typemax(Int32)/2],
             ys[abs.(ys).<typemax(Int32)/2]))
    A = (U.x[2]-U.x[1]) * (U.y[2]-U.y[1])
    P = sum(U.density[:])*A
    return sum(surprise.(U.density[:]))*A/P
end
function conditional_entropy(xs::AbstractVector{Float64}, ys::AbstractVector{Float64})
    return joint_entropy(xs,ys) - entropy(ys)
end
function mutual_information(xs::AbstractVector{Float64}, ys::AbstractVector{Float64})
    return entropy(xs) + entropy(ys) - joint_entropy(xs,ys)
end
function mutual_information(xs::AbstractVector{Float64}, ys::AbstractMatrix{Float64})
    return [mutual_information(xs,ys[i,:]) for i in 1:size(ys,1)]
end

function mutual_information_matrix(xs::AbstractMatrix{Float64})
    N = size(xs,2)
    M = zeros(N,N)

    pairs = [(i, j) for i in 2:N for j in 1:i-1]
    pair_total = length(pairs)
    processed_pair_count = Atomic{Int}(0)
    @threads for (i, j) in pairs
        M[i,j] = mutual_information(@view(xs[:,i]),@view(xs[:,j]))
        M[j,i] = M[i,j]
        current_pair_count = atomic_add!(processed_pair_count, 1) + 1
        if current_pair_count % 1000 == 0
            println(stderr, "$current_pair_count / $pair_total  ($(round(100current_pair_count/pair_total; digits=1))%)")
        end
    end
    return M
end

function observe_percent_false(xs::Vector{Float64}, ys::Vector{Float64})
    minxy = minimum([xs;ys])
    maxxy = maximum([xs;ys])
    Avg = (minxy+maxxy)/2
    bounds = ((minxy,maxxy).-Avg).*1.3.+ Avg

    P = kde(xs[abs.(xs).<typemax(Int32)/2],boundary=bounds)
    Q = kde(ys[abs.(ys).<typemax(Int32)/2],boundary=bounds)

    Umin = minimum.(zip(P.density[:],Q.density[:]))
    pmin = sum(Umin)
    if pmin == 0.
        return 0.
    end
    return pmin/(sum(P.density[:])+sum(Q.density[:]))
end
function observe_percent_false(xs::Matrix{Float64}, ys::Matrix{Float64})
    return [observe_percent_false(xs[i,:],ys[i,:]) for i in 1:size(xs,1)]
end

function moments_of_distribution(xs::Vector{Float64}, n::Int64)
    U = kde(xs[abs.(xs).<typemax(Int32)/2])
    A = U.x[2]-U.x[1]
    p = sum(U.density[:])
    μₙ= [sum(U.x.^i .* U.density[:])/p for i in 1:n]
    return μₙ
end
function moments_of_distribution(xs::Matrix{Float64}, n::Int64)
    return mapslices((v)->moments_of_distribution(v,n),xs,dims=[2])
end
