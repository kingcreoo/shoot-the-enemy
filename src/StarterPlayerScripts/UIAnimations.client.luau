local TweenService = game:GetService("TweenService")
-- // UI animations, written by KingCreoo on 5-26-2025
-- // Handles UI animations :)

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting: Lighting = game:GetService("Lighting")

-- Bindables for cross-script UI control
local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local GameLoadedBindable: BindableEvent = Bindables:WaitForChild("GameLoaded")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")
local CloseHUDBindable: BindableEvent = Bindables:WaitForChild("CloseHUD")

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Screen-wide blur toggle when frames open
local GUIBlur: BlurEffect = Lighting:WaitForChild("GUIBlur")
local BlurOn = false

-- Tween preset used whenever a frame opens
local OpenInfo = TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

-- Emoji list for rotating store icon
local StoreEmojis = {
    "rbxassetid://104230400329278",
    "rbxassetid://115845499094871",
    "rbxassetid://131785217527372",
    "rbxassetid://98869560137662",
    "rbxassetid://137193933072710"
}

-- // Defining our GUI
local HUD: ScreenGui = LocalGui:WaitForChild("HUD")
local FramesGui: ScreenGui = LocalGui:WaitForChild("Frames")

local TactileWorldFrame: Frame = FramesGui:WaitForChild("TactileWorld")

-- HUD containers / buttons
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

-- Groupings for animation routines
local HUDElements = {CodesButton, SettingsButton, OpsContainer, SkinsContainer, UpgradesContainer, QuestsContainer, StoreContainer, GemContainer, GoldContainer}
local HUDButtonsOscillation = {CodesButton, SettingsButton, OpsContainer, SkinsContainer, UpgradesContainer, QuestsContainer}
local HUDButtonsPulse = {StoreContainer}
local HUDButtonsSideOscillation = {GoldContainer, GemContainer}

local HUDOpen = nil                               -- true/false/nil for HUD visibility

local Frames = {["TactileWorld"] = TactileWorldFrame}
local ActiveFrame = nil                           -- currently open pop-up frame

-- // Functions

-- Pulls current currency values into HUD labels
local function UpdateStats()
    GoldContainer:WaitForChild("TextLabel").Text = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Gold").Value
    GemContainer:WaitForChild("TextLabel").Text = LocalPlayer:WaitForChild("leaderstats"):WaitForChild("Gems").Value
end

-- Sequentially pops each HUD element (slow version used after load)
local function OpenHUD()
    for _, Element in pairs(HUDElements) do
        Element.Size = UDim2.new(0,0,0,0)
    end

    HUD.Enabled = true
    HUDOpen = true

    for _, Element in pairs(HUDElements) do
        task.spawn(function()
            local PopTween = TweenService:Create(Element, TweenInfo.new(.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Element:GetAttribute("Size")})
            PopTween:Play()
        end)

        task.wait(.2)
        continue
    end
end

-- Faster version for reopening HUD after closing a frame
local function OpenHUDFast()
    for _, Element in pairs(HUDElements) do
        Element.Size = UDim2.new(0,0,0,0)
    end

    HUD.Enabled = true
    HUDOpen = true

    for _, Element in pairs(HUDElements) do
        task.spawn(function()
            local PopTween = TweenService:Create(Element, TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Element:GetAttribute("Size")})
            PopTween:Play()
        end)

        task.wait(.075)
        continue
    end
end

-- Shrinks all HUD buttons out before hiding
local function CloseHUD()
    HUDOpen = false

    for _, Element in pairs(HUDElements) do
        task.spawn(function()
            local SuckTween = TweenService:Create(Element, TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,0)})
            SuckTween:Play()
        end)

        task.wait(.075)
        continue
    end
end

