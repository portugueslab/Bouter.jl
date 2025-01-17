module Bouter

import JSON
import DeepDish
import Feather
import CSV
using DataFrames
using LinearAlgebra
using DataFrames
using Formatting

export Experiment

mutable struct ImagingData
    dataArray::AbstractArray
    framerate::Float64
end

"A structure which handles Stytra experiments"
mutable struct Experiment
    path::String
    metadata::Dict{String, Any}
    fish_id::String
    session_id::String
    behavior_log::Union{DataFrame, Nothing}
    estimator_log::Union{DataFrame, Nothing}
    stimulus_log::Union{DataFrame, Nothing}
    imaging_data::Union{ImagingData, Nothing}
end

function Experiment(path::String)
    if endswith(path, ".json")
        metadata = JSON.parsefile(path)
        fish_id = get(metadata["general"],
                      "fish_id",
                       basename(dirname(path)))
        session_id = get(metadata["general"],
                       "session_id",
                        split(basename(path),'_')[1])

    end
    return Experiment(dirname(path), metadata, fish_id, session_id, nothing, nothing, nothing, nothing)
end

function load_exp_df(s::String)
    if endswith(s, ".h5") || endswith(s, ".hdf5")
        return DeepDish.load_deepdish(s)["data"]
    elseif endswith(s, ".feather")
        return Feather.read(s)
    elseif endswith(s, ".csv")
        return CSV.File(s) |> DataFrame
    end
end

function Base.getproperty(e::Experiment, v::Symbol)
    if v == :behavior_log || v == :estimator_log
        bl = getfield(e, v)
        if bl == nothing
            if haskey(e.metadata["tracking"], string(v)) && isfile(joinpath(e.path,e.metadata["tracking"][string(v)]))
                setfield!(e, v, load_exp_df(joinpath(e.path,e.metadata["tracking"][string(v)])))
            elseif isfile(joinpath(e.path, "$(e.session_id)_log.hdf5"))
                setfield!(e, v, load_exp_df(joinpath(e.path, "$(e.session_id)_log.hdf5")))
            elseif isfile(joinpath(e.path, "$(e.session_id)_behavior_log.hdf5"))
                setfield!(e, v, load_exp_df(joinpath(e.path, "$(e.session_id)_behavior_log.hdf5")))
            else
                throw(ArgumentError("This log does not exist"))
            end
        end
    elseif v == :stimulus_log
        bl = getfield(e, v)
        if bl == nothing
            if haskey(e.metadata["stimulus"], string(v)) &&
                isa(e.metadata["stimulus"][string(v)], String) &&
                isfile(joinpath(e.path,e.metadata["stimulus"][string(v)]))

                    setfield!(e, v, load_exp_df(
                        joinpath(e.path,e.metadata["stimulus"][string(v)]))
                    )

            else
                for fileroot in ["stimulus_log", "dynamic_log", "stimulus_param_log"]
                    filebase = joinpath(e.path, e.session_id * "_"*fileroot*".")
                    if isfile(filebase*"h5")
                        setfield!(e, v, load_exp_df(filebase*"h5"))
                    elseif isfile(filebase*"hdf5")
                        setfield!(e, v, load_exp_df(filebase*"hdf5"))
                    end
                end
            end
        end
        if getfield(e, v) === nothing
            throw(ArgumentError("Stimulus log does not exist"))
        end
    end
    return getfield(e, v)
end

include("utilities.jl")
include("segmentation.jl")
include("free/kinematics.jl")
include("free/preparation.jl")
include("free/background_motion.jl")

end # module
