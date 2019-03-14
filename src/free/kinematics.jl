using DataFrames

function normalise_bout(df)
    dir_init = angle_mean(df.theta[1:5])+π
    coord = [df.x df.y]
    coord .= coord .- coord[1:1,1:2]
    coord .= coord * rot_mat(dir_init)
    return [coord df.theta .- dir_init]
end

function summarize_bouts(bouts::Array{DataFrame, 1})
    sel_headers = ["t", "x", "y", "theta"]
    variants = ["st", "en"]
    full_dict = Dict(Symbol(prefix, "_", suffix) => Array{Union{Missing,Float64}}(undef, length(bouts))
                     for prefix in variants for suffix in sel_headers)
    header_symbols = Symbol.(sel_headers)

    for (i_bout, bout) in enumerate(bouts)
        for header in sel_headers
            full_dict[Symbol("st_", header)][i_bout] = bout[Symbol(header)][1]
            full_dict[Symbol("en_", header)][i_bout] = bout[Symbol(header)][end]
        end
    end
    return DataFrame(full_dict)
end

function summarize_bouts(bouts::Array{DataFrame, 1}, continuity::Array)
    df = summarize_bouts(bouts)
    df.follows_previous = continuity
    return df
end
