
function normalise_bout(df)
    dir_init = angle_mean(df.theta[1:5])+π
    coord = [df.x df.y]
    coord .= coord .- coord[1:1,1:2]
    coord .= coord * rot_mat(dir_init)
    return [coord df.theta .- dir_init]
end