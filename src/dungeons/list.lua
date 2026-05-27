-- Each dungeon: name, palette (bg, accent), enemy archetype, hp, count, unlock granted on clear.
-- Attacks granted in order: dash, uppercut, spin, beam, shockwave, etc.
local D = {}

local archetypes = {
    "bit",        -- weak, small
    "byte",       -- medium
    "packet",     -- fast
    "daemon",     -- ranged
    "firewall",   -- tanky
    "virus",      -- splits on death
    "kernel",     -- heavy hitter
    "root",       -- mini-boss
}

local unlocks = {
    [2]  = "dash",
    [4]  = "uppercut",
    [7]  = "spin",
    [10] = "beam",
    [13] = "shockwave",
    [16] = "double_slash",
    [19] = "venom",
    [22] = "ground_pound",
    [25] = "phase",
    [28] = "overclock",
}

for i = 1, 30 do
    local arch = archetypes[((i - 1) % #archetypes) + 1]
    local boss = (i % 5 == 0)
    D[i] = {
        name = string.format("SECTOR %02d", i),
        archetype = arch,
        enemyHp = 2 + math.floor(i * 0.6),
        enemyCount = boss and 1 or (3 + math.floor(i / 4)),
        boss = boss,
        unlock = unlocks[i],
        palette = {
            bg = { 0.04 + (i % 5) * 0.01, 0.05, 0.10 + (i % 7) * 0.01 },
            accent = { 0.2 + (i % 3) * 0.1, 0.8, 0.5 },
        },
    }
end

D[30].name = "THE COMPUTER"
D[30].enemyHp = 60
D[30].enemyCount = 1
D[30].boss = true

return D
