-- // Enemy registry, written by KingCreoo on 5-28-2025
-- // Manages each enemy in a grand table

-- // DEFINE
local EnemyRegistry = {}
EnemyRegistry.__index = EnemyRegistry

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local EnemyModules = ReplicatedStorage:WaitForChild("EnemyModules")
local Grunt = require(EnemyModules:WaitForChild("Grunt"))

local EnemyModulesTable = {["Grunt"] = Grunt}
local Enemies = ReplicatedStorage:WaitForChild("Enemies")

-- // Local functions

local function CreateEnemy(Type: string)
    local Enemy = Enemies:WaitForChild(Type):Clone()
    Enemy.Parent = ReplicatedStorage
end

-- // Module functions

function EnemyRegistry.new(World: string, Level: string, LevelModel: Model)
    local self = setmetatable({}, EnemyRegistry)

    -- Create registry of enemies
    self.Registry = {}
    for _, EnemyTable in pairs(Settings["LEVEL_DATA"][World][Level]["Enemies"]) do
        local Enemy = CreateEnemy(EnemyTable[1])
        self.Registry[Enemy] = EnemyModulesTable[EnemyTable[1]].new(Enemy, LevelModel, EnemyTable)
    end

    return self
end

function EnemyRegistry:Cleanup()
    for Enemy, _ in pairs(self.Registry) do
        Enemy:Destroy()
    end

    table.clear(self.Registry)
end

-- // RETURN
return EnemyRegistry