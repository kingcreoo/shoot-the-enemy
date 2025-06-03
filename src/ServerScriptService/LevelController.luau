-- // LevelController written by KingCreoo on 5-27-2025
-- // Manages how the player progresses through a level

-- // Define module
local LevelController = {}
LevelController.__index = LevelController

-- // Services, variables, modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SETTINGS = require(ReplicatedStorage:WaitForChild("Settings"))

local PlayAreas = ReplicatedStorage:WaitForChild("PlayAreas")
local Limbo = workspace:WaitForChild("Limbo")

local Events = ReplicatedStorage:WaitForChild("Events")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local GenerateEvent: RemoteEvent = Events:WaitForChild("GenerateLevel")
local RequestLogFunction: RemoteFunction = Functions:WaitForChild("RequestLog")

-- // Local functions

local function SelectVacantPlayArea()
    local SelectedArea
    for _, Area in pairs(PlayAreas:GetChildren()) do
        if Area:GetAttribute("Occupied") == true then continue end

        Area:SetAttribute("Occupied", true)
        SelectedArea = Area
        break
    end

    return SelectedArea
end

-- // Module functions
function LevelController.Create(Player: Player, World: string, Level: string)
    local self = setmetatable({}, LevelController)
    self.Player = Player
    self.World = World
    self.Level = Level

    return self
end

function LevelController:Initialize()
    print(self.Player.Name .. " is starting " .. self.World .. " " .. self.Level .. "!")

    --Select available area
    self.Area = SelectVacantPlayArea()

    -- Communicate to client that level is starting
    GenerateEvent:FireClient(self.Player, self.World, self.Level, self.Area)

    -- Teleport player to limbo
    task.delay(1, function()
        self.Player.Character:SetPrimaryPartCFrame(Limbo:WaitForChild("Spawn").CFrame + Vector3.new(0,5,0))
    end)
end

-- // Return module
return LevelController