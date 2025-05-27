-- // LevelController written by KingCreoo on 5-27-2025
-- // Manages how the player progresses through a level

-- // Define module
local LevelController = {}
LevelController.__index = LevelController

-- // Module functions
function LevelController.Create(Player: Player, World: string, Level: string)
    local self = setmetatable({}, LevelController)
    self.Player = Player

    return self
end

-- // Return module
return LevelController