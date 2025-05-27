local TweenService = game:GetService("TweenService")
-- // Level selector, written by KingCreoo on 5-27-2025
-- // Manages the functionality for each level selector, right here in one script :)

-- // Define module
local LevelSelector = {}
LevelSelector.__index = LevelSelector

-- // Services, variables, modules

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayLevelEvent: RemoteEvent = Events:WaitForChild("PlayLevel")

-- // Module functions

function LevelSelector.new(Gui, LockedColor, ButtonImages)
    local self = setmetatable({}, LevelSelector)
    self.Gui = Gui
    self.Levels = self.Gui:WaitForChild("LevelsContainer"):WaitForChild("ScrollingFrame"):WaitForChild("Levels")
    self.Operators = self.Gui:WaitForChild("LevelsContainer"):WaitForChild("ScrollingFrame"):WaitForChild("Operators")

    self.Continue = self.Gui:WaitForChild("InfoContainer"):WaitForChild("Continue")
    self.DifficultyImage = self.Gui:WaitForChild("InfoContainer"):WaitForChild("DifficultyLabel"):WaitForChild("Image")
    self.LevelText = self.Gui:WaitForChild("InfoContainer"):WaitForChild("LevelLabel"):WaitForChild("TextLabel")

    self.PlaySceneImage = self.Gui:WaitForChild("InfoContainer"):WaitForChild("PlayScene")
    
    self.LockedColor = LockedColor
    self.ButtonImages = ButtonImages

    return self
end

function LevelSelector:Update(PlayerData: table)
    for Level, Completed in pairs(PlayerData["Worlds"][self.Gui.Name:gsub("World", "")]) do
        if Level == "Level1" then
            self.Levels:WaitForChild(Level).ImageColor3 = Color3.fromRGB(255, 255, 255)
            self.Levels:WaitForChild(Level):WaitForChild("Lock").Visible = false

            if Completed == 0 and PlayerData["Worlds"][self.Gui.Name:gsub("World", "")]["Level2"] == 0 then
                self:Select(Level)
            end

            continue
        elseif Completed == 0 then
            local LevelNumber = tonumber(Level:match('%d+'))
            local PreviousLevel = "Level" .. tostring(LevelNumber-1)

            if PlayerData["Worlds"][self.Gui.Name:gsub("World", "")][PreviousLevel] == 1 then
                self.Levels:WaitForChild(Level).ImageColor3 = Color3.fromRGB(255, 255, 255)
                self.Levels:WaitForChild(Level):WaitForChild("Lock").Visible = false

                self:Select(Level)
            else
                self.Levels:WaitForChild(Level).ImageColor3 = self.LockedColor
                self.Levels:WaitForChild(Level):WaitForChild("Lock").Visible = true
            end
        elseif Completed == 1 then
            self.Levels:WaitForChild(Level).ImageColor3 = Color3.fromRGB(255, 255, 255)
            self.Levels:WaitForChild(Level):WaitForChild("Lock").Visible = false
        end
    end
end

function LevelSelector:Select(SelectedLevel: string)
    self.SelectedLevel = SelectedLevel
    self.LevelText.Text = SelectedLevel:gsub("(%a+)(%d+)", "%1 %2")
    -- TODO set difficulty icon
    -- TODO set play scene image

    for _, Level: ImageLabel in pairs(self.Levels:GetChildren()) do
        local SelectedTween = Level:FindFirstChild("SelectedTween")
        if SelectedTween then
            SelectedTween:Destroy()
        end
    end

    local SelectedTween = TweenService:Create(self.Levels:WaitForChild(SelectedLevel), TweenInfo.new(.75, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.new(.25,0,.25,0)})
    SelectedTween.Parent = self.Levels:WaitForChild(SelectedLevel)
    SelectedTween:Play()
end

function LevelSelector:WatchDog()
    for _, LevelButton in pairs(self.Levels:GetChildren()) do
        LevelButton.MouseButton1Click:Connect(function()
            -- TODO Select this level, write code later
        end)
    end

    self.Continue.MouseButton1Click:Connect(function()
        PlayLevelEvent:FireServer(self.Gui.Name, self.SelectedLevel)
    end)
end

-- // Return module
return LevelSelector