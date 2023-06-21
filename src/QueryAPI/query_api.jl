"""
QueryAPIClient for read functions related to the InfluxDB Server
"""
module QueryAPI

using Parameters
using ..BaseClient

export QueryAPIClient

export FluxQueryFilter
export flux_query_str
export build_flux_query
export fluxFilterToDict
include("flux_filter.jl")

include("query_api_client.jl")
export QueryAPIClient
export apiClient
export readRaw
export readWithParams

end
