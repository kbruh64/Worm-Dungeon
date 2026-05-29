local Dungeons = require("src.dungeons.list")
local Weapons = require("src.weapons")

local Progress = {
    currentDungeon = 1,
    weapons = {},          -- ordered list of unlocked weapon names
    equipped = "slash",    -- currently active weapon
    dmgBonus = 0,
    maxHpBonus = 0,
    speedBonus = 0,
    kills = 0,
}

local function has(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

function Progress.reset()
    Progress.currentDungeon = 1
    Progress.weapons = { "slash", "punch" }
    Progress.equipped = "slash"
    Progress.dmgBonus = 0
    Progress.maxHpBonus = 0
    Progress.speedBonus = 0
    Progress.kills = 0
end

function Progress.dungeon() return Dungeons[Progress.currentDungeon] end
function Progress.isFinal() return Progress.currentDungeon == #Dungeons end
function Progress.total() return #Dungeons end

function Progress.unlock(name)
    if not name or has(Progress.weapons, name) then return false end
    table.insert(Progress.weapons, name)
    Progress.equipped = name
    return true
end

function Progress.equip(name)
    if has(Progress.weapons, name) then Progress.equipped = name end
end

function Progress.cycleWeapon(dir)
    local i = 1
    for idx, n in ipairs(Progress.weapons) do
        if n == Progress.equipped then i = idx; break end
    end
    i = i + dir
    if i < 1 then i = #Progress.weapons end
    if i > #Progress.weapons then i = 1 end
    Progress.equipped = Progress.weapons[i]
end

function Progress.advance() Progress.currentDungeon = Progress.currentDungeon + 1; return Progress.currentDungeon <= #Dungeons end

-- ---- roguelike rewards ----

local STAT_REWARDS = {
    { kind = "hp",    label = "+25 MAX HP",    apply = function() Progress.maxHpBonus = Progress.maxHpBonus + 25 end },
    { kind = "heal",  label = "FULL HEAL",     apply = function() Progress._wantHeal = true end },
    { kind = "dmg",   label = "+1 DAMAGE",     apply = function() Progress.dmgBonus = Progress.dmgBonus + 1 end },
    { kind = "speed", label = "+10% SPEED",    apply = function() Progress.speedBonus = Progress.speedBonus + 0.1 end },
}

function Progress.rollRewards()
    -- Always offer 3 choices; mix weapons (if available) with stat upgrades.
    local locked = {}
    for _, name in ipairs(Weapons.order) do
        if not has(Progress.weapons, name) then table.insert(locked, name) end
    end

    local choices = {}
    if #locked > 0 then
        local pick = locked[math.random(1, #locked)]
        table.insert(choices, { kind = "weapon", weapon = pick, label = "NEW: " .. string.upper(pick) })
    end
    while #choices < 3 do
        local r = STAT_REWARDS[math.random(1, #STAT_REWARDS)]
        local dup = false
        for _, c in ipairs(choices) do if c.kind == r.kind then dup = true end end
        if not dup then
            table.insert(choices, { kind = r.kind, label = r.label, apply = r.apply })
        end
    end
    return choices
end

function Progress.takeReward(reward)
    if reward.kind == "weapon" then
        Progress.unlock(reward.weapon)
    elseif reward.apply then
        reward.apply()
    end
end

function Progress.consumeHealRequest()
    if Progress._wantHeal then Progress._wantHeal = false; return true end
    return false
end

return Progress
