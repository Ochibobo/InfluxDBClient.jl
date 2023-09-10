using InfluxDBClient
using Test
using Dates

## Global WriteAPI Client
writer = WriteAPI.WriteAPIClient()

## Writes TestSet
@testset "Writes TestSet" begin
    struct RoomStateEntry
        room::String
        co::Int
        hum::Float64
        temp::Float64
        time::DateTime
    end

    ## Mark the struct with the measurement interface functions
    WriteAPI.measurement(::Type{RoomStateEntry}) = "home"
    WriteAPI.tags(::Type{RoomStateEntry}) = [:room]
    WriteAPI.timestamp(::Type{RoomStateEntry}) = :time

    entry = RoomStateEntry("Kitchen", 0, 35.9, 23, DateTime(2023, 9, 10))

    ## Get the type of the entry
    T = typeof(entry)

    @testset "Write Measurement Interface Construction" begin
         ## Confirm the measurement
        @test WriteAPI.measurement(T) == "home"
        ## Confirm the tags
        @test WriteAPI.tags(T) == [:room]
        ## Confirm the timestamp fields
        @test WriteAPI.timestamp(T) == :time
        ## Confirm the excluded fields
        @test WriteAPI.exclude(T) == []

        ## Build the ILP Record
        ilp_record = WriteAPI.buildRecord(entry)
        expected_record = "home,room=Kitchen co=0,hum=35.9,temp=23.0 1694304000000000000\n"
        
        ## Assert that the produced record matches the generated ILP record
        @test ilp_record == expected_record
    end

    ## Single Measurement Interface Tests
    @testset "Write Single Measurement Interface To Database" begin
        response = WriteAPI.write(writer, "airSensors", entry)

        @test !isnothing(response)
        @test response.status == Int(ResponseCodes.NO_CONTENT)
    end

    ## Multiple Measurement Interfaces Write Tests
    @testset "Write Multiple Measurement Interfaces To Database" begin
        response = WriteAPI.write(writer, "airSensors", repeat([entry], 5))

        @test !isnothing(response)
        @test response.status == Int(ResponseCodes.NO_CONTENT)
    end


    ## Point test
    
end

## 