"""
...
# Arguments
- `snp::TouchstonerSnP`: Provided Touchstone file
- `parameter_type::Str`: Network parameter you want to plot. Possible options:
    * `S` scattering parameters
    * `Y` admittance parameters
    * `Z` impedance parameters
    * `H` hybrid-h parameters (two-port network only)
    * `G` hybrid-g parameters (two-port network only)
- `ports::Arr` : Ports to plot. For example, in order to plot S11 and S12 you the provided parameter
                    should he [[1, 1], [1, 2]]
- `noise_data::Bool` : If set to `true` returns results for Noise Data. Else,
    Network Data are assumed
...
"""
function plot_snp(snp::TouchstoneSnP, parameter_type::String, ports::Set = [], noise_data=false)
    # todo, implement option for alternative plotting options (e.g. Smith chart)
    # for now, just the magnitudes will be plotted 
    
    frequencies = sort(collect(keys(snp.network_data)))
    parameters = getindex.(Ref(snp.network_data), frequencies)
    # Convert to appropriate parameters

    # this is the most inefficient way possible to achieve this but in most cases, there are 4 ports at most
    if snp.matrix_format != "FULL"
        ports = Set(sort.(ports))
    end
    
    
    tplot = plot(palette = :darktest, xlabel = "Frequency ["*snp.frequency_unit*"]", ylabel = "|Magnitude| [dB]")

    for p in ports
        labelp = parameter_type*string(p[1])*string(p[2])
        
        param_magnitudes = []

        for freq in frequencies
            ri_param = getindex(convert_param_type(snp, freq, parameter_type, noise_data), p[1], p[2])
            push!(param_magnitudes, 20log10(sqrt(real(ri_param)^2+imag(ri_param)^2)))
        end
        plot!(tplot, frequencies, param_magnitudes, label=labelp, lw = 2)
    end
    gui(tplot)

end