"""
WriteAPIClient for write functions related to the InfluxDB Server
"""
module WriteAPI

using Parameters

using ..BaseClient

## Type Definitions

"""
    const SymbolColumnValue = Union{String, Symbol}

`SymbolColumnValue` type for types who's value can be `Union{String,Symbol}`
"""
const SymbolColumnValue = Union{String, Symbol}


"""
    const EQUAL_SIGN = '='

`Equal` character constant
"""
const EQUAL_SIGN = '='


"""
    const COMMA = ','

`Comma` character constant
"""
const COMMA = ','


"""
    const SPACE_CHAR = ' '

`Space` character constant
"""
const SPACE_CHAR = ' '


"""
    const RETURN_CHAR = '\n'

`Return` character constant
"""
const RETURN_CHAR = '\n'

## The WriteType object
include("write_type.jl")
export WriteType

## The WriteOptions object
include("write_options.jl")
export WriteOptions

##  WritePrecision object
include("write_precision.jl")
export WritePrecision
export timestampConverter

# AsyncWriteAPIClient
include("async_write_api_client.jl")
export AsyncWriteAPIClient
export apiClient
export updateBuffer!
export buffer
export clearBuffer!
export bufferLength
export isBufferEmpty
export flush
export write

## WriteAPIClient
include("write_api_client.jl")
export WriteAPIClient
export apiClient
export write

## Point object
include("models/point.jl")
export Point
export Timestamp
export writePrecision
export setMeasurement!
export measurement
export addTag!
export addTags!
export tags
export addField!
export addFields!
export fields
export setTimestamp!
export timestamp
export @measurement
export @tags
export @fields
export @timestamp
export batchWrite

## TabularData object
include("models/tabular_data.jl")
export TabularData
export batchWrite
export partialString
export ILPSchema

## MeasurementInterface object 
include("models/measurement_interface.jl")
export measurement
export tags
export writePrecision
export exclude
export buildRecord
export batchWrite


end
