-- // Client, written by KingCreoo on 5-26-2025
-- // Handles a variety of client events & communications

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

local ProximityPromptsFolder = workspace:WaitForChild("ProximityPrompts")
local TactileWorldProximityPrompt: ProximityPrompt = ProximityPromptsFolder:WaitForChild("TactileWorld"):WaitForChild("Prompt")

local ProximityPrompts = {TactileWorldProximityPrompt}
local PlayPromptDebounce = false

-- // Functions

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