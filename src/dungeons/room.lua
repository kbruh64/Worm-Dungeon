-- One room of the computer system. Procedural tile grid with computer-themed
-- floor patterns, solid obstacles (server racks, capacitors, vents), and an
-- exit terminal that activates once enemies are cleared.
local TILE = 8
local Room = {}
Room.__index = Room

-- playable bounds (inside the room frame). Top HUD: y=0..12, bottom HUD: y=GAME_H-12..GAME_H.
local PLAY_X1, PLAY_Y1 = 8, 14
local PLAY_X2, PLAY_Y2 = nil, nil

local function ensureBounds()
    PLAY_X2 = GAME_W - 8
    PLAY_Y2 = GAME_H - 14
end

Room.TILE = TILE

local function chooseFloorPattern(seed)
    -- Deterministic pattern per room seed. Pattern is a function (col, row) -> floor variant index.
    local r = seed
    local kind = (r % 5)
    if kind == 0 then
        return function(c, rr) return ((c + rr) % 2 == 0) and 1 or 2 end
    elseif kind == 1 then
        return function(c, rr) return (rr % 4 == 0) and 3 or 1 end
    elseif kind == 2 then
        return function(c, rr) return (c % 5 == 0) and 4 or 1 end
    elseif kind == 3 then
        return function(c, rr) return ((c * 7 + rr * 3) % 9 == 0) and 5 or 1 end
    else
        return function(c, rr) return 1 end
    end
end

-- Place a few obstacles (server racks etc). Each obstacle: {x, y, w, h, kind, color}.
-- Tile-aligned, never inside spawn or exit zones, never overlapping.
local function generateObstacles(palette, seed)
    ensureBounds()
    math.randomseed(seed)
    local obstacles = {}
    local count = 2 + (seed % 4)
    local kinds = { "rack", "capacitor", "vent", "chip", "data_node" }

    local function fits(x, y, w, h)
        if x < PLAY_X1 + 16 or x + w > PLAY_X2 - 16 then return false end
        if y < PLAY_Y1 + 12 or y + h > PLAY_Y2 - 12 then return false end
        -- keep spawn (center) and exit (right-mid) clear
        local cx, cy = GAME_W / 2, GAME_H / 2
        if math.abs((x + w/2) - cx) < 24 and math.abs((y + h/2) - cy) < 24 then return false end
        local ex, ey = PLAY_X2 - 12, GAME_H / 2
        if math.abs((x + w/2) - ex) < 16 and math.abs((y + h/2) - ey) < 16 then return false end
        for _, o in ipairs(obstacles) do
            if not (x + w + 4 < o.x or o.x + o.w + 4 < x or y + h + 4 < o.y or o.y + o.h + 4 < y) then
                return false
            end
        end
        return true
    end

    local tries = 0
    while #obstacles < count and tries < 60 do
        tries = tries + 1
        local kind = kinds[math.random(1, #kinds)]
        local w, h
        if kind == "rack" then w, h = 16, 24
        elseif kind == "capacitor" then w, h = 8, 12
        elseif kind == "vent" then w, h = 24, 8
        elseif kind == "chip" then w, h = 16, 16
        else w, h = 12, 12 -- data_node
        end
        local x = PLAY_X1 + math.random(0, math.floor((PLAY_X2 - PLAY_X1 - w) / TILE)) * TILE
        local y = PLAY_Y1 + math.random(0, math.floor((PLAY_Y2 - PLAY_Y1 - h) / TILE)) * TILE
        if fits(x, y, w, h) then
            table.insert(obstacles, { x = x, y = y, w = w, h = h, kind = kind, color = palette.accent, phase = math.random() * 6.28 })
        end
    end
    return obstacles
end

function Room.new(dungeonData, seed)
    ensureBounds()
    return setmetatable({
        palette = dungeonData.palette,
        floorPattern = chooseFloorPattern(seed),
        obstacles = generateObstacles(dungeonData.palette, seed),
        time = 0,
        exitOpen = false,
    }, Room)
end

function Room:update(dt) self.time = self.time + dt end

function Room:bounds() return PLAY_X1, PLAY_Y1, PLAY_X2, PLAY_Y2 end

-- AABB collision: return adjusted x,y if (x,y,w,h) overlaps any obstacle.
function Room:resolveCollision(x, y, w, h, oldX, oldY)
    -- check obstacles + room bounds
    if x < PLAY_X1 then x = PLAY_X1 end
    if y < PLAY_Y1 then y = PLAY_Y1 end
    if x + w > PLAY_X2 then x = PLAY_X2 - w end
    if y + h > PLAY_Y2 then y = PLAY_Y2 - h end

    for _, o in ipairs(self.obstacles) do
        if not (x + w <= o.x or o.x + o.w <= x or y + h <= o.y or o.y + o.h <= y) then
            -- resolve by axis: try previous x first, then previous y
            local triedX = { x = oldX, y = y }
            if (triedX.x + w <= o.x or o.x + o.w <= triedX.x or triedX.y + h <= o.y or o.y + o.h <= triedX.y) then
                x = oldX
            else
                y = oldY
            end
        end
    end
    return x, y
end

function Room:exitRect()
    local ex = PLAY_X2 - 10
    local ey = math.floor(GAME_H / 2) - 6
    return ex, ey, 8, 12
end

function Room:exitHit(px, py, pw, ph)
    if not self.exitOpen then return false end
    local ex, ey, ew, eh = self:exitRect()
    return not (px + pw < ex or ex + ew < px or py + ph < ey or ey + eh < py)
end

local function px(x, y, w, h)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), w or 1, h or 1)
end

