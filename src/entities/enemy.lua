local FX = require("src.fx")

local Enemy = {}
Enemy.__index = Enemy

local archetypes = {
    bit      = { w = 8,  h = 8,  speed = 30, hp = 1, color = {1, 0.4, 0.4}, contact = 1 },
    byte     = { w = 12, h = 12, speed = 40, hp = 2, color = {1, 0.6, 0.3}, contact = 1 },
    packet   = { w = 12, h = 8,  speed = 80, hp = 1, color = {0.5, 0.9, 1}, contact = 1 },
    daemon   = { w = 14, h = 14, speed = 20, hp = 2, color = {0.8, 0.4, 1}, contact = 1, ranged = true },
    firewall = { w = 18, h = 18, speed = 25, hp = 5, color = {1, 0.5, 0.2}, contact = 2 },
    virus    = { w = 12, h = 12, speed = 50, hp = 2, color = {0.4, 1, 0.6}, contact = 1, splits = true },
    kernel   = { w = 20, h = 20, speed = 35, hp = 6, color = {1, 0.9, 0.5}, contact = 2 },
    root     = { w = 32, h = 28, speed = 45, hp = 10, color = {1, 0.3, 0.6}, contact = 2 },
}

function Enemy.new(x, y, arch, hpScale)
    local a = archetypes[arch] or archetypes.bit
    return setmetatable({
        x = x, y = y, w = a.w, h = a.h,
        speed = a.speed, hp = hpScale or a.hp, maxHp = hpScale or a.hp,
        color = a.color, contact = a.contact,
        arch = arch, ranged = a.ranged, splits = a.splits,
        hitFlash = 0, dead = false,
        fireTimer = math.random() * 2,
        bobT = math.random() * 6.28,
        spinT = 0,
    }, Enemy)
end

function Enemy:rect() return self.x, self.y, self.w, self.h end

function Enemy:damage(n)
    self.hp = self.hp - n
    self.hitFlash = 0.12
    FX.spark(self.x + self.w / 2, self.y + self.h / 2, self.color, 6, 60, 0.3)
    FX.spark(self.x + self.w / 2, self.y + self.h / 2, {1, 1, 1}, 3, 100, 0.2)
    if self.hp <= 0 then
        self.dead = true
        FX.spark(self.x + self.w / 2, self.y + self.h / 2, self.color, 16, 120, 0.5)
        FX.spark(self.x + self.w / 2, self.y + self.h / 2, {1, 1, 1}, 6, 140, 0.3)
        FX.shakeFor(0.18, 1.5)
    end
end

function Enemy:update(dt, worm, addEnemy, addProjectile)
    self.hitFlash = math.max(0, self.hitFlash - dt)
    self.bobT = self.bobT + dt * 4
    self.spinT = self.spinT + dt

    local dx = worm.x - self.x
    local dy = worm.y - self.y
    local d = math.sqrt(dx * dx + dy * dy)
    if d > 0.1 then
        if self.ranged then
            if d > 60 then
                self.x = self.x + (dx / d) * self.speed * dt
                self.y = self.y + (dy / d) * self.speed * dt
            end
            self.fireTimer = self.fireTimer - dt
            if self.fireTimer <= 0 then
                self.fireTimer = 1.4
                addProjectile({
                    x = self.x + self.w / 2, y = self.y + self.h / 2,
                    vx = (dx / d) * 70, vy = (dy / d) * 70,
                    life = 3, damage = 1, color = self.color,
                })
            end
        else
            self.x = self.x + (dx / d) * self.speed * dt
            self.y = self.y + (dy / d) * self.speed * dt
        end
    end

    if not (worm.x + worm.w < self.x or self.x + self.w < worm.x
         or worm.y + worm.h < self.y or self.y + self.h < worm.y) then
        worm:damage(self.contact)
    end
end

-- ---- geometric pixel-sprite rendering ----

local function px(x, y, w, h)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), w or 1, h or 1)
end

local function setBodyColor(self)
    if self.hitFlash > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    end
end

local function shadeColor(c, k)
    return c[1] * k, c[2] * k, c[3] * k
end

local sprites = {}

local function drawShadow(self)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", self.x + self.w / 2, self.y + self.h + 1, self.w / 2.5, 1.5)
end

local function glowEye(cx, cy, color)
    love.graphics.setColor(color[1], color[2], color[3], 0.4)
    px(cx - 1, cy - 1, 3, 3)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    px(cx, cy, 1, 1)
end

