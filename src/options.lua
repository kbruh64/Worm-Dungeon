-- Shared options widget: a list of adjustable settings rows (sliders + toggles)
-- used by both the main-menu Settings screen and the in-game pause overlay.
local Settings = require("src.settings")
local Audio = require("src.audio")
local FX = require("src.fx")

local Options = {}

Options.items = {
    { id = "music", label = "MUSIC", kind = "slider",
      get = function() return Settings.data.music end,
      set = function(v) Audio.setMusicVol(v) end },
    { id = "sfx", label = "SFX", kind = "slider",
      get = function() return Settings.data.sfx end,
      set = function(v) Audio.setSfxVol(v) end },
    { id = "fullscreen", label = "FULLSCREEN", kind = "toggle",
      get = function() return Settings.data.fullscreen end,
      set = function(v) Settings.data.fullscreen = v; love.window.setFullscreen(v) end },
    { id = "shake", label = "SCREEN SHAKE", kind = "toggle",
      get = function() return Settings.data.shake end,
      set = function(v) Settings.data.shake = v; FX.shakeEnabled = v end },
    { id = "crt", label = "CRT GLOW", kind = "toggle",
      get = function() return Settings.data.crt end,
      set = function(v) Settings.data.crt = v end },
}

function Options.count() return #Options.items end

-- Adjust the focused row. dir is -1 / +1 (toggle ignores magnitude).
function Options.adjust(sel, dir)
    local it = Options.items[sel]
    if not it then return end
    if it.kind == "slider" then
        local v = math.max(0, math.min(1, it.get() + dir * 0.1))
        v = math.floor(v * 10 + 0.5) / 10
        it.set(v)
    else
        it.set(not it.get())
        Audio.play("move")
    end
    Settings.save()
end

-- Draw the rows starting at (x, y). rowH between rows. Returns next free y.
function Options.draw(x, y, w, sel, rowH)
    rowH = rowH or 16
    love.graphics.setFont(Fonts.small)
    for i, it in ipairs(Options.items) do
        local focused = (i == sel)
        local ry = y + (i - 1) * rowH
        love.graphics.setColor(1, 1, 1, focused and 1 or 0.45)
        love.graphics.print((focused and "> " or "  ") .. it.label, x, ry)

        if it.kind == "slider" then
            local bx, bw = x + w - 56, 44
            love.graphics.setColor(1, 1, 1, 0.2)
            love.graphics.rectangle("fill", bx, ry + 1, bw, 5)
            love.graphics.setColor(0.4, 1, 0.6, focused and 1 or 0.5)
            love.graphics.rectangle("fill", bx, ry + 1, bw * it.get(), 5)
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.rectangle("line", bx + 0.5, ry + 1.5, bw - 1, 4)
        else
            local on = it.get()
            love.graphics.setColor(on and 0.4 or 1, on and 1 or 0.5, on and 0.6 or 0.5, focused and 1 or 0.6)
            love.graphics.print(on and "ON" or "OFF", x + w - 24, ry)
        end
    end
    return y + #Options.items * rowH
end

return Options
