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

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayerScripts: PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local LocalPlayerModule = require(LocalPlayerScripts:WaitForChild("PlayerModule"))
local LocalPlayerControls = LocalPlayerModule:GetControls()
local Mouse = LocalPlayer:GetMouse()

local SoldierModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Soldier"))

local LevelManagementEvents = ReplicatedStorage:WaitForChild("LevelManagement")
local StartLevelEvent: RemoteEvent = LevelManagementEvents:WaitForChild("Start")
local RequestDataFunction: RemoteFunction = LevelManagementEvents:WaitForChild("RequestData")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")
local CloseHUDBindable: BindableEvent = Bindables:WaitForChild("CloseHUD")

local Lobby = workspace:WaitForChild("Lobby Build")

-- // Module functions

function LevelController.New(World: string, Level: string, Area: string, StartEntities: table, Orientation: string)
    local self = setmetatable({}, LevelController)
    self.World = World
    self.Level = Level
    self.Area = Area
    self.StartEntities = StartEntities
    self.Orientation = Orientation

    return self
end

function LevelController:Initialize()
    -- Disable player's controls
    LocalPlayerControls:Disable()

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

    -- Generate & load level
    local Level = ReplicatedStorage:WaitForChild("Levels"):WaitForChild(self.World):WaitForChild(self.Level):Clone()
    Level:SetPrimaryPartCFrame(ReplicatedStorage:WaitForChild("PlayAreas"):WaitForChild(self.Area).CFrame)
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

    StartLevelEvent.OnClientEvent:Connect(function()
        self:Start()
    end)
end

function LevelController:AlignTeam()
    local SoldierNumber = 1
    for _, Soldier in pairs(self.Team) do
        Soldier:Align(self.Orientation[SoldierNumber])
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

    self.Team = {}

    -- Create soldier modules for each starting soldier
    for _ = 1, self.StartEntities["Team"] do
        local NewSoldier = SoldierModule.new()
        table.insert(self.Team, NewSoldier)
        NewSoldier:Create(self.TeamFolder, self.Skin, #self.Team+1)
    end

    self.AlignTeam()

    -- Start off the soldiers in there correct positions. Player controls will manage the positions after this segment vvv
    for _, Soldier in pairs(self.Team) do
        Soldier.Model:SetPrimaryPartCFrame(self.CenterPart.CFrame + Soldier.Model:GetAttribute("Offset"))
    end
end

function LevelController:Start()
    -- Generate controls
    self.Controls = RunService.RenderStepped:Connect(function()
        local MouseHit = Mouse.Hit

        -- Apply movement limits
        local TargetX = math.clamp(MouseHit.Position.X, (self.LevelModel.Start.Position.X - 20), (self.LevelModel.Start.Position.X + 20))

        for _, Soldier in pairs(self.TeamFolder:GetChildren()) do
            -- Lerp to the target position
            local SoldierTargetX = TargetX + Soldier:GetAttribute("Offset").X

            local TargetPosition = Soldier.PrimaryPart.Position
            TargetPosition = Vector3.new(
                TargetPosition.X + (SoldierTargetX - TargetPosition.X) * .1,
                TargetPosition.Y,
                TargetPosition.Z
            )

            --local SoldierPosition = TargetPosition + Soldier:GetAttribute("Offset")

            Soldier:SetPrimaryPartCFrame(CFrame.new(TargetPosition))
        end
    end)
end

-- // Return module
return LevelController