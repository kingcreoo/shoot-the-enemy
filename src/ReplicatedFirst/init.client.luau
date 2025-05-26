-- // Initialize, written by KingCreoo on 5-26-2025
-- // Manages the loading screen as player joins the game

-- // Services & Variables

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local PlayerControls = PlayerModule:GetControls()

local LocalGui = LocalPlayer.PlayerGui
local LoadingScreensGui: ScreenGui = LocalGui:WaitForChild("LoadingScreens")
local GameLoadingFrame: Frame = LoadingScreensGui:WaitForChild("GameLoad")

local ScrollBarFrame:Frame = GameLoadingFrame:WaitForChild("Scrollbar")
local Loadbar: ImageLabel = ScrollBarFrame:WaitForChild("BackgroundLeft")
local BackgroundRight = ScrollBarFrame:WaitForChild("BackgroundRight")
local LoadText: TextLabel = GameLoadingFrame:WaitForChild("LoadingText")
local Frame = GameLoadingFrame:WaitForChild("Frame")
local TextLabel1 = GameLoadingFrame:WaitForChild("TextLabel1")
local TextLabel2 = GameLoadingFrame:WaitForChild("TextLabel2")
local Label = GameLoadingFrame:WaitForChild("Label")
local Shine = Label:WaitForChild("Shine")
local TextLabel = Label:WaitForChild("TextLabel")


local ElementsTable = {GameLoadingFrame, ScrollBarFrame, Loadbar, BackgroundRight, LoadText, Frame, TextLabel1, TextLabel2, Label, Shine, TextLabel}
for _, Halftone in pairs(Frame:WaitForChild("Halftones"):GetChildren()) do
    table.insert(ElementsTable, Halftone)
end

local FadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local Dots = {'.', '..', '...'}
local Index = 1

-- // Functionality

-- Enable custom loading screen & disable default loading screen
Loadbar.Size = UDim2.new(0.04, 0, 1, 0)
Loadbar.Position = UDim2.new(0,02, .5, 0)
GameLoadingFrame.Visible = true
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Disable player's controls
PlayerControls:Disable()

-- Play loading animation
local LoadbarTween: Tween = TweenService:Create(Loadbar, TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(1,0,1,0), Position = UDim2.new(.5, 0, .5, 0)})
LoadbarTween:Play()

-- Animate loading text
local StartTime = os.time()
repeat
    LoadText.Text = "Loading" .. Dots[Index]
    Index = Index % #Dots+1
    task.wait(.4)
until os.time() - StartTime >= 5

-- Re-enable player's controls
PlayerControls:Enable()

-- Play fade away animation
for _, Element in pairs(ElementsTable) do
    if Element.ClassName == "TextLabel" then
        local FadeTween = TweenService:Create(Element, FadeInfo, {TextTransparency = 1})
        FadeTween:Play()
        local FadeTween2 = TweenService:Create(Element:WaitForChild("UIStroke"), FadeInfo, {Transparency = 1})
        FadeTween2:Play()
    elseif Element.ClassName == "Frame" then
        local FadeTween = TweenService:Create(Element, FadeInfo, {BackgroundTransparency = 1})
        FadeTween:Play()
    elseif Element.ClassName == "ImageLabel" then
        local FadeTween = TweenService:Create(Element, FadeInfo, {ImageTransparency = 1})
        FadeTween:Play()
    end
end