-- bit: tiny pulsing diamond core with glowing eye
function sprites.bit(self)
    drawShadow(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    local bob = math.sin(self.bobT) * 0.6
    setBodyColor(self)
    -- diamond body
    px(cx - 3, cy - 1 + bob, 6, 2)
    px(cx - 2, cy - 2 + bob, 4, 1)
    px(cx - 2, cy + 1 + bob, 4, 1)
    px(cx - 1, cy - 3 + bob, 2, 1)
    px(cx - 1, cy + 2 + bob, 2, 1)
    -- inner shine
    love.graphics.setColor(1, 1, 1, 0.6)
    px(cx - 1, cy - 1 + bob, 1, 1)
    -- glowing eye
    glowEye(cx, cy + bob, {1, 1, 0.4})
end

-- byte: cyberpunk robot head with antennas, glowing eyes, jagged mouth, side panels
function sprites.byte(self)
    drawShadow(self)
    local hop = math.floor(self.bobT * 2) % 2 == 0 and 0 or -1
    local x, y = self.x, self.y + hop
    -- antennae with pulsing tips
    setBodyColor(self)
    px(x + 2, y, 1, 2)
    px(x + self.w - 3, y, 1, 2)
    local pulse = (math.floor(self.bobT * 3) % 2 == 0) and 1 or 0
    love.graphics.setColor(1, 0.4 + pulse * 0.4, 0.2, 1)
    px(x + 2, y - 1 - pulse, 1, 1)
    px(x + self.w - 3, y - 1 - pulse, 1, 1)
    -- body
    setBodyColor(self)
    px(x + 1, y + 2, self.w - 2, self.h - 3)
    -- side panel highlights
    love.graphics.setColor(shadeColor(self.color, 1.4))
    px(x + 1, y + 2, 1, self.h - 3)
    px(x + 1, y + 2, self.w - 2, 1)
    -- shadow side
    love.graphics.setColor(shadeColor(self.color, 0.4))
    px(x + self.w - 2, y + 2, 1, self.h - 3)
    px(x + 1, y + self.h - 2, self.w - 2, 1)
    -- glowing eyes
    love.graphics.setColor(0, 0, 0, 1)
    px(x + 3, y + 5, 2, 2)
    px(x + self.w - 5, y + 5, 2, 2)
    glowEye(x + 3, y + 5, {0.4, 1, 1})
    glowEye(x + self.w - 5, y + 5, {0.4, 1, 1})
    -- jagged metal grin
    love.graphics.setColor(0, 0, 0, 1)
    px(x + 3, y + self.h - 4, self.w - 6, 2)
    love.graphics.setColor(1, 1, 1, 0.8)
    for i = 0, 2 do px(x + 3 + i * 2, y + self.h - 4, 1, 1) end
    for i = 0, 1 do px(x + 4 + i * 2, y + self.h - 3, 1, 1) end
    -- bolts in corners
    love.graphics.setColor(shadeColor(self.color, 1.6))
    px(x + 2, y + 3, 1, 1); px(x + self.w - 3, y + 3, 1, 1)
    px(x + 2, y + self.h - 3, 1, 1); px(x + self.w - 3, y + self.h - 3, 1, 1)
end

-- packet: arrowhead with motion trails behind it
function sprites.packet(self)
    drawShadow(self)
    local x, y = self.x, self.y
    -- motion trail
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.3)
    px(x - 2, y + 3, 1, 2)
    px(x - 4, y + 3, 1, 2)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.6)
    px(x, y + 2, 2, 4)
    -- arrowhead body
    setBodyColor(self)
    px(x + 0, y + 2, 2, 4)
    px(x + 2, y + 1, 2, 6)
    px(x + 4, y + 0, 2, 8)
    px(x + 6, y + 1, 2, 6)
    px(x + 8, y + 2, 2, 4)
    -- white core highlight
    love.graphics.setColor(1, 1, 1, 1)
    px(x + 4, y + 3, 2, 2)
    -- inner shadow
    love.graphics.setColor(shadeColor(self.color, 0.5))
    px(x + 2, y + 6, 2, 1)
    px(x + 4, y + 7, 2, 1)
    px(x + 6, y + 6, 2, 1)
end

