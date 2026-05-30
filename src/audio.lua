-- Procedural chiptune audio: music + SFX are synthesized at runtime as
-- SoundData, so the game ships with zero audio asset files. Works natively
-- and under love.js (Web Audio).
local Settings = require("src.settings")

local Audio = {}

local SR = 22050           -- sample rate (mono); low enough to synth quickly
local music = {}           -- name -> SoundData (lazily built)
local sfx = {}             -- name -> { sources... } round-robin pool
local current = nil        -- currently playing music Source
local currentName = nil

------------------------------------------------------------------- synthesis
-- note name ("a4", "c#3", "-") -> frequency in Hz. "-" is a rest (0).
local SEMI = { c = 0, ["c#"] = 1, d = 2, ["d#"] = 3, e = 4, f = 5,
               ["f#"] = 6, g = 7, ["g#"] = 8, a = 9, ["a#"] = 10, b = 11 }
local function note(name)
    if not name or name == "-" then return 0 end
    local letter = name:sub(1, #name - 1):lower()
    local octave = tonumber(name:sub(#name)) or 4
    local semi = (SEMI[letter] or 0) + (octave - 4) * 12
    return 261.63 * 2 ^ (semi / 12) -- relative to C4
end

local function osc(wave, phase)
    if wave == "square" then return phase < 0.5 and 1 or -1
    elseif wave == "saw" then return 2 * phase - 1
    elseif wave == "tri" then return phase < 0.5 and (4 * phase - 1) or (3 - 4 * phase)
    elseif wave == "sine" then return math.sin(phase * 2 * math.pi)
    else return math.random() * 2 - 1 end -- noise
end

-- additively mix one enveloped note into a float buffer (1-based table).
local function addNote(buf, n, startT, dur, f, wave, vol)
    if f <= 0 then return end
    local s0 = math.floor(startT * SR)
    local len = math.min(n - s0, math.floor(dur * SR))
    if len <= 0 then return end
    local attack = math.max(1, math.floor(0.004 * SR))
    local release = math.max(1, math.floor(0.05 * SR))
    for i = 0, len - 1 do
        local phase = (f * (i / SR)) % 1
        local env = 1
        if i < attack then env = i / attack
        elseif i > len - release then env = (len - i) / release end
        local idx = s0 + i + 1
        buf[idx] = (buf[idx] or 0) + osc(wave, phase) * vol * env
    end
end

-- short percussive kick: pitch drops fast, quick decay.
local function addKick(buf, n, startT, vol)
    local s0 = math.floor(startT * SR)
    local len = math.min(n - s0, math.floor(0.12 * SR))
    for i = 0, len - 1 do
        local t = i / SR
        local f = 150 * math.exp(-t * 24) + 45
        local env = math.exp(-t * 18)
        local idx = s0 + i + 1
        buf[idx] = (buf[idx] or 0) + math.sin(2 * math.pi * f * t) * vol * env
    end
end

local function addHat(buf, n, startT, vol)
    local s0 = math.floor(startT * SR)
    local len = math.min(n - s0, math.floor(0.03 * SR))
    for i = 0, len - 1 do
        local env = 1 - i / len
        local idx = s0 + i + 1
        buf[idx] = (buf[idx] or 0) + (math.random() * 2 - 1) * vol * env
    end
end

-- Build a looping track SoundData from layered patterns.
-- spec = { step=seconds, bars=int, layers={ {wave,vol,sustain,pat={...}} },
--          perc={ kick={1,0,...}, hat={...} } }
local function buildTrack(spec)
    local maxlen = 1
    for _, l in ipairs(spec.layers) do maxlen = math.max(maxlen, #l.pat) end
    if spec.perc then
        if spec.perc.kick then maxlen = math.max(maxlen, #spec.perc.kick) end
        if spec.perc.hat then maxlen = math.max(maxlen, #spec.perc.hat) end
    end
    local steps = maxlen * (spec.bars or 1)
    local seconds = steps * spec.step
    local n = math.floor(seconds * SR)
    local buf = {}

    for _, l in ipairs(spec.layers) do
        for s = 0, steps - 1 do
            local name = l.pat[(s % #l.pat) + 1]
            addNote(buf, n, s * spec.step, spec.step * (l.sustain or 0.9),
                    note(name), l.wave, l.vol)
        end
    end
    if spec.perc then
        for s = 0, steps - 1 do
            if spec.perc.kick and spec.perc.kick[(s % #spec.perc.kick) + 1] == 1 then
                addKick(buf, n, s * spec.step, spec.perc.kvol or 0.5)
            end
            if spec.perc.hat and spec.perc.hat[(s % #spec.perc.hat) + 1] == 1 then
                addHat(buf, n, s * spec.step, spec.perc.hvol or 0.12)
            end
        end
    end

    local sd = love.sound.newSoundData(n, SR, 16, 1)
    for i = 0, n - 1 do
        local v = buf[i + 1] or 0
        if v > 1 then v = 1 elseif v < -1 then v = -1 end
        sd:setSample(i, v)
    end
    return sd
end

----------------------------------------------------------------- music specs
local TRACKS = {
    -- calm, sparse minor theme for menus / story / reward breathers
    menu = {
        step = 0.22, bars = 1,
        layers = {
            { wave = "tri", vol = 0.16, sustain = 0.98, pat = {
                "a2","-","-","-","f2","-","-","-","c3","-","-","-","g2","-","-","-" } },
            { wave = "sine", vol = 0.14, sustain = 0.95, pat = {
                "a4","-","e4","-","f4","-","c4","-","c5","-","g4","-","g4","-","b4","-" } },
            { wave = "tri", vol = 0.08, sustain = 0.6, pat = {
                "-","a5","-","-","-","f5","-","-","-","e5","-","-","-","d5","-","-" } },
        },
    },
    -- driving battle loop
    battle = {
        step = 0.11, bars = 1,
        layers = {
            { wave = "square", vol = 0.16, sustain = 0.85, pat = {
                "a2","a2","-","a2","c3","-","a2","-","e2","e2","-","e2","g2","-","e2","-" } },
            { wave = "square", vol = 0.11, sustain = 0.55, pat = {
                "a4","c5","e5","c5","d5","c5","a4","g4","a4","-","e5","g5","f5","e5","d5","c5" } },
        },
        perc = { kick = { 1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0 },
                 hat  = { 0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0 } },
    },
    -- faster, heavier boss loop
    boss = {
        step = 0.09, bars = 1,
        layers = {
            { wave = "saw", vol = 0.17, sustain = 0.8, pat = {
                "a1","a1","a1","c2","a1","a1","g1","g1","f1","f1","f1","a1","e2","e2","d2","c2" } },
            { wave = "square", vol = 0.12, sustain = 0.5, pat = {
                "a4","-","a4","c5","e5","-","d5","-","f5","-","e5","-","c5","d5","e5","f5" } },
        },
        perc = { kick = { 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0 }, kvol = 0.55,
                 hat  = { 0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1 } },
    },
    -- bright major victory loop
    victory = {
        step = 0.16, bars = 1,
        layers = {
            { wave = "tri", vol = 0.16, sustain = 0.95, pat = {
                "c3","-","g3","-","c3","-","g3","-","a2","-","e3","-","f2","-","c3","-" } },
            { wave = "square", vol = 0.12, sustain = 0.6, pat = {
                "c5","e5","g5","c6","g5","e5","c5","e5","a4","c5","e5","a5","f4","a4","c5","g5" } },
        },
        perc = { hat = { 1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0 } },
    },
}

------------------------------------------------------------------- SFX specs
-- Render a SoundData from frequency-sweep + optional noise segments.
local function buildSfx(opts)
    local dur = opts.dur
    local n = math.floor(dur * SR)
    local sd = love.sound.newSoundData(n, SR, 16, 1)
    local phase = 0
    for i = 0, n - 1 do
        local t = i / SR
        local k = i / n
        local f = (opts.f1 or 440) + ((opts.f2 or opts.f1 or 440) - (opts.f1 or 440)) * k
        phase = (phase + f / SR) % 1
        local v = osc(opts.wave or "square", phase) * (1 - (opts.noise or 0))
        if (opts.noise or 0) > 0 then v = v + (math.random() * 2 - 1) * opts.noise end
        local env = math.exp(-t * (opts.decay or 12))
        if opts.swell then env = math.min(1, k * 4) * env end
        v = v * (opts.vol or 0.3) * env
        if v > 1 then v = 1 elseif v < -1 then v = -1 end
        sd:setSample(i, v)
    end
    return sd
end

-- Render a small arpeggio (list of note names) into one SoundData.
local function buildArp(names, stepDur, wave, vol)
    local n = math.floor(#names * stepDur * SR)
    local buf = {}
    for s, nm in ipairs(names) do
        addNote(buf, n, (s - 1) * stepDur, stepDur * 1.1, note(nm), wave, vol)
    end
    local sd = love.sound.newSoundData(n, SR, 16, 1)
    for i = 0, n - 1 do
        local v = buf[i + 1] or 0
        if v > 1 then v = 1 elseif v < -1 then v = -1 end
        sd:setSample(i, v)
    end
    return sd
end

local SFX_BUILDERS = {
    swing  = function() return buildSfx{ f1 = 1200, f2 = 400, dur = 0.09, wave = "noise", noise = 0.9, vol = 0.22, decay = 24 } end,
    hit    = function() return buildSfx{ f1 = 620, f2 = 180, dur = 0.08, wave = "square", noise = 0.3, vol = 0.3, decay = 26 } end,
    kill   = function() return buildSfx{ f1 = 420, f2 = 50, dur = 0.26, wave = "saw", noise = 0.25, vol = 0.32, decay = 9 } end,
    hurt   = function() return buildSfx{ f1 = 220, f2 = 80, dur = 0.2, wave = "square", vol = 0.34, decay = 8 } end,
    dash   = function() return buildSfx{ f1 = 280, f2 = 900, dur = 0.16, wave = "tri", noise = 0.2, vol = 0.24, decay = 7, swell = true } end,
    shoot  = function() return buildSfx{ f1 = 820, f2 = 440, dur = 0.09, wave = "square", vol = 0.2, decay = 18 } end,
    move   = function() return buildSfx{ f1 = 760, f2 = 760, dur = 0.05, wave = "square", vol = 0.22, decay = 22 } end,
    slam   = function() return buildSfx{ f1 = 140, f2 = 40, dur = 0.32, wave = "square", noise = 0.3, vol = 0.4, decay = 8 } end,
    select = function() return buildArp({ "e5", "a5" }, 0.07, "square", 0.26) end,
    clear  = function() return buildArp({ "c5", "e5", "g5", "c6" }, 0.07, "tri", 0.24) end,
    pickup = function() return buildArp({ "c5", "g5", "c6" }, 0.06, "square", 0.24) end,
}

----------------------------------------------------------------------- public
function Audio.load()
    -- SFX are tiny; build them all up front.
    for name, builder in pairs(SFX_BUILDERS) do
        local sd = builder()
        local pool = {}
        for i = 1, 4 do pool[i] = love.audio.newSource(sd, "static") end
        sfx[name] = { pool = pool, idx = 1 }
    end
    -- Pre-build the two most common tracks so there's no in-game hitch.
    music.menu = buildTrack(TRACKS.menu)
    music.battle = buildTrack(TRACKS.battle)
end

local function getTrack(name)
    if not music[name] and TRACKS[name] then
        music[name] = buildTrack(TRACKS[name])
    end
    return music[name]
end

function Audio.playMusic(name)
    if name == currentName and current and current:isPlaying() then return end
    if current then current:stop() end
    local sd = getTrack(name)
    if not sd then current, currentName = nil, nil; return end
    current = love.audio.newSource(sd, "static")
    current:setLooping(true)
    current:setVolume(Settings.data.music)
    current:play()
    currentName = name
end

function Audio.stopMusic()
    if current then current:stop() end
    current, currentName = nil, nil
end

function Audio.play(name)
    local entry = sfx[name]
    if not entry or Settings.data.sfx <= 0 then return end
    local src = entry.pool[entry.idx]
    entry.idx = entry.idx % #entry.pool + 1
    src:stop()
    src:setVolume(Settings.data.sfx)
    src:play()
end

function Audio.setMusicVol(v)
    Settings.data.music = v
    if current then current:setVolume(v) end
end

function Audio.setSfxVol(v)
    Settings.data.sfx = v
    -- a short blip so the player hears the new level while adjusting
    Audio.play("move")
end

return Audio
