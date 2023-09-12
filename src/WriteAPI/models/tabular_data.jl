# using DataFrames
using Dates
using Tables
using Parameters
using DataFrames

import Base: string
"""
Writing using DataFrames
"""

"""
    @with_kw mutable struct ILPSchema
        measurement::Symbol
        tags::Vector{Symbol}
        fields::Vector{Symbol}
        excluded::Vector{Symbol}
        timestamp::Symbol
        writePrecision::WritePrecision
    end

# Arguments
- `measurement::Symbol` - the measurement of the `ILP` record.
- `tags::Vector{Symbol}` - the list of `tags` of an `ILP` record. The `tags` are `columns` present in the table present in a `TabularData` instance
- `fields::Vector{Symbol}` - the list of `fields` of an `ILP` record. The `fields` are `columns` present in the table present in a `TabularData` instance
- `excluded::Vector{Symbol}` - the list of columns to be excluded from the `ILP` record.
- `timestamp::Symbol` - the `timestamp` entry of the `ILP` record. This symbol represents the column that represent the timestamp information
- `writePrecision::WritePrecision` -  the `writePrecision` of the `ILP` records generated from rows of the `TabularData`.

The `fields` field is not set explicitly. It is computed as the remaining columns after removing the tags, the excluded fields and the timestamp field.

`ILPSchema` struct that holds the schema that define the structure of the ILP record that oughts to be formed from 
each row entry of a `TabularData`'s instance.
"""
@with_kw mutable struct ILPSchema
    measurement::Symbol
    tags::Vector{Symbol}
    fields::Vector{Symbol}
    excluded::Vector{Symbol} = []
    timestamp::Symbol
    writePrecision::WritePrecision
end

"""
    measurement(i::ILPSchema)::Symbol

Retrieve the `measurement` name associated with a `ILPSchema` instance.
"""
measurement(i::ILPSchema)::Symbol = i.measurement


"""
    tags(i::ILPSchema)::Vector{Symbol}
   
Retrieve the `tags` assoicated with a `ILPSchema` instance
"""
tags(i::ILPSchema)::Vector{Symbol} = i.tags


"""
    fields(i::ILPSchema)::Vector{Symbol}

Retrieve the `fields` assoicated with a `ILPSchema` instance
"""
fields(i::ILPSchema)::Vector{Symbol} = i.fields


"""
    excluded(i::ILPSchema)::Vector{Symbol} 

Retrieve the `excluded` fields that are excempt from the ILP statements generated that are assoicated
with the `ILPSchema` instance.
"""
excluded(i::ILPSchema)::Vector{Symbol} = i.excluded


"""
    timestamp(i::ILPSchema)::Symbol

Retrieve the `timestamp` field associated with a `ILPSchema` instance
"""
timestamp(i::ILPSchema)::Symbol = i.timestamp


"""
    writePrecision(i::ILPSchema)::WritePrecision

`writePrecision` to get the `WritePrecision` of `ILPSchema`
"""
writePrecision(i::ILPSchema)::WritePrecision = i.writePrecision


