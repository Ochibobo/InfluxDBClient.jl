using Dates
"""

    @enum WritePrecision begin
        ns = Nanosecond
        μ = Microsecond
        ms = Millisecond
        s = Second
    end

`WritePrecision` enum to hold the different time classes use to cast a record's timestamp value to before persistence
"""
@enum WritePrecision begin
    ns
    μ
    ms
    s
end


"""
    function timestampConverter(timestamp::DateTime, writePrecision::WritePrecision)::Integer

function used to convert the `timestamp` value of type `DateTime` into an `Integer`
"""
function timestampConverter(timestamp::DateTime, writePrecision::WritePrecision)::Integer
    ## Convert to econds first
    timeInMilliseconds = Dates.Millisecond(Dates.value(timestamp) - Dates.UNIXEPOCH)

    if writePrecision == ns
        return convert(Dates.Nanosecond, timeInMilliseconds).value
    elseif writePrecision == μ
        return convert(Dates.Microsecond, timeInMilliseconds).value
    elseif writePrecision == ms
        return timeInMilliseconds.value
    elseif writePrecision == s
        return round(Int, timeInMilliseconds.value / 1000)
    else
        throw(ArgumentError("Invalid writePrecision value"))
    end
end

"""
    function timestampConverter(time::Date, writePrecision::WritePrecision)::Integer

function used to convert the `timestamp` value of type `Date` into an `Integer`
"""
function timestampConverter(time::Date, writePrecision::WritePrecision)::Integer
    return timestampConverter(DateTime(time), writePrecision)
end
