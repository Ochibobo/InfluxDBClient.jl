using Parameters
using Dates
import Base: string, convert

"""
    @with_kw mutable struct Timestamp{T <: Union{Integer, Date, DateTime}}
        value::T
        precision::WritePrecision = ns
    end

`Timestamp` struct used to capture the time with a default precision
"""
@with_kw mutable struct Timestamp{T <: Union{Integer, Date, DateTime}}
    value::T
    precision::WritePrecision = ns
end

"""
    Base.convert(::Type{Timestamp{Integer}}, t::Timestamp{K})::Timestamp{Integer} where K <: Union{Date, DateTime}

All `Timestamp` struct instances are normalized to `Timestamp{Integer}` to normalize timestamp related operations.

`convert` object of type `Timestamp{DateTime}` or `Timestamp{Date}` to `Timestamp{Integer}`
"""
function Base.convert(::Type{Timestamp{Integer}}, t::Timestamp{K})::Timestamp{Integer} where K <: Union{Date, DateTime}
    return Timestamp{Integer}(value = timestampConverter(t.value, t.precision), precision = t.precision)
end

"""
    Base.string(t::Timestamp{T}) where T

`string` representation of the `Timestamp{Integer}` struct
"""
function Base.string(t::Timestamp{T}) where T
    T <: Integer ? string(t.value) : string(convert(Timestamp{Integer}, t).value)
end

"""
    @with_kw mutable struct Point
        measurement::String
        tags::NamedTuple
        fields::NamedTuple
        time::Timestamp
    end

`Point` struct used as one of the methods to store a record information that is to be written to the database
"""
@with_kw mutable struct Point
    measurement::SymbolColumnValue = ""
    tags::NamedTuple = NamedTuple()
    fields::NamedTuple = NamedTuple()
    timestamp::Timestamp = Timestamp{Integer}(value = 1)
end

"""
    writePrecision(p::Point) = p.timestamp.precision

`writePrecision` to get the `WritePrecision` of a `Point`
"""
writePrecision(p::Point) = p.timestamp.precision


"""
    measurement(p::Point, measurement::T)::Point where T <: SymbolColumnValue

Function used to set the `measurement` field value of a Point
"""
function setMeasurement!(p::Point, measurement::T)::Point where T <: SymbolColumnValue
    p.measurement = measurement
    return p
end

"""
    measurement(p::Point)::SymbolColumnValue = p.measurement

Function used to get the `measurement` of a `Point` instance
"""
measurement(p::Point)::SymbolColumnValue = p.measurement


"""
    addTag!(p::Point, t::Pair{T, V})::Point where {T <: SymbolColumnValue, V}

Function used to assign a `tag` to a `Point` instance
"""
function addTag!(p::Point, t::Pair{T, V})::Point where {T <: SymbolColumnValue, V}
    p.tags = (;p.tags..., Dict(Symbol(t.first) => t.second)...)
    return p
end


"""
    addTags!(p::Point, ts::Pair{T, V}...)::Point where {T <: SymbolColumnValue, V}

Function used to assign multiple `tag`s to a `Point` instance
"""
function addTags!(p::Point, ts::Pair{T, V}...)::Point where {T <: SymbolColumnValue, V}
    for t in ts
        p = addTag!(p, t)
    end

    return p
end



"""
    tags(p::Point)::NamedTuple

Function used to get the `tags` of a `Point` instance
"""
tags(p::Point)::NamedTuple = p.tags 



"""
    addField!(p::Point, t::Pair{T, V})::Point where {T <: SymbolColumnValue, V}

Function used to assign a `field` to a `Point` instance
"""
function addField!(p::Point, t::Pair{T, V})::Point where {T <: SymbolColumnValue, V}
    p.fields = (;p.fields..., Dict(Symbol(t.first) => t.second)...)
    return p
end


"""
    addFields!(p::Point, ts::Pair{T, V}...)::Point where {T <: SymbolColumnValue, V}

Function used to assign multiple `field`s to a `Point` instance
"""
function addFields!(p::Point, ts::Pair{T, <: Any}...)::Point where {T <: SymbolColumnValue}
    for t in ts
        p = addField!(p, t)
    end

    return p
end


"""
    fields(p::Point)::NamedTuple

Function to get the `fields` associated with a `Point` instance
"""
fields(p::Point)::NamedTuple = p.fields 



"""
    setTimestamp!(p::Point, t::Timestamp)::Point

Used to assign a timestamp to a point
"""
function setTimestamp!(p::Point, t::Timestamp)::Point
    p.timestamp = t
    return p
end


"""
    timestamp(p::Point)::Timestamp

Function to get the `timestamp` associated with a `Point` instance
"""
timestamp(p::Point)::Timestamp = p.timestamp = t



