-- // Server, written by KingCreoo on 5-26-2025
-- // Manages the server's basic code and communication

-- // Services, variables, and modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")

local SpawnsFolder = workspace:WaitForChild("Spawns")
local Spawns = SpawnsFolder:GetChildren()

-- // Functions

local function OnPlayerAdded(Player)
    local Spawned = false
    local Character = Player.Character or Player.CharacterAdded:Wait()

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

-- // Events & Handling
Players.PlayerAdded:Connect(OnPlayerAdded)