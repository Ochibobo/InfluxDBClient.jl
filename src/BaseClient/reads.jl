import JSON
"""
"""
const READ_HEADERS = Vector{Pair{String, String}}()
push!(READ_HEADERS, "Accept" => "application/csv")


"""
"""
function queryRaw(apiClient::APIClient, url::String, fluxQuery::String)
    _url = apiClient.url * url * "?org=$(apiClient.org)"
    
    push!(READ_HEADERS, "Content-Type" => "application/vnd.flux")
    push!(READ_HEADERS, "Authorization" => "Token $(apiClient.token)")

    try
        response = HTTP.post(_url, READ_HEADERS, fluxQuery)
        data = response.body
        return DataFrame(CSV.File(data))
    catch e
        throw(e)
    end
end


"""
    queryWithParams(apiClient::APIClient, url::String, fluxQuery::String, params::Dict; extras::Dict)::DataFrame

!!! Note

    This is only supported by InfluxDB Cloud.

Query together with params. `extras` dictionary holds any other data one may want to send together with the query and params.
See REQUEST BODY SCHEMA section in https://docs.influxdata.com/influxdb/cloud/api/#operation/PostQuery for more on `extras`.
"""
function queryWithParams(apiClient::APIClient, url::String, fluxQuery::String, params::Dict; extras::Dict)::DataFrame
    _url = apiClient.url * url * "?org=$(apiClient.org)"
    
    push!(READ_HEADERS, "Content-Type" => "application/json")
    push!(READ_HEADERS, "Authorization" => "Token $(apiClient.token)")

    body = Dict("query" => fluxQuery, "params" => params)

    ## If the extras are not empty, add them to the body
    if !isempty(extras)
        for (k, v) in extras
            body[k] = v
        end
    end

    ## Post the query
    try
        response = HTTP.post(_url, READ_HEADERS, JSON.json(body))
        data = response.body
        return DataFrame(CSV.File(data))
    catch e
        throw(e)
    end
end
