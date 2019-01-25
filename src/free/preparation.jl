
function get_scale_mm(exp::Experiment)
    cal_params = exp.metadata["stimulus"]["calibration_params"]
    proj_mat = hcat(cal_params["cam_to_proj"]...)
    return norm(proj_mat[:, :2] * [1.0, 0.0]) * cal_params["mm_px"]
end

function n_segments(df::DataFrame)
    return maximum(map(s -> parse(Int, last(split(s, "_"))),
                       filter(s -> occursin("theta_", s),
                        string.(names(df)))))+1
end

function n_fish(df::DataFrame)
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
        
            format("f{:d}_x", i_fish)=> "x",
            format("f{:d}_vx", i_fish)=> "vx",
            format("f{:d}_y", i_fish)=> "y",
            format("f{:d}_vy", i_fish)=> "vy",
            format("f{:d}_theta", i_fish)=> "theta",
            format("f{:d}_vtheta", i_fish)=> "vtheta",
        (
            format("f{:d}_theta_{:02d}", i_fish, i)=> format("theta_{:02d}",i)
            for i in 0:n_segments-1)...
        )
    return Dict((Symbol.(key)=>Symbol.(value) for (key, value) in dr)...)
end

function fish_columns(log::DataFrame)

end