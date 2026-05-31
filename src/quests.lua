-- Quests are the way to earn coins. Each one tracks a lifetime stat held in the
-- Profile (kills, sectors cleared, best combo, bosses beaten); once its target
-- is reached the reward is paid out exactly once. Quests are checked whenever
-- you return to the home page / shop and when a sector is cleared.
local Profile = require("src.profile")

local Quests = {}

local function statFor(metric)
    local s = Profile.data.stats
    if metric == "kills"    then return s.kills
    elseif metric == "dungeons" then return s.dungeons
    elseif metric == "boss" then return s.boss
    elseif metric == "combo" then return s.combo end
    return 0
end

Quests.list = {
    { id = "kill1",   name = "FIRST CONTACT", metric = "kills",    target = 1,   reward = 5,
      desc = "Defeat your first enemy." },
    { id = "kill25",  name = "PEST CONTROL",  metric = "kills",    target = 25,  reward = 15,
      desc = "Defeat 25 enemies." },
    { id = "kill100", name = "EXTERMINATOR",  metric = "kills",    target = 100, reward = 40,
      desc = "Defeat 100 enemies." },
    { id = "kill300", name = "SYSTEM PURGE",  metric = "kills",    target = 300, reward = 100,
      desc = "Defeat 300 enemies." },
    { id = "dun1",    name = "FIRST DESCENT", metric = "dungeons", target = 1,   reward = 10,
      desc = "Clear a sector." },
    { id = "dun5",    name = "DEEP DIVE",     metric = "dungeons", target = 5,   reward = 30,
      desc = "Clear 5 sectors." },
    { id = "dun15",   name = "SPELUNKER",     metric = "dungeons", target = 15,  reward = 75,
      desc = "Clear 15 sectors." },
    { id = "combo8",  name = "COMBO ARTIST",  metric = "combo",    target = 8,   reward = 20,
      desc = "Reach an 8-hit combo." },
    { id = "combo15", name = "UNTOUCHABLE",   metric = "combo",    target = 15,  reward = 50,
      desc = "Reach a 15-hit combo." },
    { id = "boss1",   name = "GIANT SLAYER",  metric = "boss",     target = 1,   reward = 25,
      desc = "Clear a boss sector." },
}

-- Current progress toward a quest, clamped to its target. Returns cur, target.
function Quests.progress(q)
    return math.min(statFor(q.metric), q.target), q.target
end

function Quests.isComplete(q) return statFor(q.metric) >= q.target end
function Quests.isClaimed(q)  return Profile.data.quests[q.id] == true end

-- Pay out coins for any newly-completed quests. Returns the list of quests that
-- were just claimed (so callers can show a "+coins" notification).
function Quests.check()
    local newly = {}
    for _, q in ipairs(Quests.list) do
        if not Quests.isClaimed(q) and Quests.isComplete(q) then
            Profile.data.quests[q.id] = true
            Profile.addCoins(q.reward)
            newly[#newly + 1] = q
        end
    end
    if #newly > 0 then Profile.save() end
    return newly
end

return Quests
