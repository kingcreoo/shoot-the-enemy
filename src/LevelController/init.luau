-- // LevelController (VERSION II), written by KingCreoo on 5-28-2025
-- // Controls logic of the level while being aided by child modules

-- // DEFINE
local LevelController = {}
LevelController.__index = LevelController

-- // Services, modules, and variables

-- Child modules
local EnemyRegistryModule = require(script.EnemyRegistry)
local EntityHandler = require(script.EntityHandler)
local LoadScreenHandler = require(script.LoadScreenHandler)
local TeamHandler = require(script.TeamHandler)

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Settings
local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

-- Cached player data
local LocalPlayer = Players.LocalPlayer
local LocalPlayerScripts: PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local LocalPlayerModule = require(LocalPlayerScripts:WaitForChild("PlayerModule"))
local LocalPlayerControls = LocalPlayerModule:GetControls()
local Mouse = LocalPlayer:GetMouse()

-- Variables
local Functions = ReplicatedStorage:WaitForChild("Functions")
local RequestLogFunction: RemoteFunction = Functions:WaitForChild("RequestLog")

local Lobby = workspace:WaitForChild("Lobby Build")

-- // Local functions

local function FindAncestorWithAnimationController(Instance)
	while Instance do
		if Instance:FindFirstChildOfClass("AnimationController") then
			return Instance
		end
		Instance = Instance.Parent
	end
	return nil
end

-- // Module functions

-- Constructor
function LevelController.new(World: string, Level: string, Area: string)
    local self = setmetatable({}, LevelController)
    self.World = World
    self.Level = Level
    self.LevelModelString = Settings["LEVEL_DATA"][self.World][self.Level]["LevelModel"]
    self.Area = Area
    self.Orientation = Settings["LEVEL_DATA"][self.World][self.Level]["Orientation"]
    self.DueDeaths = {}
    self.DueBullets = {}

    return self
end

-- Set up level
function LevelController:Initialize()
    --1) Disable player's controls
    LocalPlayerControls:Disable()

    --2) Manage load screen (3 seconds)
    LoadScreenHandler.LoadBeginningScreen(self.World)

    --3) Generate & load level
    local Level = ReplicatedStorage:WaitForChild("Levels"):WaitForChild(self.World):WaitForChild(self.LevelModelString):Clone()
    Level:SetPrimaryPartCFrame(ReplicatedStorage:WaitForChild("PlayAreas"):WaitForChild(self.Area.Name).CFrame)
    Level.Name = "ActiveLevel"
    Level.Parent = workspace
    self.LevelModel = Level
    local EnemyFolder = Instance.new("Folder")
    EnemyFolder.Name   = "Enemies"
    EnemyFolder.Parent = self.LevelModel

    --4) Generate handlers
    self.EntityHandler = EntityHandler.new(Settings["LEVEL_DATA"][self.World][self.Level]["EntityTypes"])
    self.TeamHandler, self.TeamFolder = TeamHandler.new(self.World, self.Level, self.LevelModel, "Default") -- Set skin here later
    self.EnemyRegistry = EnemyRegistryModule.new(self.World, self.Level, self.LevelModel)

    --5) Deload lobby
    Lobby.Parent = ReplicatedStorage

    --6) Change player's camera
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = Level:WaitForChild("CameraReference").CFrame

    --7) Generate controls
    self.Controls = self:Controls()

    --8) Start countdown (3 seconds)
    --skip for now

    --9) Generate bullet manager
    self.BulletManager = self:BulletManager()
end

-- Activate controls
function LevelController:Controls()
    RunService.RenderStepped:Connect(function()
        -- Get mouse position
        local MouseHit = Mouse.Hit

        -- Apply movement limits
        local TargetX = math.clamp(MouseHit.Position.X, (self.LevelModel.Start.Position.X - 20), (self.LevelModel.Start.Position.X + 20))

        for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
            -- Lerp to the target position
            local SoldierTargetX = (TargetX + self.TeamHandler:GetSoldierOffset(Soldier).X)

            local TargetPosition = Soldier.PrimaryPart.Position
            TargetPosition = Vector3.new(
                TargetPosition.X + (SoldierTargetX - TargetPosition.X) * .1,
                TargetPosition.Y,
                TargetPosition.Z
            )

            Soldier:SetPrimaryPartCFrame(CFrame.new(TargetPosition) * CFrame.Angles(0, math.rad(180), 0))
        end
    end)
