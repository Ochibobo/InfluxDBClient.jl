"""
    const WRITE_HEADERS = Vector{Pair{String, String}}()

`HTTP-Headers` for the writer client
"""
const WRITE_HEADERS = Vector{Pair{String, String}}()
push!(WRITE_HEADERS, "Content-Type" => "text/plain; charset=utf-8")
push!(WRITE_HEADERS, "Accept" => "application/json")


"""
    const WRITE_SUCCESS_CHANNEL = Channel{Integer}(1)

`Channel` used to send `success` messages to a listener of async writes. It contains the success code: `200` only.
"""
const WRITE_SUCCESS_CHANNEL = Channel{Integer}(5000)


"""
    const WRITE_ERROR_CHANNEL = Channel{Tuple{Integer, String}}()

`Channel` used to send `error` messages to a listener of async writes. It contains the error code & the error message.
"""
const WRITE_ERROR_CHANNEL = Channel{Tuple{Integer, String}}(5000)


"""
    writeData(apiClient::ApiClient, url::String, body::String)::Nothing

Function used to write data to the `InfluxDB` server. An `exception` is thrown if write is not successful.
"""
function writeData(apiClient::APIClient, url::String, body::String)::Nothing
    ## Append url information to the url
    _url = apiClient.url * url * "&org=$(apiClient.org)"

    push!(WRITE_HEADERS, "Authorization" => "Token $(apiClient.token)")

    try
        response = HTTP.post(_url, WRITE_HEADERS, body)
        println(response)
    catch e
        ## Execute a retry
        throw(e)
        ## Retry on failure based on writeOptions
    end

    return nothing
end


"""
    writeDataAsync(apiClient::ApiClient, url::String, body::String)::Nothing

Function used to `asynchronously` write data to the `InfluxDB` server. 
`Channels are used`
"""
function writeDataAsync(apiClient::APIClient, url::String, body::String)::Nothing
    ## Append url information to the url
    _url = apiClient.url * url * "&org=$(apiClient.org)"

    push!(WRITE_HEADERS, "Authorization" => "Token $(apiClient.token)")

    errormonitor(@async begin
        try
            response = HTTP.post(_url, WRITE_HEADERS, body)
            ## Write the ResponseCode to the WRITE_SUCCESS_CHANNEL
            status = response.status
            body = response.body
            @show status
            @show body
            ## Write to channel
            if (status == ResponseCodes.SUCCESS || status == ResponseCodes.NO_CONTENT) 
                ## Write the status to the WRITE_SUCCESS_CHANNEL
                put!(WRITE_SUCCESS_CHANNEL, status)
            else
                ## Write the status + error to the WRITE_ERROR_CHANNEL
                put!(WRITE_ERROR_CHANNEL, (status, string(body)))
            end
        catch e
            @error e
            ## Execute retries
            throw(e)
            ## Write the error to the WRITE_ERROR_CHANNEL
            put!(WRITE_ERROR_CHANNEL, (status, string(e)))
            ## Retry on failure based on writeOptions
        end
    end)

    return nothing
end


"""

Listener for the `WRITE_SUCCESS_CHANNEL`
"""
doWithSuccess(statusCode::Integer) = println("Successful write: ", statusCode)


"""

Listener for the `WRITE_ERROR_CHANNEL`
"""
doWithErr(error::Tuple{Integer, String}) = println("Error: ", error)


"""
"""
function onSuccess(cb = doWithSuccess)
    while true
        ## take the value from the success link and execute onSuccess
        val = take!(WRITE_SUCCESS_CHANNEL)
        ## Run onSuccess
        cb(val)
    end
end


"""

Listener for the `WRITE_ERROR_CHANNEL`
"""
function onError(cb = doWithErr)
    while true
        ## take the value from the error link and execute doWithErr
        val = take!(WRITE_ERROR_CHANNEL)
        ## Run onErr
        cb(val)
    end
end
