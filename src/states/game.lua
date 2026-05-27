local Worm = require("src.entities.worm")
local Enemy = require("src.entities.enemy")
local Progress = require("src.progress")
local Weapons = require("src.weapons")
local FX = require("src.fx")

local Game = {}

local worm
local enemies, projectiles
local input
local banner, bannerTimer
local clearTimer

local function spawnDungeon()
    local d = Progress.dungeon()
    enemies, projectiles = {}, {}
    for _ = 1, d.enemyCount do
        local x = 40 + math.random(0, GAME_W - 80)
        local y = 40 + math.random(0, GAME_H - 80)
        local arch = d.archetype
        if d.boss and Progress.isFinal() then arch = "root"
        elseif d.boss then arch = "kernel" end
        table.insert(enemies, Enemy.new(x, y, arch, d.enemyHp))
    end
    banner = d.name
    bannerTimer = 2.0
end

function Game:enter()
    local baseMax = 6 + Progress.maxHpBonus
    if not worm or worm.hp <= 0 or Progress.currentDungeon == 1 then
        worm = Worm.new(GAME_W / 2, GAME_H / 2)
    end
    worm.maxHp = baseMax
    if Progress.consumeHealRequest() then worm.hp = worm.maxHp end
    worm.hp = math.min(worm.hp, worm.maxHp)
    if worm.hp < worm.maxHp then worm.hp = math.min(worm.maxHp, worm.hp + 1) end
    worm.x, worm.y = GAME_W / 2, GAME_H / 2
    input = {}
    clearTimer = nil
    FX.reset()
    spawnDungeon()
end

local function readInput()
    input.left  = love.keyboard.isDown("a")
    input.right = love.keyboard.isDown("d")
    input.up    = love.keyboard.isDown("w")
    input.down  = love.keyboard.isDown("s")
end

local function rectsOverlap(a, b)
    return not (a.x + a.w < b.x or b.x + b.w < a.x or a.y + a.h < b.y or b.y + b.h < a.y)
end

local function circleHitsRect(cx, cy, r, rx, ry, rw, rh)
    local nx = math.max(rx, math.min(cx, rx + rw))
    local ny = math.max(ry, math.min(cy, ry + rh))
    local dx, dy = cx - nx, cy - ny
    return dx * dx + dy * dy <= r * r
end

function Game:update(dt)
    if bannerTimer then bannerTimer = math.max(0, bannerTimer - dt); if bannerTimer == 0 then bannerTimer = nil end end
    FX.update(dt)

    readInput()
    local mgx, mgy = MouseGame()
    worm:aimAt(mgx, mgy)
    worm:update(dt, input, Progress.speedBonus)

    local hb = worm:hitbox()
    for _, e in ipairs(enemies) do
        e:update(dt, worm,
            function(ne) table.insert(enemies, ne) end,
            function(p) table.insert(projectiles, p) end)
        if hb and not e.dead then
            local hit
            if hb.shape == "radial" then
                hit = circleHitsRect(hb.cx, hb.cy, hb.radius, e.x, e.y, e.w, e.h)
            else
                hit = rectsOverlap(hb, { x = e.x, y = e.y, w = e.w, h = e.h })
            end
            if hit then
                local dmg = hb.damage + Progress.dmgBonus + math.floor(worm.comboCount / 2)
                e:damage(dmg)
                if e.dead and e.splits and e.w > 6 then
                    for _ = 1, 2 do
                        table.insert(enemies, Enemy.new(e.x, e.y, "bit", 1))
                    end
                end
            end
        end
    end

    for i = #projectiles, 1, -1 do
        local p = projectiles[i]
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt; p.life = p.life - dt
        if rectsOverlap({ x = p.x - 2, y = p.y - 2, w = 4, h = 4 },
                        { x = worm.x, y = worm.y, w = worm.w, h = worm.h }) then
            worm:damage(p.damage); table.remove(projectiles, i)
        elseif p.life <= 0 then table.remove(projectiles, i) end
    end

    for i = #enemies, 1, -1 do
        if enemies[i].dead then
            worm.kills = worm.kills + 1
            Progress.kills = Progress.kills + 1
            table.remove(enemies, i)
        end
    end

    if worm.hp <= 0 then Progress.reset(); worm = nil; SM:switch("menu"); return end

    if #enemies == 0 then
        clearTimer = (clearTimer or 0) + dt
        if clearTimer > 1.0 then
            clearTimer = nil
            SM:switch("reward")
        end
    end
