-- Purchasable armour. Each piece grants permanent passive bonuses that are
-- applied at the start of every run (see Progress.reset). Owning multiple
-- pieces stacks their bonuses.
--   maxHp  = flat bonus to maximum HP
--   speed  = fractional move-speed bonus (0.15 = +15%)
--   dmg    = flat bonus damage to every attack
--   reduce = fraction of incoming damage ignored (0.12 = -12% damage taken)
local Armour = {}

Armour.defs = {
    hide   = { name = "WORM HIDE",   price = 15, glyph = "(", color = { 0.6, 1, 0.6 },
               maxHp = 20, desc = "Tough skin. +20 MAX HP." },
    turbo  = { name = "TURBO SHELL", price = 25, glyph = ">", color = { 0.5, 1, 1 },
               speed = 0.15, desc = "Light and fast. +15% SPEED." },
    scales = { name = "IRON SCALES", price = 35, glyph = "#", color = { 0.8, 0.8, 0.95 },
               reduce = 0.12, desc = "Plated hide. -12% damage taken." },
    spikes = { name = "SPIKED MAIL", price = 45, glyph = "x", color = { 1, 0.6, 0.4 },
               dmg = 1, desc = "Barbed plates. +1 DAMAGE." },
    titan  = { name = "TITAN PLATE", price = 90, glyph = "@", color = { 1, 0.85, 0.4 },
               maxHp = 50, reduce = 0.15, desc = "+50 MAX HP and -15% damage taken." },
}

Armour.order = { "hide", "turbo", "scales", "spikes", "titan" }

function Armour.get(id) return Armour.defs[id] end

return Armour