local function drawFloorTile(self, c, r, variant)
    local x = PLAY_X1 + c * TILE
    local y = PLAY_Y1 + r * TILE
    local p = self.palette
    -- base
    love.graphics.setColor(p.bg[1] * 1.4, p.bg[2] * 1.4, p.bg[3] * 1.4, 1)
    px(x, y, TILE, TILE)
    -- variants
    if variant == 1 then
        love.graphics.setColor(p.accent[1] * 0.25, p.accent[2] * 0.25, p.accent[3] * 0.25, 1)
        px(x, y + TILE - 1, TILE, 1)
        px(x, y, 1, TILE)
    elseif variant == 2 then
        love.graphics.setColor(p.accent[1] * 0.4, p.accent[2] * 0.4, p.accent[3] * 0.4, 1)
        px(x + 3, y + 3, 2, 2)
    elseif variant == 3 then
        -- horizontal trace line
        love.graphics.setColor(p.accent[1] * 0.5, p.accent[2] * 0.5, p.accent[3] * 0.5, 1)
        px(x, y + 3, TILE, 1)
        px(x, y + 4, TILE, 1)
    elseif variant == 4 then
        -- vertical bus line with solder pads
        love.graphics.setColor(p.accent[1] * 0.5, p.accent[2] * 0.5, p.accent[3] * 0.5, 1)
        px(x + 3, y, 1, TILE)
        px(x + 4, y, 1, TILE)
        love.graphics.setColor(p.accent[1], p.accent[2], p.accent[3], 0.6)
        px(x + 2, y + 3, 3, 1)
    elseif variant == 5 then
        -- data node blink
        local blink = math.floor(self.time * 2 + c + r) % 4 == 0
        love.graphics.setColor(p.accent[1] * 0.4, p.accent[2] * 0.4, p.accent[3] * 0.4, 1)
        px(x + 3, y + 3, 2, 2)
        if blink then
            love.graphics.setColor(0.6, 1, 0.8, 1)
            px(x + 3, y + 3, 2, 2)
        end
    end
end

function Room:drawFloor()
    local cols = math.floor((PLAY_X2 - PLAY_X1) / TILE)
    local rows = math.floor((PLAY_Y2 - PLAY_Y1) / TILE)
    for r = 0, rows - 1 do
        for c = 0, cols - 1 do
            drawFloorTile(self, c, r, self.floorPattern(c, r))
        end
    end
end

