local Story = {}

local pages
local page = 1
local timer = 0
local revealed = 0

function Story:enter(opts)
    opts = opts or {}
    if opts.victory then
        pages = {
            "The core falls silent.",
            "The wires cool. The fans still.",
            "A green worm wriggles free into open air.",
            "-- END --",
        }
    else
        pages = {
            "A green worm dozed in damp soil.",
            "A wormhole tore open above the garden\nand pulled it screaming into the wires.",
            "Inside: 30 sectors of hostile code.",
            "At the center: THE COMPUTER itself.",
            "Bite through the defenses, little worm.",
        }
    end
    page = 1
    revealed = 0
    timer = 0
end

function Story:update(dt)
    timer = timer + dt
    local target = #pages[page]
    if revealed < target then
        revealed = math.min(target, revealed + dt * 40)
    end
end

function Story:draw()
    love.graphics.setFont(Fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    local text = pages[page]:sub(1, math.floor(revealed))
    love.graphics.printf(text, 20, 60, GAME_W - 40, "center")

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(timer * 3))
    love.graphics.printf("[ENTER]", 0, GAME_H - 20, GAME_W, "center")
end

function Story:keypressed(key)
    if key == "return" or key == "space" then
        if revealed < #pages[page] then
            revealed = #pages[page]
            return
        end
        page = page + 1
        revealed = 0
        if page > #pages then
            if pages[#pages] == "-- END --" then
                SM:switch("menu")
            else
                SM:switch("game")
            end
        end
    elseif key == "escape" then
        SM:switch("menu")
    end
end

return Story
