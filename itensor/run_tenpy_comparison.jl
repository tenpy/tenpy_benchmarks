using LinearAlgebra
using MKL
using ITensors, ITensorMPS
using ArgParse

println(BLAS.get_config())

mutable struct CustomObserver <: AbstractObserver
    start_walltime::Float64
    max_seconds::Float64
    nsweeps::Int64
    sweeps::Vector{Int}
    maxlinkdims::Vector{Int}
    walltimes::Vector{Float64}

    CustomObserver(nsweeps::Int64, max_seconds::Float64) = new(time(), max_seconds, nsweeps,
                                                               Vector{Int}(), Vector{Int}(), Vector{Float64}())
end

function ITensors.checkdone!(o::CustomObserver;kwargs...)
    t_now = time()
    elapsed = t_now - o.start_walltime
    sw = kwargs[:sweep]
    psi = kwargs[:psi]
    push!(o.sweeps, sw)
    push!(o.maxlinkdims, maxlinkdim(psi))
    push!(o.walltimes, elapsed)
    if sw >= o.nsweeps
        println("stopping dmrg after sweep $sw")
        return true
    end
    if elapsed > o.max_seconds
        println("stopping dmrg after sweep $sw due to taking $elapsed seconds")
        return true
    end
    return false  # else keep going
end

function run(; maxdim::Int=2028,
               nsweeps::Int = 22,
               max_seconds::Float64 = 1000.,
               blas_num_threads::Int = 1,
               outputlevel::Int = 1,
               conserve_qns::Bool = false,
               use_sparse_mpo::Bool = false,
               N::Int = 100,
    )
    println("Using $blas_num_threads BLAS threads")
    BLAS.set_num_threads(blas_num_threads)
    @show conserve_qns
    @show use_sparse_mpo
    sites = siteinds("S=1", N; conserve_qns = conserve_qns)
    ampo = AutoMPO()
    for j in 1:N-1
        ampo .+= 0.5, "S+", j, "S-", j+1
        ampo .+= 0.5, "S-", j, "S+", j+1
        ampo .+=      "Sz", j, "Sz", j+1
    end
    HD = MPO(ampo,sites)
    if use_sparse_mpo
        println("Splitting blocks of H (= making MPO sparse)")
        H = splitblocks(linkinds, HD)
    else
        println("Using dense MPO")
        H = HD
    end
    psi0 = productMPS(sites, n -> isodd(n) ? "↑" : "↓")
    sweeps = Sweeps(nsweeps)
    maxdims = min.(maxdim, [10,   10,   
                            32,   32,   
                            64,   64,   
                            128,  128,  
                            256,  256,  
                            384,  384,  
                            512,  512,  
                            768,  768,  
                            1024, 1024, 
                            1536, 1536, 
                            2048, 2048, ])
    maxdim!(sweeps, maxdims...)
    cutoff!(sweeps, 0.0)
    obs = CustomObserver(nsweeps, max_seconds)
    t = @elapsed begin
    energy, ψ = dmrg(H, psi0, sweeps;
                     observer=obs, outputlevel=outputlevel)
    end
    println("total time $t")
    return obs
end

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--blas_num_threads"
            help = "number of BLAS threads"
            arg_type = Int
            default = 1
        "--conserve_qns"
            help = "a positional argument"
            arg_type = Bool
            default = true
        "--max_seconds"
            help = "Stop DMRG if total runtime exceeeds this"
            arg_type = Float64
            default = 1000.
        "--output_filename"
            help = "Stop DMRG if total runtime exceeeds this"
            arg_type = String
            default = ""
    end
    return parse_args(s)
end


function main()
    args = parse_commandline()
    @show args
    obs = run(
        blas_num_threads=args["blas_num_threads"],
        conserve_qns=args["conserve_qns"],
        use_sparse_mpo=args["conserve_qns"],
        max_seconds=args["max_seconds"],
       )
    output_filename = args["output_filename"]
    if output_filename != ""
        mkpath(dirname(output_filename))
        open(output_filename, "w") do io
            println(io, "# sweep maxlinkdim walltime")
            for (sweep, max_dim, walltime) in zip(obs.sweeps, obs.maxlinkdims, obs.walltimes)
                println(io, "$sweep $max_dim $walltime")
            end
        end
    end
end

main()
