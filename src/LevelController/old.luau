-- // Level controller(Client), written by KingCreoo on 5-27-2025
-- // Controls the clients portion of the level:)

-- // Define module
local LevelController = {}
LevelController.__index = LevelController

-- // Services, modules, and variables

-- Child modules
local BulletModule = require(script.BulletHandler)
local ExplosionModule = require(script.ExplosionHandler)
local LoadScreenHandler = require(script.LoadScreenHandler)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local LocalPlayer = Players.LocalPlayer
local LocalPlayerScripts: PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local LocalPlayerModule = require(LocalPlayerScripts:WaitForChild("PlayerModule"))
local LocalPlayerControls = LocalPlayerModule:GetControls()
local Mouse = LocalPlayer:GetMouse()

local Animations = ReplicatedStorage:WaitForChild("Animations")
local BulletFolder = ReplicatedStorage:WaitForChild("Bullets")
local Bullets = workspace:WaitForChild("Bullets")

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

function LevelController:Initialize()
    -- Disable player's controls
    LocalPlayerControls:Disable()

    -- Manage load screen
    LoadScreenHandler.LoadBeginningScreen(self.World)

    -- Generate & load level
    local Level = ReplicatedStorage:WaitForChild("Levels"):WaitForChild(self.World):WaitForChild(self.LevelModelString):Clone()
    Level:SetPrimaryPartCFrame(ReplicatedStorage:WaitForChild("PlayAreas"):WaitForChild(self.Area.Name).CFrame)
    Level.Name = "ActiveLevel"
    Level.Parent = workspace
    self.LevelModel = Level

    -- Generate bullet & explosion handlers
    self.BulletHandler = BulletModule.new()
    self.ExplosionHandler = ExplosionModule.new()

    -- Generate & load player's team (but don't enable controls yet)
    self:GenerateTeam()

    -- Deload lobby
    Lobby.Parent = ReplicatedStorage

    -- Change player's camera
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = Level:WaitForChild("CameraReference").CFrame

    -- Generate enemy manager
    self.EnemyManager = self:EnemyManager(Settings["LEVEL_DATA"][self.World][self.Level]["EnemySpawnSequence"])

    -- Start countdown

    -- Generate controls
    self.Controls = self:Controls()

    -- Generate bullet manager
    self.BulletManager = self:BulletManager()
end

function LevelController:RemoveSoldier(SoldierToRemove)
    SoldierToRemove:Destroy()
end

