-- // LOAD SCREEN HANDLER, written by KingCreoo on 5-26-2025
-- // Manages load screens for the level :)

-- // DEFINE
local LoadScreenHandler = {}

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local LocalGui = LocalPlayer:WaitForChild("PlayerGui")

local Bindables = ReplicatedStorage:WaitForChild("Bindables")
local CloseFrameBindable: BindableEvent = Bindables:WaitForChild("CloseFrame")

-- // Module functions

function LoadScreenHandler.LoadBeginningScreen(World: string)
    CloseFrameBindable:Fire(nil, false, true)

    local LoadingScreen: Frame = LocalGui:WaitForChild("LoadingScreens"):WaitForChild(World)
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
        local Elements = LoadingScreen:GetDescendants()
        table.insert(Elements, LoadingScreen)

        for _, Element in pairs(Elements) do
            if Element.ClassName == "Frame" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {BackgroundTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "TextLabel" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {TextTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "ImageLabel" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {ImageTransparency = 1})
                FadeoutTween:Play()
            elseif Element.ClassName == "UIStroke" then
                local FadeoutTween = TweenService:Create(Element, TweenInfo.new(1), {Transparency = 1})
                FadeoutTween:Play()
            end
        end

        task.delay(1.05, function()
            LoadingScreen.Visible = false
            for _, Element in pairs(Elements) do
                if Element.ClassName == "Frame" then
                    Element.BackgroundTransparency = 0
                elseif Element.ClassName == "TextLabel" then
                    Element.TextTransparency = 0
                elseif Element.ClassName == "ImageLabel" then
                    Element.ImageTransparency = 0
                elseif Element.ClassName == "UIStroke" then
                    Element.Transparency = 0
                end
            end
        end)
    end)
end

function LoadScreenHandler.LoadEndingScreen()

end

-- // RETURN
return LoadScreenHandler