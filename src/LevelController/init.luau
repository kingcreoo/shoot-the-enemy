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
local BulletHandler = require(script.BulletHandler)

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

local DueBullets = {}
local DueDeaths = {}

local Bullets = Workspace:WaitForChild("Bullets")
local Explosions = Workspace:WaitForChild("Explosions")

local EnemyModules = ReplicatedStorage:WaitForChild("EnemyModules")

-- // Module functions

-- Constructor
-- Creates a new level controller instance for managing level state and logic
function LevelController.new(World: string, Level: string, Area: string)
    local self = setmetatable({}, LevelController)
    self.World = World
    self.Level = Level
    self.LevelModelString = Settings["LEVEL_DATA"][self.World][self.Level]["LevelModel"]
    self.Area = Area
    self.Orientation = Settings["LEVEL_DATA"][self.World][self.Level]["Orientation"]

    return self
end

-- Set up level
-- Initializes the level by setting up environment, handlers, and starting systems
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
    self.Weapon = Settings["LEVEL_DATA"][self.World][self.Level]["StartWeapon"]
    self.Distance = (self.LevelModel:WaitForChild("Goal1").Position - self.LevelModel:WaitForChild("Spawn1").Position).Magnitude

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
    self.BulletManager = BulletHandler.new(self.EnemyRegistry, self.EntityHandler, self.TeamHandler, self.Distance)
end

-- Activate controls
-- Sets up mouse-based controls for player movement and soldier positioning
function LevelController:Controls()
    RunService.RenderStepped:Connect(function()
        -- Get mouse position
        local MouseHit = Mouse.Hit

        -- Apply movement limits
        local TargetX = math.clamp(MouseHit.Position.X, (self.LevelModel.Start.Position.X - 20), (self.LevelModel.Start.Position.X + 20))

        -- Lerp to the target position + their personal offset
        for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
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

-- // RETURN
return LevelController