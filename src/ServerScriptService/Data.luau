-- // Data, created by KingCreoo on 5-27-2025
-- // Manages loading & saving the player's data

-- // Define module
local Data = {}

-- // Services, Modules, & Variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local DataStore = DataStoreService:GetDataStore("DataStore1")

local Database = {}
local Saves = {}

-- // Local functions

-- Deep-clone a table so DEFAULT_DATA isn’t mutated
local function DeepCopy(Table: table)
    local Copy = {}

    for k, v in pairs(Table) do
        if type(v) == table then
            DeepCopy(v) -- recursion on nested tables
        else
            Copy[k] = v
        end
    end

    return Copy
end


-- // Module functions

-- Handle gathering player's data upon joining the game
function Data.Initialize(Player: Player)
    local PlayerData
    local NewPlayer

    local Success, ErrorMessage = pcall(function()
        PlayerData = DataStore:GetAsync("Player_" .. Players:GetUserIdFromNameAsync(Player.Name))
    end)

    if not Success then
        warn(ErrorMessage)
        -- TODO warn player that there data has loaded improperly
    end

    if not PlayerData then
        PlayerData = DeepCopy(Settings.DEFAULT_DATA)
        NewPlayer = true
    end

    Database[Player.Name] = PlayerData

    return PlayerData, NewPlayer    -- second return value indicates fresh profile
end

-- Handle setting player's data after changes
function Data.Set(Player: Player, PlayerData: table)
    Database[Player.Name] = PlayerData

    -- Sync leaderboard folder for UI
    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        for Stat, Value in pairs(PlayerData["leaderstats"]) do
            leaderstats:WaitForChild(Stat).Value = Value
        end
    end

    -- Write-frequency guard: only set to save if >60 s since last write
    local TimeOfTransaction = os.time()
    local ToSave

    if not Saves[Player.Name] then
        ToSave = true
    else
        if Saves[Player.Name] - TimeOfTransaction > 60 then
            ToSave = true
        end
    end

    if not ToSave then return end

    Saves[Player.Name] = TimeOfTransaction

    local Success, ErrorMessage = pcall(function()
        DataStore:SetAsync("Player_" .. Player:GetUserIdFromNameAsync(Player.Name), PlayerData)
    end)

    if not Success then
        warn(ErrorMessage)
        -- TODO warn player that their data has stored improperly
    end
end

-- Returns player's data from the database
function Data.Get(Player: Player)
    return Database[Player.Name]
end

-- Removes player's data from the database
function Data.Remove(Player: Player)
    local PlayerData = DeepCopy(Database[Player.Name])
    print('Removing ' .. Player.Name .. ". Their data:")
    print(PlayerData)
    Database[Player.Name] = nil

    local Success, ErrorMessage = pcall(function()
        DataStore:SetAsync("Player_" .. Players:GetUserIdFromNameAsync(Player.Name), PlayerData)
    end)

    if not Success then
        warn(ErrorMessage)
        -- TODO warn player that their data has stored improperly
    end
end

-- // Return module
return Data