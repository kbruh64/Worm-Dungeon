local FX = require("src.fx")

local Enemy = {}
Enemy.__index = Enemy

-- hpMul scales the dungeon's base HP; ability marks special behavior.
local archetypes = {
    bit      = { w = 8,  h = 8,  speed = 32, hpMul = 1.5, color = {1, 0.4, 0.4}, contact = 6 },
    byte     = { w = 12, h = 12, speed = 42, hpMul = 2.5, color = {1, 0.6, 0.3}, contact = 8, ability = "dash" },
    packet   = { w = 12, h = 8,  speed = 70, hpMul = 2,   color = {0.5, 0.9, 1}, contact = 7, ability = "dash" },
    daemon   = { w = 14, h = 14, speed = 22, hpMul = 2.5, color = {0.8, 0.4, 1}, contact = 8, ranged = true, ability = "burst" },
    firewall = { w = 18, h = 18, speed = 26, hpMul = 4,   color = {1, 0.5, 0.2}, contact = 10, ability = "shield" },
    virus    = { w = 12, h = 12, speed = 48, hpMul = 3,   color = {0.4, 1, 0.6}, contact = 8, splits = true, ability = "heal" },
    kernel   = { w = 20, h = 20, speed = 34, hpMul = 4.5, color = {1, 0.9, 0.5}, contact = 14, ability = "jump" },
    root     = { w = 32, h = 28, speed = 46, hpMul = 6,   color = {1, 0.3, 0.6}, contact = 18, ability = "boss" },
}

function Enemy.new(x, y, arch, hpScale)
    local a = archetypes[arch] or archetypes.bit
    local hp = math.ceil((hpScale or 2) * (a.hpMul or 1))
    return setmetatable({
        x = x, y = y, w = a.w, h = a.h,
        speed = a.speed, hp = hp, maxHp = hp,
        color = a.color, contact = a.contact,
        arch = arch, ranged = a.ranged, splits = a.splits,
        ability = a.ability,
        hitFlash = 0, dead = false,
        fireTimer = math.random() * 2,
        bobT = math.random() * 6.28,
        spinT = 0,
        -- ability state
        abilityCd = 3 + math.random() * 2.5,
        shieldTimer = 0,
        dashTimer = 0, dvx = 0, dvy = 0,
        jumpState = nil, jumpTimer = 0, jx = 0, jy = 0,
        healGlow = 0,
        sinceHit = 99,
        hurtCd = 0,
        kbX = 0, kbY = 0,
        poisonTime = 0, poisonDmg = 0, poisonTick = 0,
    }, Enemy)
end

function Enemy:applyKnockback(fromX, fromY, force)
    local dx, dy = cx(self) - fromX, cy(self) - fromY
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.1 then dx, dy, d = 1, 0, 1 end
    self.kbX = self.kbX + (dx / d) * force
    self.kbY = self.kbY + (dy / d) * force
end

function Enemy:applyPoison(dmg, time)
    self.poisonDmg = dmg
    self.poisonTime = time
    self.poisonTick = 0
end

function Enemy:rect() return self.x, self.y, self.w, self.h end

local function cx(self) return self.x + self.w / 2 end
local function cy(self) return self.y + self.h / 2 end

function Enemy:damage(n)
    if self.hurtCd > 0 then return false end
    self.hurtCd = 0.25
    self.sinceHit = 0
    if self.shieldTimer > 0 then
        -- shield absorbs: chip it instead of taking full damage
        self.hitFlash = 0.12
        FX.spark(cx(self), cy(self), {0.5, 0.8, 1}, 5, 50, 0.25)
        self.shieldTimer = self.shieldTimer - 0.4
        return false
    end
    self.hp = self.hp - n
    self.hitFlash = 0.12
    FX.spark(cx(self), cy(self), self.color, 6, 60, 0.3)
    FX.spark(cx(self), cy(self), {1, 1, 1}, 3, 100, 0.2)
    if self.hp <= 0 then
        self.dead = true
        FX.spark(cx(self), cy(self), self.color, 16, 120, 0.5)
        FX.spark(cx(self), cy(self), {1, 1, 1}, 6, 140, 0.3)
        FX.shakeFor(0.18, 1.5)
    end
    return true
end

-- ability handlers return true if they took over movement this frame
local function abilityDash(self, dt, worm, dx, dy, d)
    if self.dashTimer > 0 then
        self.dashTimer = self.dashTimer - dt
        self.x = self.x + self.dvx * dt
        self.y = self.y + self.dvy * dt
        FX.streak(cx(self), cy(self), -self.dvx * 0.1, -self.dvy * 0.1, self.color, 2)
        return true
    end
    if self.abilityCd <= 0 and d < 90 and d > 0.1 then
        self.dashTimer = 0.35
        self.dvx = (dx / d) * self.speed * 4
        self.dvy = (dy / d) * self.speed * 4
        self.abilityCd = 2.5 + math.random() * 1.5
        FX.spark(cx(self), cy(self), self.color, 6, 70, 0.3)
        return true
    end
    return false
