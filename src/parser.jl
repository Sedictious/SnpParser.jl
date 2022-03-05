include("utils.jl")

struct TouchstoneSnP
    frequency_unit::String
    parameter_type::String
    parameter_format::String
    reference_resistance::Int # [Ohm]
    number_of_ports::Int
    number_of_frequencies::Int
    number_of_noise_frequencies::Int
    reference::Array{Float64}
    two_port_data_order::String
    matrix_format::String
    network_data::Dict#{Array{Float64}, 1}
    noise_data::Dict#{Array{Float64}, 1}
    
    function TouchstoneSnP(snp::AbstractString)
            
        sentences = map(uppercase, readlines(snp))
        # Default parameters
        frequency_unit = "GHZ"
        parameter_type = "S"
        parameter_format = "MA"
        reference_resistance = 50 # [Ohm]
        number_of_ports = 2 # Required
        number_of_frequencies = 2 # Required
        number_of_noise_frequencies = 0 # Required if noise data is present
        reference = []
        two_port_data_order = ""
        matrix_format = "FULL"
        network_data = Dict()
        noise_data = Dict()
        t_network = []
        t_noise = []

        i = 1
        i = skip_comments(sentences, i)
        m = match(r"^\s{0,}\[VERSION\]\s(2\.0)", sentences[i])[1]
        if m != "2.0"
            throw("Only version 2.0 is currently supported")
        end
        i = skip_comments(sentences, i+1)
        
        # Parse option line
        freq_unit = match(r"((?:GHZ)|(?:KHZ)|(?:MHZ)|(?:HZ))", sentences[i])
        if !(freq_unit === nothing)
            frequency_unit = freq_unit[1][1:end-1]*"z"
        end

        param_type = match(r"\s(S|Y|Z|H|G)\s", sentences[i])
        if !(param_type === nothing)
            parameter_type = param_type[1] 
        end
        
        param_format = match(r"((?:DB)|(?:MA)|(?:RI))", sentences[i])
        if !(param_format === nothing)
            parameter_format = param_format[1]
        end

        ref_resistance = match(r"R (\d+)", sentences[i])

        if !(ref_resistance === nothing)
            try
                reference_resistance = parse(Int, ref_resistance[1])
            catch
                throw("Incorrect number of reference resistance")
            end
        end
        
        i = skip_comments(sentences, i+1)

        # Parse keywords that don't appear in a specific order
        while true
            keyword = match(r"^\s*\[(.+)\]", sentences[i])[1]
            if keyword == "NUMBER OF PORTS"
                number_of_ports = parse(Int, match(r"^\[NUMBER OF PORTS\]\s+(\d+)", sentences[i])[1])
            elseif keyword == "TWO-PORT ORDER"
                two_port_data_order = match(r"^\[TWO-PORT DATA ORDER\]\s+((?:12_21)|(?:21_12))", sentences[i])[1]
            elseif keyword == "NUMBER OF FREQUENCIES"
                number_of_frequencies = parse(Int, match(r"^\[NUMBER OF FREQUENCIES\]\s+(\d+)", sentences[i])[1])
            elseif keyword == "NUMBER OF NOISE FREQUENCIES"
                number_of_noise_frequencies = parse(Int, match(r"^\[NUMBER OF NOISE FREQUENCIES\]\s+(\d+)", sentences[i])[1])
            elseif keyword == "REFERENCE"
                # TODO: Think about a more elegant way to do this
                reference = []
                while true
                   for k in split(split(sentences[i], "!")[1])
                        if k != "[REFERENCE]"
                            append!(reference, parse(Float64, k)) 
                        end
                    end
                    if length(reference) >= number_of_ports
                        break
                    end
                    i = skip_comments(sentences, i+1)
                end
            elseif keyword == "MATRIX FORMAT"
                matrix_format = match(r"((?:FULL)|(?:LOWER)|(?:UPPER))", sentences[i])[1]
            elseif keyword == "NETWORK DATA"
                # This should always come at the end along with network noise data
                network_data_len = number_of_frequencies * ((matrix_format=="FULL") ? 2*number_of_ports^2 + 1 : number_of_ports^2 + number_of_ports + 1)
                i = skip_comments(sentences, i+1)
                while true
                    t_network = vcat(t_network, parse.(Float64, split(split(sentences[i], "!")[1])))
                    (length(t_network) < network_data_len) || break
                    i = skip_comments(sentences, i+1)
                end
            elseif keyword == "NOISE DATA"
                # This should always come at the end along with network data
                noise_data_len = number_of_noise_frequencies * ((matrix_format=="FULL") ? 2*number_of_ports^2 + 1 : number_of_ports^2 + number_of_ports + 1)
                
                i = skip_comments(sentences, i+1)
                while true
                    t_noise = vcat(t_noise, parse.(Float64, split(split(sentences[i], "!")[1])))
                    (length(t_noise) < noise_data_len) || break
                    i = skip_comments(sentences, i+1)
                end
            end
        try 
            i = skip_comments(sentences, i+1)
        catch 
            break
        end
        
        end

        network_data = transform_vector_to_matrix_mode(t_network, String(matrix_format), number_of_frequencies)
        if number_of_noise_frequencies > 0
            noise_data = transform_vector_to_matrix_mode(t_noise, String(matrix_format), number_of_noise_frequencies)
        end
        
        new(frequency_unit, parameter_type, parameter_format, reference_resistance, number_of_ports,
        number_of_frequencies, number_of_noise_frequencies, reference, two_port_data_order, matrix_format,
        network_data, noise_data)
    end