-- Closes whichever frame is active (or a specific one) + optional HUD/blur control
local function CloseFrame(FrameString: string, ForceClose: boolean, ToCloseHUD: boolean)
    local FrameToClose
    if FrameString then
        FrameToClose = Frames[FrameString]
    else
        FrameToClose = ActiveFrame
    end

    ActiveFrame = nil

    local CloseTween = TweenService:Create(FrameToClose, OpenInfo, {Size = UDim2.new(0,0,0,0)})
    CloseTween:Play()

    CloseTween.Completed:Connect(function()
        FrameToClose.Visible = false
    end)

    if not HUDOpen and ToCloseHUD == false then
        task.spawn(function()
            OpenHUDFast()
        end)
    end

    if ToCloseHUD then
        CloseHUD()
    end

    if BlurOn then
        if ForceClose == true then return end

        local BlurTween = TweenService:Create(GUIBlur, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = 0})
        BlurTween:Play()
        BlurTween.Completed:Connect(function()
            BlurOn = false
            GUIBlur.Enabled = false
        end)
    end
end

-- Opens a named frame with blur + optional HUD closing
local function OpenFrame(FrameString: string, ToCloseHUD: boolean, Force: boolean)
    if ActiveFrame ~= nil and not Force then return end
    if ActiveFrame == FrameString then return end

    if ActiveFrame ~= nil then
        CloseFrame(ActiveFrame, true)
        task.wait(.2)
    end

    if not BlurOn then
        BlurOn = true
        GUIBlur.Enabled = true
        local BlurTween = TweenService:Create(GUIBlur, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = 24})
        BlurTween:Play()
    end

    if ToCloseHUD then
        if not HUDOpen then return end
        task.spawn(function()
            CloseHUD()
        end)
        task.wait(.05)
    end

    local Frame = Frames[FrameString]
    ActiveFrame = Frame

    Frame.Size = UDim2.new(0,0,0,0)
    Frame.Visible = true

    local OpenTween = TweenService:Create(Frame, OpenInfo, {Size = Frame:GetAttribute("Size")})
    OpenTween:Play()
end

-- // Animations
-- Hover oscillation for main HUD buttons
for _, Target in pairs(HUDButtonsOscillation) do
    -- Size and rotation tweens set up once per button
    local OriginalSize = Target.Size
    local HoverSize = OriginalSize + UDim2.new(0, 10, 0, 10)
    local SizeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local GrowTween = TweenService:Create(Target, SizeTweenInfo, {Size = HoverSize})
    local ShrinkTween = TweenService:Create(Target, SizeTweenInfo, {Size = OriginalSize})

    -- Rotation oscillation setup
    local RotationAmplitude = 8
    local RotationTime = .75
    local CurrentTween = nil
    local IsHovering = false

    -- Starts endless left-right rotation
    local function StartOscillation()
        local Direction = 1

        local FirstTween = TweenService:Create(Target, TweenInfo.new(RotationTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = RotationAmplitude})

        FirstTween.Completed:Connect(function()
            if IsHovering then
                Direction = -1
                local function CreateOscillationTween()
                    local TargetRotation = RotationAmplitude * Direction
                    local Tween = TweenService:Create(Target, TweenInfo.new(RotationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = TargetRotation})

                    Tween.Completed:Connect(function()
                        if IsHovering then
                            Direction *= -1
                            CurrentTween = CreateOscillationTween()
                            CurrentTween:Play()
                        end
                    end)
                    return Tween
                end
                CurrentTween = CreateOscillationTween()
                CurrentTween:Play()
            end
        end)

        CurrentTween = FirstTween
        FirstTween:Play()
    end

    local function StopOscillation()
        IsHovering = false
        if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
        TweenService:Create(Target, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0}):Play()
    end

    -- Hover events
    Target.MouseEnter:Connect(function()
        if IsHovering then return end
        IsHovering = true
        GrowTween:Play()
        StartOscillation()
    end)
    Target.MouseLeave:Connect(function()
        ShrinkTween:Play()
        StopOscillation()
    end)
end

