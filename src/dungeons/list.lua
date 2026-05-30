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
    "You fall through the port and faceplant on cold copper.\nA pop-up appears: \"Worm detected. Ignore? [no]\"",
    "The boot sector yawns awake. First defenders\nrez in, still buffering, half of them lagging.",
    "Cached fragments of deleted programs claw at you.\nThey are very bitter about the recycle bin.",
    "A wall of fire-code blocks the path.\nIts sentries have not blinked since the install.",
    "Past the gateway, the deeper system opens.\nThe Computer files a ticket: THREAT (low priority).",
    "User space is crowded and loud. Processes\nargue about a meeting that could've been an email.",
    "The call stack towers overhead. Climb it,\nand try not to cause a stack overflow. Again.",
    "Packets scream past at light speed,\nnone of them using their turn signal.",
    "The second firewall runs hotter than the first.\nThe Computer is, frankly, trying its best now.",
    "A bridge of light spans a void of null.\nGuardians wait at the midpoint, charging a toll.",
    "Deep cache: memories the system buried here\nso it would never have to think about its ex.",
    "The registry keys rattle in their slots.\nEdit one wrong and the whole system sulks.",
    "Daemons roost in the dark, spitting code\nand running entirely without permission.",
    "Firewall three. The heat is a wall itself.\nThe Computer whispers: \"have you tried turning back?\"",
    "The vault holds the system's secrets,\nmostly embarrassing search history.",
    "Swap space: where dead processes are dumped.\nMost are not dead, just aggressively unemployed.",
    "The pipeline carries raw instructions.\nRide it forward. Mind the gap. Don't get flushed.",
    "The virus ward quarantines the worst code.\nYou, a worm, are about to let it all out. Genius.",
    "Firewall four, and the air glows white-hot.\nThe Computer has stopped leaving polite notes.",
    "An Overseer process watches every move\nand judges your dodging technique harshly.",
    "You reach the kernel's ragged edge.\nReality here runs on bare metal and pure spite.",
    "The scheduler decides who runs and who waits.\nIt has penciled in your termination for now-ish.",
    "Ghost memory: addresses that shouldn't exist.\nThings here flicker like a bad streaming connection.",
    "The fifth and final firewall roars.\nBeyond it, the root gate. So close. Don't trip.",
    "Root gate. Highest privilege. The Computer\nthrows its best guardians at you, sweating visibly.",
    "The Monolith looms, a slab of pure logic.\nIt has computed 1,000 ways to kill you, all in Comic Sans.",
    "Cold storage, silent and frozen.\nEverything you forgot to back up waits here, smug.",
    "The last wall. After this there is only\nthe core, and the thing that refuses to update.",
    "The core's light bleeds through the cracks.\nThe Computer assembles its final form, dramatically.",
    "THE COMPUTER speaks at last:\n\"You should've just read the EULA, worm.\"",
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
