
"""
QueryAPI struct
"""
@with_kw mutable struct QueryAPIClient
    apiClient::APIClient = APIClient()
    path::String = "/api/v2/query"
end


"""
APIClient
"""
apiClient(reader::QueryAPIClient)::APIClient = reader.apiClient


"""
"""
function readRaw(reader::QueryAPIClient, fluqQuery::String)
    queryRaw(apiClient(reader), reader.path, fluqQuery)
end


"""
"""
function readWithParams(reader::QueryAPIClient, fluxQuery::String, params::Dict; extras::Dict)
    queryWithParams(apiClient(reader), reader.path, fluxQuery, params, extras = extras)
end


"""
"""
function readWithParams(reader::QueryAPIClient, fluxQuery::String, params::T; extras::Dict) where T <: FluxQueryFilter
    readWithParams(reader, fluxQuery, fluxFilterToDict(params), extras = extras)
end