-- daemon: floating cyclops with horns, tracking iris, magical aura
function sprites.daemon(self)
    drawShadow(self)
    local bob = math.sin(self.bobT) * 1.5
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2 + bob
    -- pulsing aura
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.25)
    love.graphics.circle("fill", cx, cy, 9 + math.sin(self.bobT * 2))
    setBodyColor(self)
    -- horns/spikes
    px(self.x + 1, self.y + bob, 2, 3)
    px(self.x + self.w - 3, self.y + bob, 2, 3)
    px(self.x + 2, self.y - 1 + bob, 1, 1)
    px(self.x + self.w - 3, self.y - 1 + bob, 1, 1)
    -- body hexagon
    px(cx - 5, cy - 1, 10, 3)
    px(cx - 4, cy - 3, 8, 2)
    px(cx - 4, cy + 2, 8, 2)
    px(cx - 3, cy - 4, 6, 1)
    px(cx - 3, cy + 4, 6, 1)
    -- highlight ridge
    love.graphics.setColor(shadeColor(self.color, 1.4))
    px(cx - 3, cy - 3, 6, 1)
    px(cx - 4, cy - 2, 2, 1)
    -- shadow underside
    love.graphics.setColor(shadeColor(self.color, 0.5))
    px(cx - 3, cy + 3, 6, 1)
    -- iris tracks somewhat
    love.graphics.setColor(1, 1, 1, 1)
    px(cx - 2, cy - 1, 4, 3)
    local irisOff = math.cos(self.spinT * 0.5)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    px(cx - 1 + irisOff, cy, 2, 2)
    love.graphics.setColor(0, 0, 0, 1)
    px(cx + irisOff, cy, 1, 1)
    -- eyelid line
    love.graphics.setColor(0, 0, 0, 1)
    px(cx - 2, cy - 2, 4, 1)
end

-- firewall: brick wall with layered flames + angry glare
function sprites.firewall(self)
    drawShadow(self)
    local x, y = self.x, self.y
    -- wall base
    setBodyColor(self)
    px(x, y + 5, self.w, self.h - 5)
    -- brick pattern
    love.graphics.setColor(shadeColor(self.color, 0.5))
    for r = 0, 2 do
        local offset = (r % 2 == 0) and 0 or 3
        for c = -1, 4 do
            local bx = x + offset + c * 6
            local by = y + 5 + r * 5
            if bx >= x and bx + 4 <= x + self.w then
                px(bx, by, 1, 4)
            end
        end
        px(x, y + 5 + r * 5 + 4, self.w, 1)
    end
    -- top highlight
    love.graphics.setColor(shadeColor(self.color, 1.4))
    px(x, y + 5, self.w, 1)
    -- multi-layer flames
    local flick = math.floor(self.bobT * 4) % 3
    love.graphics.setColor(1, 0.2, 0, 1)
    for i = 0, 4 do
        local fx = x + i * 4
        px(fx, y + 4, 3, 1)
    end
    love.graphics.setColor(1, 0.6, 0.1, 1)
    for i = 0, 4 do
        local fx = x + i * 4 + (i % 2 == flick and 0 or 0)
        px(fx + 1, y + 2 + (flick == 1 and -1 or 0), 1, 2)
        px(fx, y + 3, 3, 1)
    end
    love.graphics.setColor(1, 0.9, 0.3, 1)
    for i = 0, 4 do
        local fx = x + i * 4
        px(fx + 1, y + 1 + (flick == 2 and -1 or 0), 1, 1)
    end
    love.graphics.setColor(1, 1, 0.8, 1)
    for i = 0, 4 do
        local fx = x + i * 4
        if (i + flick) % 2 == 0 then
            px(fx + 1, y, 1, 1)
        end
    end
    -- angry glowing eyes set into wall
    love.graphics.setColor(0, 0, 0, 1)
    px(x + 4, y + 10, 3, 2)
    px(x + self.w - 7, y + 10, 3, 2)
    love.graphics.setColor(1, 0.3, 0, 1)
    px(x + 5, y + 10, 1, 1)
    px(x + self.w - 6, y + 10, 1, 1)
    -- angry brow
    love.graphics.setColor(0, 0, 0, 1)
    px(x + 3, y + 9, 4, 1)
    px(x + self.w - 7, y + 9, 4, 1)
end