end

local function abilityShield(self)
    if self.abilityCd <= 0 and self.shieldTimer <= 0 then
        self.shieldTimer = 3.0
        self.abilityCd = 6.0
        FX.ring(cx(self), cy(self), {0.5, 0.8, 1}, 12, 12)
    end
end

local function abilityHeal(self, dt, enemies)
    if self.abilityCd <= 0 then
        self.abilityCd = 5.0
        self.healGlow = 0.8
        -- heal self and nearby allies
        local function heal(e)
            if not e.dead and e.hp < e.maxHp then
                e.hp = math.min(e.maxHp, e.hp + math.ceil(e.maxHp * 0.25))
                FX.spark(e.x + e.w / 2, e.y + e.h / 2, {0.4, 1, 0.5}, 6, 50, 0.4)
            end
        end
        heal(self)
        if enemies then
            for _, e in ipairs(enemies) do
                if e ~= self then
                    local ddx, ddy = e.x - self.x, e.y - self.y
                    if ddx * ddx + ddy * ddy < 60 * 60 then heal(e) end
                end
            end
        end
    end
    if self.healGlow > 0 then self.healGlow = self.healGlow - dt end
end

local function abilityJump(self, dt, worm, d)
    if self.jumpState == "telegraph" then
        self.jumpTimer = self.jumpTimer - dt
        if self.jumpTimer <= 0 then
            self.jumpState = "air"
            self.jumpTimer = 0.4
            self.jx, self.jy = worm.x, worm.y -- leap target
        end
        return true
    elseif self.jumpState == "air" then
        self.jumpTimer = self.jumpTimer - dt
        local tx, ty = self.jx - self.x, self.jy - self.y
        self.x = self.x + tx * dt * 6
        self.y = self.y + ty * dt * 6
        if self.jumpTimer <= 0 then
            self.jumpState = nil
            FX.ring(cx(self), cy(self), self.color, 16, 18)
            FX.shakeFor(0.25, 2.5)
            -- slam shockwave: hurt worm if close on landing
            local wdx, wdy = worm:centerX() - cx(self), worm:centerY() - cy(self)
            if wdx * wdx + wdy * wdy < 24 * 24 then worm:damage(self.contact) end
        end
        return true
    end
    if self.abilityCd <= 0 and d < 120 then
        self.jumpState = "telegraph"
        self.jumpTimer = 0.5
        self.abilityCd = 4.0
        return true
    end
    return false
end

local function abilityBlink(self, dt, worm, d)
    if self.abilityCd <= 0 and d < 50 then
        -- teleport away from worm
        local a = math.random() * math.pi * 2
        FX.ring(cx(self), cy(self), self.color, 10, 10)
        self.x = self.x + math.cos(a) * 70
        self.y = self.y + math.sin(a) * 70
        self.abilityCd = 3.5
        FX.ring(cx(self), cy(self), self.color, 10, 10)
    end
end

local function abilityBurst(self, dt, worm, addProjectile)
    if self.abilityCd <= 0 then
        self.abilityCd = 5.0
        FX.ring(cx(self), cy(self), self.color, 12, 10)
        FX.shakeFor(0.1, 1)
        local n = 6
        for i = 0, n - 1 do
            local a = (i / n) * math.pi * 2
            addProjectile({
                x = cx(self), y = cy(self),
                vx = math.cos(a) * 48, vy = math.sin(a) * 48,
                life = 2.2, damage = 5, color = self.color,
            })
        end
    end
end

local function abilitySummon(self, dt, addEnemy, enemies)
    if self.abilityCd <= 0 and enemies and #enemies < 14 then
        self.abilityCd = 5.0
        FX.ring(cx(self), cy(self), {1, 1, 1}, 12, 12)
        for i = 1, 2 do
            local a = math.random() * math.pi * 2
            local minion = Enemy.new(cx(self) + math.cos(a) * 16, cy(self) + math.sin(a) * 16, "bit", 1)
            addEnemy(minion)
            FX.spark(minion.x, minion.y, minion.color, 6, 60, 0.3)
        end
    end
end