"""
    struct TabularData
        table
        ilpSchema::ILPSchema
    end

Creates an object that stores a `copy` of the passed data. It is used as the way to write data to an InfluxDB instance.

The passed `table` requires a conformity to the Tables.jl interface and the implementation of `copy(table)`if it is not defined.

The `fields` field is not set explicitly. It is computed as the remaining columns after removing the tags, the excluded fields and the timestamp field.
"""
struct TabularData
    table
    ilpSchema::ILPSchema

    function TabularData(table; measurement::Symbol,
                        tags::Vector{Symbol}, 
                        excluded::Vector{Symbol} = Vector{Symbol}(), 
                        timestamp::Symbol, 
                        writePrecision::WritePrecision = ns)
        ## Retrieve the type of the passed table
        table_type = typeof(table)
        ## Assert the passed data implements the table interface
        !Tables.istable(table) && error("values of type: $(table_type) do not implement the Tables.jl interface. 
                Visit (https://tables.juliadata.org/stable/) for instructions on how to make Type $(table_type) implement the interface.")
        ## Create a copy of the table object
        table_copy = copy(table)
        ## Get the table column names
        columns = Tables.columnnames(table_copy)
        ## Asset timestamp is an valid column name
        timestamp ∉ columns && error("specified timestamp column ($timestamp) is not the Table of type $(table_type)")
        ## Get the timestamp column type
        t = eltype(Tables.getcolumn(table_copy, timestamp))
        ## Assert the timestamp is a column of type DateTime, Date or Integer
        any(tt -> typeof(t) <: tt, [Dates.Date, Dates.DateTime, Integer]) && error("unsupported timestamp column ($timestamp) of type $t. 
                                                                        Supported types are: Date, DateTime and Integer")
        ## Assert tags are a column
        any(==(1), tags .∉ [columns]) && error("at least one of the specified tags in ($tags) is not a valid $table_type column")
        ## Assert excluded fields are a columns
        any(==(1), excluded .∉ [columns]) && error("at least one of the specified fields in ($excluded) is not a valid $table_type column")
        ## Assign to the fields vector = columns - (tags + excluded + timestamp)
        fields = filter(f -> f ∉ [timestamp, excluded..., tags...], columns)
        ## Assert there's at least one field specified
        length(fields) == 0 && error("there must be at least one field column specified. Either your excluded/tags/tags + excluded have left no fields 
                                      for the ILP. At least one field is required.")
        ## Create a new instance of an ILPSchema
        ilpSchema = ILPSchema(measurement = measurement, tags = tags, fields = fields, 
                            excluded = excluded, timestamp = timestamp, writePrecision = writePrecision)
        ## Return a new tabular data instance
        new(table_copy, ilpSchema)
    end
end

## Tabular Data fields accessors

"""
    table(t::TabularData)

Retrieve the `table` from a `TabularData` instance. The `table` is the data store which implements the 
`Tables.jl` interface.
"""
table(t::TabularData) = t.table


"""
    table_size(t::TabularData)

Return the number of rows present in the `table` present in the `TabularData`
"""
function table_size(t::TabularData)::Int
    ## Return the number of rows if the table is a dataframe
    table(t) isa DataFrame && return size(table(t))[1]

    ## Return length otherwise (other table interfaces use this)
    return length(table(t))
end



"""
    ilpSchema(t::TabularData)

Get the `ILPSchema` of the `TabularData` instance
"""
ilpSchema(t::TabularData) = t.ilpSchema


"""
    measurement(t::TabularData)::Symbol

Retrieve the `measurement` name associated with a `TabularData` instance.
"""
measurement(t::TabularData)::Symbol = measurement(ilpSchema(t))


"""
    tags(t::TabularData)::Vector{Symbol}
   
Retrieve the `tags` assoicated with a `TabularData` instance
"""
tags(t::TabularData)::Vector{Symbol} = tags(ilpSchema(t))


"""
    fields(t::TabularData)::Vector{Symbol}

Retrieve the `fields` assoicated with a `TabularData` instance
"""
fields(t::TabularData)::Vector{Symbol} = fields(ilpSchema(t))


"""
    excluded(t::TabularData)::Vector{Symbol} 

Retrieve the `excluded` fields that are excempt from the ILP statements generated that are assoicated
with the `TabularData` instance.
"""
excluded(t::TabularData)::Vector{Symbol} = excluded(ilpSchema(t))


"""
    timestamp(t::TabularData)::Symbol

Retrieve the `timestamp` field associated with a `TabularData` instance
"""
timestamp(t::TabularData)::Symbol = timestamp(ilpSchema(t))


"""
    writePrecision(t::TabularData)::WritePrecision

`writePrecision` to get the `WritePrecision` of `TabularData`
"""
writePrecision(t::TabularData)::WritePrecision = writePrecision(ilpSchema(t))


"""
    row_string(row, i::ILPSchema)::String

Function that converts a `TabularData` row into an ILP record statement.
"""
function row_string(row, i::ILPSchema)::String
    ## Build the tags
    _tags = map(t -> string(t) * EQUAL_SIGN * string(Tables.getcolumn(row, t)), tags(i))
    _tags_str = length(_tags) == 0 ? "" : COMMA * join(_tags, COMMA)
    _tags_str *= SPACE_CHAR

    ## Build the fields
    _fields = map(f -> string(f) * EQUAL_SIGN * string(Tables.getcolumn(row, f)), fields(i))
    _timestamp = buildTimestamp(Tables.getcolumn(row,timestamp(i)), writePrecision(i))

    return string(measurement(i)) * _tags_str * join(_fields, COMMA) * SPACE_CHAR * _timestamp * RETURN_CHAR
end


"""
    Base.string(tabularData::TabularData; batchSize = 0)::String

Function used to convert tabular data into ILP statements
"""
function Base.string(tabularData::TabularData)::String
    ilp_str = ""
    schema = ilpSchema(tabularData)

    for row in Tables.rows(table(tabularData))
        ilp_str *= row_string(row, schema)
    end

    return ilp_str
end


"""
    partialString(tabularData::TabularData, start::Integer = 1, batchSize::Integer)::Tuple{Integer, String}

Function used to generate `ILP` record statements based on a subset of rows of table in a `TabularData` instance.
The `batchSize` specifies the number of `rows` to take at a time. The `start` argument specifies the start index.

The function returns a tuple = `Tuple{Integer, String}` where the `Integer` represents the next index to be included 
as the next `start` index of the subsequent generation. The `ILP` record produced is the `String` element of the tuple.
"""
function partialString(tabularData::TabularData, start::Integer = 1, batchSize::Integer = 1)::Tuple{Integer, String}
    ilp_str = ""
    schema = ilpSchema(tabularData)
    _table = table(tabularData)
    
    ## Get the table size
    _table_size = table_size(tabularData)

    ## Get the expected last_index
    last_index = start + batchSize - 1

    ## Set the last index to the start + batchSize or to the length of the table if the start + batchSize > length(table)
    if last_index > _table_size
        last_index = _table_size
    end

    ## Convert the indices that are within the scope to an ILP record statement
    if _table isa DataFrame
        for row in Tables.rows(_table)[start: last_index]
            ilp_str *= row_string(row, schema)
        end
    else
        for row in Tables.rows(_table[start: last_index])
            ilp_str *= row_string(row, schema)
        end
    end
   
    return (last_index + 1, ilp_str)
end


"""
    batchWrite(writer::WriteAPIClient, bucket::String, tabularData::TabularData)

Function used to batch-write a `TabularData` instance. The size of the batch is determine by the `batchSize` parameter of the 
`writeOption` object in the `writer`.
"""
function batchWrite(writer::WriteAPIClient, bucket::String, tabularData::TabularData)::Vector
    ## Start at index 1
    startIndex = 1
    n = table_size(tabularData)
    ## Fetch the batch size specified in the writer's writeOptions
    batchSize = writer.writeOptions.batchSize
    ## Responses
    responses = []

    ## Write the batches one at a time
    while startIndex < n
        startIndex, ilp = partialString(tabularData, startIndex, batchSize)
        ## Write the ilp to the server
        response = write(writer, bucket, ilp, precision = writePrecision(tabularData))
        ## Add the response to responses
        push!(responses, response)
    end

    return responses
end

"""
    write(writer::WriteAPIClient, bucket::String, tabularData::TabularData)

`write` function for tabular data should take a WriteAPIClient too
"""
function write(writer::WriteAPIClient, bucket::String, tabularData::TabularData)
    write(writer, bucket, string(tabularData), precision = writePrecision(tabularData))
end


"""
Example:

df = DataFrame(
    co = [0, 0, 0, 0],
    hum = [35.9, 36.2, 36.1, 35.8],
    temp = [21, 23, 22.7, 23.5],
    room = ["Kitchen", "Bedroom", "Library", "HttpArea"],
    time = ["2023-05-30T08:00:00Z", "2023-05-30T09:00:00Z", "2023-05-30T10:00:00Z", "2023-05-30T11:00:00Z"]
)
"""



