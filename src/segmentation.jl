
function extract_segments_above_thresh(
    vel, threshold=0.1; min_duration=20, pad_before=12, pad_after=25, skip_missing=true
)
    """ Useful for extracing bouts from velocity or vigor

    :param vel:
    :param threshold:
    :param min_duration:
    :param pad_before:
    :param pad_after:
    :return:
    """

    bouts = Tuple{UInt64, UInt64}[]
    connected = Bool[]
        
    in_bout = false
    continuity = false
    start = 0
    i = max(pad_before + 1, 2)
    bout_ended = pad_before
    while i < size(vel)[end] - pad_after
        if ismissing(vel[i])
            continuity = false
            if in_bout && skip_missing
                in_bout = false
            end

        elseif i > bout_ended && vel[i - 1] < threshold < vel[i] && !in_bout
            in_bout = true
            start = i - pad_before

        elseif vel[i - 1] > threshold > vel[i] && in_bout
            in_bout = false
            if i - start > min_duration
                push!(bouts, (start, i + pad_after))
                bout_ended = i + pad_after
                if continuity
                    push!(connected, true)
                else
                    push!(connected, false)
                end
            end
        end
        continuity = true
        i += 1
    end
    return bouts, connected
end