function Enemy:update(dt, worm, addEnemy, addProjectile, enemies)
    self.hitFlash = math.max(0, self.hitFlash - dt)
    self.bobT = self.bobT + dt * 4
    self.spinT = self.spinT + dt
    self.abilityCd = self.abilityCd - dt
    self.shieldTimer = math.max(0, self.shieldTimer - dt)
    self.sinceHit = self.sinceHit + dt
    self.hurtCd = math.max(0, self.hurtCd - dt)

    -- knockback impulse (decays quickly)
    if self.kbX ~= 0 or self.kbY ~= 0 then
        self.x = self.x + self.kbX * dt
        self.y = self.y + self.kbY * dt
        self.kbX = self.kbX * 0.82
        self.kbY = self.kbY * 0.82
        if math.abs(self.kbX) < 2 and math.abs(self.kbY) < 2 then self.kbX, self.kbY = 0, 0 end
    end

    -- poison damage-over-time (ticks ~3x/sec, ignores hurt cooldown)
    if self.poisonTime > 0 then
        self.poisonTime = self.poisonTime - dt
        self.poisonTick = self.poisonTick - dt
        if self.poisonTick <= 0 then
            self.poisonTick = 0.33
            self.hp = self.hp - self.poisonDmg
            FX.spark(cx(self), cy(self), {0.4, 1, 0.3}, 3, 30, 0.3)
            if self.hp <= 0 and not self.dead then
                self.dead = true
                FX.spark(cx(self), cy(self), {0.4, 1, 0.3}, 14, 110, 0.5)
            end
        end
    end

    -- RAGE passive: below 35% HP, move faster and act more often
    self.raging = self.hp / self.maxHp < 0.35
    local speed = self.speed
    if self.raging then speed = speed * 1.35; self.abilityCd = self.abilityCd - dt * 0.25 end

    local dx = worm.x - self.x
    local dy = worm.y - self.y
    local d = math.sqrt(dx * dx + dy * dy)

    -- abilities (some override movement)
    local handled = false
    local ab = self.ability
    if ab == "boss" then
        if not self._bossPick or self.abilityCd <= 0 then
            self._bossPick = ({ "dash", "jump", "burst", "summon", "shield" })[math.random(1, 5)]
        end
        ab = self._bossPick
    end

    if ab == "dash" then handled = abilityDash(self, dt, worm, dx, dy, d)
    elseif ab == "shield" then abilityShield(self)
    elseif ab == "heal" then abilityHeal(self, dt, enemies)
    elseif ab == "jump" then handled = abilityJump(self, dt, worm, d)
    elseif ab == "blink" then abilityBlink(self, dt, worm, d)
    elseif ab == "burst" then abilityBurst(self, dt, worm, addProjectile)
    elseif ab == "summon" then abilitySummon(self, dt, addEnemy, enemies) end

    if not handled then
        if self.ranged then
            if d > 60 then
                self.x = self.x + (dx / d) * speed * dt
                self.y = self.y + (dy / d) * speed * dt
            end
            self.fireTimer = self.fireTimer - dt
            if self.fireTimer <= 0 then
                self.fireTimer = 2.4
                addProjectile({
                    x = cx(self), y = cy(self),
                    vx = (dx / d) * 65, vy = (dy / d) * 65,
                    life = 3, damage = 6, color = self.color,
                })
            end
        elseif d > 0.1 then
            self.x = self.x + (dx / d) * speed * dt
            self.y = self.y + (dy / d) * speed * dt
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
    elseif self.poisonTime and self.poisonTime > 0 then
        local p = 0.6 + 0.4 * math.sin(self.spinT * 10)
        love.graphics.setColor(self.color[1] * 0.5, self.color[2] * 0.6 + 0.4 * p, self.color[3] * 0.5, 1)
    elseif self.raging then
        -- pulsing red-hot tint when enraged
        local p = 0.5 + 0.5 * math.sin(self.spinT * 12)
        love.graphics.setColor(
            math.min(1, self.color[1] + 0.4 * p),
            self.color[2] * (0.6 - 0.2 * p),
            self.color[3] * (0.6 - 0.2 * p), 1)
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
    -- jump telegraph: shadow grows / warning ring on ground
    if self.jumpState == "telegraph" then
        love.graphics.setColor(1, 0.2, 0.2, 0.4 + 0.4 * math.sin(self.bobT * 6))
        love.graphics.circle("line", cx(self), cy(self) + self.h / 2, 8)
    end

    local draw = sprites[self.arch] or sprites.bit
    draw(self)

    -- heal glow
    if self.healGlow and self.healGlow > 0 then
        love.graphics.setColor(0.4, 1, 0.5, self.healGlow * 0.6)
        love.graphics.circle("line", cx(self), cy(self), self.w)
        love.graphics.setColor(0.4, 1, 0.5, 1)
        px(cx(self) - 2, cy(self) - 5, 1, 3)
        px(cx(self) - 3, cy(self) - 4, 3, 1)
    end

    -- shield bubble
    if self.shieldTimer > 0 then
        local a = 0.3 + 0.3 * math.sin(self.spinT * 8)
        love.graphics.setColor(0.5, 0.8, 1, a + 0.3)
        love.graphics.circle("line", cx(self), cy(self), self.w * 0.8 + 2)
        love.graphics.setColor(0.7, 0.9, 1, a)
        love.graphics.circle("line", cx(self), cy(self), self.w * 0.8 + 1)
    end

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
