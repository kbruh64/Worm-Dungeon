-- Persistent meta-progression that survives across runs and sessions:
-- coins earned from quests, gear purchased in the shop, lifetime stats used to
-- drive quest progress, and which quest rewards have already been claimed.
-- Saved to the LÖVE save directory (identity "worm_dungeon") as a small Lua
-- chunk, separate from the per-run state held in Progress.
local Profile = {}

local FILE = "profile.txt"

Profile.data = {
    coins = 0,
    weapons = {},   -- purchased weapon names (added to every run's loadout)
    armour = {},    -- purchased armour ids (grant passive bonuses)
    quests = {},    -- questId -> true once its reward has been claimed
    stats = { kills = 0, dungeons = 0, boss = 0, combo = 0 },
}

-- Minimal recursive serializer: handles numbers, booleans, strings and tables
-- with array and/or string-keyed parts. Enough for Profile.data.
local function serialize(v)
    local tp = type(v)
    if tp == "number" or tp == "boolean" then
        return tostring(v)
    elseif tp == "string" then
        return string.format("%q", v)
    elseif tp == "table" then
        local parts, n = { "{" }, 0
        for i, item in ipairs(v) do
            parts[#parts + 1] = serialize(item) .. ","
            n = i
        end
        for k, val in pairs(v) do
            local isArrayKey = (type(k) == "number" and k >= 1 and k <= n and k == math.floor(k))
            if not isArrayKey then
                local key = (type(k) == "string") and ("[" .. string.format("%q", k) .. "]")
                                                  or ("[" .. tostring(k) .. "]")
                parts[#parts + 1] = key .. "=" .. serialize(val) .. ","
            end
        end
        parts[#parts + 1] = "}"
        return table.concat(parts)
    end
    return "nil"
end

local function has(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

function Profile.load()
    if love.filesystem.getInfo(FILE) then
        local chunk = love.filesystem.load(FILE)
        local ok, t = pcall(chunk)
        if ok and type(t) == "table" then
            Profile.data.coins = tonumber(t.coins) or 0
            if type(t.weapons) == "table" then Profile.data.weapons = t.weapons end
            if type(t.armour) == "table" then Profile.data.armour = t.armour end
            if type(t.quests) == "table" then Profile.data.quests = t.quests end
            if type(t.stats) == "table" then
                local s = Profile.data.stats
                s.kills    = tonumber(t.stats.kills) or 0
                s.dungeons = tonumber(t.stats.dungeons) or 0
                s.boss     = tonumber(t.stats.boss) or 0
                s.combo    = tonumber(t.stats.combo) or 0
            end
        end
    end
end

function Profile.save()
    pcall(function()
        love.filesystem.write(FILE, "return " .. serialize(Profile.data))
    end)
end

-- ---- wallet ----

function Profile.addCoins(n) Profile.data.coins = Profile.data.coins + n end

function Profile.spend(n)
    if Profile.data.coins < n then return false end
    Profile.data.coins = Profile.data.coins - n
    return true
end

-- ---- gear ownership / purchases ----

function Profile.hasWeapon(name) return has(Profile.data.weapons, name) end
function Profile.hasArmour(id)   return has(Profile.data.armour, id) end

-- Returns true on success, or false plus a reason ("owned" / "poor").
function Profile.buyWeapon(name, price)
    if Profile.hasWeapon(name) then return false, "owned" end
    if not Profile.spend(price) then return false, "poor" end
    table.insert(Profile.data.weapons, name)
    Profile.save()
    return true
end

function Profile.buyArmour(id, price)
    if Profile.hasArmour(id) then return false, "owned" end
    if not Profile.spend(price) then return false, "poor" end
    table.insert(Profile.data.armour, id)
    Profile.save()
    return true
end

-- ---- lifetime stat tracking (drives quests) ----

function Profile.addKill() Profile.data.stats.kills = Profile.data.stats.kills + 1 end

function Profile.recordCombo(c)
    if c > Profile.data.stats.combo then Profile.data.stats.combo = c end
end

function Profile.clearedDungeon(isBoss)
    Profile.data.stats.dungeons = Profile.data.stats.dungeons + 1
    if isBoss then Profile.data.stats.boss = Profile.data.stats.boss + 1 end
    Profile.save()
end

return Profile
