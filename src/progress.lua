local Dungeons = require("src.dungeons.list")

local Progress = {
    currentDungeon = 1,
    inventory = {},     -- list of weapon names (unlocked, unordered storage)
    hotbar = {},        -- 9 slots; each is a weapon name or nil
    activeSlot = 1,
    kills = 0,
}

local function has(list, name)
    for _, n in ipairs(list) do if n == name then return true end end
    return false
end

function Progress.reset()
    Progress.currentDungeon = 1
    Progress.inventory = { "slash", "punch" }
    Progress.hotbar = { "slash", "punch", nil, nil, nil, nil, nil, nil, nil }
    Progress.activeSlot = 1
    Progress.kills = 0
end

function Progress.dungeon() return Dungeons[Progress.currentDungeon] end

function Progress.unlock(name)
    if not name or has(Progress.inventory, name) then return end
    table.insert(Progress.inventory, name)
    -- auto-place into first empty hotbar slot
    for i = 1, 9 do
        if not Progress.hotbar[i] then
            Progress.hotbar[i] = name
            return
        end
    end
end

function Progress.advance()
    local d = Dungeons[Progress.currentDungeon]
    if d and d.unlock and d.unlock ~= "dash" then
        Progress.unlock(d.unlock)
    end
    Progress.currentDungeon = Progress.currentDungeon + 1
    return Progress.currentDungeon <= #Dungeons
end

function Progress.activeWeapon() return Progress.hotbar[Progress.activeSlot] end

function Progress.selectSlot(i)
    if i >= 1 and i <= 9 then Progress.activeSlot = i end
end

function Progress.cycleSlot(dir)
    local n = Progress.activeSlot + dir
    if n < 1 then n = 9 end
    if n > 9 then n = 1 end
    Progress.activeSlot = n
end

function Progress.swapHotbar(a, b)
    Progress.hotbar[a], Progress.hotbar[b] = Progress.hotbar[b], Progress.hotbar[a]
end

function Progress.isFinal() return Progress.currentDungeon == #Dungeons end
function Progress.total() return #Dungeons end

return Progress
