-- // Level controller(Client), written by KingCreoo on 5-27-2025
-- // Controls the clients portion of the level:)

-- // Define module
local LevelController = {}
LevelController.__index = LevelController

-- // Services, modules, and variables

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayerScripts: PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local LocalPlayerModule = require(LocalPlayerScripts:WaitForChild("PlayerModule"))
local LocalPlayerControls = LocalPlayerModule:GetControls()

local LevelManagementEvents = ReplicatedStorage:WaitForChild("LevelManagement")
local StartLevelEvent: RemoteEvent = LevelManagementEvents:WaitForChild("Start")
local RequestDataFunction: RemoteFunction = LevelManagementEvents:WaitForChild("RequestData")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")
local CloseHUDBindable: BindableEvent = Bindables:WaitForChild("CloseHUD")

local Lobby = workspace:WaitForChild("Lobby Build")

-- // Module functions

function LevelController.New(World: string, Level: string, Area: string, StartEntities: table)
    local self = setmetatable({}, LevelController)
    self.World = World
    self.Level = Level
    self.Area = Area
    self.StartEntities = StartEntities

    return self
end

function LevelController:Initialize()
    -- Disable player's controls
    LocalPlayerControls:Disable()

    -- Close all HUD items and frames & start loading screen
    CloseHUDBindable:Fire()
    CloseFrameBindable:Fire()

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
        local FadeoutTween = TweenService:Create(LoadingScreen, TweenInfo.new(1), {Transparency = 1})
        FadeoutTween:Play()

        FadeoutTween.Completed:Connect(function()
            LoadingScreen.Visible = false
        end)
    end)

    -- Generate & load level
    local Level = ReplicatedStorage:WaitForChild("Levels"):WaitForChild(self.World):WaitForChild(self.Level):Clone()
    Level:SetPrimaryPartCFrame(ReplicatedStorage:WaitForChild("PlayAreas"):WaitForChild(self.Area).CFrame)
    Level.Name = "ActiveLevel"
    Level.Parent = workspace

    -- Deload lobby
    Lobby.Parent = ReplicatedStorage

    -- Change player's camera

    StartLevelEvent.OnClientEvent:Connect(function()
        self:Start()
    end)
end

function LevelController:Start()
end

-- // Return module
return LevelController