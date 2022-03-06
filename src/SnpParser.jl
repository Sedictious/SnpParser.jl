module SnpParser

using LinearAlgebra;
using Plots; 

include("parser.jl")
include("utils.jl")
include("plotter.jl")

export TouchstoneSnP, plot_snp

end # module
