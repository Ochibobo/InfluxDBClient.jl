"""
    abstract type FluxQueryFilter end

Abstract type that is to be extended by any other struct that
"""
abstract type FluxQueryFilter end


"""
    fluxFilterToDict(filter::T)::Dict where T <: FluxQueryFilter

Function used to convert a `FluxQueryFilter` instance to a dictionary
"""
function fluxFilterToDict(filter::T)::Dict where T <: FluxQueryFilter
    fields = fieldnames(T)
    dict_entries = map(f -> (string(f), getproperty(filter, f)), fields)

    return Dict(dict_entries)
end

"""

`flux_query_str` for flux query definition. This also allows the definition of SQL queries.
"""
macro flux_query_str(ex)
    return quote
        replace(replace($(esc(ex)), "\n" => ""), r"\s{1,}" => " ")
    end
end


"""
    build_flux_query(query_str::String, filter::T) where T <: FluxQueryFilter

`build_flux_query` function to combine the flux query with struct filter parameters which are a subset of `FluxQueryFilter`
and return a full flux query where filter params are mapped to the query params
"""
function build_flux_query(query_str::String, filter::T) where T <: FluxQueryFilter
    fields = fieldnames(T)
    filter_params = map(f -> "\$$(string(f))" => "\"$(getproperty(filter, f))\"", fields)

    return replace(query_str, filter_params...)
end

 
"""
    build_flux_query(query_str::String, filter::Dict{K, V}) where {K, V}

`build_flux_query` function to combine the flux query with dictionary filter parameters
and return a full flux query where filter params are mapped to the query params
"""
function build_flux_query(query_str::String, filter::Dict{K, V}) where {K, V}
    filter_params = map(k -> "\$$(string(k))" => string(filter[k]), collect(keys(filter)))

    return replace(query_str, filter_params...)
end

"""
Example:
No struct or map nestings, no brackets!
"""
# struct LastXDaysUsageFilter <: FluxQueryFilter
#     bucket::String
#     measuerement::String
#     start::String
# end


# query = """
#         from(bucket: $bucket)
#         |> range(start: $start)
#         |> filter(fn: (r) => r._measurement == $measuerement)
#         """

# lastXMinutesUsageFilter = LastXMinutesUsageFilter()

# influxQuery = buildQuery(query, lastXMinutesUsageFilter)