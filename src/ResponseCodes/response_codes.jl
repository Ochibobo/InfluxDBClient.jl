### Response Codes

module ResponseCodes

export ResponseCode

"""
    @enum ResponseStatusCode begin
        SUCCESS = 200
        NO_CONTENT = 204
        BAD_REQUEST = 400
        UNAUTHORIZED = 401
        NOT_FOUND = 404
        REQUEST_ENTITY_TOO_LARGE = 413
        UNPROCESSABLE_ENTITY = 422
        TOO_MANY_REQUESTS = 429
        INTERNAL_SERVER_ERROR = 500
        SERVICE_UNAVAILABLE = 503
    end

Response codes returned by the `InfluxDB` server
"""
@enum ResponseCode begin
    SUCCESS = 200
    NO_CONTENT = 204
    BAD_REQUEST = 400
    UNAUTHORIZED = 401
    NOT_FOUND = 404
    REQUEST_ENTITY_TOO_LARGE = 413
    UNPROCESSABLE_ENTITY = 422
    TOO_MANY_REQUESTS = 429
    INTERNAL_SERVER_ERROR = 500
    SERVICE_UNAVAILABLE = 503
end

end