function Room:drawFrame()
    local p = self.palette
    -- chip-edge frame
    love.graphics.setColor(p.accent[1] * 0.7, p.accent[2] * 0.7, p.accent[3] * 0.7, 1)
    px(PLAY_X1 - 2, PLAY_Y1 - 2, PLAY_X2 - PLAY_X1 + 4, 2)
    px(PLAY_X1 - 2, PLAY_Y2, PLAY_X2 - PLAY_X1 + 4, 2)
    px(PLAY_X1 - 2, PLAY_Y1 - 2, 2, PLAY_Y2 - PLAY_Y1 + 4)
    px(PLAY_X2, PLAY_Y1 - 2, 2, PLAY_Y2 - PLAY_Y1 + 4)
    -- chip pins along edges
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    for c = 0, math.floor((PLAY_X2 - PLAY_X1) / 8) do
        px(PLAY_X1 + c * 8 + 1, PLAY_Y1 - 4, 2, 2)
        px(PLAY_X1 + c * 8 + 1, PLAY_Y2 + 2, 2, 2)
    end
    for r = 0, math.floor((PLAY_Y2 - PLAY_Y1) / 8) do
        px(PLAY_X1 - 4, PLAY_Y1 + r * 8 + 1, 2, 2)
        px(PLAY_X2 + 2, PLAY_Y1 + r * 8 + 1, 2, 2)
    end
end

local obstacleDraw = {}

function obstacleDraw.rack(o, t)
    -- server rack with status LEDs
    love.graphics.setColor(0.15, 0.15, 0.18, 1)
    px(o.x, o.y, o.w, o.h)
    love.graphics.setColor(0.35, 0.35, 0.4, 1)
    px(o.x, o.y, o.w, 1)
    px(o.x, o.y, 1, o.h)
    love.graphics.setColor(0.08, 0.08, 0.1, 1)
    px(o.x + o.w - 1, o.y, 1, o.h)
    px(o.x, o.y + o.h - 1, o.w, 1)
    -- rack slots
    for i = 0, 4 do
        local sy = o.y + 3 + i * 4
        love.graphics.setColor(0.05, 0.05, 0.08, 1)
        px(o.x + 2, sy, o.w - 4, 2)
        -- LED
        local blink = math.floor(t * 3 + i + o.phase) % 4
        if blink == 0 then love.graphics.setColor(0.3, 1, 0.4, 1)
        elseif blink == 1 then love.graphics.setColor(1, 0.6, 0.2, 1)
        else love.graphics.setColor(0.2, 0.3, 0.2, 1) end
        px(o.x + 3, sy, 1, 1)
        love.graphics.setColor(0.2, 0.6, 1, 1)
        if i % 2 == 0 then px(o.x + o.w - 4, sy, 1, 1) end
    end
end

function obstacleDraw.capacitor(o, t)
    -- electrolytic capacitor
    love.graphics.setColor(0.2, 0.2, 0.4, 1)
    px(o.x, o.y + 2, o.w, o.h - 2)
    love.graphics.setColor(0.35, 0.35, 0.6, 1)
    px(o.x, o.y + 2, o.w, 1)
    px(o.x, o.y + 2, 1, o.h - 2)
    love.graphics.setColor(0.1, 0.1, 0.25, 1)
    px(o.x + o.w - 1, o.y + 2, 1, o.h - 2)
    px(o.x, o.y + o.h - 1, o.w, 1)
    -- top dome
    love.graphics.setColor(0.5, 0.5, 0.8, 1)
    px(o.x + 1, o.y + 1, o.w - 2, 1)
    px(o.x + 2, o.y, o.w - 4, 1)
    -- label "K" stripe
    love.graphics.setColor(1, 0.9, 0.4, 1)
    px(o.x + 2, o.y + 4, 1, 4)
    -- leads
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    px(o.x + 2, o.y + o.h, 1, 1)
    px(o.x + o.w - 3, o.y + o.h, 1, 1)
end

function obstacleDraw.vent(o, t)
    -- horizontal cooling vent / heatsink
    love.graphics.setColor(0.25, 0.25, 0.3, 1)
    px(o.x, o.y, o.w, o.h)
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    px(o.x, o.y, o.w, 1)
    love.graphics.setColor(0.1, 0.1, 0.15, 1)
    px(o.x, o.y + o.h - 1, o.w, 1)
    -- fins
    for i = 0, math.floor(o.w / 3) - 1 do
        love.graphics.setColor(0.1, 0.1, 0.15, 1)
        px(o.x + 1 + i * 3, o.y + 1, 1, o.h - 2)
        love.graphics.setColor(0.4, 0.4, 0.5, 1)
        px(o.x + 2 + i * 3, o.y + 1, 1, o.h - 2)
    end
    -- heat shimmer
    local shimmer = math.floor(t * 4 + o.phase) % 3
    love.graphics.setColor(1, 0.5, 0.2, 0.3)
    for i = 0, 3 do
        px(o.x + 2 + i * 6, o.y - 2 - shimmer, 1, 1)
    end
