module SnpParser

using LinearAlgebra;
using Plots; 

include("parser.jl")
include("utils.jl")
include("plotter.jl")

export TouchstoneSnP, plot_snp

# snp = TouchstoneSnP("test/example/one_port_z_params")
# println(snp)

s_params = [0.61 0.05; 3.72 0.45];
z0 = 50;

#plot_snp(snp, "S", Set([[1, 1], [2, 2], [3, 3]]))
#println(admittance_params_to_scatter(scatter_params_to_admittance(s_params, z0), z0))
#ri = get_ri_form(snp, 3.0)
#println(ri)
#println(impedance_params_to_scatter(ri, 40))

end # module
