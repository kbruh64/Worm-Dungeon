love.graphics.setDefaultFilter("nearest", "nearest", 0)

GAME_W, GAME_H = 320, 180

local StateMachine = require("src.state_machine")
local Menu = require("src.states.menu")
local Story = require("src.states.story")
local Game = require("src.states.game")
local Reward = require("src.states.reward")
local Victory = require("src.states.victory")
local SettingsState = require("src.states.settings")
local Shop = require("src.states.shop")
local QuestsState = require("src.states.quests")
local Settings = require("src.settings")
local Profile = require("src.profile")
local Audio = require("src.audio")
local FX = require("src.fx")

local canvas
local vignette

local sm

-- Soft radial edge-darkening drawn over the framebuffer when CRT glow is on.
local function buildVignette()
    local data = love.image.newImageData(GAME_W, GAME_H)
    local cx, cy = GAME_W / 2, GAME_H / 2
    local maxd = math.sqrt(cx * cx + cy * cy)
    data:mapPixel(function(x, y)
        local dx, dy = (x - cx), (y - cy)
        local d = math.sqrt(dx * dx + dy * dy) / maxd
        local a = math.max(0, d - 0.45) * 0.95
        return 0, 0, 0, math.min(0.8, a)
    end)
    vignette = love.graphics.newImage(data)
    vignette:setFilter("nearest", "nearest")
end

function love.load()
    canvas = love.graphics.newCanvas(GAME_W, GAME_H)
    canvas:setFilter("nearest", "nearest")

    Settings.load()
    Profile.load()
    Audio.load()
    FX.shakeEnabled = Settings.data.shake
    if Settings.data.fullscreen then love.window.setFullscreen(true) end
    buildVignette()

    local path = "assets/fonts/PressStart2P.ttf"
    local function tryFont(size)
        if love.filesystem.getInfo(path) then
            return love.graphics.newFont(path, size, "mono")
        end
        return love.graphics.newFont(size)
    end
    -- Press Start 2P is an 8x8 pixel font; pick sizes that are exact multiples.
    Fonts = { small = tryFont(8), medium = tryFont(16), large = tryFont(24) }
    Fonts.small:setFilter("nearest", "nearest")
    Fonts.medium:setFilter("nearest", "nearest")
    Fonts.large:setFilter("nearest", "nearest")

    sm = StateMachine.new()
    sm:register("menu", Menu)
    sm:register("story", Story)
    sm:register("game", Game)
    sm:register("reward", Reward)
    sm:register("victory", Victory)
    sm:register("settings", SettingsState)
    sm:register("shop", Shop)
    sm:register("quests", QuestsState)
    sm:switch("menu")

    _G.SM = sm
end

function love.update(dt)
    sm:update(dt)
end

local viewScale, viewOx, viewOy = 1, 0, 0

function ScreenToGame(x, y)
    return (x - viewOx) / viewScale, (y - viewOy) / viewScale
end

function MouseGame()
    local mx, my = love.mouse.getPosition()
    return ScreenToGame(mx, my)
end

local function drawScaled()
    love.graphics.setCanvas({ canvas, stencil = true })
    love.graphics.clear(0.04, 0.05, 0.08, 1)
    sm:draw()
    -- vignette is always on for mood; CRT glow stacks a second pass for a
    -- heavier edge-darkening.
    if vignette then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(vignette, 0, 0)
        if Settings.data.crt then love.graphics.draw(vignette, 0, 0) end
    end
    love.graphics.setCanvas()

    local sw, sh = love.graphics.getDimensions()
    viewScale = math.floor(math.min(sw / GAME_W, sh / GAME_H))
    if viewScale < 1 then viewScale = 1 end
    viewOx = math.floor((sw - GAME_W * viewScale) / 2)
    viewOy = math.floor((sh - GAME_H * viewScale) / 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, viewOx, viewOy, 0, viewScale, viewScale)
end

function love.draw()
    drawScaled()
end

function love.keypressed(key)
    if key == "f11" then
        local fs = not love.window.getFullscreen()
        love.window.setFullscreen(fs)
        Settings.data.fullscreen = fs
        Settings.save()
        return
    end
    sm:keypressed(key)
end

function love.mousepressed(x, y, button)
    if sm.current and sm.current.mousepressed then
        local gx, gy = ScreenToGame(x, y)
        sm.current:mousepressed(gx, gy, button)
    end
end

function love.wheelmoved(dx, dy)
    if sm.current and sm.current.wheelmoved then
        sm.current:wheelmoved(dx, dy)
    end
end
