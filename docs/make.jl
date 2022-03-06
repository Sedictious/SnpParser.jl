push!(LOAD_PATH,"../src/")
using SnpParser

Documentermakedocs(
         sitename = "SnpParser.jl",
         modules  = [SnpParser],
         pages=[
                "Home" => "index.md"
               ])
               
deploydocs(;
    repo="github.com/Sedictious/SnpParser.jl",
)