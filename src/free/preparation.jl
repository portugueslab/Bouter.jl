using Statistics
using ImageFiltering
using Printf

function get_scale_mm(exp::Experiment)
    cal_params = exp.metadata["stimulus"]["calibration_params"]
    proj_mat = vcat(transpose.(cal_params["cam_to_proj"])...)
    return norm(proj_mat[:, 1:2] * [1.0, 0.0]) * cal_params["mm_px"]
end

function extract_n_segments(df::DataFrame)
    return maximum(map(s -> parse(Int, last(split(s, "_"))),
                       filter(s -> occursin("theta_", s),
                        string.(names(df)))))+1
end

function extract_n_fish(df::DataFrame)
    return maximum(map(s -> parse(Int, first(split(s, "_"))[2:end]),
    filter(s -> startswith(s, "f"),
     string.(names(df)))))+1
end

function _fish_column_names(i_fish, n_segments)
    return Symbol.([
        (format("f{:d}_$(pfx)$(p)", i_fish) for p in ["x", "y","theta"] for pfx in ["","v"])...,
        (format("f{:d}_theta_{:02d}", i_fish, i) for i in 0:n_segments-1)...])
end

function _fish_renames(i_fish, n_segments)
    dr = Dict(      
        ("f$(i_fish)_$(pfx)$(p)" => "$(pfx)$(p)" for p in ["x", "y","theta"] for pfx in ["","v"])...,
        (
            format("f{:d}_theta_{:02d}", i_fish, i)=> format("theta_{:02d}",i)
            for i in 0:n_segments-1)...
        )
    return Dict((Symbol.(key)=>Symbol.(value) for (key, value) in dr)...)
end

function _rename_fish(df, i_fish, n_segments)
    return rename(df[ [:t; _fish_column_names(i_fish, n_segments)]], _fish_renames(i_fish, n_segments))
end

"Extracts bout as a part of a dataframe, normalizing its velocities"
function _extract_bout(df, s, e, n_segments, i_fish=0, scale=1.0)
    bout = _rename_fish(df[s:e, :], i_fish, n_segments)
    # scale to physical coordinates
    dt = (bout.t[end] - bout.t[1]) / size(bout, 1)
    for sym in [:x, :vx, :y, :vy]
        bout[sym] .*= scale
    end
    for sym in [:vx, :vy, :vtheta]
        bout[sym] ./= dt
    end
    return bout
end

function median_missing(a)
    if isempty(a)
       return missing
   else 
       return median(a)
   end
end

"Extracts bouts from a freely-swimming fish experiment"
function extract_bouts(
    cexp::Experiment;
    max_interpolate=2,
    window_size=7,
    recalculate_vel=false,
    scale=nothing, convert_to_missing=true, kwargs...)

    if convert_to_missing
        NaN_to_missing!(cexp.behavior_log)
    end

    df = cexp.behavior_log

    scale = scale == nothing ? get_scale_mm(cexp) : scale

    n_fish = extract_n_fish(df)
    n_segments = extract_n_segments(df)
    bouts = []
    continuous = []
    for i_fish in 0:n_fish-1
        if recalculate_vel
            for thing in ["x", "y", "theta"]
                df[Symbol("f", string(i_fish), "_v", thing)] = [0 ;
                    diff(df[Symbol("f", string(i_fish), "_v", thing)])]
            end
        end
        vel = interpolate_missing(
                df[Symbol("f", i_fish, "_vx")] .^ 2 .+
                df[Symbol("f", i_fish, "_vy")] .^ 2, max_interpolate)
        med_vel = similar(vel)
        vel = mapwindow!(median_missing ∘ skipmissing, med_vel, vel, window_size)
        bout_locations, continuity = extract_segments_above_thresh(vel, kwargs...)
        all_bouts_fish = [
            _extract_bout(df, s, e, n_segments, i_fish, scale)
            for (s, e) in bout_locations
        ]
        push!(bouts, all_bouts_fish)
        push!(continuous, continuity)
    end
    return bouts, continuous
end