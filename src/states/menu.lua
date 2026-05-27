local Menu = {}

local items = { "START", "QUIT" }
local sel = 1
local t = 0

function Menu:enter()
    sel = 1
end

function Menu:update(dt)
    t = t + dt
end

function Menu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Fonts.large)
    local title = "WORM DUNGEON"
    local tw = Fonts.large:getWidth(title)
    love.graphics.print(title, math.floor((GAME_W - tw) / 2), 40)

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.6)
    local sub = "a green worm vs. the machine"
    love.graphics.print(sub, math.floor((GAME_W - Fonts.small:getWidth(sub)) / 2), 80)

    love.graphics.setFont(Fonts.medium)
    for i, item in ipairs(items) do
        if i == sel then
            love.graphics.setColor(1, 1, 1, 1)
            local arrow = "> " .. item .. " <"
            local w = Fonts.medium:getWidth(arrow)
            love.graphics.print(arrow, math.floor((GAME_W - w) / 2), 110 + (i - 1) * 20)
        else
            love.graphics.setColor(1, 1, 1, 0.4)
            local w = Fonts.medium:getWidth(item)
            love.graphics.print(item, math.floor((GAME_W - w) / 2), 110 + (i - 1) * 20)
        end
    end

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(t * 2))
    local hint = "ENTER to select"
    love.graphics.print(hint, math.floor((GAME_W - Fonts.small:getWidth(hint)) / 2), GAME_H - 16)
end

function Menu:keypressed(key)
    if key == "up" or key == "w" then sel = (sel - 2) % #items + 1
    elseif key == "down" or key == "s" then sel = sel % #items + 1
    elseif key == "return" or key == "space" then
        if items[sel] == "START" then
            local Progress = require("src.progress")
            Progress.reset()
            SM:switch("story")
        elseif items[sel] == "QUIT" then love.event.quit() end
    end
end

return Menu
