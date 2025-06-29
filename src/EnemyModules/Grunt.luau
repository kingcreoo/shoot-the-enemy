-- // Tactile squad enemy module written by KingCreoo on 2-6-2025

-- Tactile squad is a basic unit that spawns at the spawn areas naturally
-- Since tactile squad has multiple units, we loop through the main model to access them
-- Each unit inside the folder has an offset value

-- STATS
local HEALTH = 3
local WEAPON = "M4"

local ACTION_LOOP = {
    [1] = {"March", 22, 1}
}

-- ANIMATIONS
local WEAPON_ANIMATION = "M4Idle"
local MARCH_ANIMATION = "M4March"

-- // Define module
local Grunt = {}
Grunt.__index = Grunt

-- // Services, variables, and modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animations = ReplicatedStorage:WaitForChild("Animations")
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Module functions
function Grunt.new(Model: Model, LevelModel: Model, InfoTable: table)
    local self = setmetatable({}, Grunt)
    self.Model = Model
    self.LevelModel = LevelModel
    self.InfoTable = InfoTable

    self.Health = HEALTH
    self.Animator = self.Model:WaitForChild("AnimationController"):WaitForChild("Animator")

    return self
end

function Grunt:Spawn()
    --1) Position unit where it's to be spawned (in it's lane factory + it's unit offset)
    self.Model:SetPrimaryPartCFrame(self.LevelModel:WaitForChild("Spawn" .. tostring(self.InfoTable[3])).CFrame + self.InfoTable[4])

    --2) Set unit weapon and health
    local NewWeapon = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild(WEAPON):Clone()
    NewWeapon.Parent = self.Model
    NewWeapon.Name = "Weapon"
    local Handle = NewWeapon:WaitForChild("Handle")
    local Joint = Instance.new("Motor6D")
    Joint.Parent = Handle
    Joint.Part0 = self.Model:WaitForChild("Right Arm")
    Joint.Part1 = Handle

    Joint.C0 = Settings["WEAPON_DATA"][WEAPON]["C0"]
    Joint.C1 = Settings["WEAPON_DATA"][WEAPON]["C1"]

    local UnitHealth = Instance.new("IntValue")
    UnitHealth.Name = "Health"
    UnitHealth.Value = HEALTH
    UnitHealth.Parent = self.Model

    --3) Run spawn animation
    -- For now, just make the unit visible. We will create animations later
    self.Model.Parent = self.LevelModel:WaitForChild("Enemies")

    --4) After spawn animation, run ActionLoop
    self:ActionLoop()
end

function Grunt:ActionLoop()
    for Index, Table in ipairs(ACTION_LOOP) do
        if Table[1] == "March" then
            if Index == #ACTION_LOOP then
                self:March(true, Table[2], Table[3])
            else
                self:March(false, Table[2], Table[3])
            end
        end
    end
end

function Grunt:March(FinalMarch: boolean, Duration: number, FractionOfDistance: number)
    --1) Get animator & play the unit's marching track
    local MarchTrack = self.Animator:LoadAnimation(Animations:WaitForChild(MARCH_ANIMATION))
    MarchTrack:Play()

    --2) Play the weapon's marching track
    local WeaponTrack = self.Animator:LoadAnimation(Animations:WaitForChild(WEAPON_ANIMATION))
    WeaponTrack:Play()

    --3) Create and play a tween that moves the unit along
    local StartCFrame = self.Model.PrimaryPart.CFrame
    local GoalCFrame = self.LevelModel:FindFirstChild("Goal" .. tostring(self.InfoTable[3])).CFrame + self.InfoTable[4]                     -- lane offset
    local TargetCFrame = StartCFrame:Lerp(GoalCFrame, FractionOfDistance)

    local MarchTween = TweenService:Create(
        self.Model.PrimaryPart,
        TweenInfo.new(Duration, Enum.EasingStyle.Linear),
        { CFrame = TargetCFrame }
    )

    MarchTween:Play()

    --4) If the tween ends and this is a final march, we trigger the reach end function
    MarchTween.Completed:Connect(function()
        if FinalMarch then
            self:ReachEnd()
        end
    end)
end

function Grunt:ReachEnd()
    print("Unit has reached the end. Write heart decrements later.")
    self:Destroy()
end

function Grunt:TakeDamage(Damage: number)
    --1) Calculate whether unit will be alive after receiving damage
    if self.Health - Damage <= 0 then
        -- If no, then destroy the unit
        self:Destroy()
    else
        -- If yes, then subtract the damage from health and update UI(later)
        self.Health -= Damage
    end
end

function Grunt:Destroy()
    --1) Run death animation
    -- For now, just delete model
    if self.Destroyed then return end
    self.Destroyed = true

    -- TODO: play death FX / drop loot
    self.Model:Destroy()
end

-- // Return module
return Grunt