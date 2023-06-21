module InfluxDBClient

export BaseClient
export WriteAPI
export QueryAPI
export ResponseCodes

## The response codes
include("ResponseCodes/response_codes.jl")
using .ResponseCodes

## The base client
include("BaseClient/base_client.jl")
using .BaseClient

## The WriteAPI 
include("WriteAPI/write_api.jl")
using .WriteAPI

## The QueryAPI
include("QueryAPI/query_api.jl")
using .QueryAPI

## The DeleteAPI
include("DeleteAPI/delete_api.jl")
using .DeleteAPI

end

