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

    return Enemy
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

function EnemyRegistry:GetEnemyInfo()
    local EnemyInfo = {}

    for Enemy, Controller in pairs(self.Registry) do
        if not Enemy.Parent or not Enemy.PrimaryPart then
            self.Registry[Enemy] = nil
            continue
        end
        local EnemyInfoTable = {}

        EnemyInfoTable["Enemy"] = Enemy
        EnemyInfoTable["Controller"] = Controller
        EnemyInfoTable["MovementMode"] = Controller.MovementMode
        EnemyInfoTable["StartTime"] = Controller.StartTime
        EnemyInfoTable["HitboxRadius"] = Controller.HitboxRadius
        EnemyInfoTable["X"] = Enemy.PrimaryPart.Position.X
        EnemyInfoTable["Z"] = Enemy.PrimaryPart.Position.Z

        table.insert(EnemyInfo, EnemyInfoTable)
    end

    return EnemyInfo
end

function EnemyRegistry:Remove(Enemy)
    self.Registry[Enemy] = nil
end

-- // RETURN
return EnemyRegistry