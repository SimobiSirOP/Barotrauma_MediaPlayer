
SoundHelpers = {}

function SoundHelpers.IsOgg(data)
    return string.sub(data, 0, 4) == "OggS"
end

function SoundHelpers.IsChannelDisposed(channel)
    return channel.ALSourceIndex == -1
end

return SoundHelpers
