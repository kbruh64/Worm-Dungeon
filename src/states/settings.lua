local Options = require("src.options")
local Audio = require("src.audio")

local SettingsState = {}
local sel = 1
local t = 0
local rows -- Options rows + a trailing BACK row

function SettingsState:enter()
    sel = 1
    t = 0
    rows = Options.count() + 1 -- last row is BACK
end

function SettingsState:update(dt) t = t + dt end

function SettingsState:draw()
    love.graphics.clear(0.04, 0.05, 0.08, 1)

    love.graphics.setFont(Fonts.large)
    love.graphics.setColor(0.4, 1, 0.6, 1)
    love.graphics.printf("SETTINGS", 0, 22, GAME_W, "center")

    local x, w = 70, 180
    Options.draw(x, 60, w, sel, 16)

    -- BACK row
    local backIdx = Options.count() + 1
    local by = 60 + Options.count() * 16
    local focused = (sel == backIdx)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, focused and 1 or 0.45)
    love.graphics.print((focused and "> " or "  ") .. "BACK", x, by)

    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(t * 3))
    love.graphics.printf("ARROWS adjust   ENTER / ESC back", 0, GAME_H - 12, GAME_W, "center")
end

local function back()
    SM:switch("menu")
end

function SettingsState:keypressed(key)
    local backIdx = Options.count() + 1
    if key == "up" or key == "w" then
        sel = (sel - 2) % rows + 1; Audio.play("move")
    elseif key == "down" or key == "s" then
        sel = sel % rows + 1; Audio.play("move")
    elseif key == "left" or key == "a" then
        if sel <= Options.count() then Options.adjust(sel, -1) end
    elseif key == "right" or key == "d" then
        if sel <= Options.count() then Options.adjust(sel, 1) end
    elseif key == "return" or key == "space" then
        if sel == backIdx then Audio.play("select"); back()
        elseif Options.items[sel].kind == "toggle" then Options.adjust(sel, 1) end
    elseif key == "escape" then
        back()
    end
end

return SettingsState
