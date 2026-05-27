local Worm = require("src.entities.worm")
local Enemy = require("src.entities.enemy")
local Progress = require("src.progress")
local Weapons = require("src.weapons")

local Game = {}

local worm
local enemies, projectiles
local input
local banner, bannerTimer
local clearTimer
local inventoryOpen = false
local invCursor = 1
local invDragging = nil  -- weapon name being dragged from inventory

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
    worm = Worm.new(GAME_W / 2, GAME_H / 2)
    input = {}
    inventoryOpen = false
    invDragging = nil
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
    if inventoryOpen then return end

    readInput()
    local mgx, mgy = MouseGame()
    worm:aimAt(mgx, mgy)
    worm:update(dt, input)

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
                local dmg = hb.damage + math.floor(worm.comboCount / 2)
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

    if worm.hp <= 0 then Progress.reset(); SM:switch("menu"); return end

    if #enemies == 0 then
        clearTimer = (clearTimer or 0) + dt
        if clearTimer > 1.2 then
            clearTimer = nil
            local justUnlocked = (Progress.dungeon() or {}).unlock
            local hasMore = Progress.advance()
            if hasMore then
                if justUnlocked then
                    banner = "UNLOCKED: " .. string.upper(justUnlocked)
                    bannerTimer = 2.2
                end
                spawnDungeon()
                worm.hp = math.min(worm.maxHp, worm.hp + 2)
            else
                SM:switch("victory")
            end
        end
    end
end

-- ---------- HUD / hotbar / inventory ----------

local SLOT_SIZE = 18
local HOTBAR_Y = GAME_H - SLOT_SIZE - 4

local function hotbarOrigin()
    local totalW = 9 * SLOT_SIZE
    return math.floor((GAME_W - totalW) / 2), HOTBAR_Y
end

local function drawSlot(x, y, weapon, selected)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE)
    love.graphics.setColor(selected and 1 or 0.4, selected and 1 or 0.4, selected and 1 or 0.4, 1)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, SLOT_SIZE - 1, SLOT_SIZE - 1)
    if selected then
        love.graphics.rectangle("line", x - 0.5, y - 0.5, SLOT_SIZE + 1, SLOT_SIZE + 1)
    end
    if weapon then
        local def = Weapons.get(weapon)
        if def then
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], 1)
            love.graphics.setFont(Fonts.medium)
            local g = def.glyph
            love.graphics.print(g, x + math.floor((SLOT_SIZE - Fonts.medium:getWidth(g)) / 2),
                                   y + math.floor((SLOT_SIZE - Fonts.medium:getHeight()) / 2) - 1)
        end
    end
end

local function drawHotbar()
    local ox, oy = hotbarOrigin()
    for i = 1, 9 do
        drawSlot(ox + (i - 1) * SLOT_SIZE, oy, Progress.hotbar[i], i == Progress.activeSlot)
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(tostring(i), ox + (i - 1) * SLOT_SIZE + 1, oy + 1)
    end
    local active = Progress.activeWeapon()
    if active then
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(string.upper(active), 0, oy - 10, GAME_W, "center")
    end
end

local function drawHud()
    love.graphics.setColor(0.2, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 4, 4, 60, 5)
    love.graphics.setColor(0.3, 1, 0.3, 1)
    love.graphics.rectangle("fill", 4, 4, 60 * (worm.hp / worm.maxHp), 5)

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(0.6, 0.8, 0.6, 1)
    love.graphics.print(string.format("D%02d/%02d", Progress.currentDungeon, Progress.total()), GAME_W - 50, 4)

    if worm.comboCount > 1 then
        love.graphics.setColor(1, 0.6, 0.3, math.min(1, worm.comboTimer * 2))
        love.graphics.setFont(Fonts.medium)
        love.graphics.print("x" .. worm.comboCount, GAME_W - 30, 12)
    end
end

local INV_COLS = 6
local INV_ROWS = 4
local function inventoryGrid()
    local gw = INV_COLS * SLOT_SIZE
    local gh = INV_ROWS * SLOT_SIZE
    local ox = math.floor((GAME_W - gw) / 2)
    local oy = math.floor((GAME_H - gh) / 2) - 8
    return ox, oy, gw, gh
end

