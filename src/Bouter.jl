module Bouter

import JSON
import DeepDish
import Feather
import CSV
using DataFrames


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
    if endswith(s, ".h5")
        return DeepDish.load_deepdish(s)
    elseif endswith(s, ".feather")
        return Feather.read(s)
    elseif endswith(s, ".csv")
        return CSV.File(s) |> DataFrame
    end
end

function Base.getproperty(e::Experiment, v::Symbol)
    if v in (:behavior_log, :estimator_log, :stimulus_log)
            bl = getfield(e, v)
            if bl == nothing
                if isa(e.metadata["tracking"][string(v)], String)
                    setfield!(e, v, load_exp_df(e.metadata["tracking"][string(v)]))
                end
            end
    end
    return getfield(e, v)
end


end # module
