"""
Module responsible for sending delete requests to the InfluxDB server
"""
module DeleteAPI

using Parameters
using ..BaseClient

include("delete_api_client.jl")
export DeleteAPIClient
export DeletePredicate
export apiClient
export delete

end
