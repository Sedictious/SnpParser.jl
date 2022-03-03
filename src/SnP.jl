module SnP

using Test, Plots, Match
println("Hello")
include("parser.jl")

TouchstoneSnP("example/example_port2")
end