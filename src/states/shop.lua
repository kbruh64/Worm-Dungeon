-- The shop: spend coins earned from quests on permanent gear. Two tabs:
-- WEAPONS (added to your run loadout) and ARMOUR (passive stat bonuses).
local Audio = require("src.audio")
local Profile = require("src.profile")
local Weapons = require("src.weapons")
local Armour = require("src.armour")
local UI = require("src.ui")

local Shop = {}

-- Weapons for sale: everything beyond the starting slash/punch, priced by power.
local weaponShop = {
    { name = "uppercut",     price = 20 },
    { name = "spin",         price = 30 },
    { name = "double_slash", price = 35 },
    { name = "venom",        price = 40 },
    { name = "beam",         price = 45 },
    { name = "shockwave",    price = 50 },
    { name = "phase",        price = 55 },
    { name = "ground_pound", price = 70 },
    { name = "overclock",    price = 100 },
}

local tab = 1          -- 1 = weapons, 2 = armour
local sel = 1
local t = 0
local flash, flashT, flashCol

local LIST_X, LIST_Y, ROW_H = 12, 40, 12

local function tabCount() return tab == 1 and #weaponShop or #Armour.order end

local function setFlash(msg, col)
    flash = msg; flashT = 1.6; flashCol = col or { 1, 1, 1 }
end

-- Resolve the focused entry into common fields used for both drawing and buying.
local function entry(i)
    if tab == 1 then
        local e = weaponShop[i]
        local def = Weapons.get(e.name)
        return { id = e.name, def = def, glyph = def.glyph, color = def.color,
                 name = def.name, price = e.price, owned = Profile.hasWeapon(e.name) }
    else
        local id = Armour.order[i]
        local def = Armour.get(id)
        return { id = id, def = def, glyph = def.glyph, color = def.color,
                 name = def.name, price = def.price, owned = Profile.hasArmour(id) }
    end
end

local function buy()
    local it = entry(sel)
    if it.owned then setFlash("ALREADY OWNED", { 1, 1, 0.4 }); Audio.play("move"); return end
    local ok
    if tab == 1 then ok = Profile.buyWeapon(it.id, it.price)
    else ok = Profile.buyArmour(it.id, it.price) end
    if ok then
        setFlash("PURCHASED " .. it.name, { 0.4, 1, 0.6 }); Audio.play("pickup")
    else
        setFlash("NOT ENOUGH COINS", { 1, 0.5, 0.4 }); Audio.play("hurt")
    end
end

function Shop:enter()
    tab = 1; sel = 1; t = 0; flash = nil; flashT = nil
    Audio.playMusic("menu")
end

function Shop:update(dt)
    t = t + dt
    if flashT then flashT = flashT - dt; if flashT <= 0 then flash, flashT = nil, nil end end
end

function Shop:draw()
    love.graphics.clear(0.04, 0.05, 0.08, 1)

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(0.4, 1, 0.6, 1)
    love.graphics.printf("SHOP", 0, 4, GAME_W, "center")
    UI.coins(GAME_W - 56, 7, Profile.data.coins)

    -- tabs
    love.graphics.setFont(Fonts.small)
    local tabs = { "WEAPONS", "ARMOUR" }
    local tx = 12
    for i, label in ipairs(tabs) do
        local on = (tab == i)
        love.graphics.setColor(1, 1, 1, on and 1 or 0.4)
        love.graphics.print(label, tx, 24)
        if on then
            love.graphics.setColor(0.4, 1, 0.6, 1)
            love.graphics.rectangle("fill", tx, 33, Fonts.small:getWidth(label), 1)
        end
        tx = tx + Fonts.small:getWidth(label) + 16
    end

    -- item list
    for i = 1, tabCount() do
        local it = entry(i)
        local y = LIST_Y + (i - 1) * ROW_H
        local focused = (i == sel)
        if focused then
            love.graphics.setColor(1, 1, 1, 0.1)
            love.graphics.rectangle("fill", LIST_X - 4, y - 1, GAME_W - 16, 11)
        end
        love.graphics.setColor(it.color[1], it.color[2], it.color[3], focused and 1 or 0.85)
        love.graphics.print(it.glyph, LIST_X, y)
        love.graphics.setColor(1, 1, 1, focused and 1 or 0.6)
        love.graphics.print(it.name, LIST_X + 12, y)
        if it.owned then
            love.graphics.setColor(0.4, 1, 0.6, 1)
            love.graphics.print("OWNED", GAME_W - 56, y)
        else
            local afford = Profile.data.coins >= it.price
            love.graphics.setColor(1, 0.84, 0.2, afford and 1 or 0.45)
            love.graphics.rectangle("fill", GAME_W - 64, y, 4, 4)
            love.graphics.setColor(afford and 1 or 0.7, afford and 0.9 or 0.45, 0.4, 1)
            love.graphics.print(tostring(it.price), GAME_W - 56, y)
        end
    end

    -- description of the focused item
    local it = entry(sel)
    local sub = ""
    if tab == 1 then
        local d = it.def
        sub = "DMG " .. d.dmg
            .. (d.knock and ("  KNOCK " .. d.knock) or "")
            .. (d.dot and ("  POISON " .. d.dot.dmg .. "/s") or "")
    end
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", 8, GAME_H - 31, GAME_W - 16, 20)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.85)
    love.graphics.printf(it.def.desc or "", 12, GAME_H - 29, GAME_W - 24, "left")
    if sub ~= "" then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf(sub, 12, GAME_H - 20, GAME_W - 24, "left")
    end

    -- bottom line: purchase feedback, else controls hint
    if flash then
        love.graphics.setColor(flashCol[1], flashCol[2], flashCol[3], math.min(1, flashT * 1.5 + 0.3))
        love.graphics.printf(flash, 0, GAME_H - 9, GAME_W, "center")
    else
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.printf("A/D tab   W/S pick   ENTER buy   ESC back", 0, GAME_H - 9, GAME_W, "center")
    end
end

function Shop:keypressed(key)
    local count = tabCount()
    if key == "escape" then
        Audio.play("select"); SM:switch("menu")
    elseif key == "left" or key == "a" or key == "right" or key == "d" then
        tab = (tab == 1) and 2 or 1; sel = 1; Audio.play("move")
    elseif key == "up" or key == "w" then
        sel = (sel - 2) % count + 1; Audio.play("move")
    elseif key == "down" or key == "s" then
        sel = sel % count + 1; Audio.play("move")
    elseif key == "return" or key == "space" then
        buy()
    end
end

function Shop:mousepressed(gx, gy, button)
    if button ~= 1 then return end
    -- click a row to focus it; click the focused row again to buy
    for i = 1, tabCount() do
        local y = LIST_Y + (i - 1) * ROW_H
        if gx >= LIST_X - 4 and gx <= GAME_W - 4 and gy >= y - 1 and gy <= y + 10 then
            if sel == i then buy() else sel = i; Audio.play("move") end
            return
        end
    end
end

return Shop
