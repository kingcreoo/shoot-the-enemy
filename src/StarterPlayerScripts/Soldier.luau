-- // Soldier, written by KingCreoo on 6-2-2025
-- // Manages the soldiers behavior :)

-- // Define module
local Soldier = {}
Soldier.__index = Soldier

-- // Services, variables, and modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Module functions
function Soldier.new()
    local self = setmetatable({}, Soldier)

    return self
end

function Soldier:Create(TeamFolder: Folder, Skin: string)
        self.Model = ReplicatedStorage:WaitForChild("Skins"):WaitForChild(Skin):Clone()
        self.Model.Parent = TeamFolder
end

function Soldier:Align(Offset: Vector3)
    self.Model:SetAttribute("Offset", Offset)
end

function Soldier:Fire()

end

function Soldier:Remove()

end

-- // Return module
return Soldier