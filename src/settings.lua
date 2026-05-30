-- Persistent player settings. Saved to the LÖVE save directory (identity
-- "worm_dungeon") as a tiny Lua chunk so it survives across sessions.
local Settings = {}

local FILE = "settings.txt"

Settings.data = {
    music = 0.6,      -- 0..1 music volume
    sfx = 0.8,        -- 0..1 sound-effect volume
    fullscreen = false,
    shake = true,     -- screen shake on/off
    crt = true,       -- vignette / CRT-style edge darkening
}

local function clamp01(v) return math.max(0, math.min(1, v)) end

function Settings.load()
    if love.filesystem.getInfo(FILE) then
        local chunk = love.filesystem.load(FILE)
        local ok, t = pcall(chunk)
        if ok and type(t) == "table" then
            for k, v in pairs(t) do
                if Settings.data[k] ~= nil then Settings.data[k] = v end
            end
        end
    end
    Settings.data.music = clamp01(Settings.data.music)
    Settings.data.sfx = clamp01(Settings.data.sfx)
end

function Settings.save()
    local parts = { "return {" }
    for k, v in pairs(Settings.data) do
        parts[#parts + 1] = string.format("%s=%s,", k, tostring(v))
    end
    parts[#parts + 1] = "}"
    love.filesystem.write(FILE, table.concat(parts))
end

return Settings