################################################
#                                              #
#                                              #
#   MACRO Definitions used to build a Point    #
#                                              #
#                                              #
################################################


"""
    @measurement(name)

`measurement` macro used to set the `measurement` to a `Point` instance
"""
macro measurement(name)
    return quote
        (point) -> setMeasurement!(point, $(esc(name)))
    end
end


"""
    @tag(tagPair)

`tag` macro used to add a `tag` to a `Point` instance
"""
macro tag(tagPair)
    return quote
        (point) -> addTag!(point, $(esc(tagPair)))
    end
end


"""
    @tags(tagPairs)

`tags` macro used to add multiple `tag`s to a `Point` instance
"""
macro tags(tagPairs)
    return quote
        (point) -> addTags!(point, $(esc(tagPairs)))
    end
end


"""
    @field(fieldPair)

`field` macro used to add a field to a `Point` instance
"""
macro field(fieldPair)
    return quote
        (point) -> addField!(point, $(esc(fieldPair)))
    end
end


"""
    @fields(fieldPairs)

`fields` macro used to add multiple fields to a `Point` instance
"""
macro fields(fieldPairs)
    return quote
        (point) -> addFields!(point, $(esc(fieldPairs)))
    end
end


"""
    macro timestamp(timestamp) end

`timestamp` macro used to set the timestamp value for a point
"""
macro timestamp(timestamp)
    return quote
        (point) -> setTimestamp!(point, $(esc(timestamp)))
    end
end


"""
    function string(p::Point)::String end

convert the `Point` struct to an ILP record
"""
function string(p::Point)::String
    ## Build the tags string
    tag_entries = map(t -> string(t) * EQUAL_SIGN * string(p.tags[t]), keys(p.tags))

    ## Join tag_entries with commas
    tags = length(tag_entries) == 0 ? "" : COMMA * join(tag_entries, COMMA)
    tags *= SPACE_CHAR

    ## Build the fields
    field_entries = map(f -> string(f) * EQUAL_SIGN * string(p.fields[f]), keys(p.fields))

    ## Assert that there is at least one field
    length(field_entries) == 0 && error("there must be at least one field column specified. At least one field is required.")
    ## join field_entries with commas
    fields = join(field_entries, COMMA)
    fields *= SPACE_CHAR

    ## Return the record
    return string(p.measurement) * tags * fields * string(p.timestamp) * RETURN_CHAR
end

"""
    write(writer::WriteAPIClient, bucket::String, point::Point)

`write` function to write a Point to the database
"""
function write(writer::WriteAPIClient, bucket::String, point::Point)
    write(writer, bucket, string(point), precision = writePrecision(point))
end


"""
    write(writer::WriteAPIClient, bucket::String, points::Vector{Point})
        
`write` function to write a `Vector{Point}` to the database
"""
function write(writer::WriteAPIClient, bucket::String, points::Vector{Point})
    isempty(points) && return nothing
    ilp_str = join("\n", string.(points))
    write(writer, bucket, ilp_str, precision = writePrecision(points[1])) 
end


"""
    batch_write(writer::WriteAPIClient, bucket::String, points::Vector{Point})

Function used to batch-write a `Vector{Point}` instance. The size of the batch is determine by the `batchSize` parameter of the 
`writeOption` object in the `writer`.
"""
function batchWrite(writer::WriteAPIClient, bucket::String, points::Vector{Point})
    ilp_str = ""
    batchSize = writer.writeOptions.batchSize
    precision = writePrecision(entry)

    for (index, entry) in enumerate(points)
        ## Write the string if the batchSize is reached
        if(index % batchSize == 0)
            ## Write the ILP to the server
            write(writer, bucket, ilp_str, precision = precision)
            ## Reset the ilp string
            ilp_str = ""
        end
        ## Build the ILP string
        ilp_str *= string(entry)
    end

    ## Final write - flush out any bits of the ilp remaining
    length(ilp_str) > 0  && write(writer, bucket, ilp_str, precision = writePrecision(T))

    return nothing
end


"""
    write(writer::AsyncWriteAPIClient, bucket::String, point::Point)

Function used to write `asynchronously` to the InfluxDB Server
"""
function write(writer::AsyncWriteAPIClient, bucket::String, point::Point)
    ## Attempt to write to the data to the server
    write(writer, bucket, string(point), precision = writePrecision(point))
end

"""
Example
"""
# point = WriteAPI.Point() |>
#         WriteAPI.@measurement(:home) |>
#         WriteAPI.@tags(:room => "Bathroom") |>
#         WriteAPI.@fields(:hum => 32.4) |>
#         WriteAPI.@fields(:temp => 24.3) |>
#         WriteAPI.@fields(:co => 0) |>
#         WriteAPI.@timestamp(WriteAPI.Timestamp(now(), WriteAPI.ns))