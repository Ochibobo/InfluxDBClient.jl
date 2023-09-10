using HTTP
"""
Responsible for synchronous writes
"""

"""
    @with_kw mutable struct WriteAPIClient
        apiClient::ApiClient = ApiClient()
        writeOptions::WriteOptions = WriteOptions()
        path::String = "/api/v2/write"
    end

`WriteAPI` struct definition.
"""
@with_kw mutable struct WriteAPIClient
    apiClient::APIClient = APIClient()
    writeOptions::WriteOptions = WriteOptions()
    path::String = "/api/v2/write"
end



"""
    write(writer::WriteAPIClient, bucket::String, data::String; precision::WritePrecision = ns)
        
`write` to write raw strings to InfluxDB. The underlying write function for all writers
"""
function write(writer::WriteAPIClient, bucket::String, data::String; precision::WritePrecision = ns)::Union{HTTP.Response, Nothing}
    url = writer.path * "?bucket=$bucket&precision=$(precision)"

    ## Branch on synchronous or asynchronous writeType
    return writeData(apiClient(writer), url, data)
end


"""
    apiClient(writer::WriteAPIClient) 

Get the writer's api client
"""
apiClient(writer::WriteAPIClient) = writer.apiClient