end

function obstacleDraw.chip(o, t)
    -- IC chip with pins on all sides and label
    love.graphics.setColor(0.08, 0.08, 0.1, 1)
    px(o.x, o.y, o.w, o.h)
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    px(o.x + 1, o.y + 1, o.w - 2, 1)
    px(o.x + 1, o.y + 1, 1, o.h - 2)
    -- pins
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    for i = 0, 2 do
        px(o.x + 2 + i * 4, o.y - 1, 2, 1)
        px(o.x + 2 + i * 4, o.y + o.h, 2, 1)
        px(o.x - 1, o.y + 2 + i * 4, 1, 2)
        px(o.x + o.w, o.y + 2 + i * 4, 1, 2)
    end
    -- pin 1 marker
    love.graphics.setColor(1, 1, 1, 1)
    px(o.x + 2, o.y + 2, 1, 1)
    -- label dots
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    px(o.x + 6, o.y + 6, 4, 1)
    px(o.x + 6, o.y + 9, 3, 1)
end

function obstacleDraw.data_node(o, t)
    -- pulsing data node / glowing core
    local pulse = 0.5 + 0.5 * math.sin(t * 3 + o.phase)
    love.graphics.setColor(o.color[1] * 0.3, o.color[2] * 0.3, o.color[3] * 0.3, 1)
    px(o.x, o.y, o.w, o.h)
    love.graphics.setColor(o.color[1] * 0.6, o.color[2] * 0.6, o.color[3] * 0.6, 1)
    px(o.x + 1, o.y + 1, o.w - 2, o.h - 2)
    love.graphics.setColor(o.color[1], o.color[2], o.color[3], 1)
    px(o.x + 3, o.y + 3, o.w - 6, o.h - 6)
    love.graphics.setColor(1, 1, 1, 0.5 + pulse * 0.5)
    px(o.x + o.w / 2 - 1, o.y + o.h / 2 - 1, 2, 2)
    -- corner brackets
    love.graphics.setColor(0.8, 0.9, 1, 1)
    px(o.x, o.y, 2, 1); px(o.x, o.y, 1, 2)
    px(o.x + o.w - 2, o.y, 2, 1); px(o.x + o.w - 1, o.y, 1, 2)
    px(o.x, o.y + o.h - 1, 2, 1); px(o.x, o.y + o.h - 2, 1, 2)
    px(o.x + o.w - 2, o.y + o.h - 1, 2, 1); px(o.x + o.w - 1, o.y + o.h - 2, 1, 2)
end

function Room:drawObstacles()
    for _, o in ipairs(self.obstacles) do
        local fn = obstacleDraw[o.kind] or obstacleDraw.chip
        fn(o, self.time)
    end
end

function Room:drawExit()
    local ex, ey, ew, eh = self:exitRect()
    if self.exitOpen then
        local pulse = 0.5 + 0.5 * math.sin(self.time * 6)
        -- door frame
        love.graphics.setColor(0.1, 0.1, 0.15, 1)
        px(ex - 1, ey - 1, ew + 2, eh + 2)
        -- portal glow
        love.graphics.setColor(0.3, 1, 0.6, 1)
        px(ex, ey, ew, eh)
        love.graphics.setColor(1, 1, 1, pulse)
        px(ex + 2, ey + 2, ew - 4, eh - 4)
        -- arrow
        love.graphics.setColor(0, 0, 0, 1)
        local cx = ex + ew / 2 - 1
        local cy = ey + eh / 2
        px(cx, cy - 2, 1, 5)
        px(cx + 1, cy - 1, 1, 3)
        px(cx + 2, cy, 1, 1)
    else
        -- sealed port (locked)
        love.graphics.setColor(0.15, 0.15, 0.18, 1)
        px(ex, ey, ew, eh)
        love.graphics.setColor(0.4, 0.1, 0.1, 1)
        px(ex + 1, ey + 1, ew - 2, eh - 2)
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
        local cx = ex + ew / 2 - 1
        local cy = ey + eh / 2 - 1
        px(cx, cy, 2, 2)
        -- lock symbol bars
        love.graphics.setColor(0.2, 0.05, 0.05, 1)
        for i = 0, 2 do px(ex + 1, ey + 2 + i * 3, ew - 2, 1) end
    end
end

return Room
