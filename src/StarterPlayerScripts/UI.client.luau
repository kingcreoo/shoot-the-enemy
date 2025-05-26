-- // UI Handler, written by KingCreoo on 5-26-2025
-- // Handles UI :)

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local GameLoadedBindable: BindableEvent = Bindables:WaitForChild("GameLoaded")

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


-- // Defining our GUI
local HUD: ScreenGui = LocalGui:WaitForChild("HUD")

local StatsDisplay: Folder = HUD:WaitForChild("StatsDisplay")
local SideMenu: Folder = HUD:WaitForChild("SideMenu")
local BottomMenu: Folder = HUD:WaitForChild("BottomMenu")

local GoldContainer: Frame = StatsDisplay:WaitForChild("GoldContainer")
local GemContainer: Frame = StatsDisplay:WaitForChild("GemContainer")

local OpsContainer: Frame = SideMenu:WaitForChild("OpsContainer")
local QuestsContainer: Frame = SideMenu:WaitForChild("QuestsContainer")
local StoreContainer: Frame = SideMenu:WaitForChild("StoreContainer")
local SkinsContainer: Frame = SideMenu:WaitForChild("SkinsContainer")
local UpgradesContainer: Frame = SideMenu:WaitForChild("UpgradesContainer")

local SettingsButton: ImageButton = BottomMenu:WaitForChild("Settings")
local CodesButton: ImageButton = BottomMenu:WaitForChild("Codes")

local HUDElements = {CodesButton, SettingsButton, OpsContainer, SkinsContainer, UpgradesContainer, QuestsContainer, StoreContainer, GemContainer, GoldContainer}

-- // Functions
local function OpenHUD()
    for _, Element in pairs(HUDElements) do
        Element.Size = UDim2.new(0,0,0,0)
    end

    HUD.Enabled = true

    for _, Element in pairs(HUDElements) do
        task.spawn(function()
            local PopTween = TweenService:Create(Element, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Element:GetAttribute("Size")})
            PopTween:Play()
        end)

        task.wait(.2)
        continue
    end
end

-- // Events  & Handling
GameLoadedBindable.Event:Connect(OpenHUD)