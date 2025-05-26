-- // Initialize, written by KingCreoo on 5-26-2025
-- // Manages the loading screen as player joins the game

-- // Services & Variables

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer

local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local PlayerControls = PlayerModule:GetControls()

local LocalGui = LocalPlayer.PlayerGui
local LoadingScreensGui: ScreenGui = LocalGui:WaitForChild("LoadingScreens")
local GameLoadingFrame: Frame = LoadingScreensGui:WaitForChild("GameLoad")

local ScrollBarFrame:Frame = GameLoadingFrame:WaitForChild("Scrollbar")
local Loadbar: ImageLabel = ScrollBarFrame:WaitForChild("BackgroundLeft")
local LoadText: TextLabel = GameLoadingFrame:WaitForChild("LoadingText")

local SkipButton: ImageButton = GameLoadingFrame:WaitForChild("Skip")
local ItemText: TextLabel = GameLoadingFrame:WaitForChild("ItemText")

local WorkspaceDescendants = workspace:GetDescendants()


local ElementsTable = GameLoadingFrame:GetDescendants()
table.insert(ElementsTable, GameLoadingFrame)

local FadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local Dots = {'.', '..', '...'}
local Index = 1

-- // Functionality

local TotalAssets = #WorkspaceDescendants
local LoadedAssets = 0
local Skipped = false

-- If player clicks skip, then set skipped to true and trigger early fade tween
SkipButton.MouseButton1Click:Connect(function()
	Skipped = true
end)

-- Enable custom loading screen & disable default loading screen
Loadbar.Size = UDim2.new(0.04, 0, 1, 0)
Loadbar.Position = UDim2.new(0,02, .5, 0)
GameLoadingFrame.Visible = true
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Animate loading text
task.spawn(function()
	while not Skipped and LoadedAssets < TotalAssets do
		LoadText.Text = "Loading" .. Dots[Index]
		Index = Index % #Dots + 1
		task.wait(0.4)
	end
end)

-- Disable player's controls
PlayerControls:Disable()

-- Start actual loading process
for _, Asset in ipairs(WorkspaceDescendants) do
	if Skipped then break end

	if Asset:IsA("Decal") or Asset:IsA("Texture") or Asset:IsA("Sound") or Asset:IsA("MeshPart") then
		pcall(function()
			ContentProvider:PreloadAsync({Asset})
		end)
	end

	LoadedAssets += 1
	ItemText.Text = string.format("%d / %d parts loaded", LoadedAssets, TotalAssets)

	local progress = math.clamp(LoadedAssets / TotalAssets, 0, 1)
	Loadbar:TweenSizeAndPosition(
		UDim2.new(0.04 + 0.96 * progress, 0, 1, 0),
		UDim2.new(0.02 + 0.48 * progress, 0, 0.5, 0),
		Enum.EasingDirection.InOut,
		Enum.EasingStyle.Quad,
		0.2,
		true
	)

	task.wait()
end

-- Re-enable player controls and fade away UI
PlayerControls:Enable()

for _, Element in pairs(ElementsTable) do
	if Element.ClassName == "TextLabel" then
		local FadeTween = TweenService:Create(Element, FadeInfo, {TextTransparency = 1})
		FadeTween:Play()
	elseif Element.ClassName == "Frame" then
		local FadeTween = TweenService:Create(Element, FadeInfo, {BackgroundTransparency = 1})
		FadeTween:Play()
	elseif Element.ClassName == "ImageLabel" or Element.ClassName == "ImageButton" then
		local FadeTween = TweenService:Create(Element, FadeInfo, {ImageTransparency = 1})
		FadeTween:Play()
    elseif Element.ClassName == "UIStroke" then
		local FadeTween = TweenService:Create(Element, FadeInfo, {Transparency = 1})
		FadeTween:Play()
	end
end