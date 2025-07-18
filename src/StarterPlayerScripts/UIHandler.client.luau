-- // UI handler, written by KingCreoo on 5-27-2025
-- // Handles UI functionality and behavior

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- BindableEvents that open / close full-screen frames (shared with UIAnimations)
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

-- Networking
local Events = ReplicatedStorage:WaitForChild("Events")
local LevelCompletedEvent: RemoteEvent = Events:WaitForChild("LevelCompleted")

local Functions = ReplicatedStorage:WaitForChild("Functions")
local RequestDataFunction: RemoteFunction = Functions:WaitForChild("RequestData")

-- Local player GUI refs
local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local FramesGui: ScreenGui = LocalGui:WaitForChild("Frames")

-- Level selector class (client-side)
local LevelSelectorModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("LevelSelector"))
local TactileWorldFrame = FramesGui:WaitForChild("TactileWorld")

-- // Images & Colors
-- Button sprite sheet (standard / hover / pressed / selected variants)
local TactileWorldButtons = {
    ["Standard"] = "rbxassetid://121503023134117",
    ["StandardHover"] = "rbxassetid://113739377729984",
    ["StandardPressed"] = "rbxassetid://105104597491258",
    ["Selected"] = "rbxassetid://96946769649554",
    ["SelectedHover"] = "rbxassetid://136641707482901",
    ["SelectedPressed"] = "rbxassetid://82028027894172"
}
local TactileWorldUnselectedModifier = Color3.fromRGB(72, 139, 159) -- grey-out tint for locked levels

-- // Level selector functionality
local TactileWorldLS = LevelSelectorModule.new(TactileWorldFrame, TactileWorldUnselectedModifier, TactileWorldButtons)
local LevelSelectors = {TactileWorldLS}

-- // Event handling

-- Server fires when level ends → refresh buttons to reflect newly unlocked levels
LevelCompletedEvent.OnClientEvent:Connect(function(PlayerData: table)
    for _, World in pairs(LevelSelectors) do
        World:Update(PlayerData)
    end
end)

-- Initial data pull one second after client loads to populate selectors
task.delay(1, function()
    local PlayerData: table = RequestDataFunction:InvokeServer()
    for _, World in pairs(LevelSelectors) do
        World:Update(PlayerData)
    end
end)

-- Attach click handlers / watchdogs to each world selector
for _, World in pairs(LevelSelectors) do
    World:WatchDog()
end