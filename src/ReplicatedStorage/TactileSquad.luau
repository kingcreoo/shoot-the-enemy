-- // Tactile squad enemy module written by KingCreoo on 2-6-2025

-- Tactile squad is a basic unit that spawns at the spawn areas naturally
-- Since tactile squad has multiple units, we loop through the main model to access them
-- Each unit inside the folder has an offset value

-- // Define module
local TactileSquad = {}
TactileSquad.__index = TactileSquad

-- // Services, variables, and modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ReplicatedModel = ReplicatedStorage:WaitForChild("Enemies"):WaitForChild("TactileSquad")

-- // Module functions
function TactileSquad.new(LevelModel: Model, Column: number)
    local self = setmetatable({}, TactileSquad)
    self.Column = Column
    self.LevelModel = LevelModel

    return self
end

function TactileSquad:Spawn()
    -- No spawn animation necessary because this enemy spawns at the natural spawn points and crawls its way into the scene
    local Model = ReplicatedModel:Clone()
    self.Model = Model

    -- Create a unit table for easier reference
    self.Units = {}
    self.Units[1] = Model:WaitForChild("NHRs"):WaitForChild("1")
    self.Units[2] = Model:WaitForChild("NHRs"):WaitForChild("2")
    self.Units[3] = Model:WaitForChild("NHRs"):WaitForChild("3")

    -- Set positions of each unit
    self.Units[1]:SetPrimaryPartCFrame(self.LevelModel:WaitForChild("Spawn" .. tostring(self.Column)).CFrame)
    self.Units[2]:SetPrimaryPartCFrame(self.LevelModel:WaitForChild("Spawn" .. tostring(self.Column)).CFrame + Model:WaitForChild("NHRs"):WaitForChild("2"):GetAttribute("Offset"))
    self.Units[3]:SetPrimaryPartCFrame(self.LevelModel:WaitForChild("Spawn" .. tostring(self.Column)).CFrame + Model:WaitForChild("NHRs"):WaitForChild("3"):GetAttribute("Offset"))

    -- Set our model's parent into the workspace so that the units are visible
    self.Model.Parent = self.LevelModel:WaitForChild("Enemies")

    -- Return set of units to the level controller
    return self.Units
end

function TactileSquad:March()
    for _, Unit in pairs(self.Units) do
        local MarchTween = TweenService:Create(Unit.PrimaryPart, TweenInfo.new(10, Enum.EasingStyle.Linear), {CFrame = self.LevelModel:FindFirstChild("Goal" .. tostring(self.Column)).CFrame + Unit:GetAttribute("Offset")})
        MarchTween:Play()
    end
end

function TactileSquad:Damage()

end

function TactileSquad:Remove()

end

-- // Return module
return TactileSquad