-- Lightweight pixel-art particle + screen-shake system.
local FX = {
    particles = {},
    popups = {},
    shake = 0,
    shakeMag = 0,
    flash = 0,
    flashColor = {1, 1, 1, 1},
    shakeEnabled = true,
}

function FX.reset()
    FX.particles = {}
    FX.popups = {}
    FX.shake = 0
    FX.shakeMag = 0
    FX.flash = 0
end

-- Floating combat text (e.g. damage numbers) that drifts up and fades.
function FX.popup(x, y, text, color)
    table.insert(FX.popups, {
        x = x, y = y, vy = -18,
        life = 0.6, maxLife = 0.6,
        text = tostring(text), color = color or {1, 1, 1},
    })
end

function FX.shakeFor(dur, mag)
    if dur > FX.shake then FX.shake = dur end
    if mag > FX.shakeMag then FX.shakeMag = mag end
end

function FX.flashFor(dur, r, g, b)
    FX.flash = math.max(FX.flash, dur)
    FX.flashColor = { r or 1, g or 1, b or 1, 1 }
end

function FX.spark(x, y, color, count, speed, life)
    count = count or 8
    speed = speed or 60
    life = life or 0.35
    for i = 1, count do
        local a = math.random() * math.pi * 2
        local s = speed * (0.4 + math.random() * 0.8)
        table.insert(FX.particles, {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            life = life, maxLife = life,
            color = color, size = 1 + (math.random() < 0.3 and 1 or 0),
            gravity = 0,
        })
    end
end

function FX.dust(x, y, color, count)
    count = count or 4
    for i = 1, count do
        local a = -math.pi + math.random() * math.pi
        local s = 30 + math.random() * 30
        table.insert(FX.particles, {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s * 0.4,
            life = 0.4, maxLife = 0.4,
            color = color, size = 1,
            gravity = 40,
        })
    end
end

function FX.streak(x, y, dx, dy, color, count)
    count = count or 6
    for i = 1, count do
        local jitter = (math.random() - 0.5) * 2
        table.insert(FX.particles, {
            x = x + (math.random() - 0.5) * 3,
            y = y + (math.random() - 0.5) * 3,
            vx = dx + jitter * 10, vy = dy + jitter * 10,
            life = 0.25, maxLife = 0.25,
            color = color, size = 1,
            gravity = 0,
        })
    end
end

function FX.ring(x, y, color, count, radius)
    count = count or 12
    radius = radius or 14
    for i = 1, count do
        local a = (i / count) * math.pi * 2
        table.insert(FX.particles, {
            x = x + math.cos(a) * 2, y = y + math.sin(a) * 2,
            vx = math.cos(a) * radius * 3, vy = math.sin(a) * radius * 3,
            life = 0.35, maxLife = 0.35,
            color = color, size = 1,
            gravity = 0,
        })
    end
end

function FX.update(dt)
    FX.shake = math.max(0, FX.shake - dt)
    if FX.shake == 0 then FX.shakeMag = 0 end
    FX.flash = math.max(0, FX.flash - dt)
    for i = #FX.particles, 1, -1 do
        local p = FX.particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(FX.particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            if p.gravity ~= 0 then p.vy = p.vy + p.gravity * dt end
            p.vx = p.vx * 0.92
            p.vy = p.vy * 0.96
        end
    end
    for i = #FX.popups, 1, -1 do
        local p = FX.popups[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(FX.popups, i)
        else
            p.y = p.y + p.vy * dt
            p.vy = p.vy * 0.9
        end
    end
end

function FX.draw()
    for _, p in ipairs(FX.particles) do
        local a = math.max(0, p.life / p.maxLife)
        local c = p.color
        love.graphics.setColor(c[1], c[2], c[3], a)
        love.graphics.rectangle("fill", math.floor(p.x), math.floor(p.y), p.size, p.size)
    end
    if #FX.popups > 0 and Fonts and Fonts.small then
        love.graphics.setFont(Fonts.small)
        for _, p in ipairs(FX.popups) do
            local a = math.max(0, p.life / p.maxLife)
            local c = p.color
            love.graphics.setColor(0, 0, 0, a * 0.8)
            love.graphics.print(p.text, math.floor(p.x) + 1, math.floor(p.y) + 1)
            love.graphics.setColor(c[1], c[2], c[3], a)
            love.graphics.print(p.text, math.floor(p.x), math.floor(p.y))
        end
    end
end

function FX.drawOverlay()
    if FX.flash > 0 then
        local c = FX.flashColor
        love.graphics.setColor(c[1], c[2], c[3], FX.flash * 1.2)
        love.graphics.rectangle("fill", 0, 0, GAME_W, GAME_H)
    end
end

function FX.shakeOffset()
    if FX.shake <= 0 or not FX.shakeEnabled then return 0, 0 end
    local m = FX.shakeMag
    return (math.random() - 0.5) * m * 2, (math.random() - 0.5) * m * 2
end

return FX
