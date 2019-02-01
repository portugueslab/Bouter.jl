using Statistics
using RollingFunctions

function get_scale_mm(exp::Experiment)
    cal_params = exp.metadata["stimulus"]["calibration_params"]
    proj_mat = hcat(cal_params["cam_to_proj"]...)
    return norm(proj_mat[:, :2] * [1.0, 0.0]) * cal_params["mm_px"]
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
        format("f{:d}_x", i_fish),
        format("f{:d}_vx", i_fish),
        format("f{:d}_y", i_fish),
        format("f{:d}_vy", i_fish),
        format("f{:d}_theta", i_fish),
        format("f{:d}_vtheta", i_fish),
        (format("f{:d}_theta_{:02d}", i_fish, i) for i in 0:n_segments-1)...])
end

function _fish_renames(i_fish, n_segments)
    dr = Dict(
            format("f{:d}_x", i_fish) => "x",
            format("f{:d}_vx", i_fish) => "vx",
            format("f{:d}_y", i_fish) => "y",
            format("f{:d}_vy", i_fish) => "vy",
            format("f{:d}_theta", i_fish) => "theta",
            format("f{:d}_vtheta", i_fish) => "vtheta",
        (
            format("f{:d}_theta_{:02d}", i_fish, i) => format("theta_{:02d}",i)
            for i in 0:n_segments-1)...
        )
    return Dict((Symbol.(key)=>Symbol.(value) for (key, value) in dr)...)
end

function fish_columns(log::DataFrame)

end

function extract_bouts(exp::Experiment; max_interpolate=2, window_size=7, recalculate_vel=false, scale=nothing)
    
    df = exp.behavior_log

    scale = scale != nothing ? scale : get_scale_mm(exp)

    n_fish = extract_n_fish(df)
    n_segments = extract_n_segments(df)

    bouts = []
    continuous = []
    for i_fish in range(n_fish)
        if recalculate_vel
            for thing in ["x", "y", "theta"]
                df[Symbol(format("f{}_v{}", i_fish, thing)] = 
                    [0; diff(dfint[Symbol(format("f{}_{}",\i_fish, thing))])]
            end
        end
        vel = dfint[Symbol(format("f{}_vx", i_fish))] ^ 2 +
              dfint[Symbol(format("f{}_vy", i_fish))] ^ 2
        vel = rollmedian(vel, window_size)
        bout_locations, continuity = extract_segments_above_thresh(vel.values)
        all_bouts_fish =  _extract_bout(dfint, s, e, n_segments, i_fish, scale)
            for (s, e) in bout_locations
        ]
        bouts.append(all_bouts_fish)
        continuous.append(np.array(continuity))
    end
    return bouts, continuous

end