-- virus: spiky orb with rotating spikes, sharp teeth, beating nucleus
function sprites.virus(self)
    drawShadow(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    -- rotating spikes drawn first (under body)
    setBodyColor(self)
    for i = 0, 7 do
        local a = (i / 8) * math.pi * 2 + self.spinT * 2
        local r1, r2 = 5, 7
        local x1, y1 = cx + math.cos(a) * r1, cy + math.sin(a) * r1
        local x2, y2 = cx + math.cos(a) * r2, cy + math.sin(a) * r2
        px(x1, y1, 1, 1)
        px((x1 + x2) / 2, (y1 + y2) / 2, 1, 1)
        px(x2, y2, 1, 1)
    end
    -- main blob body
    setBodyColor(self)
    px(cx - 4, cy - 3, 8, 6)
    px(cx - 3, cy - 4, 6, 1)
    px(cx - 3, cy + 3, 6, 1)
    -- highlight
    love.graphics.setColor(shadeColor(self.color, 1.5))
    px(cx - 3, cy - 3, 2, 2)
    -- teeth at bottom
    love.graphics.setColor(1, 1, 1, 1)
    px(cx - 3, cy + 2, 1, 1); px(cx - 1, cy + 2, 1, 1); px(cx + 1, cy + 2, 1, 1); px(cx + 3, cy + 2, 1, 1)
    -- evil eyes
    love.graphics.setColor(0, 0, 0, 1)
    px(cx - 2, cy - 1, 1, 2)
    px(cx + 1, cy - 1, 1, 2)
    -- beating nucleus
    local pulse = math.floor(self.bobT * 3) % 2
    love.graphics.setColor(1, 0.8, 0.2, 0.6 + pulse * 0.4)
    px(cx, cy, 1, 1)
end

-- kernel: rotating crystal core with energy aura + orbiting sparks
function sprites.kernel(self)
    drawShadow(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    -- pulsing aura
    local pulse = 1 + math.sin(self.bobT) * 0.15
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 0.2)
    love.graphics.circle("fill", cx, cy, 12 * pulse)
    -- outer diamond
    setBodyColor(self)
    for r = 0, 9 do
        local w = 18 - r * 2
        if w > 0 then
            px(cx - w / 2, cy - 9 + r, w, 1)
            px(cx - w / 2, cy + 9 - r, w, 1)
        end
    end
    -- facet highlights
    love.graphics.setColor(shadeColor(self.color, 1.5))
    for r = 0, 5 do
        px(cx - r, cy - 5 + r, 1, 1)
        px(cx - r - 1, cy - 4 + r, 1, 1)
    end
    -- inner glow diamond
    love.graphics.setColor(shadeColor(self.color, 1.8))
    for r = 0, 5 do
        local w = 10 - r * 2
        if w > 0 then
            px(cx - w / 2, cy - 5 + r, w, 1)
            px(cx - w / 2, cy + 5 - r, w, 1)
        end
    end
    -- hot core
    love.graphics.setColor(1, 1, 0.8, 1)
    px(cx - 1, cy - 1, 2, 2)
    love.graphics.setColor(1, 0.4, 0.1, 1)
    px(cx, cy, 1, 1)
    -- orbiting sparks
    for i = 0, 2 do
        local a = self.spinT * 3 + i * (math.pi * 2 / 3)
        local sx, sy = cx + math.cos(a) * 11, cy + math.sin(a) * 11
        love.graphics.setColor(1, 1, 0.6, 1)
        px(sx, sy, 1, 1)
        love.graphics.setColor(1, 0.7, 0.3, 0.5)
        px(sx + math.cos(a) * 1, sy + math.sin(a) * 1, 1, 1)
    end
end

-- root (final boss): wide menacing skull-block
function sprites.root(self)
    setBodyColor(self)
    px(self.x + 2, self.y + 2, self.w - 4, self.h - 4)
    -- shadow
    love.graphics.setColor(shadeColor(self.color, 0.4))
    px(self.x + 2, self.y + self.h - 4, self.w - 4, 2)
    px(self.x + self.w - 4, self.y + 2, 2, self.h - 4)
    -- circuit details
    love.graphics.setColor(shadeColor(self.color, 1.6))
    for i = 0, 3 do
        px(self.x + 4 + i * 6, self.y + 4, 4, 1)
        px(self.x + 4 + i * 6, self.y + self.h - 5, 4, 1)
    end
    -- glowing eyes
    love.graphics.setColor(0, 0, 0, 1)
    px(self.x + 5, self.y + 8, 6, 4)
    px(self.x + self.w - 11, self.y + 8, 6, 4)
    love.graphics.setColor(1, 0.2, 0.4, 1)
    local pulse = math.floor(self.bobT) % 2
    px(self.x + 7 - pulse, self.y + 9, 2, 2)
    px(self.x + self.w - 9 - pulse, self.y + 9, 2, 2)
    -- jagged mouth
    love.graphics.setColor(0, 0, 0, 1)
    px(self.x + 6, self.y + self.h - 9, self.w - 12, 3)
    love.graphics.setColor(1, 1, 1, 1)
    for i = 0, 4 do
        px(self.x + 7 + i * 4, self.y + self.h - 9, 2, 1)
        px(self.x + 9 + i * 4, self.y + self.h - 7, 2, 1)
    end
end

function Enemy:draw()
    local draw = sprites[self.arch] or sprites.bit
    draw(self)

    if self.maxHp > 3 then
        local bw = self.w
        love.graphics.setColor(0, 0, 0, 1)
        px(self.x, self.y - 3, bw, 1)
        love.graphics.setColor(1, 0.3, 0.3, 1)
        px(self.x, self.y - 3, bw * (self.hp / self.maxHp), 1)
    end
end

Enemy.archetypes = archetypes
return Enemy