end


"""
Converts Network/Noise data to complex matrix
...
# Arguments
- `snp::TouchstonerSnP`: provided Touchstone file
- `frequency::Int`: target frequency (must be specified in snp)
- `noise_data::Bool` if set to `true` returns results for Noise Data. Else,
    Network Data are assumed
...
"""
function get_ri_form(snp::TouchstoneSnP, frequency::Float64, noise_data::Bool=false)
data = noise_data ? snp.noise_data : snp.network_data
if !haskey(data, frequency)
    throw("Frequency not specified in data")
end

parameters = data[frequency]
n, m = size(parameters)
if snp.parameter_format == "RI"
    return [to_complex([i, 2j - 1:2j]) for i = 1:n, j = 1:n]
elseif snp.parameter_format == "MA"
   return [to_complex(ma_to_ri(parameters[i, 2j - 1:2j])) for i = 1:n, j = 1:n]
elseif snp.parameter_format == "DB"
    return [to_complex(ma_to_ri(db_to_ma(parameters[i, 2j - 1:2j]))) for i = 1:n, j = 1:n]
end
end

"""
Converts Network/Noise parameters to specified parameters
...
# Arguments
- `snp::TouchstonerSnP`: provided Touchstone file
- `frequency::Int`: target frequency (must be specified in snp)
- `parameter_type`::Str : parameter typ to convert to (source type being the  one specified in SnP)
- `noise_data::Bool` if set to `true` returns results for Noise Data. Else,
    Network Data are assumed
...
"""
function convert_param_type(snp::TouchstoneSnP, frequency::Float64, parameters_type::String, noise_data::Bool=false)
    data = noise_data ? snp.noise_data : snp.network_data
    if !haskey(data, frequency)
        throw("Frequency not specified in data")
    end

    # Convert to R-I format for easier conversion
    parameters = get_ri_form(snp, frequency, noise_data)
    # todo: Mixed-port parameters
    # Also I don't like this at all :P
    if parameters_type == "S"
        if snp.parameter_type == "S"
            return parameters
        elseif snp.parameter_type == "Y"
            return admittance_params_to_scatter(parameters, snp.reference_resistance)
        elseif snp.parameter_type == "Z"
            return impedance_params_to_scatter(parameters, snp.reference_resistance)
        end
    elseif parameters_type == "Y"
        if snp.parameter_type == "S"
            return scatter_params_to_admittance(parameters, snp.reference_resistance)
        elseif snp.parameter_type == "Y"
            return parameters
        elseif snp.parameter_type == "Z"
            return inv(parameters)
        end
    elseif parameters_type == "Z"
        if snp.parameter_type == "S"
            return scatter_params_to_impedance(parameters, snp.reference_resistance)
        elseif snp.parameter_type == "Y"
            return inv(parameters)
        elseif snp.parameter_type == "Z"
            return parameters
    end
end

end