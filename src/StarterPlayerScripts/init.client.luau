-- // Client, written by KingCreoo on 5-26-2025
-- // Handles a variety of client events & communications

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelControllerModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("LevelController"))

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

local Events = ReplicatedStorage:WaitForChild("Events")

local GenerateEvent: RemoteEvent = Events:WaitForChild("GenerateLevel")

local ProximityPromptsFolder = workspace:WaitForChild("ProximityPrompts")
local TactileWorldProximityPrompt: ProximityPrompt = ProximityPromptsFolder:WaitForChild("TactileWorld"):WaitForChild("Prompt")

local ProximityPrompts = {TactileWorldProximityPrompt}
local PlayPromptDebounce = false

local CurrentLevel

-- // Functions
local function GenerateLevel(World: string, Level: string, Area: string)
    CurrentLevel = LevelControllerModule.new(World, Level, Area)
    CurrentLevel:Initialize()
end

local function OpenLevelSelector(WorldName: string)
    if PlayPromptDebounce then return end

    PlayPromptDebounce = true
    task.delay(2, function()
        PlayPromptDebounce = false
    end)

    OpenFrameBindable:Fire(WorldName, true)
end

local function CloseLevelSelector(WorldName: string)
    CloseFrameBindable:Fire(WorldName)
end

-- // Events
TactileWorldProximityPrompt.PromptShown:Connect(function()
    OpenLevelSelector("TactileWorld")
end)
TactileWorldProximityPrompt.PromptHidden:Connect(function()
    CloseLevelSelector("TactileWorld")
end)
GenerateEvent.OnClientEvent:Connect(GenerateLevel)