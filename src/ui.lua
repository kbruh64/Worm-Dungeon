-- Tiny shared UI helpers used across menu / shop / quest screens.
local UI = {}

-- Draw a small gold coin icon followed by the amount, using the small font,
-- with the icon's top-left at (x, y). Returns the x just past the text so
-- callers can chain. `alpha` defaults to 1.
function UI.coins(x, y, n, alpha)
    alpha = alpha or 1
    love.graphics.setColor(1, 0.84, 0.2, alpha)
    love.graphics.rectangle("fill", x, y, 5, 5)
    love.graphics.setColor(1, 0.96, 0.6, alpha)
    love.graphics.rectangle("fill", x + 1, y + 1, 2, 2)
    love.graphics.setColor(0.55, 0.42, 0.05, alpha)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, 4, 4)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 0.9, 0.4, alpha)
    local s = tostring(n)
    love.graphics.print(s, x + 8, y - 1)
    return x + 8 + Fonts.small:getWidth(s)
end

return UI
