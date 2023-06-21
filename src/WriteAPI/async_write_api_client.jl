"""
Responsible for asynchronous writes
"""

"""
    @with_kw mutable struct AsyncWriteAPIClient
        apiClient::APIClient = APIClient()
        writeOptions::WriteOptions = WriteOptions()
        path::String = "/api/v2/write"
    end

`AsyncWriteAPI` for asynchronous writes
"""
@with_kw mutable struct AsyncWriteAPIClient
    apiClient::APIClient = APIClient()
    writeOptions::WriteOptions =  WriteOptions()
    path::String = "/api/v2/write"
    buffer::Vector{String} = Vector{String}()
    timer::Timer = Timer(0) ## A timer instance
end


"""
    apiClient(writer::AsyncWriteAPIClient) 

Get the async writer's api client
"""
apiClient(writer::AsyncWriteAPIClient) = writer.apiClient


"""
    updateBuffer!(writer::AsyncWriteAPIClient, data::String)

Function used to add an `ILP` record statement to the buffer of an `AsyncWriteAPIClient`
"""
updateBuffer!(writer::AsyncWriteAPIClient, data::String)  = push!(buffer(writer), data)


"""
    buffer(writer::AsyncWriteAPIClient)::String 

Function used to get an `AsyncWriteAPIClient`'s buffer
"""
buffer(writer::AsyncWriteAPIClient)::Vector{String} = writer.buffer


"""
    clearBuffer!(writer::AsyncWriteAPIClient)

Function to remove all `ILP` records from an `AsyncWriteAPIClient`'s buffer
"""
clearBuffer!(writer::AsyncWriteAPIClient) = empty!(buffer(writer))


"""
    bufferLength(writer::AsyncWriteAPIClient)::Integer

Function used to get the length of the `AsyncWriteAPIClient`'s buffer
"""
bufferLength(writer::AsyncWriteAPIClient)::Integer = length(buffer(writer))


"""
    isBufferEmpty(writer::AsyncWriteAPIClient)::Bool

Function to check if the `AsyncWriteAPIClient`'s `buffer` is empty.
"""
isBufferEmpty(writer::AsyncWriteAPIClient)::Bool = isempty(buffer(writer))


"""
    timer(writer::AsyncWriteAPIClient)::Timer

Function used to get the `AsyncWriteAPIClient`'s timer
"""
timer(writer::AsyncWriteAPIClient)::Union{Timer,Nothing} = writer.timer


"""
    isTimerOpen(writer::AsyncWriteAPIClient)::Bool 

Function used to check if the `AsyncWriteAPIClient`'s timer is open
"""
isTimerOpen(writer::AsyncWriteAPIClient)::Bool = isopen(timer(writer))


"""
    setTimer(writer::AsyncWriteAPIClient, timer::Timer)::Nothing

Function to set the timer for an `AsyncWriteAPIClient` instance
"""
setTimer!(writer::AsyncWriteAPIClient, timer::Timer)::Timer = writer.timer = timer


"""
    startTimer(writer::AsyncWriteAPIClient; cb = println("Timer is on"), delay = 2)::Nothing

Function used to start the `AsyncWriteAPIClient`'s timer
"""
function startTimer(writer::AsyncWriteAPIClient; cb = println("Timer is on"), delay = 2)::Nothing
    t = Timer(cb, delay, interval = writer.writeOptions.flushInterval)
    ## Set the current timer instance to the writer's timer
    setTimer!(writer, t)

    return nothing
end


"""
    closeTimer!(writer::AsyncWriteAPIClient)

Function used to close the `AsyncWriteAPIClient`'s timer
"""
closeTimer!(writer::AsyncWriteAPIClient) = close(timer(writer))


"""
    write(writer::AsyncWriteAPIClient, bucket::String; data::String; precision::WritePrecision = ns, timerDelay = 2)

Data are asynchronously written to the underlying buffer and they are automatically sent to a server
when the size of the write buffer reaches the batch size, default 5000, or the flush interval, 
default 1s, times out. Writes are automatically retried on server back pressure.

Asynchronous write client is recommended for frequent periodic writes.
"""
function write(writer::AsyncWriteAPIClient, bucket::String, data::String; precision::WritePrecision = ns, timerDelay = 2)
    ## Form the url
    url = writer.path * "?bucket=$bucket&precision=$(precision)"

    ## Update the writer's buffer
    updateBuffer!(writer, data)

    ## On each update, check if the observer is active
    ## if active, do nothing else restart the Timer and activate the observer
    if !isTimerOpen(writer)
        ## Define the callback
        cb(timer) = begin
            ## Convert the data to string
            ilp_str = join(buffer(writer), "\n")
            ## Set Buffer to a new buffer -> Bad for GCC or reset Buffer
            clearBuffer!(writer)
            ## Close the timer
            close(timer)
            ## Attempt to write the string
            writeDataAsync(apiClient(writer), url, ilp_str)
        end

        ## Start the timer with instructions to write
        startTimer(writer, cb = cb, delay = writer.writeOptions.flushInterval)
    end

    ## Get the set batch size
    batchSize = writer.writeOptions.batchSize

    ## If the buffer size exceeds the batchSize, write all data out and clear the buffer
    if bufferLength(writer) >= batchSize
        ## Convert the data to string
        ilp_str = join(buffer(writer), "\n")
        ## Set Buffer to a new buffer -> Bad for GCC or reset Buffer
        clearBuffer!(writer)
        ## At this point, close the timer & set it to nothing.
        closeTimer!(writer)
        ## Attempt to write the string
        writeDataAsync(apiClient(writer), url, ilp_str)
    end
