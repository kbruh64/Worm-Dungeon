local Progress = require("src.progress")

local Story = {}

local pages
local page = 1
local timer = 0
local revealed = 0
local mode = "intro"

function Story:enter(opts)
    opts = opts or {}
    mode = opts.mode or (opts.victory and "victory") or "intro"

    if mode == "victory" then
        pages = {
            "The core falls silent.",
            "The wires cool. The fans still.",
            "A green worm wriggles free into open air.",
            "-- END --",
        }
    elseif mode == "level" then
        local d = Progress.dungeon()
        pages = {
            string.format("SECTOR %02d / %02d", Progress.currentDungeon, Progress.total()),
            d.name,
            d.story or "",
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
        revealed = math.min(target, revealed + dt * 45)
    end
end

function Story:draw()
    -- emphasize the title page (page with the sector name) in level mode
    if mode == "level" and page == 2 then
        love.graphics.setFont(Fonts.large)
    else
        love.graphics.setFont(Fonts.medium)
    end
    love.graphics.setColor(1, 1, 1, 1)
    local text = pages[page]:sub(1, math.floor(revealed))
    love.graphics.printf(text, 16, 56, GAME_W - 32, "center")

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(1, 1, 1, 0.4 + 0.4 * math.sin(timer * 3))
    love.graphics.printf("[ENTER]", 0, GAME_H - 20, GAME_W, "center")
end

local function advance()
    if mode == "victory" then
        SM:switch("menu")
    elseif mode == "intro" then
        SM:switch("story", { mode = "level" })
    else
        SM:switch("game")
    end
end

function Story:keypressed(key)
    if key == "return" or key == "space" then
        if revealed < #pages[page] then
            revealed = #pages[page]
            return
        end
        page = page + 1
        revealed = 0
        if page > #pages then advance() end
    elseif key == "escape" then
        if mode == "level" then SM:switch("game") else SM:switch("menu") end
    end
end

return Story
