using FileIO

struct MovingBackground
    images :: AbstractArray{AbstractArray}
    image_labels :: AbstractArray
    stim_ends :: AbstractArray
    motion
    mm_px
    centre_relative :: Bool
    shifts :: Union{Nothing, AbstractArray}
    display_size :: Tuple{Int64, Int64}
    proj_mat :: AbstractArray{Float64, 2}
end

function MovingBackground(exp::Experiment; asset_dir=raw"J:/_Shared/stytra_resources")
    stim_log = exp.metadata["stimulus"]["log"]
    
    if occursin(".h5", stim_log[1]["background_name"])
        bgimslist = Deepdish.load_deepdish(
            join(split(stim_log[1]["background_name"], "/")[1:end-1])
        )
        images = [
            bgimslist[parse(Int, split(item["background_name"], "/")[end])]

            for item in stim_log
        ]
        image_labels = [
            parse(Int, split(item["background_name"], "/")[end])

            for item in stim_log
        ]
    else
        images = []
        image_labels = []
        for item in stim_log:
            bn = item["background_name"]
            push!(images, load(joinpath(asset_dir, bn)))
            push!(image_labels, bn)
        end
    end

    centre_relative = stim_log[1]["centre_relative"]
    display_size = exp.metadata["stimulus"]["display_params"]["size"]

    if centre_relative
        shifts = Array{Float64}(undef, (2, length(images)))
        for i_stim in 1:length(images)
            imh, imw = images[i_stim].shape[1:2]
            h, w = display_size
            display_centre = (w / 2, h / 2)
            image_centre = (imw / 2, imh / 2)
            shifts[i_stim, :] = (
                display_centre[1] - image_centre[1],
                display_centre[2] - image_centre[2],
            )
        end
    end

end