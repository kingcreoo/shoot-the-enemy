-- // UI Handler, written by KingCreoo on 5-26-2025
-- // Handles UI :)

-- // Services, variables, modules

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting: Lighting = game:GetService("Lighting")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local GameLoadedBindable: BindableEvent = Bindables:WaitForChild("GameLoaded")
local OpenFrameBindable: BindableEvent = Bindables:WaitForChild("OpenFrame")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

local LocalPlayer = Players.LocalPlayer
local LocalGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUIBlur: BlurEffect = Lighting:WaitForChild("GUIBlur")
local BlurOn = false

local OpenInfo = TweenInfo.new(.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

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
local HUDButtonsOscillation = {CodesButton, SettingsButton, OpsContainer, SkinsContainer, UpgradesContainer, QuestsContainer}
local HUDButtonsPulse = {StoreContainer}
local HUDButtonsSideOscillation = {GoldContainer, GemContainer}

local HUDOpen = nil

local Frames = {["TactileWorld"] = TactileWorldFrame}
local ActiveFrame = nil

-- // Functions
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

local function CloseFrame(FrameString: string, ForceClose: boolean)
    local Frame = Frames[FrameString]

    ActiveFrame = nil

    local CloseTween = TweenService:Create(Frame, OpenInfo, {Size = UDim2.new(0,0,0,0)})
    CloseTween:Play()

    CloseTween.Completed:Connect(function()
        Frame.Visible = false
    end)

    if not HUDOpen then
        if ForceClose then return end

        task.spawn(function()
            OpenHUDFast()
        end)
    end

    if BlurOn then
        if ForceClose then return end

        local BlurTween = TweenService:Create(GUIBlur, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = 0})
        BlurTween:Play()
        BlurTween.Completed:Connect(function()
            BlurOn = false
            GUIBlur.Enabled = false
        end)
    end
end

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

    ActiveFrame = FrameString
    local Frame = Frames[FrameString]

    Frame.Size = UDim2.new(0,0,0,0)
    Frame.Visible = true

    local OpenTween = TweenService:Create(Frame, OpenInfo, {Size = Frame:GetAttribute("Size")})
    OpenTween:Play()
end

-- // Animations

-- Oscillation & enter animation
for _, Target in pairs(HUDButtonsOscillation) do
    -- Size settings
    local OriginalSize = Target.Size
    local HoverSize = OriginalSize + UDim2.new(0, 10, 0, 10)
    local SizeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local GrowTween = TweenService:Create(Target, SizeTweenInfo, {Size = HoverSize})
    local ShrinkTween = TweenService:Create(Target, SizeTweenInfo, {Size = OriginalSize})

    -- Rotation oscillation
    local RotationAmplitude = 8 -- degrees
    local RotationTime = .75   -- time per half swing
    local CurrentTween = nil
    local IsHovering = false

    local function StartOscillation()
        local Direction = 1

        local FirstTween = TweenService:Create(Target, TweenInfo.new(RotationTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Rotation = RotationAmplitude
        })

        FirstTween.Completed:Connect(function()
            if IsHovering then
                Direction = -1

                local function CreateOscillationTween()
                    local TargetRotation = RotationAmplitude * Direction
                    local Tween = TweenService:Create(Target, TweenInfo.new(RotationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Rotation = TargetRotation
                    })

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

        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end

        local ResetTween = TweenService:Create(Target, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0})
        ResetTween:Play()
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

-- Side oscillation & enter animation

for _, SelectTarget in pairs(HUDButtonsSideOscillation) do
    local Target: ImageLabel = SelectTarget:WaitForChild("Icon")

    -- Size settings
    local OriginalSize = Target.Size
    local HoverSize = OriginalSize + UDim2.new(0, 10, 0, 10)
    local SizeTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local GrowTween = TweenService:Create(Target, SizeTweenInfo, {Size = HoverSize})
    local ShrinkTween = TweenService:Create(Target, SizeTweenInfo, {Size = OriginalSize})

    -- Rotation oscillation
    local RotationAmplitude = 8 -- degrees
    local RotationTime = .75   -- time per half swing
    local CurrentTween = nil
    local IsHovering = false

    local function StartOscillation()
        local Direction = 1

        local FirstTween = TweenService:Create(Target, TweenInfo.new(RotationTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Rotation = RotationAmplitude
        })

        FirstTween.Completed:Connect(function()
            if IsHovering then
                Direction = -1

                local function CreateOscillationTween()
                    local TargetRotation = RotationAmplitude * Direction
                    local Tween = TweenService:Create(Target, TweenInfo.new(RotationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Rotation = TargetRotation
                    })

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

        if CurrentTween then
            CurrentTween:Cancel()
            CurrentTween = nil
        end

        local ResetTween = TweenService:Create(Target, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Rotation = 0})
        ResetTween:Play()
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

-- Pulse & enter animation
for _, Target in pairs(HUDButtonsPulse) do
    -- Original size (assuming original scale is 0.15 for X and Y, offset is 0)
    local OriginalScaleX = 0.15
    local OriginalScaleY = 0.15
    local OriginalSize = UDim2.new(OriginalScaleX, 0, OriginalScaleY, 0)

    -- Pulse size adds 10 pixels offset on both axes (you can adjust)
    local PulseSize = UDim2.new(OriginalScaleX, 10, OriginalScaleY, 10)

    local PulseTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local ShrinkTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local PulseTween = nil
    local ShrinkTween = nil
    local IsHovering = false

    local function StartPulse()
        if PulseTween then
            PulseTween:Cancel()
            PulseTween = nil
        end
        PulseTween = TweenService:Create(Target, PulseTweenInfo, {Size = PulseSize})
        PulseTween:Play()
    end

    local function StopPulse()
        if PulseTween then
            PulseTween:Cancel()
            PulseTween = nil
        end
        -- Start a smooth shrink tween back to original size
        if ShrinkTween then
            ShrinkTween:Cancel()
            ShrinkTween = nil
        end
        ShrinkTween = TweenService:Create(Target, ShrinkTweenInfo, {Size = OriginalSize})
        ShrinkTween:Play()
    end

    -- Hover events
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

-- Rotate icons for store animation
task.spawn(function()
    local Index = 2
    while true do
        TweenService:Create(StoreContainer:WaitForChild("ImageLabel"), TweenInfo.new(1.5), {ImageTransparency = 1}):Play()
        task.wait(1.5)

        StoreContainer:WaitForChild("ImageLabel").Image = StoreEmojis[Index]
        TweenService:Create(StoreContainer:WaitForChild("ImageLabel"), TweenInfo.new(1.5), {ImageTransparency = 0}):Play()

        Index = Index % #StoreEmojis +1
        task.wait(20)
    end
end)

-- Idle side menu animation
task.spawn(function()
    while true do
        for _, Element in pairs(HUDElements) do
            task.wait(.15)
            local OriginSize = Element:GetAttribute("Size")
            local NewSize = OriginSize + UDim2.new(0,25,0,25)

            local ScaleTween = TweenService:Create(Element, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = NewSize})
            ScaleTween:Play()

            task.delay(.15, function()
                local ReturnTween = TweenService:Create(Element, TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = OriginSize})
                ReturnTween:Play()
            end)

            continue
        end

        task.wait(60)
    end
end)

-- // Events  & Handling
GameLoadedBindable.Event:Connect(OpenHUD)
OpenFrameBindable.Event:Connect(OpenFrame)
CloseFrameBindable.Event:Connect(CloseFrame)