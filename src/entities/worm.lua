local Weapons = require("src.weapons")
local FX = require("src.fx")

local Worm = {}
Worm.__index = Worm

local SPEED = 70
local DASH_SPEED = 220
local DASH_TIME = 0.18
local INVULN_TIME = 0.5
local COMBO_WINDOW = 0.6

function Worm.new(x, y)
    return setmetatable({
        x = x, y = y, w = 10, h = 8,
        dir = 1,                 -- -1 left, +1 right (mouse-based)
        aimAngle = 0,
        hp = 6, maxHp = 6,
        attack = nil,            -- current weapon name being executed
        attackTimer = 0,
        comboCount = 0,
        comboTimer = 0,
        dashTimer = 0,
        invuln = 0,
        segments = {},
        kills = 0,
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
    if self.attack then return end
    local def = Weapons.get(name)
    if not def then return end
    self.attack = name
    self.attackTimer = def.dur
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

function Worm:update(dt, input)
    self.attackTimer = math.max(0, self.attackTimer - dt)
    if self.attackTimer == 0 then self.attack = nil end
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

    local speed = SPEED
    if self.dashTimer > 0 then
        speed = DASH_SPEED
        mx = math.cos(self.aimAngle)
        my = math.sin(self.aimAngle)
    end
    if self.attack then speed = speed * 0.3 end

    self.x = self.x + mx * speed * dt
    self.y = self.y + my * speed * dt
    self.x = math.max(8, math.min(GAME_W - 8 - self.w, self.x))
    self.y = math.max(24, math.min(GAME_H - 8 - self.h, self.y))

    table.insert(self.segments, 1, { x = self.x, y = self.y })
    while #self.segments > 6 do table.remove(self.segments) end
end

function Worm:draw()
    for i = #self.segments, 1, -1 do
        local s = self.segments[i]
        local a = 1 - (i / (#self.segments + 1))
        love.graphics.setColor(0.2 + a * 0.3, 0.7 + a * 0.3, 0.2 + a * 0.3, 0.6)
        love.graphics.rectangle("fill", math.floor(s.x), math.floor(s.y + 1), self.w - i, self.h - 2)
    end

    local flicker = (self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 0)
    if not flicker then
        love.graphics.setColor(0.3, 1, 0.3, 1)
        love.graphics.rectangle("fill", math.floor(self.x), math.floor(self.y), self.w, self.h)
        love.graphics.setColor(0, 0, 0, 1)
        local ex = self.dir > 0 and (self.x + self.w - 3) or (self.x + 1)
        love.graphics.rectangle("fill", math.floor(ex), math.floor(self.y + 2), 2, 2)
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
            local ex = cx + math.cos(self.aimAngle) * def.reach
            local ey = cy + math.sin(self.aimAngle) * def.reach
            love.graphics.setLineWidth(3)
            love.graphics.line(cx, cy, ex, ey)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.setLineWidth(1)
            love.graphics.line(cx, cy, ex, ey)
        else
            -- angled slash arc along aim
            local cx, cy = self:centerX(), self:centerY()
            local ax = math.cos(self.aimAngle)
            local ay = math.sin(self.aimAngle)
            local px2 = -ay
            local py2 = ax
            local reach = def.reach
            for i = 0, reach, 2 do
                local t = i / reach
                local off = math.sin(t * math.pi) * 6 * (1 - prog * 0.5)
                local x = cx + ax * i + px2 * off
                local y = cy + ay * i + py2 * off
                love.graphics.rectangle("fill", math.floor(x), math.floor(y), 2, 2)
            end
            love.graphics.setColor(1, 1, 1, alpha * 0.7)
            for i = 0, reach, 4 do
                local t = i / reach
                local off = math.sin(t * math.pi) * 6 * (1 - prog * 0.5)
                local x = cx + ax * i + px2 * off
                local y = cy + ay * i + py2 * off
                love.graphics.rectangle("fill", math.floor(x), math.floor(y), 1, 1)
            end
        end
    end
end

return Worm
