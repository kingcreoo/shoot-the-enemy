-- // Server, written by KingCreoo on 5-26-2025
-- // Manages the server's basic code and communication

-- // Services, variables, and modules
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService:WaitForChild("Server"):WaitForChild("Data"))

local Events = ReplicatedStorage:WaitForChild("Events")

local SpawnsFolder = workspace:WaitForChild("Spawns")
local Spawns = SpawnsFolder:GetChildren()

-- // Functions

local function InitializeData(Player: Player, PlayerData: table)
    local leaderstats = Instance.new("Folder")
    leaderstats.Parent = Player
    leaderstats.Name = "leaderstats"

    for Name, Value in pairs(PlayerData["leaderstats"]) do
        local String = type(Value) .. "Value"

        local Stat = Instance.new(string.upper(string.sub(String, 1, 1)) .. string.sub(String, 2, -1))
        Stat.Name = Name
        Stat.Value = Value
        Stat.Parent = leaderstats
    end
end

local function SelectSpawnPoint(Character)
    local Spawned = false

    -- Teleport player to an open spawn point
    for _, Spawn: Part in pairs(Spawns) do
        if Spawn:GetAttribute("Occupied") == true then continue end

        Character:SetPrimaryPartCFrame(Spawn.CFrame + Vector3.new(0, 5, 0))
        Spawned = true
        Spawn:SetAttribute("Occupied", true)

        -- Reset after 12 seconds in a separate thread
        task.delay(12, function()
            Spawn:SetAttribute("Occupied", false)
        end)

        -- Stop loop after spawning the player
        break
    end

    -- If no spawn points are available, then send to spawn 1
    if not Spawned then
        Character:SetPrimaryPartCFrame(SpawnsFolder:WaitForChild("Spawn1").CFrame + Vector3.new(0, 5, 0))
    end
end

local function OnPlayerAdded(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()

    -- Teleport player to a spawn point
    SelectSpawnPoint(Character)

    -- Handle loading player's data (or new player)
    local PlayerData, NewPlayer = Data.Initialize(Player)
    if NewPlayer then
        print(Player.Name .. " has joined the game. They are a new player. Their data has been initialized with default data.")
    else
        print(Player.Name .. " has joined the game. They are a returning player. Their data:")
        print(PlayerData)
    end

    -- Initialize player's leaderstats
    InitializeData(Player, PlayerData)
end

local function OnPlayerRemoving(Player)
    Data.Remove(Player)
end

-- // Events & Handling
Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)