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
        if matrix_mode == "UPPER"
            n = round(0.5*(sqrt(4*k - 3) - 1))
            freq_params[arr[k*(m-1) + 1]] = [2i <= j ? (arr[(n*(n+1)-(n-i+1+1)*(n-i+1))>>>1 + 1 + (j-1)%n - (i - 1)]) : 0 for i=1:2n, j=1:n]
        elseif matrix_mode == "LOWER"
            n = Int(round(0.5*(sqrt(4*k - 3) - 1)))
            freq_params[arr[k*(m-1) + 1]] = [2i >= j ? varr[(((i+1)*i)>>>1 + (n-1) - ((n - j )%n)- (i-1))] : 0 for i=1:n, j=1:2n]
        elseif matrix_mode == "FULL"
            n = convert(Int64, round(sqrt(k)))
            freq_params[arr[k*(m-1) + 1]] = [arr[i*n + j] for i = 1:n, j = 1:n]
        end
    end
    return freq_params
 end
