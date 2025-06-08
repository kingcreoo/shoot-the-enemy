-- // Level controller(Client), written by KingCreoo on 5-27-2025
-- // Controls the clients portion of the level:)

-- // Define module
local LevelController = {}
LevelController.__index = LevelController

-- // Services, modules, and variables

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayerScripts: PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local LocalPlayerModule = require(LocalPlayerScripts:WaitForChild("PlayerModule"))
local LocalPlayerControls = LocalPlayerModule:GetControls()
local Mouse = LocalPlayer:GetMouse()

local Animations = ReplicatedStorage:WaitForChild("Animations")
local BulletFolder = ReplicatedStorage:WaitForChild("Bullets")
local Bullets = workspace:WaitForChild("Bullets")

local Events = ReplicatedStorage:WaitForChild("Events")
local Functions = ReplicatedStorage:WaitForChild("Functions")

local RequestLogFunction: RemoteFunction = Functions:WaitForChild("RequestLog")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

local Lobby = workspace:WaitForChild("Lobby Build")

-- // Module functions

function LevelController.New(World: string, Level: string, Area: string)
    local self = setmetatable({}, LevelController)
    self.World = World
    self.Level = Level
    self.LevelModelString = Settings["LEVEL_DATA"][self.World][self.Level]["LevelModel"]
    self.Area = Area
    self.Orientation = Settings["LEVEL_DATA"][self.World][self.Level]["Orientation"]
    self.FireRate = 4

    return self
end

function LevelController:LoadScreen()
    -- Close all HUD items and frames & start loading screen
    CloseFrameBindable:Fire(nil, false, true)

    local LoadingScreen: Frame = LocalGui:WaitForChild("LoadingScreens"):WaitForChild(self.World)
    local Loadbar: ImageLabel = LoadingScreen:WaitForChild("Scrollbar"):WaitForChild("BackgroundLeft")

    task.spawn(function()
        LoadingScreen.Size = UDim2.new(0,0,0,0)
        LoadingScreen.Visible = true
        LoadingScreen:TweenSize(UDim2.new(1.2, 0, 1.2, 0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, .25)

        Loadbar.Size = UDim2.new(0.05, 0, 1, 0)
        Loadbar.Position = UDim2.new(0.025, 0, 0.5, 0)
        Loadbar:TweenSizeAndPosition(UDim2.new(1,0,1,0), UDim2.new(0.5,0,0.5,0), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 2)

    end)

    task.delay(2.5, function()
        local Elements = LoadingScreen:GetDescendants()
        table.insert(Elements, LoadingScreen)

        for _, Element in pairs(Elements) do
            if Element.ClassName == "Frame" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {BackgroundTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "TextLabel" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {TextTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "ImageLabel" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {ImageTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "UIStroke" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {Transparency = 1})
                FadeoutTween:Play()
            end
        end

        task.delay(1.05, function()
            LoadingScreen.Visible = false
            for _, Element in pairs(Elements) do
                if Element.ClassName == "Frame" then
                    Element.BackgroundTransparency = 0
                elseif Element.ClassName == "TextLabel" then
                    Element.TextTransparency = 0
                elseif Element.ClassName == "ImageLabel" then
                    Element.ImageTransparency = 0
                elseif Element.ClassName == "UIStroke" then
                    Element.Transparency = 0
                end
            end
        end)
    end)
end

function LevelController:Initialize()
    -- Disable player's controls
    LocalPlayerControls:Disable()

    -- Manage load screen
    self:LoadScreen()

    -- Generate & load level
    local Level = ReplicatedStorage:WaitForChild("Levels"):WaitForChild(self.World):WaitForChild(self.LevelModelString):Clone()
    Level:SetPrimaryPartCFrame(ReplicatedStorage:WaitForChild("PlayAreas"):WaitForChild(self.Area.Name).CFrame)
    Level.Name = "ActiveLevel"
    Level.Parent = workspace
    self.LevelModel = Level

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

            for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
                local NewBullet = BulletFolder:WaitForChild(self.Weapon):Clone()
                NewBullet.Position = Soldier:WaitForChild("Weapon"):WaitForChild("Fire").Position
                NewBullet.Orientation = NewBullet.Orientation + Vector3.new(0,90,0)
                NewBullet.Parent = Bullets
                local Tween = TweenService:Create(NewBullet, TweenInfo.new(Settings["WEAPON_DATA"][self.Weapon]["BulletSpeed"], Enum.EasingStyle.Linear), {Position = NewBullet.Position + Vector3.new(0, 0, 250)})
                Tween:Play()

                Tween.Completed:Connect(function()
                    if NewBullet then
                        NewBullet:Destroy()
                    end
                end)
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