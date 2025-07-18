-- // Grunt enemy module written by KingCreoo on 7-5-2025

local TYPE = "Grunt"

-- // Define module
local Grunt = {}
Grunt.__index = Grunt

-- // Services, variables, and modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animations = ReplicatedStorage:WaitForChild("Animations")
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

-- // Module functions
-- Creates new Grunt enemy instance
function Grunt.new(Model: Model, LevelModel: Model, InfoTable: table)
    --1) Set metatable
    local self = setmetatable({}, Grunt)

    --2) Go about setting variables for later use
    self.Model = Model
    self.LevelModel = LevelModel
    self.InfoTable = InfoTable

    self.MovementMode = Settings["ENEMY_DATA"][TYPE]["MovementMode"]
    self.HitboxRadius = Settings["ENEMY_DATA"][TYPE]["HitboxRadius"]
    self.Health = Settings["ENEMY_DATA"][TYPE]["Health"]
    self.Weapon = Settings["ENEMY_DATA"][TYPE]["Weapon"]
    self.TotalDuration = Settings["ENEMY_DATA"][TYPE]["TotalDuration"]

    self.ACTION_LOOP = Settings["ENEMY_DATA"][TYPE]["ACTION_LOOP"]
    self.Animations = Settings["ENEMY_DATA"][TYPE]["Animations"]

    self.Animator = self.Model:WaitForChild("AnimationController"):WaitForChild("Animator")

    --3) Spawn the enemy at it's spawn time, and note spawn time/tick
    task.delay(InfoTable[2], function()
        self.StartTime = os.time()
        self.StartTick = tick()
        self:Spawn()
    end)
    
    return self
end

-- Spawns the enemy unit in the level
function Grunt:Spawn()
    --1) Position unit where it's to be spawned (in it's lane factory + it's unit offset)
    self.Model:SetPrimaryPartCFrame(self.LevelModel:WaitForChild("Spawn" .. tostring(self.InfoTable[3])).CFrame + self.InfoTable[4])

    --2) Set unit weapon and health
    local NewWeapon = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild(self.Weapon):Clone()
    NewWeapon.Parent = self.Model
    NewWeapon.Name = "Weapon"
    local Handle = NewWeapon:WaitForChild("Handle")
    local Joint = Instance.new("Motor6D")
    Joint.Parent = Handle
    Joint.Part0 = self.Model:WaitForChild("Right Arm")
    Joint.Part1 = Handle

    Joint.C0 = Settings["WEAPON_DATA"][self.Weapon]["C0"]
    Joint.C1 = Settings["WEAPON_DATA"][self.Weapon]["C1"]

    local UnitHealth = Instance.new("IntValue")
    UnitHealth.Name = "Health"
    UnitHealth.Value = self.Weapon
    UnitHealth.Parent = self.Model

    --3) Run spawn animation
    -- For now, just make the unit visible. We will create animations later
    self.Model.Parent = self.LevelModel:WaitForChild("Enemies")

    --4) After spawn animation, run ActionLoop
    self:ActionLoop()
end

-- Executes enemy's action sequence loop
function Grunt:ActionLoop()
    --) We loop through each of the actions in the action loop for this enemy
    for Index, Table in ipairs(self.ACTION_LOOP) do
        -- Index is the position the action is in the action loop, table is the table containing details for that action

        -- If the enemy has been killed, just return
        if self.Destroyed then
            return
        end
        if Table[1] == "March" then
            -- If this action is a march, then march the enemy!
            if Index == #self.ACTION_LOOP then
                -- If this march action is the last action in the loop, march with 'finalmarch' set to true
                self:March(true, Table[2], Table[3])
            else
                -- If not, then just march normally
                self:March(false, Table[2], Table[3])
            end
        end
    end
end

function Grunt:March(FinalMarch: boolean, Duration: number, FractionOfDistance: number)
    --0) If we're on the final march, then set the time remaining so that other modules can see
    if FinalMarch then
        self.FinalMarchTick = tick()
        self.FinalMarchDuration = Duration
    end

    --1) Get animator & play the unit's marching track
    local MarchTrack = self.Animator:LoadAnimation(Animations:WaitForChild(self.Animations["March"]))
    MarchTrack:Play()

    --2) Play the weapon's marching track
    local WeaponTrack = self.Animator:LoadAnimation(Animations:WaitForChild(self.Animations["Weapon"]))
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
        if FinalMarch and not self.Destroyed then
            self:ReachEnd()
        end
    end)
end

-- Handles enemy reaching the end of the level
function Grunt:ReachEnd()
    print("Unit has reached the end. Write heart decrements later.")
    self:Destroy()
end

-- Applies damage to enemy and returns death status
function Grunt:TakeDamage(Damage: number)
    --1) Calculate whether unit will be alive after receiving damage
    if self.Health - Damage <= 0 then
        -- If no, then destroy the unit
        self:Destroy()

        return true
    else
        -- If yes, then subtract the damage from health and update UI(later)
        self.Health -= Damage

        return false
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

-- Returns enemy's relevant data for external systems
function Grunt:GetData()
    -- Returns most relevant data about the enemy
    return self.InfoTable, self.StartTime, self.Health
end

-- // Return module
Grunt.TYPE = TYPE
Grunt.ACTION_LOOP = Settings["ENEMY_DATA"][TYPE]["ACTION_LOOP"]
return Grunt