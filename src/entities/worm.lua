local Weapons = require("src.weapons")
local FX = require("src.fx")

local Worm = {}
Worm.__index = Worm

local SPEED = 88
local DASH_SPEED = 220
local DASH_TIME = 0.18
local INVULN_TIME = 0.7
local COMBO_WINDOW = 0.6

local BODY_LEN = 8        -- visible trailing body pixels
local BODY_SPACING = 0.022 -- seconds of trail history between segments

function Worm.new(x, y)
    local trail = {}
    for i = 1, 64 do trail[i] = { x = x, y = y, t = 0 } end
    return setmetatable({
        x = x, y = y, w = 3, h = 3,
        dir = 1,
        aimAngle = 0,
        hp = 100, maxHp = 100,
        attack = nil,
        attackTimer = 0,
        atkCd = 0,
        comboCount = 0,
        comboTimer = 0,
        dashTimer = 0,
        invuln = 0,
        trail = trail,
        kills = 0,
        time = 0,
    }, Worm)
end

function Worm:centerX() return self.x + self.w / 2 end
function Worm:centerY() return self.y + self.h / 2 end

function Worm:hitbox()
    if not self.attack then return nil end
    local def = Weapons.get(self.attack)
    if not def then return nil end

    if def.shape == "radial" then
        local r = def.reach
        return {
            x = self:centerX() - r, y = self:centerY() - r,
            w = r * 2, h = r * 2,
            damage = def.dmg, type = self.attack, shape = "radial",
            radius = r, cx = self:centerX(), cy = self:centerY(),
        }
    end

    local reach = def.reach
    local hx = self.dir > 0 and (self.x + self.w) or (self.x - reach)
    return {
        x = hx, y = self.y - 2, w = reach, h = self.h + 4,
        damage = def.dmg, type = self.attack, shape = def.shape,
    }
end

function Worm:fireWeapon(name)
    if self.attack or self.atkCd > 0 then return end
    local def = Weapons.get(name)
    if not def then return end
    self.attack = name
    self.attackTimer = def.dur
    self.atkCd = def.dur + (def.cd or 0.25)
    if self.comboTimer > 0 then
        self.comboCount = self.comboCount + 1
    else
        self.comboCount = 1
    end
    self.comboTimer = COMBO_WINDOW

    local cx, cy = self:centerX(), self:centerY()
    local fx = cx + math.cos(self.aimAngle) * 8
    local fy = cy + math.sin(self.aimAngle) * 8

    if def.shape == "radial" then
        FX.ring(cx, cy, def.color, 16, def.reach)
        FX.shakeFor(0.18, 1.5)
    elseif def.shape == "beam" then
        FX.streak(cx, cy, math.cos(self.aimAngle) * 200, math.sin(self.aimAngle) * 200, def.color, 14)
        FX.flashFor(0.06, def.color[1], def.color[2], def.color[3])
        FX.shakeFor(0.12, 1)
    else
        FX.streak(fx, fy, math.cos(self.aimAngle) * 80, math.sin(self.aimAngle) * 80, def.color, 8)
        FX.shakeFor(0.08, 1)
    end
end

function Worm:dash()
    if self.dashTimer > 0 or self.attack then return end
    self.dashTimer = DASH_TIME
    self.invuln = math.max(self.invuln, DASH_TIME)
    FX.dust(self:centerX(), self.y + self.h, {0.6, 1, 0.6}, 6)
end

function Worm:damage(n)
    if self.invuln > 0 then return end
    self.hp = self.hp - n
    self.invuln = INVULN_TIME
end

function Worm:aimAt(gx, gy)
    local dx = gx - self:centerX()
    local dy = gy - self:centerY()
    self.aimAngle = math.atan2(dy, dx)
    self.dir = (dx >= 0) and 1 or -1
end

function Worm:update(dt, input, speedBonus)
    self.time = self.time + dt
    self.attackTimer = math.max(0, self.attackTimer - dt)
    if self.attackTimer == 0 then self.attack = nil end
    self.atkCd = math.max(0, self.atkCd - dt)
    self.comboTimer = math.max(0, self.comboTimer - dt)
    if self.comboTimer == 0 then self.comboCount = 0 end
    self.dashTimer = math.max(0, self.dashTimer - dt)
    self.invuln = math.max(0, self.invuln - dt)

    local mx, my = 0, 0
    if input.left then mx = mx - 1 end
    if input.right then mx = mx + 1 end
    if input.up then my = my - 1 end
    if input.down then my = my + 1 end
    if mx ~= 0 and my ~= 0 then mx, my = mx * 0.707, my * 0.707 end

    local speed = SPEED * (1 + (speedBonus or 0))
    if self.dashTimer > 0 then
        speed = DASH_SPEED
        mx = math.cos(self.aimAngle)
        my = math.sin(self.aimAngle)
    end
    if self.attack then speed = speed * 0.3 end

    self.x = self.x + mx * speed * dt
    self.y = self.y + my * speed * dt

    table.insert(self.trail, 1, { x = self:centerX(), y = self:centerY(), t = self.time })
    while #self.trail > 64 do table.remove(self.trail) end
