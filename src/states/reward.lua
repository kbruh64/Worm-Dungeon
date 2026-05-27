local Progress = require("src.progress")
local Weapons = require("src.weapons")

local Reward = {}
local choices, sel, t

function Reward:enter()
    choices = Progress.rollRewards()
    sel = 1
    t = 0
end

function Reward:update(dt) t = t + dt end

function Reward:draw()
    love.graphics.clear(0.04, 0.05, 0.08, 1)

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("CHOOSE A REWARD", 0, 18, GAME_W, "center")

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.printf("SECTOR " .. string.format("%02d", Progress.currentDungeon) .. " CLEARED", 0, 36, GAME_W, "center")

    local cardW, cardH = 80, 70
    local gap = 8
    local total = #choices * cardW + (#choices - 1) * gap
    local startX = math.floor((GAME_W - total) / 2)
    local y = 60

    for i, c in ipairs(choices) do
        local x = startX + (i - 1) * (cardW + gap)
        local selected = (i == sel)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x, y, cardW, cardH)
        love.graphics.setColor(1, 1, 1, selected and 1 or 0.4)
        love.graphics.rectangle("line", x + 0.5, y + 0.5, cardW - 1, cardH - 1)
        if selected then
            love.graphics.rectangle("line", x - 0.5, y - 0.5, cardW + 1, cardH + 1)
        end

        if c.kind == "weapon" then
            local def = Weapons.get(c.weapon)
            love.graphics.setFont(Fonts.large)
            love.graphics.setColor(def.color[1], def.color[2], def.color[3], 1)
            local g = def.glyph
            love.graphics.print(g, x + math.floor((cardW - Fonts.large:getWidth(g)) / 2),
                                   y + 8)
        else
            love.graphics.setFont(Fonts.large)
            love.graphics.setColor(1, 1, 0.6, 1)
            local g = "+"
            if c.kind == "hp" then love.graphics.setColor(0.6, 1, 0.6, 1)
            elseif c.kind == "heal" then love.graphics.setColor(1, 0.6, 0.6, 1); g = "*"
            elseif c.kind == "dmg" then love.graphics.setColor(1, 0.5, 0.5, 1); g = "!"
            elseif c.kind == "speed" then love.graphics.setColor(0.5, 1, 1, 1); g = ">"
            end
            love.graphics.print(g, x + math.floor((cardW - Fonts.large:getWidth(g)) / 2),
                                   y + 8)
        end

        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(c.label, x, y + cardH - 14, cardW, "center")

        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf(tostring(i), x + 2, y + 2, cardW - 4, "left")
    end

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(t * 3))
    love.graphics.printf("A / D or 1-3 to pick, ENTER to confirm", 0, GAME_H - 14, GAME_W, "center")
end

local function confirm()
    Progress.takeReward(choices[sel])
    Progress.advance()
    if Progress.currentDungeon > Progress.total() then
        SM:switch("victory")
    else
        SM:switch("game")
    end
end

function Reward:keypressed(key)
    if key == "left" or key == "a" then sel = sel - 1; if sel < 1 then sel = #choices end
    elseif key == "right" or key == "d" then sel = sel + 1; if sel > #choices then sel = 1 end
    elseif key == "1" or key == "2" or key == "3" then
        local n = tonumber(key)
        if choices[n] then sel = n; confirm() end
    elseif key == "return" or key == "space" then confirm()
    end
end

function Reward:mousepressed(gx, gy, button)
    if button ~= 1 then return end
    local cardW, cardH = 80, 70
    local gap = 8
    local total = #choices * cardW + (#choices - 1) * gap
    local startX = math.floor((GAME_W - total) / 2)
    local y = 60
    for i = 1, #choices do
        local x = startX + (i - 1) * (cardW + gap)
        if gx >= x and gx <= x + cardW and gy >= y and gy <= y + cardH then
            sel = i; confirm(); return
        end
    end
end

return Reward