local function drawInventory()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, GAME_W, GAME_H)

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(0.7, 1, 0.7, 1)
    love.graphics.printf("INVENTORY", 0, 20, GAME_W, "center")

    local ox, oy = inventoryGrid()
    for i = 1, INV_COLS * INV_ROWS do
        local col = (i - 1) % INV_COLS
        local row = math.floor((i - 1) / INV_COLS)
        local x, y = ox + col * SLOT_SIZE, oy + row * SLOT_SIZE
        local w = Progress.inventory[i]
        drawSlot(x, y, w, false)
    end

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(0.5, 0.7, 0.5, 1)
    love.graphics.printf("click an inventory item, then a hotbar slot to assign", 0, oy + INV_ROWS * SLOT_SIZE + 6, GAME_W, "center")
    love.graphics.printf("E or ESC to close", 0, GAME_H - 12, GAME_W, "center")

    -- redraw hotbar so user can drop into it
    drawHotbar()

    if invDragging then
        local mgx, mgy = MouseGame()
        local def = Weapons.get(invDragging)
        if def then
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], 1)
            love.graphics.setFont(Fonts.medium)
            love.graphics.print(def.glyph, mgx - 4, mgy - 6)
        end
    end
end

function Game:draw()
    local d = Progress.dungeon()
    local p = d.palette
    love.graphics.clear(p.bg[1], p.bg[2], p.bg[3], 1)

    love.graphics.setColor(p.accent[1] * 0.3, p.accent[2] * 0.3, p.accent[3] * 0.3, 0.5)
    for x = 0, GAME_W, 16 do love.graphics.line(x, 20, x, GAME_H - SLOT_SIZE - 8) end
    for y = 24, GAME_H - SLOT_SIZE - 8, 16 do love.graphics.line(0, y, GAME_W, y) end

    love.graphics.setColor(p.accent[1], p.accent[2], p.accent[3], 1)
    love.graphics.rectangle("line", 4, 20, GAME_W - 8, GAME_H - 24 - SLOT_SIZE - 4)

    for _, e in ipairs(enemies) do e:draw() end
    for _, pr in ipairs(projectiles) do
        love.graphics.setColor(1, 0.5, 1, 1)
        love.graphics.rectangle("fill", pr.x - 2, pr.y - 2, 4, 4)
    end
    worm:draw()

    drawHud()
    drawHotbar()

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
        love.graphics.setColor(0.7, 1, 0.7, a)
        love.graphics.printf(banner, 0, GAME_H / 2 - 8, GAME_W, "center")
    end

    if inventoryOpen then drawInventory() end
end

-- ---------- input ----------

local function hotbarSlotAt(gx, gy)
    local ox, oy = hotbarOrigin()
    if gy < oy or gy > oy + SLOT_SIZE then return nil end
    if gx < ox or gx > ox + 9 * SLOT_SIZE then return nil end
    return math.floor((gx - ox) / SLOT_SIZE) + 1
end

local function inventorySlotAt(gx, gy)
    local ox, oy = inventoryGrid()
    local col = math.floor((gx - ox) / SLOT_SIZE)
    local row = math.floor((gy - oy) / SLOT_SIZE)
    if col < 0 or col >= INV_COLS or row < 0 or row >= INV_ROWS then return nil end
    return row * INV_COLS + col + 1
end

function Game:keypressed(key)
    if key == "escape" then
        if inventoryOpen then inventoryOpen = false; invDragging = nil
        else SM:switch("menu") end
        return
    end
    if key == "e" then
        inventoryOpen = not inventoryOpen
        invDragging = nil
        return
    end
    if inventoryOpen then return end

    if key == "space" then worm:dash(); return end

    local n = tonumber(key)
    if n and n >= 1 and n <= 9 then Progress.selectSlot(n) end
end

function Game:mousepressed(gx, gy, button)
    if inventoryOpen then
        if button == 1 then
            local invIdx = inventorySlotAt(gx, gy)
            if invIdx and Progress.inventory[invIdx] then
                invDragging = Progress.inventory[invIdx]
                return
            end
            local hb = hotbarSlotAt(gx, gy)
            if hb then
                if invDragging then
                    Progress.hotbar[hb] = invDragging
                    invDragging = nil
                else
                    Progress.hotbar[hb] = nil
                end
            end
        elseif button == 2 then
            local hb = hotbarSlotAt(gx, gy)
            if hb then Progress.hotbar[hb] = nil end
            invDragging = nil
        end
        return
    end

    if button == 1 then
        local w = Progress.activeWeapon()
        if w then worm:fireWeapon(w) end
    end
end

function Game:wheelmoved(dx, dy)
    if inventoryOpen then return end
    if dy > 0 then Progress.cycleSlot(-1)
    elseif dy < 0 then Progress.cycleSlot(1) end
end

return Game
