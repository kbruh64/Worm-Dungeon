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

-- bit: tiny 6x6 diamond with eye
function sprites.bit(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    local bob = math.sin(self.bobT) * 0.5
    setBodyColor(self)
    px(cx - 3, cy - 1 + bob, 6, 2)
    px(cx - 2, cy - 2 + bob, 4, 1)
    px(cx - 2, cy + 1 + bob, 4, 1)
    px(cx - 1, cy - 3 + bob, 2, 1)
    px(cx - 1, cy + 2 + bob, 2, 1)
    love.graphics.setColor(0, 0, 0, 1)
    px(cx - 1, cy + bob, 1, 1)
end

-- byte: square robot with antenna + two eyes
function sprites.byte(self)
    setBodyColor(self)
    px(self.x + 1, self.y + 2, self.w - 2, self.h - 3)
    -- antenna
    px(self.x + self.w / 2, self.y, 1, 2)
    love.graphics.setColor(1, 1, 0.4, 1)
    px(self.x + self.w / 2, self.y - 1, 1, 1)
    -- shadow side
    love.graphics.setColor(shadeColor(self.color, 0.5))
    px(self.x + self.w - 2, self.y + 2, 1, self.h - 3)
    px(self.x + 1, self.y + self.h - 2, self.w - 2, 1)
    -- eyes
    love.graphics.setColor(0, 0, 0, 1)
    px(self.x + 3, self.y + 5, 2, 2)
    px(self.x + self.w - 5, self.y + 5, 2, 2)
    love.graphics.setColor(0.4, 1, 1, 1)
    px(self.x + 3, self.y + 5, 1, 1)
    px(self.x + self.w - 5, self.y + 5, 1, 1)
    -- mouth
    love.graphics.setColor(0, 0, 0, 1)
    px(self.x + 4, self.y + 9, self.w - 8, 1)
end

-- packet: chevron arrow, leaning toward direction
function sprites.packet(self)
    setBodyColor(self)
    local x, y = self.x, self.y
    px(x + 0, y + 2, 2, 4)
    px(x + 2, y + 1, 2, 6)
    px(x + 4, y + 0, 2, 8)
    px(x + 6, y + 1, 2, 6)
    px(x + 8, y + 2, 2, 4)
    -- highlight
    love.graphics.setColor(1, 1, 1, 0.7)
    px(x + 4, y + 1, 2, 1)
end

-- daemon: floating eye with horns
function sprites.daemon(self)
    local bob = math.sin(self.bobT) * 1
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2 + bob
    setBodyColor(self)
    -- horns
    px(self.x + 2, self.y + bob, 2, 3)
    px(self.x + self.w - 4, self.y + bob, 2, 3)
    -- body diamond
    px(cx - 5, cy - 1, 10, 3)
    px(cx - 4, cy - 3, 8, 2)
    px(cx - 4, cy + 2, 8, 2)
    px(cx - 3, cy - 4, 6, 1)
    px(cx - 3, cy + 4, 6, 1)
    -- iris
    love.graphics.setColor(1, 1, 1, 1)
    px(cx - 2, cy - 1, 4, 3)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    px(cx - 1, cy, 2, 2)
    love.graphics.setColor(0, 0, 0, 1)
    px(cx, cy, 1, 1)
end

-- firewall: brick wall with flames
function sprites.firewall(self)
    setBodyColor(self)
    px(self.x, self.y + 4, self.w, self.h - 4)
    love.graphics.setColor(shadeColor(self.color, 0.6))
    for r = 0, 2 do
        for c = 0, 3 do
            local bx = self.x + c * 5 + (r % 2 == 0 and 0 or 2)
            local by = self.y + 4 + r * 5
            px(bx, by, 4, 1) -- mortar lines
        end
    end
    -- flames on top
    love.graphics.setColor(1, 0.8, 0.2, 1)
    local flick = math.floor(self.bobT * 2) % 2
    for i = 0, 4 do
        local fx = self.x + i * 4
        px(fx + 1, self.y + 1 + flick, 2, 3)
        px(fx + 2, self.y + flick, 1, 1)
    end
    love.graphics.setColor(1, 0.3, 0.1, 1)
    for i = 0, 4 do
        local fx = self.x + i * 4
        px(fx + 1, self.y + 3 + flick, 2, 1)
    end
    -- angry eyes
    love.graphics.setColor(0, 0, 0, 1)
    px(self.x + 4, self.y + 9, 2, 2)
    px(self.x + self.w - 6, self.y + 9, 2, 2)
end

-- virus: spiky blob
function sprites.virus(self)
    setBodyColor(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    -- main body
    px(cx - 4, cy - 3, 8, 6)
    px(cx - 3, cy - 4, 6, 1)
    px(cx - 3, cy + 3, 6, 1)
    -- spikes (rotating)
    local s = math.floor(self.spinT * 4) % 4
    local spikes = {{0,-6},{6,0},{0,6},{-6,0},{4,-4},{4,4},{-4,4},{-4,-4}}
    for i, sp in ipairs(spikes) do
        if (i + s) % 2 == 0 then
            px(cx + sp[1], cy + sp[2], 1, 1)
            px(cx + sp[1] * 0.7, cy + sp[2] * 0.7, 1, 1)
        end
    end
    -- nucleus
    love.graphics.setColor(0, 0, 0, 1)
    px(cx - 1, cy - 1, 2, 2)
end

-- kernel: layered diamond core
function sprites.kernel(self)
    local cx, cy = self.x + self.w / 2, self.y + self.h / 2
    setBodyColor(self)
    -- outer diamond
    for r = 0, 8 do
        local w = 18 - r * 2
        if w > 0 then
            px(cx - w / 2, cy - 8 + r, w, 1)
            px(cx - w / 2, cy + 8 - r, w, 1)
        end
    end
    -- inner glow
    love.graphics.setColor(shadeColor(self.color, 1.5))
    for r = 0, 4 do
        local w = 10 - r * 2
        if w > 0 then
            px(cx - w / 2, cy - 4 + r, w, 1)
            px(cx - w / 2, cy + 4 - r, w, 1)
        end
    end
    -- core
    love.graphics.setColor(1, 1, 1, 1)
    px(cx - 1, cy - 1, 2, 2)
    love.graphics.setColor(1, 0.4, 0.2, 1)
    px(cx, cy, 1, 1)
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
