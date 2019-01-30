"Bridge missing values by interpolation"
function interpolate_missing(A::AbstractArray, max_interpolate)
    beenmissing = 0
    B = similar(A)
    for i in 1:length(A)
        if A[i] !== missing
            B[i] = A[i]
            if beenmissing > 0
                if beenmissing <= max_interpolate && i - beenmissing - 1 > 0
                    prev = A[i - beenmissing - 1]
                    next = A[i]
                    for (i_int, i_ins) in enumerate(i-beenmissing:i-1)
                       fact = i_int/(beenmissing + 1)
                       B[i_ins] = prev*fact + next*(1-fact)
                    end
                else
                    B[i-beenmissing:i-1] .= missing
                end
                beenmissing = 0
            end
        else
            beenmissing += 1
        end
    end
    return B
end