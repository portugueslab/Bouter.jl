using FileIO
using Interpolations
using DataFrames

struct Movement
    x :: AbstractInterpolation
    y :: AbstractInterpolation
end

struct MovingBackground
    images :: AbstractArray{AbstractArray}
    image_labels :: AbstractArray
    stim_ends :: Array{Float64, 1}
    movement :: Movement
    mm_px
    center_relative :: Bool
    shifts :: Union{Nothing, Array{NTuple{2, Float64}, 1}}
    display_size :: AbstractArray
    proj_mat :: Array{Float64, 2}
end

function get_position(m::Movement, t) :: Tuple{Float64, Float64}
    return m.x(t), m.y(t)
end

function Movement(df::DataFrame)
    return Movement(
        LinearInterpolation(df.t, df._x, extrapolation_bc=Flat()),
        LinearInterpolation(df.t, df._y, extrapolation_bc=Flat())
    )
end

function MovingBackground(cexp::Experiment; asset_dir=raw"J:/_Shared/stytra_resources")
    stim_log = cexp.metadata["stimulus"]["log"]
    
    if occursin(".h5", stim_log[1]["background_name"])
        bgimslist = DeepDish.load_deepdish(
            join(split(stim_log[1]["background_name"], "/")[1:end-1])
        )["data"]
        images = [
            bgimslist[parse(Int, split(item["background_name"], "/")[end])+1]
            for item in stim_log
        ]
        image_labels = [
            parse(Int, split(item["background_name"], "/")[end])+1

            for item in stim_log
        ]
    else
        images = []
        image_labels = []
        for item in stim_log
            bn = item["background_name"]
            push!(images, load(joinpath(asset_dir, bn)))
            push!(image_labels, bn)
        end
    end

    center_relative = stim_log[1]["centre_relative"]
    display_size = cexp.metadata["stimulus"]["display_params"]["size"]

    if center_relative
        shifts = Array{NTuple{2, Float64}}(undef, length(images))
        for i_stim in 1:length(images)
            imh, imw = size(images[i_stim])[1:2]
            h, w = display_size
            display_centre = (w / 2, h / 2)
            image_centre = (imw / 2, imh / 2)
            shifts[i_stim] = display_centre .- image_centre
       
        end
    else
        shifts = nothing
    end

    stim_ends = [stim["t_stop"] for stim in stim_log]

    cal_params = cexp.metadata["stimulus"]["calibration_params"]
    proj_mat = vcat(transpose.(cal_params["proj_to_cam"])...)

    return MovingBackground(images,
                            image_labels,
                            stim_ends,
                            Movement(cexp.stimulus_log),
                            cexp.metadata["stimulus"]["calibration_params"]["mm_px"],
                            center_relative,
                            shifts,
                            display_size,
                            proj_mat
                            )

end

function _get_i_stim(bg::MovingBackground, t)
    return searchsortedfirst(bg.stim_ends, t)
end

function get_position(bg::MovingBackground, t)
    x, y =  get_position(bg.movement, t)
    if bg.center_relative
        x, y = bg.shifts[min(_get_i_stim(bg, t), length(bg.shifts))] .+ (x, -y)
    end
    return (x, y)
end

function get_position_camera(bg::MovingBackground, t)
    return bg.proj_mat * [get_position(bg, t)... ; 1]
end

function motion_direction_velocity(bg:: MovingBackground, t; dt_vel=0.1)::Tuple{Union{Missing, Float64}, Union{Missing, Float64}}
    p0, p1 = map(ti->get_position_camera(bg, ti), [t-dt_vel, t+dt_vel])
    dp = (p0 .- p1)/dt_vel
    if all(dp .== 0)
        return missing, 0.0
    else
        return atan(dp[2], dp[1]), norm(dp)
    end
end

function background_at_bouts!(bout_summary, bg::MovingBackground)
    full_data = Dict(Symbol("bg_", prefix, "_", suffix) => Array{Union{Missing, Float64}}(undef, size(bout_summary, 1))
                     for prefix in ["st", "en"] for suffix in ["theta", "v"])
    for (i_bout, row) in enumerate(eachrow(bout_summary))
        for (prefix, t) in zip(("st", "en"), (row.st_t, row.en_t))
            full_data[Symbol("bg_", prefix, "_", "theta")][i_bout], full_data[Symbol("bg_", prefix, "_", "v")][i_bout] = motion_direction_velocity(bg, t)
        end
    end
    for (sym, val) in full_data
        bout_summary[sym] = val
    end
end