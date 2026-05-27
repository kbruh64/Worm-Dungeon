local Victory = {}
local t = 0

function Victory:enter() t = 0 end

function Victory:update(dt) t = t + dt end

function Victory:draw()
    love.graphics.setFont(Fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    local s = "YOU WIN"
    love.graphics.print(s, math.floor((GAME_W - Fonts.large:getWidth(s)) / 2), 60)

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(t * 2))
    love.graphics.printf("ENTER", 0, GAME_H - 30, GAME_W, "center")
end

function Victory:keypressed(key)
    if key == "return" or key == "space" then
        SM:switch("story", { victory = true })
    end
end

return Victory
