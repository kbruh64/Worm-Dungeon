local Audio = require("src.audio")
local Profile = require("src.profile")
local Quests = require("src.quests")
local UI = require("src.ui")

local Menu = {}

local items = { "START", "SHOP", "QUESTS", "SETTINGS", "QUIT" }
local sel = 1
local t = 0

function Menu:enter()
    sel = 1
    Audio.playMusic("menu")
    -- reconcile any quests completed during the last run so coins are awarded
    -- even if the run ended in a death rather than a sector clear.
    Quests.check()
end

function Menu:update(dt)
    t = t + dt
end

-- a green worm wiggling along a sine path under the title
local function drawWorm()
    local baseY = 70
    local cx = GAME_W / 2
    local span = 60
    for i = 10, 0, -1 do
        local px = cx - span / 2 + (span) * (i / 10) + math.sin(t * 2) * 6
        local py = baseY + math.sin(t * 4 - i * 0.5) * 4
        local g = 0.85 - (i / 10) * 0.4
        love.graphics.setColor(0.15, g, 0.2, 1)
        local s = (i <= 1) and 3 or (i <= 4) and 2 or 1
        love.graphics.rectangle("fill", math.floor(px - s / 2), math.floor(py - s / 2), s, s)
    end
    -- eye on the head
    local hx = cx - span / 2 + span + math.sin(t * 2) * 6
    local hy = baseY + math.sin(t * 4) * 4
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", math.floor(hx), math.floor(hy - 1), 1, 1)
end

function Menu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.large)
    local title = "WORM DUNGEON"
    local tw = Fonts.large:getWidth(title)
    love.graphics.print(title, math.floor((GAME_W - tw) / 2), 30)

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.6)
    local sub = "a green worm vs. the machine"
    love.graphics.print(sub, math.floor((GAME_W - Fonts.small:getWidth(sub)) / 2), 54)

    drawWorm()

    -- coin balance, top-right
    UI.coins(GAME_W - 52, 6, Profile.data.coins)

    love.graphics.setFont(Fonts.medium)
    for i, item in ipairs(items) do
        local y = 84 + (i - 1) * 16
        if i == sel then
            love.graphics.setColor(1, 1, 1, 1)
            local arrow = "> " .. item .. " <"
            local w = Fonts.medium:getWidth(arrow)
            love.graphics.print(arrow, math.floor((GAME_W - w) / 2), y)
        else
            love.graphics.setColor(1, 1, 1, 0.4)
            local w = Fonts.medium:getWidth(item)
            love.graphics.print(item, math.floor((GAME_W - w) / 2), y)
        end
    end

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(t * 2))
    local hint = "ENTER to select"
    love.graphics.print(hint, math.floor((GAME_W - Fonts.small:getWidth(hint)) / 2), GAME_H - 9)
end

function Menu:keypressed(key)
    if key == "up" or key == "w" then sel = (sel - 2) % #items + 1; Audio.play("move")
    elseif key == "down" or key == "s" then sel = sel % #items + 1; Audio.play("move")
    elseif key == "return" or key == "space" then
        Audio.play("select")
        if items[sel] == "START" then
            local Progress = require("src.progress")
            Progress.reset()
            SM:switch("story")
        elseif items[sel] == "SHOP" then
            SM:switch("shop")
        elseif items[sel] == "QUESTS" then
            SM:switch("quests")
        elseif items[sel] == "SETTINGS" then
            SM:switch("settings")
        elseif items[sel] == "QUIT" then love.event.quit() end
    end
end

return Menu
