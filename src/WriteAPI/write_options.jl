using Parameters

"""
    @with_kw mutable struct RetryOptions
        flushInterval::Integer = 5
        retryJitter::Integer = 10
        retryInterval::Integer = 10
        maxRetryDelay::Integer = 10
        maxRetryTime::Integer = 10
        exponentialBase::Integer = 10
        maxRetries::Integer = 10
    end

`RetryOptions` struct that defines the properties that determine how write retries are done
"""
@with_kw mutable struct RetryOptions
    retryJitter::Integer = 0 ## The number of milliseconds to increase the batch flush interval by a random amount
    retryInterval::Integer = 5000 ## The number of milliseconds to retry unsuccessful write. The retry interval is used when the InfluxDB server does not specify "Retry-After" header.
    maxRetryDelay::Integer = 10 ## Maximum delay time before retry - not sure
    maxRetryTime::Integer = 10 ## Maximum number of times to retry - not sure
    exponentialBase::Integer = 10 ## Exponential base for ExponentialRetries
    maxRetries::Integer = 10 ## Maximum number of retries
end


"""
    @with_kw mutable struct WriteOptions
        batchSize::Integer = 1000
        maxBufferLines::Integer = 10
        gzipEnabled::Bool = true
        writeType::WriteType = synchronous
    end

`WriteOptions` struct for write functions related to the InfluxDB Server
"""
@with_kw mutable struct WriteOptions
    retryOptions::RetryOptions = RetryOptions()
    batchSize::Integer = 10 ## The number of data point to collect in batch
    maxBufferLines::Integer = 10 ## Maximum buffer lines
    gzipEnabled::Bool = true ## Whether GZIP is supported
    writeType::WriteType = synchronous ## The different write types - useless
    flushInterval::Integer = 1 ## The number of milliseconds before the batch is written
end

"""
Accessors & setters for the above structs
"""
