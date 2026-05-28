-- Weapon definitions. Each weapon: display glyph, color, hitbox shape, damage, duration, cooldown.
-- shape = "arc" (reach forward), "radial" (around worm), "beam" (long reach), "self" (buff).
-- dur = active hitbox time; cd = recovery time after the swing before you can attack again.
local Weapons = {}

Weapons.defs = {
    slash         = { glyph = "/",  color = {1, 0.2, 0.2},  shape = "arc",    reach = 16, dur = 0.18, cd = 0.20, dmg = 1 },
    punch         = { glyph = "o",  color = {1, 0.9, 0.6},  shape = "arc",    reach = 10, dur = 0.12, cd = 0.16, dmg = 1 },
    uppercut      = { glyph = "^",  color = {1, 0.6, 1},    shape = "arc",    reach = 12, dur = 0.22, cd = 0.30, dmg = 2 },
    spin          = { glyph = "@",  color = {1, 0.3, 0.3},  shape = "radial", reach = 18, dur = 0.30, cd = 0.45, dmg = 2 },
    beam          = { glyph = "=",  color = {0.5, 1, 1},    shape = "beam",   reach = 80, dur = 0.20, cd = 0.40, dmg = 3 },
    double_slash  = { glyph = "X",  color = {1, 0.3, 0.5},  shape = "arc",    reach = 20, dur = 0.24, cd = 0.35, dmg = 2 },
    shockwave     = { glyph = "~",  color = {0.4, 0.6, 1},  shape = "radial", reach = 28, dur = 0.35, cd = 0.50, dmg = 2 },
    venom         = { glyph = "v",  color = {0.4, 1, 0.3},  shape = "arc",    reach = 14, dur = 0.20, cd = 0.28, dmg = 1, dot = 2 },
    ground_pound  = { glyph = "G",  color = {0.8, 0.6, 0.2},shape = "radial", reach = 36, dur = 0.45, cd = 0.65, dmg = 3 },
    phase         = { glyph = "*",  color = {0.7, 0.7, 1},  shape = "arc",    reach = 18, dur = 0.22, cd = 0.30, dmg = 2 },
    overclock     = { glyph = "!",  color = {1, 1, 0.4},    shape = "beam",   reach = 100, dur = 0.18, cd = 0.35, dmg = 4 },
}

Weapons.order = {
    "slash", "punch", "uppercut", "spin", "double_slash",
    "beam", "shockwave", "venom", "ground_pound", "phase", "overclock",
}

function Weapons.get(name) return Weapons.defs[name] end

return Weapons
