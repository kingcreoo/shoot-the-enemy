-- // Entity handler, written by KingCreoo on 5-28-2025
-- // Manages entities for a level :)

-- // DEFINE
local EntityHandler = {}
EntityHandler.__index = EntityHandler

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Entities = ReplicatedStorage:WaitForChild("Entities")

-- // Module functions

-- Constructor
function EntityHandler.New(EntityTypes: table)
    local self = setmetatable({}, EntityHandler)

    self.Pool = {}
    self.Active = {}

    -- For each type of entity in this level, we create a pool
    for _, EntityType in pairs(EntityTypes) do
        self.Pool[EntityType] = {}
        self.Active[EntityType] = {}

        -- We pre-warm each pool with 500 entities
        local EntityTemplate = Entities:WaitForChild(EntityType)
        for _ = 1, 500 do
            local Entity = EntityTemplate:Clone()
            Entity.Parent = ReplicatedStorage
            table.insert(self.Pool[EntityType], Entity)
        end
    end

    return self
end

-- Returns one entity of the requested type
function EntityHandler:Create(Type: string)
    -- Get an entity from it's pool type
    local Entity = table.remove(self.Pool[Type])

    -- Add entity to it's active pool type
    table.insert(self.Active[Type], Entity)

    -- Return entity
    return Entity
end

-- Recycles an entity
function EntityHandler:Recycle(Entity: Part)
    -- Park the entity in ReplicatedStorage
    Entity.Parent = ReplicatedStorage

    -- Remove entity from it's active pool type
    for Index, Key in ipairs(self.Active[Entity.Name]) do
        if Key == Entity then
            table.remove(self.Active[Entity.Name], Index)
            break
        end
    end

    -- Re-insert the entity into it's pool type
    table.insert(self.Pool[Entity.Name], Entity)
end

-- Cleans up all entities
function EntityHandler:Cleanup()
    for _, Pool in pairs(self.Pool) do
        for _, Entity in pairs(Pool) do
            Entity:Destroy()
        end
    end

    for _, Active in pairs(self.Active) do
        for _, Entity in pairs(Active) do
            Entity:Destroy()
        end
    end
end

-- // RETURN
return EntityHandler