end


"""
    flush(writer::AsyncWriteAPIClient, bucket::String; precision::WritePrecision = ns)

Flush any remaining `ILP` records to the server
"""
function flush(writer::AsyncWriteAPIClient, bucket::String; precision::WritePrecision = ns)
    ## If the buffer is empty, return immediately from the function
    isBufferEmpty(writer) && return

    ## Build the URL
    url = writer.path * "?bucket=$bucket&precision=$(precision)"

    ## Convert the remaining data to string
    ilp_str = join("", buffer(writer))
    ## Set Buffer to a new buffer
    clearBuffer!(writer)

    ## Attempt to write the remaining part of the buffer
    writeData(apiClient(writer), url, ilp_str)
end


"""
    @with_kw mutable struct FlushIntervalObserver
        active::Bool = false
        timer::Union{Timer, Nothing} = nothing
    end

Monitors the timer, if it is inactive; it means there's no data in the buffer
"""
@with_kw mutable struct FlushIntervalObserver
    active::Bool = false
    timer::Union{Timer, Nothing} = nothing
end


"""
    activate(f::FlushIntervalObserver)::Nothing

Function used to activate the `FlushIntervalObserver` instance
"""
activate(f::FlushIntervalObserver)::Nothing = f.active = true


"""
    deactivate(f::FlushIntervalObserver)::Nothing

Function used to deactivate the `FlushIntervalObserver` instance
"""
deactivate(f::FlushIntervalObserver)::Nothing = f.active = false


"""
    isActive(f::FlushIntervalObserver)::Bool 

Function used to check if the `FlushIntervalObserver` is currently active
"""
isActive(f::FlushIntervalObserver)::Bool = f.active


"""
    timer(f::FlushIntervalObserver)::Timer

Function used to get the `FlushIntervalObserver`'s timer object
"""
timer(f::FlushIntervalObserver)::Union{Timer,Nothing} = f.timer


"""
    setTimer!(f::FlushIntervalObserver, t::Timer)::Nothing

Function used to set the `FlushIntervalObserver`'s timer object
"""
setTimer!(f::FlushIntervalObserver, t::Timer)::Nothing = f.timer = t


"""
    hasTimer(f::FlushIntervalObserver)::Bool 

Function used to check if the `FlushIntervalObserver` has a timer already
"""
hasTimer(f::FlushIntervalObserver)::Bool = !isnothing(timer(f))




"""
Async Writer should be a new writer
- Write on batchSize
- Write on flushInterval
- 
Use Channels to handle async write-exceptions
Retries


API Design:
- Event driven programming for async operations::Channels
    - WriteSuccessEvent - published when arrived the success response from Platform server
    - BackpressureEvent - published when is client backpressure applied - won't implement this
    - WriteErrorEvent - published when occurs a unhandled exception
    - WriteRetriableErrorEvent - published when occurs a retriable error
- Use Different API's??
    - WriteAPI
    - WriteBlockingAPI

- What happens when one wants batching but they only offer a string at a time vs batching across collections.
- Use a task that monitors time to execute a write if the buffer has values, shut the monitor otherwise.
    - Use a Timer object
    - Start a timer on buffer insert
        - Is it on all insert? or on all latest inserts? or since the first insert?
        - Introduce a delay before starting the timer - like 100ms before starting the timer.
        - On insert, restart the timer.
        - On start persistence, disable the timer.
        - On finish persistence, if the buffer still has data, start the timer, else leave the timer as being disabled.
    - close the timer when the buffer is empty.
-  What if I made write a task and scheduled it onTimer or onBufferFill



- One channel receiving a string
- Data sent by the timer or the buffer limit
- Upon reception, read the data and clear the buffer, stop the timer.

Implementation:
2 writers in 1 channel:
    - Read & clear a common buffer.
    - Clearing means resetting the buffer. 
    - Are tasks like threads?
        - Do I need to lock shared memory? - nope - tasks are placed on the scheduler, one after the other.
    - 
Tests are awaiting now::
"""



