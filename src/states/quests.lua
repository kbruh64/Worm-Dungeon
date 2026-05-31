-- The quest log: shows every quest, its progress, and its coin reward. Entering
-- this page reconciles progress and pays out any quests completed since the
-- last visit, so coins earned in-game show up here.
local Audio = require("src.audio")
local Profile = require("src.profile")
local Quests = require("src.quests")
local UI = require("src.ui")

local QuestsState = {}

local t = 0
local justEarned = 0

function QuestsState:enter()
    t = 0
    Audio.playMusic("menu")
    justEarned = 0
    for _, q in ipairs(Quests.check()) do justEarned = justEarned + q.reward end
end

function QuestsState:update(dt) t = t + dt end

function QuestsState:draw()
    love.graphics.clear(0.04, 0.05, 0.08, 1)

    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(0.4, 1, 0.6, 1)
    love.graphics.printf("QUESTS", 0, 4, GAME_W, "center")
    UI.coins(GAME_W - 56, 7, Profile.data.coins)

    love.graphics.setFont(Fonts.small)
    local y0, rowH = 26, 14
    for i, q in ipairs(Quests.list) do
        local y = y0 + (i - 1) * rowH
        local cur, tgt = Quests.progress(q)
        local claimed = Quests.isClaimed(q)

        love.graphics.setColor(claimed and 0.45 or 1, 1, claimed and 0.65 or 1, claimed and 1 or 0.9)
        love.graphics.print(q.name, 8, y)

        -- progress bar
        local bx, bw = 148, 64
        love.graphics.setColor(1, 1, 1, 0.16)
        love.graphics.rectangle("fill", bx, y + 1, bw, 6)
        love.graphics.setColor(claimed and 0.4 or 0.5, 1, claimed and 0.6 or 0.7, 1)
        love.graphics.rectangle("fill", bx, y + 1, bw * (cur / tgt), 6)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", bx + 0.5, y + 1.5, bw - 1, 5)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(cur .. "/" .. tgt, bx + bw + 4, y)

        if claimed then
            love.graphics.setColor(0.4, 1, 0.6, 1)
            love.graphics.print("DONE", GAME_W - 34, y)
        else
            UI.coins(GAME_W - 40, y, q.reward)
        end
    end

    if justEarned > 0 then
        love.graphics.setColor(1, 0.9, 0.4, 0.55 + 0.45 * math.sin(t * 4))
        love.graphics.printf("+" .. justEarned .. " COINS EARNED!", 0, GAME_H - 9, GAME_W, "center")
    else
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.printf("Complete quests in-game to earn coins    ESC back", 0, GAME_H - 9, GAME_W, "center")
    end
end

function QuestsState:keypressed(key)
    if key == "escape" or key == "return" or key == "space" then
        Audio.play("select"); SM:switch("menu")
    end
end

return QuestsState
