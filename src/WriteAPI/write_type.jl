"""
    @enum WriteType begin
        batching
        synchronous
        asynchronous
    end

`enum` defining the different write types for InfluxDB. 

!!!  warning

This `enum` is currently not being used. While it appears in the implementation of other clients in other languages,
in this context it has been `deprecated`. The way this API client was defined deemed it's utility irrelevant.
"""
@enum WriteType begin
    synchronous
    asynchronous
end