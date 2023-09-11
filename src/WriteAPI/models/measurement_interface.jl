using Dates

### Adding properties to an existing struct

"""
    measurement(::Type{T}) where T

Function used to define the `measurement` of the struct of type `T`
"""
function measurement(::Type{T}) where T
    error("No measurement defined for elements of type $(T)")
end

"""
    tags(::Type{T})::Vector{Symbol} where T 

Function used to define the `tag` fields of the struct of type `T`
"""
function tags(::Type{T})::Vector{Symbol} where T 
    error("no tags defined for elements of type $(T)")
end

"""
    timestamp(::Type{T})::Symbol where T 

Function used to define the `timestamp` field of the struct of type `T`
"""
function timestamp(::Type{T})::Symbol where T 
    error("no timestamp defined for elements of type $(T)")
end


"""
    writePrecision(::Type{T})::WritePrecision where T 

Function used to define the `WitePrecision` field of the struct of type `T`. The default `WritePrecision` is `ns`.
"""
function writePrecision(::Type{T})::WritePrecision where T
    return ns
end

"""
    exclude(::Type{T})::Vector{Symbol} where T 

Function used to define the fields to be excluded when generating the ILP for the struct of type `T`.
"""
function exclude(::Type{T})::Vector{Symbol} where T
    return Vector{Symbol}()
end


"""
    buildTags(s, v::Vector{Symbol})::String

Return a string representation of the `tags` fields related to object `s`
"""
function buildTags(s, v::Vector{Symbol})::String
    if(length(v) == 0) return [] end
    ## Retreive the field names
    _fieldnames = fieldnames(typeof(s))

    ## Assert the specified symbols vector v is not longer than the _fieldnames vector
    length(v) > length(_fieldnames) && error("specified tags are more than the fields present on the struct of type $t")
    ## Assert that all specified symbols in v are field names in the struct
    any(==(0), v .∈ [_fieldnames]) && error("assert that all tag symbols are present as field names on the struct of type $t")
    ## Build a vector of tags
    _tags = map(e -> string(e) * EQUAL_SIGN * string(getfield(s, e)), v)

    return join(_tags, COMMA) * SPACE_CHAR
end

"""
    buildTimestamp(timestamp::T, writePrecision::WritePrecision)::String where T <: Union{Dates.Date, Dates.DateTime}

Return a string representation of the `timestamp` field
"""
function buildTimestamp(timestamp::T, writePrecision::WritePrecision)::String where T <: Union{Dates.Date, Dates.DateTime}
    ## Build the timestamp value together with the write precision
    return string(timestampConverter(timestamp, writePrecision))
end

"""
    buildTimestamp(timestamp::Int, writePrecision::WritePrecision)::String

When the timestamp is an integer, you are responsible for ensuring it's value matches the specified precision
Return a string representation of the timestamp field if it's of type Integer
"""
function buildTimestamp(timestamp::Integer, writePrecision::WritePrecision)::String
    _ = writePrecision
    return string(timestamp)
end

"""
    buildFields(s, excludedFields::Vector{Symbol})::String

Return a string representation of the `fields` of the struct `s`. Fields present in the `excludedFields` vector are excluded.
"""
function buildFields(s, excludedFields::Vector{Symbol})::String
    ## Excluded fields include the tags, the timestamp & other excluded fields
    t = typeof(s)

    ## Get the remaining fields
    includedFields = setdiff(fieldnames(t), excludedFields)

    length(includedFields) == 0 && error("there must be at least one field specified. Either your excludedFields/tags/tags + excludedFields 
                                          have left no fields for the ILP. At least one field is required.")

    _fields = map(e -> string(e) * EQUAL_SIGN * string(getfield(s, e)), includedFields)

    return join(_fields, COMMA) * SPACE_CHAR
end

"""
    buildRecord(s)::String

Return a string representation of struct `s`. This is the ILP string for this struct.
"""
function buildRecord(s)::String
    t = typeof(s)
    ## Get the measurement 
    _measurement = measurement(t)

    ## Get the tags
    _tags = tags(t)
    _tagsStr = length(_tags) == 0 ? SPACE_CHAR : COMMA * buildTags(s, _tags)
    ## Get the timestamp
    ts = timestamp(t)
    _timestamp = buildTimestamp(getfield(s, ts), writePrecision(t))

    ## Get the excluded fields
    excluded = Vector{Symbol}()
    push!(excluded, _tags..., ts, exclude(t)...)

    _fieldStr = buildFields(s, excluded)

    return _measurement * _tagsStr * _fieldStr * string(_timestamp) * RETURN_CHAR
end

"""
    function write(writer::WriteAPIClient, s)

`write` function for writing structs that conform to the measurement interface API
"""
function write(writer::WriteAPIClient, bucket::String, s::T) where T
    write(writer, bucket, buildRecord(s), precision = writePrecision(T))
end


"""
    function write(writer::WriteAPIClient, bucket::String, s::Vector{T}) where T

`write` function for writing structs vector that conform to the measurement interface API
"""
function write(writer::WriteAPIClient, bucket::String, s::Vector{T}) where T
    isempty(s) && return nothing
    ilp_str = join("", buildRecord.(s))
    write(writer, bucket, ilp_str, precision = writePrecision(T))
end


"""
    batchWrite(writer::WriteAPIClient, bucket::String, s::Vector{T}) where T

Function used to batch-write a `Vector{T}` instance where `T` conforms to the `Measurement` interface. 
The size of the batch is determine by the `batchSize` parameter of the `writeOption` object in the `writer`.
"""
function batchWrite(writer::WriteAPIClient, bucket::String, s::Vector{T}) where T
    ilp_str = ""
    batchSize = writer.writeOptions.batchSize
    precision = writePrecision(T)

    for (index, entry) in enumerate(s)
        ## Write the string if the batchSize is reached
        if(index % batchSize == 0)
            ## Write the ILP to the server
            write(writer, bucket, ilp_str, precision = precision)
            ## Reset the ilp string
            ilp_str = "" 
        end
        ## Build the ILP string
        ilp_str *= buildRecord(entry)
    end

    ## Final write - flush out any bits of the ilp remaining
    length(ilp_str) > 0  && write(writer, bucket, ilp_str, precision = writePrecision(T))

    return nothing
end


"""
    write(writer::AsyncWriteAPIClient, bucket::String, s::T) where T

Function used to write `asynchronously` to the InfluxDB Server
"""
function write(writer::AsyncWriteAPIClient, bucket::String, s::T) where T
    return write(writer, bucket, buildRecord(s), precision = writePrecision(T))
end


"""
Example:
"""
# struct Tempareture
#     location::String
#     value::Float64
#     bug_concentration::Integer
#     time::DateTime
# end

# ## InfluxDB
# measurement(::Type{Tempareture}) = "weather"
# tags(::Type{Tempareture}) = [:location]
# timestamp(::Type{Tempareture}) = :time
# exclude(::Type{Tempareture}) = [:bug_concentration]

# t = Tempareture("Nairobi", 24.5, 9, DateTime(2023, 5, 2))

# buildRecord(t)