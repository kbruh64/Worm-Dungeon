local Worm = require("src.entities.worm")
local Enemy = require("src.entities.enemy")
local Progress = require("src.progress")
local Weapons = require("src.weapons")
local FX = require("src.fx")
local Room = require("src.dungeons.room")

local Game = {}

local worm
local enemies, projectiles
local room
local input
local banner, bannerTimer
local clearTimer
local camX, camY = 0, 0
local LIGHT_RADIUS = 66

local function updateCamera()
    if not worm or not room then return end
    local tx = worm:centerX() - GAME_W / 2
    local ty = worm:centerY() - GAME_H / 2
    tx = math.max(0, math.min(room.ROOM_W - GAME_W, tx))
    ty = math.max(0, math.min(room.ROOM_H - GAME_H, ty))
    camX, camY = math.floor(tx), math.floor(ty)
end

local function fits(x, y, w, h)
    if not room then return true end
    for _, o in ipairs(room.obstacles) do
        if not (x + w <= o.x or o.x + o.w <= x or y + h <= o.y or o.y + o.h <= y) then
            return false
        end
    end
    return true
end

local currentWave, totalWaves, waveDelay

local function spawnWave()
    local d = Progress.dungeon()
    local x1, y1, x2, y2 = room:bounds()
    local arch = d.archetype
    if d.boss and Progress.isFinal() then arch = "root"
    elseif d.boss then arch = "kernel" end

    -- enemies per wave: split the dungeon total across waves, ramping up slightly
    local perWave = math.max(1, math.ceil(d.enemyCount / totalWaves))
    if d.boss then perWave = (currentWave == totalWaves) and 1 or perWave end

    for _ = 1, perWave do
        local tries, ex, ey = 0, nil, nil
        repeat
            tries = tries + 1
            ex = x1 + 16 + math.random(0, math.floor((x2 - x1 - 48) / 8)) * 8
            ey = y1 + 12 + math.random(0, math.floor((y2 - y1 - 36) / 8)) * 8
        until (fits(ex, ey, 18, 18) and (not worm or math.abs(ex - worm.x) > 40 or math.abs(ey - worm.y) > 40)) or tries > 40
        table.insert(enemies, Enemy.new(ex, ey, arch, d.enemyHp))
        FX.spark(ex + 9, ey + 9, d.palette.accent, 8, 80, 0.4)
    end
end

local function spawnDungeon()
    local d = Progress.dungeon()
    room = Room.new(d, Progress.currentDungeon * 1009 + 17)
    enemies, projectiles = {}, {}
    if d.boss then
        totalWaves = 1
    else
        totalWaves = 2 + math.floor(Progress.currentDungeon / 8) -- 2..5 waves
    end
    currentWave = 1
    waveDelay = nil
    spawnWave()
    banner = d.name
    bannerTimer = 2.0
end

function Game:enter()
    local baseMax = 6 + Progress.maxHpBonus
    if not worm or worm.hp <= 0 or Progress.currentDungeon == 1 then
        worm = Worm.new(0, 0)
    end
    worm.maxHp = baseMax
    if Progress.consumeHealRequest() then worm.hp = worm.maxHp end
    worm.hp = math.min(worm.hp, worm.maxHp)
    if worm.hp < worm.maxHp then worm.hp = math.min(worm.maxHp, worm.hp + 1) end
    input = {}
    clearTimer = nil
    FX.reset()
    spawnDungeon()
    local sx, sy = room:spawnPoint()
    worm.x, worm.y = sx - worm.w / 2, sy - worm.h / 2
    for i = 1, #worm.trail do worm.trail[i] = { x = sx, y = sy, t = 0 } end
    updateCamera()
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
    room:update(dt)

    readInput()
    local mgx, mgy = MouseGame()
    worm:aimAt(mgx + camX, mgy + camY)
    local prevX, prevY = worm.x, worm.y
    worm:update(dt, input, Progress.speedBonus)
    worm.x, worm.y = room:resolveCollision(worm.x, worm.y, worm.w, worm.h, prevX, prevY)
    updateCamera()

    local hb = worm:hitbox()
    for _, e in ipairs(enemies) do
        local epx, epy = e.x, e.y
        e:update(dt, worm,
            function(ne) table.insert(enemies, ne) end,
            function(p) table.insert(projectiles, p) end,
            enemies)
        if e.jumpState ~= "air" then
            e.x, e.y = room:resolveCollision(e.x, e.y, e.w, e.h, epx, epy)
        end
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

    -- wave progression
    if #enemies == 0 and not room.exitOpen then
        if currentWave < totalWaves then
            if not waveDelay then
                waveDelay = 1.2
            else
                waveDelay = waveDelay - dt
                if waveDelay <= 0 then
                    currentWave = currentWave + 1
                    waveDelay = nil
                    spawnWave()
                    banner = "WAVE " .. currentWave .. " / " .. totalWaves
                    bannerTimer = 1.4
                    FX.shakeFor(0.2, 1.5)
                end
            end
        else
            room.exitOpen = true
            banner = "CLEARED - HEAD TO EXIT"
            bannerTimer = 1.6
            FX.flashFor(0.15, 0.4, 1, 0.6)
        end
    end
    if room.exitOpen and room:exitHit(worm.x, worm.y, worm.w, worm.h) then
        SM:switch("reward")
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
    if not room.exitOpen and totalWaves > 1 then
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print(string.format("WAVE %d/%d", currentWave, totalWaves), GAME_W - 62, 12)
    end

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
    love.graphics.clear(0, 0, 0, 1)

    local sxk, syk = FX.shakeOffset()
    love.graphics.push()
    love.graphics.translate(math.floor(-camX + sxk), math.floor(-camY + syk))

    room:drawFloor()
    room:drawFrame()
    room:drawObstacles()
    room:drawExit()

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

    love.graphics.pop()

    -- darkness: stencil a circular vision hole around the worm in screen space
    local pcx = math.floor(worm:centerX() - camX + sxk)
    local pcy = math.floor(worm:centerY() - camY + syk)
    love.graphics.stencil(function()
        love.graphics.circle("fill", pcx, pcy, LIGHT_RADIUS)
    end, "replace", 1)
    love.graphics.setStencilTest("notequal", 1)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, GAME_W, GAME_H)
    love.graphics.setStencilTest()
    -- soft edge: thin dark ring just inside the vision boundary
    for i = 0, 5 do
        love.graphics.setColor(0, 0, 0, 0.12)
        love.graphics.circle("line", pcx, pcy, LIGHT_RADIUS - i)
    end

    FX.drawOverlay()

    -- crosshair in screen-space (over the darkness so it's always visible)
    local mgx, mgy = MouseGame()
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("fill", math.floor(mgx) - 2, math.floor(mgy), 5, 1)
    love.graphics.rectangle("fill", math.floor(mgx), math.floor(mgy) - 2, 1, 5)

    drawHud()

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
