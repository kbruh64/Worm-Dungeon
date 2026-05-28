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

-- Per-sector story beats: the worm's descent through the machine.
local names = {
    "THE PORT", "BOOT SECTOR", "THE CACHE", "FIREWALL I", "THE GATEWAY",
    "USER SPACE", "THE STACK", "PACKET STORM", "FIREWALL II", "THE BRIDGE",
    "DEEP CACHE", "THE REGISTRY", "DAEMON NEST", "FIREWALL III", "THE VAULT",
    "SWAP SPACE", "THE PIPELINE", "VIRUS WARD", "FIREWALL IV", "THE OVERSEER",
    "KERNEL EDGE", "THE SCHEDULER", "GHOST MEMORY", "FIREWALL V", "ROOT GATE",
    "THE MONOLITH", "COLD STORAGE", "THE LAST WALL", "CORE APPROACH", "THE COMPUTER",
}

local stories = {
    "You fall through the port and land on cold copper.\nThe system has already noticed you.",
    "The boot sector hums awake. First defenders\nrez in around the intruder worm.",
    "Cached fragments of old programs claw at you.\nThey remember being deleted.",
    "A wall of fire-code blocks the path forward.\nIts sentries do not blink.",
    "Past the gateway, the deeper system opens.\nThe Computer logs your intrusion: THREAT.",
    "User space is crowded and loud. Processes\nscatter, then turn to swarm you.",
    "The call stack towers overhead. Climb it,\nand do not let them push you off.",
    "Packets scream past at light speed.\nDodge, or be torn into checksum errors.",
    "The second firewall burns hotter than the first.\nThe Computer is starting to try.",
    "A bridge of light spans a void of null.\nGuardians wait at the midpoint.",
    "Deep cache: memories the system buried here.\nThey do not want to be read.",
    "The registry keys rattle in their slots.\nEdit one wrong and they bite.",
    "Daemons roost in the dark, spitting code.\nThis nest must be cleared to pass.",
    "Firewall three. The heat is a wall itself.\nThe Computer whispers: turn back, worm.",
    "The vault holds the system's secrets.\nIts locks are made of teeth.",
    "Swap space: where dead processes are dumped.\nMany of them are not fully dead.",
    "The pipeline carries raw instructions.\nRide it forward. Don't get flushed.",
    "The virus ward quarantines the worst code.\nYou are about to let it out.",
    "Firewall four, and the air glows white-hot.\nThe Computer has stopped warning you.",
    "An Overseer process watches every move.\nDefeat it to blind the system's eye.",
    "You reach the kernel's ragged edge.\nReality here runs on bare metal.",
    "The scheduler decides who runs and who waits.\nIt has scheduled your termination.",
    "Ghost memory: addresses that shouldn't exist.\nThings here flicker between real and not.",
    "The fifth and final firewall roars.\nBeyond it, the root gate. Almost there.",
    "Root gate. Highest privilege. The Computer\nthrows its strongest guardians at you now.",
    "The Monolith looms, a slab of pure logic.\nIt computes a thousand ways to kill you.",
    "Cold storage, silent and frozen.\nEverything forgotten waits to be remembered.",
    "The last wall. After this there is only\nthe core, and the thing that lives in it.",
    "The core's light bleeds through the cracks.\nThe Computer assembles its final form.",
    "THE COMPUTER speaks at last:\n\"You should not have come this deep, worm.\"",
}

for i = 1, 30 do
    local arch = archetypes[((i - 1) % #archetypes) + 1]
    local boss = (i % 5 == 0)
    D[i] = {
        name = names[i] or string.format("SECTOR %02d", i),
        story = stories[i],
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

D[30].enemyHp = 60
D[30].enemyCount = 1
D[30].boss = true

return D
