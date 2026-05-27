local Enemy = {}
Enemy.__index = Enemy

local archetypes = {
    bit      = { w = 8,  h = 8,  speed = 30, hp = 1, color = {1, 0.4, 0.4}, contact = 1 },
    byte     = { w = 12, h = 10, speed = 40, hp = 2, color = {1, 0.6, 0.3}, contact = 1 },
    packet   = { w = 10, h = 6,  speed = 80, hp = 1, color = {0.5, 0.9, 1}, contact = 1 },
    daemon   = { w = 12, h = 12, speed = 20, hp = 2, color = {0.8, 0.4, 1}, contact = 1, ranged = true },
    firewall = { w = 16, h = 16, speed = 25, hp = 5, color = {1, 0.5, 0.2}, contact = 2 },
    virus    = { w = 10, h = 10, speed = 50, hp = 2, color = {0.4, 1, 0.6}, contact = 1, splits = true },
    kernel   = { w = 18, h = 18, speed = 35, hp = 6, color = {0.9, 0.9, 0.5}, contact = 2 },
    root     = { w = 24, h = 20, speed = 45, hp = 10, color = {1, 0.3, 0.6}, contact = 2 },
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
        projectiles = {},
    }, Enemy)
end

function Enemy:rect() return self.x, self.y, self.w, self.h end

function Enemy:damage(n)
    self.hp = self.hp - n
    self.hitFlash = 0.1
    if self.hp <= 0 then self.dead = true end
end

function Enemy:update(dt, worm, addEnemy, addProjectile)
    self.hitFlash = math.max(0, self.hitFlash - dt)

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
                self.fireTimer = 1.5
                addProjectile({
                    x = self.x + self.w / 2, y = self.y + self.h / 2,
                    vx = (dx / d) * 60, vy = (dy / d) * 60,
                    life = 3, damage = 1,
                })
            end
        else
            self.x = self.x + (dx / d) * self.speed * dt
            self.y = self.y + (dy / d) * self.speed * dt
        end
    end

    -- contact damage
    if not (worm.x + worm.w < self.x or self.x + self.w < worm.x
         or worm.y + worm.h < self.y or self.y + self.h < worm.y) then
        worm:damage(self.contact)
    end
end

function Enemy:draw()
    if self.hitFlash > 0 then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    end
    love.graphics.rectangle("fill", math.floor(self.x), math.floor(self.y), self.w, self.h)
    -- glyph eye
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", math.floor(self.x + 2), math.floor(self.y + 2), 2, 2)
    love.graphics.rectangle("fill", math.floor(self.x + self.w - 4), math.floor(self.y + 2), 2, 2)

    -- hp bar for tough ones
    if self.maxHp > 3 then
        local bw = self.w
        love.graphics.setColor(0.2, 0.1, 0.1, 1)
        love.graphics.rectangle("fill", self.x, self.y - 3, bw, 1)
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", self.x, self.y - 3, bw * (self.hp / self.maxHp), 1)
    end
end

Enemy.archetypes = archetypes
return Enemy
