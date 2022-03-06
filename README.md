# SnpParser.jl

A module for parsing and visualizing [Touchstone](http://www.ibis.org/touchstone_ver2.0/touchstone_ver2_0.pdf) files. Currently, only version 2.0 files are supported but there are ways to easily make version 1.0 files parsable by `SnpParser`.

## Features

- [ ] Version 1.0 Support
- [x] Version 2.0 Support
- [x] Rectangular Plots
- [ ] Smith Chart Plots
- [x] Parameter Conversion
- [ ] Mixed-mode parameters support


## Usage 


This assumes that you have a Touchstone file saved up in `/path`

```julia
julia> snp = TouchstoneSnP("/path/example_file")

julia> snp.parameter_type 
"S"

julia> plot_snp(snp, "S", "output.png", Set([[1, 1], [2, 2], [3, 3]]))

```

The output plot should look something similar to this:

![Output](https://github.com/Sedictious/SnpParser.jl/blob/main/images/example_3port_s_params.png)

## Parsing version 1.0 Touchstone files

Version 1.0 is planned to be supported in a future release. However, there is an easy work-around by following the necessary steps:

* At the top of your Touchstone file add `[Version] 2.0`
* Right below the `#options` line add `[Number of Ports] N` where N is the number of ports. You can easily determine the number of ports from your network data: each row of your network data matrix should have N^2 + 1 columns
* Above your network data add the `[Network Data]` tag.
