"""
BaseClient used to create an influx DB client 
"""
module BaseClient

using Parameters
using HTTP
using CSV
using ..ResponseCodes
import JSON

export APIClient
export writeData
export writeDataAsync
export onSuccess
export onError
export queryRaw
export queryWithParams
export deleteData

"""
    @with_kw mutable struct APIClient
        url::String = "http://localhost:8086"
        token::String
        org::String
    end

`APIClient` struct that holds the `InfluxDB` server and token information.
"""
@with_kw mutable struct APIClient
    url::String = "http://localhost:8086"
    token::String = "zVlffkkbr5vDhMOZOecMc-q8prtRKLZ4wx7qrlO9wwOrGsPOFJQKVaGoIxKTMPze_aKpEKwg439EnMrMjQX3og=="
    org::String = "julia"
end



include("writes.jl")
include("reads.jl")
include("deletes.jl")

end
