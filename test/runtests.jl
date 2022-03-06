using SnpParser

using Test

# Single-port Z parameterexample
snp = TouchstoneSnP("example/one_port_z_params")

# Test SnP parameters
@test snp.frequency_unit == "MHz"
@test snp.number_of_ports == 1
@test snp.parameter_type == "Z"
@test snp.number_of_frequencies == 5
@test snp.reference_resistance == 20.0

# Test network data
@test snp.network_data[100.0] == [74.25 -4.0]
@test snp.network_data[200.0] == [60.0 -22.0]
@test snp.network_data[300.0] == [53.025 -45.0]
@test snp.network_data[400.0] == [30.0 -62.0]
@test snp.network_data[500.0] == [0.75 -89.0]

