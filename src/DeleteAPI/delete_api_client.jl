"""
    mutable struct DeleteAPIClient
        apiClient::APIClient = APIClient()
        path::String         = "/api/v2/delete"
    end

`DeleteAPIClient` struct
"""
@with_kw mutable struct DeleteAPIClient
    apiClient::APIClient = APIClient()
    path::String         = "/api/v2/delete"
end


"""
    mutable struct DeletePredicate
        predicate::String = ""
        start::String     = ""
        stop::String      = ""
    end

# Arguments:
- `predicate`: An expression in delete predicate syntax.
- `start`    : A timestamp (RFC3339 date/time format). The earliest time to delete from. (required)
- `stop`     : A timestamp (RFC3339 date/time format). The latest time to delete from.

Definition of the structure of the `filter` that is to be used for `deletions`
"""
@with_kw mutable struct DeletePredicate
    predicate::String = ""
    start::String     = ""
    stop::String      = ""
end


"""
    apiClient(deleter::DeleteAPIClient)::APIClient

Get the `apiClient` from the `DeleteAPIClient`
"""
apiClient(deleter::DeleteAPIClient)::APIClient = deleter.apiClient


"""
    delete(deleter::DeleteAPIClient, params::Dict)

Function used to delete records from the `InfluxDB` server
"""
function delete(deleter::DeleteAPIClient, bucket::String, params::Dict)
    url = deleter.path * "?bucket=$bucket"

    deleteData(apiClient(deleter), url, params)
end


"""
    delete(deleter::DeleteAPIClient, filter::T) where T <: FluxQueryFilter

Function used to delete records from the `InfluxDB` server
"""
function delete(deleter::DeleteAPIClient, bucket::String, params::DeletePredicate) 
    dict_params = Dict("start" => params.start, "stop" => params.stop)

    ## Add the predicate to the params if the predicate is not empty
    if !isempty(params.predicate)
        dict_params["predicate"] = params.predicate
    end

    delete(deleter, bucket, dict_params)
end



"""
Examples
"""
"""
DeletePredicate(predicate = "room=\"TVRoom\"",
                start = "2019-08-24T14:15:22Z",
                stop = "2023-08-24T14:15:22Z")
"""