-- // TEAM HANDLER, written by KingCreoo on 5-26-2025
-- // Manages all functions of the player's team :)

-- // DEFINE
local TeamHandler = {}
TeamHandler.__index = TeamHandler

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))
local Animations = ReplicatedStorage:WaitForChild("Animations")

-- // Local functions

-- Creates an invisible anchor part the formation can pivot around
local function CreateCenterPart(LevelModel)
    local CenterPart = Instance.new("Part")
    CenterPart.Size = Vector3.new(1, 1, 1)
    CenterPart.Transparency = 1
    CenterPart.Anchored = true
    CenterPart.CFrame = LevelModel:WaitForChild("Start").CFrame
    CenterPart.Name = "CenterPart"
    CenterPart.Parent = LevelModel

    return CenterPart
end

-- Clones the chosen skin into the level’s ActiveTeam folder
local function CreateSoldierModel(TeamFolder, Skin: string)
    local Soldier = ReplicatedStorage:WaitForChild("Skins"):WaitForChild(Skin):Clone()
    Soldier.Parent = TeamFolder
    return Soldier
end

-- // Module functions

-- Returns the X-Z offset vector for this soldier relative to CenterPart
function TeamHandler:GetSoldierOffset(Soldier)
    for Index, S in ipairs(self.Team) do
        if S == Soldier then
            return self.Orientations[Index]            -- ← match found
        end
    end
end

-- Creates a new soldier, equips weapon + idle anim, then snaps into formation
function TeamHandler:AddSoldier()
    --1) Create soldier and add to the team table
    local Soldier = CreateSoldierModel(self.TeamFolder, self.Skin)
    table.insert(self.Team, Soldier)
    local Index = #self.Team

    --2) Equip soldier's weapon & animate
    local NewWeapon = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild(self.Weapon):Clone()
    NewWeapon.Parent = Soldier
    NewWeapon.Name = "Weapon"
    local Handle = NewWeapon:WaitForChild("Handle")
    local Joint = Instance.new("Motor6D")
    Joint.Parent = Handle
    Joint.Part0 = Soldier:WaitForChild("Right Arm")
    Joint.Part1 = Handle

    -- C0/C1 offsets come straight from Settings.WEAPON_DATA
    Joint.C0 = Settings["WEAPON_DATA"][self.Weapon]["C0"]
    Joint.C1 = Settings["WEAPON_DATA"][self.Weapon]["C1"]

    -- Play idle animation matching the equipped weapon
    local Animator: Animator = Soldier:WaitForChild("AnimationController"):WaitForChild("Animator")
    local IdleAnimation = Animations:WaitForChild(self.Weapon .. "Idle")
    local Track = Animator:LoadAnimation(IdleAnimation)
    Track:Play()

    --3) Align soldier
    Soldier:SetPrimaryPartCFrame((self.CenterPart.CFrame + self.Orientations[Index]) * CFrame.Angles(0, math.rad(180), 0))
end

-- Removes a specific soldier instance from the team and destroys the model
function TeamHandler:RemoveSoldier(SoldierToRemove)
    for Index, Soldier in ipairs(self.Team) do
        if Soldier == SoldierToRemove then
            table.remove(self.Team, Index)
            break
        end
    end
    SoldierToRemove:Destroy()
end

-- Re-positions every soldier so spacing stays even after adds/removes
function TeamHandler:Align()
    for Index, Soldier in ipairs(self.Team) do
        local TargetCFrame = (self.CenterPart.CFrame + self.Orientations[Index]) * CFrame.Angles(0, math.rad(180), 0)

        local CurrentPosition = Soldier.PrimaryPart.Position
        local TargetPosition = TargetCFrame.Position

        if (CurrentPosition - TargetPosition).Magnitude > 0.001 then 
            Soldier:SetPrimaryPartCFrame(TargetCFrame)
            task.wait(.2)
        end
    end
end

-- Swaps every soldier to a new weapon and corresponding idle animation
function TeamHandler:Equip(NewWeapon: string)
    self.Weapon = NewWeapon
    for _, Soldier in ipairs(self.Team) do
        -- Destroy old weapon (if any)
        local OldWeapon = Soldier:FindFirstChild("Weapon")
        if OldWeapon then
            OldWeapon:Destroy()
        end

        -- Stop any existing idle tracks
        local Animator: Animator = Soldier:WaitForChild("AnimationController"):WaitForChild("Animator")
        local PlayingAnimations = Animator:GetPlayingAnimationTracks()
        for _, Animation in pairs(PlayingAnimations) do
            if Animation.Name:match("Idle$") then
                Animation:Stop()
            end
        end

        -- Attach the new weapon + idle animation
        local SoldierWeapon = ReplicatedStorage:WaitForChild("Weapons"):WaitForChild(self.Weapon):Clone()
        SoldierWeapon.Parent = Soldier
        SoldierWeapon.Name = "Weapon"
        local Handle = SoldierWeapon:WaitForChild("Handle")
        local Joint = Instance.new("Motor6D")
        Joint.Parent = Handle
        Joint.Part0 = Soldier:WaitForChild("Right Arm")
        Joint.Part1 = Handle

        Joint.C0 = Settings["WEAPON_DATA"][self.Weapon]["C0"]
        Joint.C1 = Settings["WEAPON_DATA"][self.Weapon]["C1"]

        local IdleAnimation = Animations:WaitForChild(self.Weapon .. "Idle")
        local Track = Animator:LoadAnimation(IdleAnimation)
        Track:Play()
    end
end

-- Constructor: sets up formation, center part, and starting soldiers
function TeamHandler.new(World: string, Level: string, LevelModel: Model, SelectedSkin: string)
    local self = setmetatable({}, TeamHandler)

    -- 1) Set variables
    self.Team = {}
    self.Weapon = Settings["LEVEL_DATA"][World][Level]["StartWeapon"]
    self.Skin = SelectedSkin
    self.Orientations = Settings["LEVEL_DATA"][World][Level]["Orientations"]
    self.CenterPart = CreateCenterPart(LevelModel)
    local TeamFolder = Instance.new("Folder")
    TeamFolder.Name = "ActiveTeam"
    TeamFolder.Parent = LevelModel
    self.TeamFolder = TeamFolder

    --2) Create soldiers (and add each to the team table)
    for _ = 1, Settings["LEVEL_DATA"][World][Level]["StartTeam"] do
        self:AddSoldier()
    end

    return self, self.TeamFolder
end

-- // RETURN
return TeamHandler