end

local function CalculateActions(StartTime, ActionLoop)
    -- Get the current time, and time elapsed since the unit spawned
    local CurrentTime = os.time()
    local TimeElapsed = CurrentTime - StartTime

    -- Walk the loop until we find the action we are on
    local LoopTimeElapsed = 0
    local CurrentAction
    local TimeRemaining
    local CurrentActionNum = 0
    for _, ActionTable in ipairs(ActionLoop) do
        CurrentActionNum += 1
        local ActionTime = ActionTable[2]
        LoopTimeElapsed += ActionTime

        if LoopTimeElapsed <= TimeElapsed then
            -- The unit is not on this action, because time has elapsed further down the loop
            continue
        elseif LoopTimeElapsed > TimeElapsed then
            -- The unit is on this action :)
            CurrentAction = ActionTable
            TimeRemaining = math.abs(TimeElapsed - LoopTimeElapsed)

            -- Break
            break
        end
    end

    -- Return the action the unit is on, the time elapsed, and time remaining on this current action
    return CurrentActionNum, CurrentAction, TimeElapsed, TimeRemaining
end

local function CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, TimeSinceFired, TimeRemaining, LevelDistance)
    local HitTime

    local CurrentSpeed = ((LevelDistance * CurrentAction[3]) / CurrentAction[2])
    local CurrentDistance = math.abs(OriginPosition.Z - Enemy.Z)
    local CurrentActionHitTime = CurrentDistance / (BulletSpeed + CurrentSpeed)
    if CurrentActionHitTime <= TimeRemaining then
        HitTime = CurrentActionHitTime + TimeSinceFired
    else
        local DistanceTravelled = (BulletSpeed + CurrentSpeed) * TimeRemaining

        local NewTimeSinceFired = TimeSinceFired + TimeRemaining
        local Direction = (Enemy.Z > OriginPosition.Z) and 1 or -1
        local NewZ = OriginPosition.Z + DistanceTravelled * Direction
        local NewOriginPosition = Vector3.new(OriginPosition.X, OriginPosition.Y, NewZ)

        HitTime = CalculateHitTime(NewOriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum+1, ActionLoop[CurrentActionNum+1], NewTimeSinceFired, ActionLoop[CurrentActionNum+1][2], LevelDistance)
    end

    return HitTime
end

local function SelectValidEnemies(EnemyTable, OriginPosition, BulletSpeed, LevelDistance)
    local ValidEnemies = {}
    for _, Enemy in pairs(EnemyTable) do
        -- If this enemy is due to die, then check the next enemy
        if table.find(DueDeaths, Enemy) then
            continue
        end

        -- We check if the bullet will hit the enemy
        if Enemy.Type == "Laneswapper" then
            --[[local EnemyModule = require(EnemyModules:WaitForChild(Enemy.Name))
            local ActionLoop = EnemyModule.ACTION_LOOP

            local CurrentActionNum, CurrentAction, _, TimeRemaining = CalculateActions(Enemy.StartTime, ActionLoop)

            local HitTime = CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, 0, TimeRemaining, LevelDistance)

            --]]
            print('todo later')
        else
            if math.abs(OriginPosition.X - Enemy.X) > Enemy.HitboxRadius then
                continue
            else
                table.insert(ValidEnemies, Enemy)
            end
        end
    end

    return ValidEnemies
end

local function SelectTarget(ValidEnemies, OriginPosition, BulletSpeed, LevelDistance)
    local Target, TargetHitTime = nil, math.huge
    for _, Enemy in pairs(ValidEnemies) do
        local EnemyModule = require(EnemyModules:WaitForChild(Enemy.Enemy.Name))
        local ActionLoop = EnemyModule.ACTION_LOOP
        local CurrentActionNum, CurrentAction, _, TimeRemaining = CalculateActions(Enemy.StartTime, ActionLoop)

        local HitTime = CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, 0, TimeRemaining, LevelDistance)

        if HitTime < TargetHitTime then
            Target = Enemy
            TargetHitTime = HitTime
        end
    end

    return Target, TargetHitTime
end

-- Manage bullets :)
function LevelController:BulletManager()

end

-- // RETURN
return LevelController