local Weapons = require("src.weapons")

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
end

function Worm:dash()
    if self.dashTimer > 0 or self.attack then return end
    self.dashTimer = DASH_TIME
    self.invuln = math.max(self.invuln, DASH_TIME)
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
        love.graphics.setColor(def.color[1], def.color[2], def.color[3], 0.85)
        if hb.shape == "radial" then
            love.graphics.circle("fill", hb.cx, hb.cy, hb.radius)
        else
            love.graphics.rectangle("fill", hb.x, hb.y, hb.w, hb.h)
        end
    end
end

return Worm
