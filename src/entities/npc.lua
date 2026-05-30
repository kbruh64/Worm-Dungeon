-- Passive friendly characters scattered through the sectors. They don't fight;
-- walk near one and it pops a speech bubble with a system tip or a bad joke.
local Npc = {}
Npc.__index = Npc

local KINDS = { "blip", "cursor", "floppy", "bug" }

-- Helpful (mostly) system info.
local TIPS = {
    "Dash has i-frames.\nPhase through everything.",
    "Combos stack damage.\nKeep biting, don't pause.",
    "Beams hit a whole line.\nLine 'em up.",
    "Poison ticks through armor.\nVery rude. Very good.",
    "Firewalls have shields.\nWait for them to drop.",
    "Low-HP enemies RAGE.\nThey speed up. Finish fast.",
    "Viruses split when killed.\nMess. Plan ahead.",
    "The exit unlocks when\nthe room is empty.",
    "Shockwave knocks 'em silly.\nLow damage though.",
    "The Computer logs your\nevery move. Creepy.",
    "Heal rewards full you up.\nGrab one before a boss.",
    "Knockback buys breathing room.\nUse it near walls.",
}

-- Bad jokes. Deeply bad.
local JOKES = {
    "Why'd the worm cross the bus?\nTo reach the other socket.",
    "404: my motivation\nnot found.",
    "I'd tell a UDP joke but\nyou might not get it.",
    "There are 10 kinds of worm:\nbinary ones, and you.",
    "I'm not lazy. I'm just\nin low-power mode.",
    "My favorite band?\nThe Buffer Overflows.",
    "I took a packet to the knee.\nNow I'm just a daemon.",
    "Knock knock.\nWho's there?\n...very long pause...\nJava.",
    "I'd cache that joke but\nyou'd just evict it.",
    "Two bytes meet. One says:\n'you look a bit off.'",
    "The Computer fears one thing:\nan unsaved document.",
    "Worms don't get viruses.\nWe ARE the virus. ...wait.",
}

