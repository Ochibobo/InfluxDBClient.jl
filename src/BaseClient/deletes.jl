import JSON

"""
    const DELETE_HEADERS = Vector{Pair{String, String}}()

Headers for a Delete Request
"""
const DELETE_HEADERS = Vector{Pair{String, String}}()
push!(DELETE_HEADERS, "Content-Type" => "application/json")


"""
    delete(apiClient::APIClient, url::String, params::Dict)

Function used to `delete` records from the `InfluxDB` server based on the specified `params`
"""
function deleteData(apiClient::APIClient, url::String, params::Dict)
    _url = apiClient.url * url * "&org=$(apiClient.org)"

    push!(DELETE_HEADERS, "Authorization" => "Token $(apiClient.token)")

    try
        HTTP.post(_url, DELETE_HEADERS, JSON.json(params))
    catch e
        throw(e)
    end
end