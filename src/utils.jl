@enum frequencyUnit begin
   Hz = 1
   kHz = 2
   MHz = 3
   GHz = 4
end

@enum parameterType begin
    S = 1 # Scattering parameters
    Y = 2 # Admittance parameters
    Z = 3 # Impedance parameters
    H = 4 # Hybrid-h parameters
    G = 5 # Hybrid-g parameters
end
@enum parameterFormat begin
    DB = 1 # decibel angle (decibel = 20log10|magnitude|) [deg]
    MA = 2 # magnitude angle [deg]
    RI = 3 #real-imaginary
end

function skip_comments(sentences::Array, i::Integer)
    while match(r"^(\s*)$", sentences[i]) != nothing || match(r"^(\s*\!)", sentences[i]) != nothing || sentences[i] == "" 
        i += 1
    end
    return i
end

function transform_vector_to_matrix_mode(arr::Array, matrix_mode::String, freq_n::Int)
    freq_params = Dict() # separate matrices based on frequencies
    i = 1
    k = Int(length(arr)/freq_n) 
    for m=1:freq_n
        varr = arr[(k*(m-1) + 2):k*m]
        n = Int(round(0.5*(sqrt(4*k - 3) - 1)))
        # TODO: Use LinearAlgebra to construct the diagonal matrices
        if matrix_mode == "UPPER"
            n = round(0.5*(sqrt(4*k - 3) - 1))
            freq_params[arr[k*(m-1) + 1]] = [2i <= j ? (arr[(n*(n+1)-(n-i+1+1)*(n-i+1))>>>1 + 1 + (j-1)%n - (i - 1)]) : 0 for i=1:2n, j=1:n]
            
        elseif matrix_mode == "LOWER"
            n = Int(round(0.5*(sqrt(4*k - 3) - 1)))
            freq_params[arr[k*(m-1) + 1]] = [2i >= j ? varr[(((i+1)*i)>>>1 + (n-1) - ((n - j )%n)- (i-1))] : 0 for i=1:n, j=1:2n]
        elseif matrix_mode == "FULL"
            n = Int(round(sqrt((k - 1)/2)))
            freq_params[arr[k*(m-1) + 1]] = [varr[(i-1)*2n + (j-1)%2n + 1] for i=1:n, j=1:2n]
        end
        i += 1
    end
    return freq_params
 end

 function scatter_params_to_admittance(s_params::Array, ref_resistance::Int)
    n, m = size(s_params)
    if n != m
        throw("Provided matrix should be square")
    end

    return inv(I + s_params)*(I - s_params)/ref_resistance
 end
 
 function admittance_params_to_scatter(y_params::Array, ref_resistance::Int)
    n, m = size(y_params)
    if n != m
        throw("Provided matrix should be square")
    end

    return inv(I + y_params*ref_resistance)*(I - y_params*ref_resistance)
 end
 
 function impedance_params_to_scatter(z_params::Array, ref_resistance::Int)
    n, m = size(z_params)
    if n != m
        throw("Provided matrix should be square")
    end

    return inv(I + z_params/ref_resistance)*(z_params/ref_resistance - I)
 end

 function scatter_params_to_impedance(s_params::Array, ref_resistance::Int)
    n, m = size(s_params)
    if n != m
        throw("Provided matrix should be square")
    end

    return inv(I - s_params)*(I + s_params)*ref_resistance
 end


 function to_complex(carr)
    return carr[1] + carr[2]im
 end

 """
 Converts parameters in Magnitude-Angle to Real-Imaginary format
...
# Arguments
- `ma_params` : Parameters in the form (magnitude[linear], angle[rad])
...
"""
function ma_to_ri(ma_params::Array)
    return [ma_params[1]*cos(ma_params[2]), ma_params[1]*sin(ma_params[2])]
end

"""
Converts parameters in Real-Imaginary to Magnitude-Angle format
...
# Arguments
- `ri_params` : Parameters in the form (real, imaginary)
...
"""
function ri_to_ma(ri_params::Array)
   return [sqrt(ri_params[1]*ri_params[1] + ri_params[2]*ri_params[2]), atan(ri_params[2]/ri_params[1])]
end


"""
Converts parameters in Decibel-Angle to Magnitude-Angle format
...
# Arguments
- `db_params` : Parameters in the form (magnitude[db], angle[rad])

Note: for Touchstoner ver2.0 files decibel = 20log10
...
"""
function db_to_ma(db_params::Array)
   return [10^(db_params[1]/20), db_params[2]]
end

"""
Converts parameters in Magnitude-Angle to Decibel-Angle format
...
# Arguments
- `ma_params` : Parameters in the form (magnitude[linear], angle[rad])

Note: for Touchstoner ver2.0 files decibel = 20log10
...
"""
function ma_to_db(ma_params::Array)
   return [20log1o(ma_params[1]), ma_params[2]]
end