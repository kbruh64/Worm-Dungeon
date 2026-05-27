love.graphics.setDefaultFilter("nearest", "nearest", 0)

GAME_W, GAME_H = 320, 180

local StateMachine = require("src.state_machine")
local Menu = require("src.states.menu")
local Story = require("src.states.story")
local Game = require("src.states.game")
local Victory = require("src.states.victory")

local canvas

local sm

function love.load()
    canvas = love.graphics.newCanvas(GAME_W, GAME_H)
    canvas:setFilter("nearest", "nearest")

    local path = "assets/fonts/Mojangles.ttf"
    local function tryFont(size)
        if love.filesystem.getInfo(path) then
            return love.graphics.newFont(path, size)
        end
        return love.graphics.newFont(size)
    end
    Fonts = { small = tryFont(8), medium = tryFont(16), large = tryFont(32) }
    Fonts.small:setFilter("nearest", "nearest")
    Fonts.medium:setFilter("nearest", "nearest")
    Fonts.large:setFilter("nearest", "nearest")

    sm = StateMachine.new()
    sm:register("menu", Menu)
    sm:register("story", Story)
    sm:register("game", Game)
    sm:register("victory", Victory)
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
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0.04, 0.05, 0.08, 1)
    sm:draw()
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
        love.window.setFullscreen(not love.window.getFullscreen())
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
