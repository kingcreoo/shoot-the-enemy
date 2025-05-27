-- // UI handler, written by KingCreoo on 5-27-2025
-- // Handles UI functionality and behavior

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

local Events = ReplicatedStorage:WaitForChild("Events")
local LevelCompletedEvent: RemoteEvent = Events:WaitForChild("LevelCompleted")

local Functions = ReplicatedStorage:WaitForChild("Functions")
local RequestDataFunction: RemoteFunction = Functions:WaitForChild("RequestData")

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local FramesGui: ScreenGui = LocalGui:WaitForChild("Frames")

local LevelSelectorModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("LevelSelector"))

local TactileWorldFrame = FramesGui:WaitForChild("TactileWorld")

-- // Images & Colors

local TactileWorldButtons = {
    ["Standard"] = "rbxassetid://121503023134117",
    ["StandardHover"] = "rbxassetid://113739377729984",
    ["StandardPressed"] = "rbxassetid://105104597491258",
    ["Selected"] = "rbxassetid://96946769649554",
    ["SelectedHover"] = "rbxassetid://136641707482901",
    ["SelectedPressed"] = "rbxassetid://82028027894172"
}
local TactileWorldUnselectedModifier = Color3.fromRGB(72, 139, 159)

-- // Level selector functionality
local TactileWorldLS = LevelSelectorModule.new(TactileWorldFrame, TactileWorldUnselectedModifier, TactileWorldButtons)
local LevelSelectors = {TactileWorldLS}

-- // Event handling

-- When the player completes a level, the server will fire the client and send along player data. We will update each of the world's selectors to match the new data.
LevelCompletedEvent.OnClientEvent:Connect(function(PlayerData: table)
    for _, World in pairs(LevelSelectors) do
        World:Update(PlayerData)
    end
end)

-- At client birth, request data from the server so we can match each selector with the player's data.
task.delay(1, function()
    local PlayerData: table = RequestDataFunction:InvokeServer()
    for _, World in pairs(LevelSelectors) do
        World:Update(PlayerData)
    end
end)

for _, World in pairs(LevelSelectors) do
    World:WatchDog()
end