-- Side oscillation for gold / gem counters
for _, SelectTarget in pairs(HUDButtonsSideOscillation) do
    local Target: ImageLabel = SelectTarget:WaitForChild("Icon")

    local OriginalSize = Target.Size
    local HoverSize = OriginalSize + UDim2.new(0, 10, 0, 10)
    local SizeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local GrowTween = TweenService:Create(Target, SizeTweenInfo, {Size = HoverSize})
    local ShrinkTween = TweenService:Create(Target, SizeTweenInfo, {Size = OriginalSize})

    local RotationAmplitude = 8
    local RotationTime = .75
    local CurrentTween = nil
    local IsHovering = false

    local function StartOscillation()
        local Direction = 1
        local FirstTween = TweenService:Create(Target, TweenInfo.new(RotationTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = RotationAmplitude})

        FirstTween.Completed:Connect(function()
            if IsHovering then
                Direction = -1
                local function CreateOscillationTween()
                    local TargetRotation = RotationAmplitude * Direction
                    local Tween = TweenService:Create(Target, TweenInfo.new(RotationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Rotation = TargetRotation})

                    Tween.Completed:Connect(function()
                        if IsHovering then
                            Direction *= -1
                            CurrentTween = CreateOscillationTween()
                            CurrentTween:Play()
                        end
                    end)
                    return Tween
                end
                CurrentTween = CreateOscillationTween()
                CurrentTween:Play()
            end
        end)

        CurrentTween = FirstTween
        FirstTween:Play()
    end

    local function StopOscillation()
        IsHovering = false
        if CurrentTween then CurrentTween:Cancel() CurrentTween = nil end
        TweenService:Create(Target, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0}):Play()
    end

    -- Hover events
    SelectTarget.MouseEnter:Connect(function()
        if IsHovering then return end
        IsHovering = true
        GrowTween:Play()
        StartOscillation()
    end)
    SelectTarget.MouseLeave:Connect(function()
        ShrinkTween:Play()
        StopOscillation()
    end)
end

-- Pulse animation for store button
for _, Target in pairs(HUDButtonsPulse) do
    -- Original size recorded as scale for responsive UIs
    local OriginalScaleX, OriginalScaleY = 0.15, 0.15
    local OriginalSize = UDim2.new(OriginalScaleX, 0, OriginalScaleY, 0)
    local PulseSize = UDim2.new(OriginalScaleX, 10, OriginalScaleY, 10)

    local PulseTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local ShrinkTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local PulseTween, ShrinkTween, IsHovering = nil, nil, false

    local function StartPulse()
        if PulseTween then PulseTween:Cancel() end
        PulseTween = TweenService:Create(Target, PulseTweenInfo, {Size = PulseSize})
        PulseTween:Play()
    end
    local function StopPulse()
        if PulseTween then PulseTween:Cancel() PulseTween = nil end
        if ShrinkTween then ShrinkTween:Cancel() end
        ShrinkTween = TweenService:Create(Target, ShrinkTweenInfo, {Size = OriginalSize})
        ShrinkTween:Play()
    end

    Target.MouseEnter:Connect(function()
        if IsHovering then return end
        IsHovering = true
        StartPulse()
    end)
    Target.MouseLeave:Connect(function()
        IsHovering = false
        StopPulse()
    end)
end

-- Rotates store icon through emoji list every ~20 s
task.spawn(function()
    local Index = 2
    while true do
        TweenService:Create(StoreContainer:WaitForChild("ImageLabel"), TweenInfo.new(1.5), {ImageTransparency = 1}):Play()
        task.wait(1.5)

        StoreContainer:WaitForChild("ImageLabel").Image = StoreEmojis[Index]
        TweenService:Create(StoreContainer:WaitForChild("ImageLabel"), TweenInfo.new(1.5), {ImageTransparency = 0}):Play()

        Index = Index % #StoreEmojis + 1
        task.wait(20)
    end
end)

-- Idle “pop” animation across all HUD buttons every 60 s
task.spawn(function()
    while true do
        task.wait(60)
        if not HUDOpen then continue end

        for _, Element in pairs(HUDElements) do
            task.wait(.15)
            local OriginSize = Element:GetAttribute("Size")
            local NewSize = OriginSize + UDim2.new(0,25,0,25)

            TweenService:Create(Element, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = NewSize}):Play()

            task.delay(.15, function()
                TweenService:Create(Element, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = OriginSize}):Play()
            end)
        end
    end
end)

-- // Events  & Handling
GameLoadedBindable.Event:Connect(OpenHUD)
OpenFrameBindable.Event:Connect(OpenFrame)
CloseFrameBindable.Event:Connect(CloseFrame)
CloseHUDBindable.Event:Connect(CloseHUD)

-- Re-render currency when leaderstat values change
for _, Value in pairs(LocalPlayer:WaitForChild("leaderstats"):GetChildren()) do
    Value.Changed:Connect(UpdateStats)
end

task.delay(1, UpdateStats)