function LevelController:AddSoldier()
    local Soldier = ReplicatedStorage:WaitForChild("Skins"):WaitForChild(self.Skin):Clone()
    Soldier:SetAttribute("Offset", self.Orientation[#self.TeamFolder:GetChildren()+1])
    Soldier:SetPrimaryPartCFrame((self.CenterPart.CFrame + self.Orientation[#self.TeamFolder:GetChildren()+1]) * CFrame.Angles(0, math.rad(180), 0))
    Soldier.Parent = self.TeamFolder
end

function LevelController:Equip(Weapon: string)
    self.Weapon = Weapon
    for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
        local OldWeapon = Soldier:FindFirstChild("Weapon")
        if OldWeapon then
            OldWeapon:Destroy()
        end

        local Animator: Animator = Soldier:WaitForChild("AnimationController"):WaitForChild("Animator")
        local PlayingAnimations = Animator:GetPlayingAnimationTracks()
        for _, Animation in pairs(PlayingAnimations) do
            if Animation.Name:match("Idle$") then
                Animation:Stop()
            end
        end

        local NewWeapon = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild(Weapon):Clone()
        NewWeapon.Parent = Soldier
        NewWeapon.Name = "Weapon"
        local Handle = NewWeapon:WaitForChild("Handle")
        local Joint = Instance.new("Motor6D")
        Joint.Parent = Handle
        Joint.Part0 = Soldier:WaitForChild("Right Arm")
        Joint.Part1 = Handle

        Joint.C0 = Settings["WEAPON_DATA"][Weapon]["C0"]
        Joint.C1 = Settings["WEAPON_DATA"][Weapon]["C1"]

        local IdleAnimation = Animations:WaitForChild(Weapon .. "Idle")
        local Track = Animator:LoadAnimation(IdleAnimation)
        Track:Play()
    end
end

function LevelController:AlignTeam()
    local SoldierNumber = 1
    for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
        Soldier:SetAttribute("Offset", self.Orientation[SoldierNumber])
        Soldier:SetPrimaryPartCFrame((self.CenterPart.CFrame + Soldier:GetAttribute("Offset")) * CFrame.Angles(0, math.rad(180), 0))
        SoldierNumber += 1
    end
end

function LevelController:GenerateTeam()
    -- TODO generate selected skin & operator
    self.Skin = --[[SelectedSkin]] "Default"

    -- Create a center part that soldiers will move based off of
    local CenterPart = Instance.new("Part")
    CenterPart.Transparency = 1
    CenterPart.Anchored = true
    CenterPart.CFrame = self.LevelModel:WaitForChild("Start").CFrame
    CenterPart.Name = "CenterPart"
    CenterPart.Parent = self.LevelModel
    self.CenterPart = CenterPart

    -- Create a folder to hold each soldier's model
    local TeamFolder = Instance.new("Folder")
    TeamFolder.Name = "ActiveTeam"
    TeamFolder.Parent = self.LevelModel
    self.TeamFolder = TeamFolder

    -- Create a folder to hold each enemy's model
    local EnemyFolder = Instance.new("Folder")
    EnemyFolder.Name = "Enemies"
    EnemyFolder.Parent = self.LevelModel
    self.EnemyFolder = EnemyFolder

    -- Create soldiers
    for _ = 1, Settings["LEVEL_DATA"][self.World][self.Level]["StartTeam"] do
        self:AddSoldier()
    end

    -- Equip the default weapon (m4)
    self:Equip("M4")

    -- Align the team before the player's loading screen ends
    self:AlignTeam()
end

function LevelController:BulletManager()
    task.spawn(function()
        while true do
            task.wait(1/Settings["WEAPON_DATA"][self.Weapon]["Firerate"])

            local RaycastParameters = RaycastParams.new()
            RaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
            RaycastParameters.IgnoreWater = true

            for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
                -- Get the bullet's origin time and position
                local FireTime = os.time()
                local OriginPosition = Soldier:WaitForChild("Weapon"):WaitForChild("Fire").Position
                local EndPosition = OriginPosition + Vector3.new(0,0,200)
                local Direction = (EndPosition - OriginPosition).Unit

                -- Create and tween the bullet in physical space
                local NewBullet = BulletFolder:WaitForChild(self.Weapon):Clone()
                NewBullet.Position = OriginPosition
                NewBullet.Orientation = NewBullet.Orientation + Vector3.new(0,90,0)
                NewBullet.Parent = Bullets
                local Tween = TweenService:Create(NewBullet, TweenInfo.new(Settings["WEAPON_DATA"][self.Weapon]["BulletSpeed"], Enum.EasingStyle.Linear), {Position = NewBullet.Position + Vector3.new(0, 0, 200)})
                Tween:Play()
                Tween.Completed:Connect(function()
                    if NewBullet then
                        NewBullet:Destroy()
                    end
                end)

                -- Fire calculation raycast
                RaycastParameters.FilterDescendantsInstances = {Soldier, NewBullet}

                local ToBreak
                repeat
                    -- Cast & get result
                    print('cast')
                    local Result = Workspace:Raycast(OriginPosition, Direction, RaycastParameters)

                    if Result then
                        print(Result.Name)
                    end

                    -- If no result, there is nothing else in the bullet's path, so we break the loop
                    if not Result then
                        ToBreak = true
                        break
                    end

                    -- If the result isn't in the enemies folder, then continue to the next item in the bullets path (and add this reuslt to the ignore list)
                    if not Result:IsAncestorOf(self.EnemyFolder) then
                        table.insert(RaycastParameters.FilterDescendantsInstances, Result.Parent)
                        continue
                    end

                    -- If the enemy is due to die, then we see if there may be another item in the bullets path after this enemy
                    local Enemy = FindAncestorWithAnimationController(Result)
                    if not Enemy then
                        table.insert(RaycastParameters.FilterDescendantsInstances, Result)
                        continue
                    end
                    if table.find(self.DueDeaths, Enemy) then
                        table.insert(RaycastParameters.FilterDescendantsInstances, Result.Parent)
                        continue
                    end

                    --
                    -- OK, this result is an enemy and is not due to die
                    --

                    -- Calculate when the bullet will be due
                    local EnemyDistance = math.abs(Result.Position.X - OriginPosition.X)
                    local BulletSpeed = 200/Settings["WEAPON_DATA"][self.Weapon]["BulletSpeed"]
                    local EnemySpeed = 200/Settings["ENEMY_DATA"][Enemy:GetAttribute("TYPE")]["MarchSpeed"]

                    local ClosingSpeed = BulletSpeed + EnemySpeed

                    local BulletTravelTime = EnemyDistance / ClosingSpeed
                    local DueTime = FireTime + BulletTravelTime

                    -- Add bullet to the enemy's due bullet list
                    if self.DueBullets[Enemy] then
                        table.insert(self.DueBullets[Enemy], {DueTime, Settings["WEAPON_DATA"][self.Weapon]["Damage"]})
                    else
                        self.DueBullets[Enemy] = {}
                        table.insert(self.DueBullets[Enemy], {DueTime, Settings["WEAPON_DATA"][self.Weapon]["Damage"]})
                    end

                    -- Check if enemy is due to die considering this bullet's damage. If so, add enemy to due deaths list
                    local TotalDamage = 0
                    for _, BulletTable: table in pairs(self.DueBullets[Enemy]) do
                        TotalDamage += BulletTable[2]
                    end
                    if TotalDamage >= Settings["ENEMY_DATA"][Enemy:GetAttribute("TYPE")]["Health"] then
                        table.insert(self.DueDeaths, Enemy)
                    end

                    -- At the due time, bullet explodes & enemy receives damage
                    task.delay(BulletTravelTime, function()
                        -- Bullet explosion animation
                        self.ExplosionHandler:Create("Standard", Result.Position, Color3.fromRGB(255, 30, 0))
                        self.ExplosionHandler:Create("Standard", Result.Position, Color3.fromRGB(255, 179, 0))

                        -- Enemy receives damage
                        local Health: IntValue = Enemy:WaitForChild("Health")
                        Health.Value = Health.Value - Settings["WEAPON_DATA"][self.Weapon]["Damage"]
                    end)

                until ToBreak

            end
        end
    end)
end

function LevelController:EnemyManager(EnemySequence: table)
    for _, EnemyTable in pairs(EnemySequence) do
        task.delay(EnemyTable[2],function()
            local EnemyController = require(ReplicatedStorage:WaitForChild("Settings"):WaitForChild(EnemyTable[1])).new(self.LevelModel, EnemyTable[3])
            EnemyController:Spawn()
            EnemyController:March()
        end)
    end
end

function LevelController:Controls()
    RunService.RenderStepped:Connect(function()
        -- Get mouse position
        local MouseHit = Mouse.Hit

        -- Apply movement limits
        local TargetX = math.clamp(MouseHit.Position.X, (self.LevelModel.Start.Position.X - 20), (self.LevelModel.Start.Position.X + 20))

        for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
            -- Lerp to the target position
            local SoldierTargetX = (TargetX + Soldier:GetAttribute("Offset").X)

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

-- // Return module
return LevelController