function Npc.new(x, y)
    local kind = KINDS[math.random(1, #KINDS)]
    local pool = (math.random() < 0.5) and TIPS or JOKES
    return setmetatable({
        x = x, y = y, w = 10, h = 10,
        kind = kind,
        line = pool[math.random(1, #pool)],
        bobT = math.random() * 6.28,
        dir = 1,
        near = false,
    }, Npc)
end

function Npc:cx() return self.x + self.w / 2 end
function Npc:cy() return self.y + self.h / 2 end

function Npc:update(dt, worm)
    self.bobT = self.bobT + dt * 3
    local dx = worm:centerX() - self:cx()
    local dy = worm:centerY() - self:cy()
    self.dir = (dx >= 0) and 1 or -1
    self.near = (dx * dx + dy * dy) < (34 * 34)
end

-- ---- pixel rendering ----
local function px(x, y, w, h)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), w or 1, h or 1)
end

local sprites = {}

-- blip: friendly chat-bubble assistant
function sprites.blip(self, x, y)
    love.graphics.setColor(0.0, 0.22, 0.28, 1)         -- outline
    px(x, y, 10, 8)
    love.graphics.setColor(0.3, 0.85, 0.95, 1)          -- body
    px(x + 1, y + 1, 8, 6)
    love.graphics.setColor(0.65, 1, 1, 1)               -- highlight
    px(x + 1, y + 1, 8, 1); px(x + 1, y + 1, 1, 5)
    love.graphics.setColor(0.12, 0.5, 0.6, 1)           -- shadow
    px(x + 8, y + 2, 1, 5); px(x + 2, y + 6, 7, 1)
    love.graphics.setColor(0.3, 0.85, 0.95, 1)          -- bubble tail
    px(x + 2, y + 8, 2, 1); px(x + 2, y + 9, 1, 1)
    love.graphics.setColor(0, 0, 0, 1)                  -- eyes + smile
    local e = (self.dir > 0) and 0 or -1
    px(x + 3 + e, y + 3, 1, 2); px(x + 6 + e, y + 3, 1, 2)
    px(x + 3, y + 5, 1, 1); px(x + 6, y + 5, 1, 1); px(x + 4, y + 6, 2, 1)
end

-- cursor: classic mouse arrow with a face
function sprites.cursor(self, x, y)
    love.graphics.setColor(0.1, 0.1, 0.12, 1)           -- outline
    for r = 0, 6 do px(x + 1, y + r, r + 2, 1) end
    love.graphics.setColor(0.95, 0.95, 1, 1)            -- white arrow
    for r = 0, 5 do px(x + 2, y + 1 + r, r + 1, 1) end
    love.graphics.setColor(0.6, 0.6, 0.7, 1)            -- shaded edge
    px(x + 2, y + 6, 4, 1)
    px(x + 6, y + 7, 2, 3)                              -- arrow tail
    love.graphics.setColor(0, 0, 0, 1)                  -- eyes
    px(x + 3, y + 3, 1, 1); px(x + 5, y + 3, 1, 1)
end

-- floppy: 3.5" disk buddy
function sprites.floppy(self, x, y)
    love.graphics.setColor(0.08, 0.1, 0.22, 1)          -- outline
    px(x, y, 10, 10)
    love.graphics.setColor(0.25, 0.35, 0.7, 1)          -- body
    px(x + 1, y + 1, 8, 8)
    love.graphics.setColor(0.45, 0.55, 0.9, 1)          -- top sheen
    px(x + 1, y + 1, 8, 1)
    love.graphics.setColor(0.85, 0.85, 0.9, 1)          -- metal shutter
    px(x + 4, y + 1, 4, 4)
    love.graphics.setColor(0.4, 0.45, 0.55, 1)
    px(x + 5, y + 1, 1, 4)
    love.graphics.setColor(0.9, 0.9, 0.95, 1)           -- label
    px(x + 2, y + 6, 6, 3)
    love.graphics.setColor(0, 0, 0, 1)                  -- face on the label
    px(x + 3, y + 7, 1, 1); px(x + 6, y + 7, 1, 1); px(x + 4, y + 8, 2, 1)
end

-- bug: a friendly debug beetle
function sprites.bug(self, x, y)
    love.graphics.setColor(0.05, 0.12, 0.05, 1)         -- outline
    px(x + 1, y + 2, 8, 7)
    love.graphics.setColor(0.4, 0.85, 0.35, 1)          -- shell
    px(x + 2, y + 3, 6, 5)
    love.graphics.setColor(0.65, 1, 0.5, 1)             -- shell sheen
    px(x + 2, y + 3, 6, 1)
    love.graphics.setColor(0.1, 0.35, 0.1, 1)           -- wing split + spots
    px(x + 4, y + 3, 1, 5)
    px(x + 3, y + 5, 1, 1); px(x + 6, y + 6, 1, 1)
    love.graphics.setColor(0.4, 0.85, 0.35, 1)          -- head
    px(x + 3, y + 1, 4, 2)
    love.graphics.setColor(0.1, 0.35, 0.1, 1)           -- antennae
    px(x + 3, y, 1, 1); px(x + 6, y, 1, 1)
    love.graphics.setColor(0, 0, 0, 1)                  -- eyes
    px(x + 3, y + 1, 1, 1); px(x + 6, y + 1, 1, 1)
end

function Npc:draw()
    local bob = math.floor(math.sin(self.bobT) * 1.5)
    local x, y = math.floor(self.x), math.floor(self.y) + bob

    -- ground shadow (stays put while the body bobs)
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", self:cx(), self.y + self.h + 1, self.w / 2.5, 1.5)

    -- faint friendly glow so they read as non-hostile
    love.graphics.setColor(0.5, 1, 0.8, 0.08 + (self.near and 0.06 or 0))
    love.graphics.circle("fill", self:cx(), y + self.h / 2, self.w * 0.7)

    local fn = sprites[self.kind] or sprites.blip
    fn(self, x, y)

    -- a little "!" indicator when you're close enough to read it
    if self.near then
        love.graphics.setColor(1, 1, 0.5, 0.6 + 0.4 * math.sin(self.bobT * 2))
        px(self:cx() - 0.5, y - 4, 1, 2)
        px(self:cx() - 0.5, y - 1, 1, 1)
    end
end

function Npc:drawBubble()
    if not self.near or not (Fonts and Fonts.small) then return end
    local font = Fonts.small
    local maxw = 110
    local _, lines = font:getWrap(self.line, maxw)
    local lh = font:getHeight()
    local boxW = maxw + 8
    local boxH = #lines * lh + 6
    local bx = math.floor(self:cx() - boxW / 2)
    local by = math.floor(self.y - boxH - 5)

    love.graphics.setColor(0.05, 0.06, 0.1, 0.92)
    love.graphics.rectangle("fill", bx, by, boxW, boxH)
    love.graphics.setColor(0.4, 1, 0.6, 1)
    love.graphics.rectangle("line", bx + 0.5, by + 0.5, boxW - 1, boxH - 1)
    -- tail pointing down at the character
    love.graphics.setColor(0.05, 0.06, 0.1, 0.92)
    px(self:cx() - 1, by + boxH, 2, 3)

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.line, bx + 4, by + 3, boxW - 8, "center")
end

return Npc