end

function Worm:draw()
    local flicker = (self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 0)

    -- body: sample trail points at fixed time spacing back from head
    if not flicker then
        for i = BODY_LEN, 1, -1 do
            local targetT = self.time - i * BODY_SPACING
            local pt = self.trail[1]
            for _, p in ipairs(self.trail) do
                if p.t <= targetT then pt = p; break end
            end
            local fade = i / BODY_LEN
            local size = (i <= 2) and 3 or (i <= 5) and 2 or 1
            local g = 0.85 - fade * 0.4
            love.graphics.setColor(0.15, g, 0.2, 1)
            love.graphics.rectangle("fill", math.floor(pt.x - size / 2), math.floor(pt.y - size / 2), size, size)
        end

        -- head: 4x3 with eye pointing at aim
        local hx = math.floor(self:centerX() - 2)
        local hy = math.floor(self:centerY() - 1)
        love.graphics.setColor(0.4, 1, 0.4, 1)
        love.graphics.rectangle("fill", hx, hy, 4, 3)
        love.graphics.setColor(0.25, 0.7, 0.25, 1)
        love.graphics.rectangle("fill", hx, hy + 2, 4, 1)
        love.graphics.setColor(0, 0, 0, 1)
        local ex = (self.dir > 0) and (hx + 3) or hx
        love.graphics.rectangle("fill", ex, hy + 1, 1, 1)
    end

    local hb = self:hitbox()
    if hb then
        local def = Weapons.get(self.attack)
        local prog = 1 - (self.attackTimer / def.dur)
        local alpha = math.sin(prog * math.pi) * 0.9 + 0.1
        love.graphics.setColor(def.color[1], def.color[2], def.color[3], alpha)
        if hb.shape == "radial" then
            local r = hb.radius * (0.4 + prog * 0.6)
            love.graphics.circle("line", hb.cx, hb.cy, r)
            love.graphics.circle("line", hb.cx, hb.cy, r - 2)
            love.graphics.setColor(1, 1, 1, alpha * 0.5)
            love.graphics.circle("line", hb.cx, hb.cy, r - 4)
        elseif hb.shape == "beam" then
            local cx, cy = self:centerX(), self:centerY()
            local len = def.reach * (0.6 + prog * 0.4)  -- beam extends as it fires
            local ex = cx + math.cos(self.aimAngle) * len
            local ey = cy + math.sin(self.aimAngle) * len
            -- outer glow
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], alpha * 0.5)
            love.graphics.setLineWidth(5)
            love.graphics.line(cx, cy, ex, ey)
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], alpha)
            love.graphics.setLineWidth(3)
            love.graphics.line(cx, cy, ex, ey)
            -- white hot core
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setLineWidth(1)
            love.graphics.line(cx, cy, ex, ey)
            -- muzzle flash
            love.graphics.circle("fill", cx, cy, 2 + math.sin(prog * math.pi) * 2)
            love.graphics.setLineWidth(1)
        else
            -- angled slash arc(s) along aim
            local cx, cy = self:centerX(), self:centerY()
            local ax, ay = math.cos(self.aimAngle), math.sin(self.aimAngle)
            local nx, ny = -ay, ax
            local reach = def.reach
            local arcs = def.twin and { 1, -1 } or { 1 }
            for _, side in ipairs(arcs) do
                love.graphics.setColor(def.color[1], def.color[2], def.color[3], alpha)
                for i = 0, reach, 2 do
                    local t = i / reach
                    -- arc sweeps from one side to the other over the swing
                    local sweep = math.sin(t * math.pi) * 8 * side
                    local swing = (prog - 0.5) * 6 * side
                    local off = sweep + swing
                    local x = cx + ax * i + nx * off
                    local y = cy + ay * i + ny * off
                    love.graphics.rectangle("fill", math.floor(x), math.floor(y), 2, 2)
                end
                love.graphics.setColor(1, 1, 1, alpha * 0.8)
                for i = 0, reach, 4 do
                    local t = i / reach
                    local off = math.sin(t * math.pi) * 8 * side + (prog - 0.5) * 6 * side
                    love.graphics.rectangle("fill", math.floor(cx + ax * i + nx * off), math.floor(cy + ay * i + ny * off), 1, 1)
                end
            end
            -- poison weapons leave drifting green motes
            if def.dot and math.random() < 0.6 then
                FX.dust(cx + ax * reach * 0.6, cy + ay * reach * 0.6, {0.4, 1, 0.3}, 1)
            end
        end
    end
end

return Worm
