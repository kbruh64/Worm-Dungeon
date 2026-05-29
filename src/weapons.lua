-- Weapon definitions.
-- shape = "arc" (forward), "radial" (around worm), "beam" (long line).
-- dur = active hitbox time; cd = recovery after the swing.
-- knock = knockback impulse applied to hit enemies.
-- dot   = { dmg, time } poison damage-over-time applied on hit.
local Weapons = {}

Weapons.defs = {
    slash = {
        name = "RED SLASH", glyph = "/", color = {1, 0.2, 0.2},
        shape = "arc", reach = 16, dur = 0.18, cd = 0.20, dmg = 2, knock = 30,
        desc = "Quick forward cut. Reliable all-rounder.",
    },
    punch = {
        name = "PUNCH", glyph = "o", color = {1, 0.9, 0.6},
        shape = "arc", reach = 10, dur = 0.12, cd = 0.16, dmg = 2, knock = 70,
        desc = "Short, fast jab. Knocks enemies back.",
    },
    uppercut = {
        name = "UPPERCUT", glyph = "^", color = {1, 0.6, 1},
        shape = "arc", reach = 13, dur = 0.22, cd = 0.30, dmg = 4, knock = 110,
        desc = "Heavy rising hit. Launches enemies away.",
    },
    spin = {
        name = "SPIN CYCLE", glyph = "@", color = {1, 0.3, 0.3},
        shape = "radial", reach = 20, dur = 0.30, cd = 0.45, dmg = 3, knock = 50,
        desc = "Spins and hits everything around you.",
    },
    double_slash = {
        name = "DOUBLE SLASH", glyph = "X", color = {1, 0.3, 0.5},
        shape = "arc", reach = 22, dur = 0.24, cd = 0.35, dmg = 3, knock = 55, twin = true,
        desc = "Wide crossing arc. Big reach, two hits.",
    },
    beam = {
        name = "DATA BEAM", glyph = "=", color = {0.5, 1, 1},
        shape = "beam", reach = 84, dur = 0.20, cd = 0.40, dmg = 4, knock = 25,
        desc = "Long piercing beam. Hits a whole line.",
    },
    shockwave = {
        name = "SHOCKWAVE", glyph = "~", color = {0.4, 0.6, 1},
        shape = "radial", reach = 30, dur = 0.35, cd = 0.50, dmg = 3, knock = 140,
        desc = "Blast ring. Massive knockback, low damage.",
    },
    venom = {
        name = "VENOM BITE", glyph = "v", color = {0.4, 1, 0.3},
        shape = "arc", reach = 15, dur = 0.20, cd = 0.28, dmg = 2, knock = 20,
        dot = { dmg = 2, time = 3 },
        desc = "Poisons on hit. Damage ticks over time.",
    },
    ground_pound = {
        name = "GROUND POUND", glyph = "G", color = {0.8, 0.6, 0.2},
        shape = "radial", reach = 38, dur = 0.45, cd = 0.65, dmg = 6, knock = 160,
        desc = "Huge slow slam. Heavy damage + knockback.",
    },
    phase = {
        name = "PHASE STRIKE", glyph = "*", color = {0.7, 0.7, 1},
        shape = "arc", reach = 20, dur = 0.18, cd = 0.26, dmg = 3, knock = 35,
        desc = "Fast spectral jab. Cuts straight through.",
    },
    overclock = {
        name = "OVERCLOCK", glyph = "!", color = {1, 1, 0.4},
        shape = "beam", reach = 110, dur = 0.18, cd = 0.35, dmg = 6, knock = 45,
        desc = "Overcharged long beam. Top-tier damage.",
    },
}

Weapons.order = {
    "slash", "punch", "uppercut", "spin", "double_slash",
    "beam", "shockwave", "venom", "ground_pound", "phase", "overclock",
}

function Weapons.get(name) return Weapons.defs[name] end

return Weapons