end

local function drawHud()
    -- hp pips
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("HP", 4, 4)
    for i = 1, worm.maxHp do
        local x = 18 + (i - 1) * 5
        if i <= worm.hp then
            love.graphics.setColor(0.3, 1, 0.3, 1)
        else
            love.graphics.setColor(1, 1, 1, 0.2)
        end
        love.graphics.rectangle("fill", x, 5, 3, 5)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("D%02d/%02d", Progress.currentDungeon, Progress.total()), GAME_W - 50, 4)

    -- equipped weapon (lower-left, no hotbar)
    local def = Weapons.get(Progress.equipped)
    if def then
        love.graphics.setColor(def.color[1], def.color[2], def.color[3], 1)
        love.graphics.setFont(Fonts.medium)
        love.graphics.print(def.glyph, 4, GAME_H - 18)
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(string.upper(Progress.equipped), 16, GAME_H - 12)
        if #Progress.weapons > 1 then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.print("Q swap", GAME_W - 38, GAME_H - 10)
        end
    end

    if worm.comboCount > 1 then
        love.graphics.setColor(1, 0.6, 0.3, math.min(1, worm.comboTimer * 2))
        love.graphics.setFont(Fonts.medium)
        love.graphics.print("x" .. worm.comboCount, GAME_W - 30, 14)
    end
end

function Game:draw()
    local d = Progress.dungeon()
    local p = d.palette
    love.graphics.clear(p.bg[1], p.bg[2], p.bg[3], 1)

    local sx, sy = FX.shakeOffset()
    love.graphics.push()
    love.graphics.translate(math.floor(sx), math.floor(sy))

    love.graphics.setColor(p.accent[1] * 0.3, p.accent[2] * 0.3, p.accent[3] * 0.3, 0.5)
    for x = 0, GAME_W, 16 do love.graphics.line(x, 16, x, GAME_H - 4) end
    for y = 20, GAME_H - 4, 16 do love.graphics.line(0, y, GAME_W, y) end

    love.graphics.setColor(p.accent[1], p.accent[2], p.accent[3], 1)
    love.graphics.rectangle("line", 2, 14, GAME_W - 4, GAME_H - 18)

    for _, e in ipairs(enemies) do e:draw() end
    for _, pr in ipairs(projectiles) do
        local c = pr.color or {1, 0.5, 1}
        love.graphics.setColor(c[1], c[2], c[3], 1)
        love.graphics.rectangle("fill", math.floor(pr.x) - 2, math.floor(pr.y) - 2, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", math.floor(pr.x) - 1, math.floor(pr.y) - 1, 2, 2)
    end
    worm:draw()
    FX.draw()
    FX.drawOverlay()

    love.graphics.pop()

    drawHud()

    -- crosshair
    local mgx, mgy = MouseGame()
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", math.floor(mgx) - 2, math.floor(mgy), 5, 1)
    love.graphics.rectangle("fill", math.floor(mgx), math.floor(mgy) - 2, 1, 5)

    if bannerTimer then
        love.graphics.setFont(Fonts.medium)
        local a = math.min(1, bannerTimer)
        love.graphics.setColor(0, 0, 0, 0.6 * a)
        love.graphics.rectangle("fill", 0, GAME_H / 2 - 12, GAME_W, 24)
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.printf(banner, 0, GAME_H / 2 - 8, GAME_W, "center")
    end
end

function Game:keypressed(key)
    if key == "escape" then Progress.reset(); worm = nil; SM:switch("menu"); return end
    if key == "space" then worm:dash(); return end
    if key == "q" then Progress.cycleWeapon(1); return end
    if key == "e" then Progress.cycleWeapon(-1); return end
end

function Game:mousepressed(gx, gy, button)
    if button == 1 then
        worm:fireWeapon(Progress.equipped)
    elseif button == 2 then
        worm:dash()
    end
end

function Game:wheelmoved(dx, dy)
    if dy > 0 then Progress.cycleWeapon(-1)
    elseif dy < 0 then Progress.cycleWeapon(1) end
end

return Game
