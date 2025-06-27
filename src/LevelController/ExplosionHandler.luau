-- // EXPLOSION HANDLER, written by KingCreoo on 5-26-2025
-- // Manages pooling of explosions

-- // DEFINE
local ExplosionHandler = {}
ExplosionHandler.__index = ExplosionHandler

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExplosionTemplates = ReplicatedStorage:WaitForChild("ExplosionTemplates")
local StandardTemplate: Part = ExplosionTemplates:WaitForChild("Standard")

local Explosions = workspace:WaitForChild("Explosions")

-- // Module functions

-- Constructor
function ExplosionHandler.new()
    local self = setmetatable({}, ExplosionHandler)

    self.StandardSize = 500
    self.StandardPool = {}
    self.StandardActive = {}

    -- Pre-warm the standard pool
    for _ = 1, self.SmallSize do
        local Explosion = StandardTemplate:Clone()
        Explosion.Parent = ReplicatedStorage
        table.insert(self.StandardPool, Explosion)
    end

    return self
end

-- Create Explosion
function ExplosionHandler:Create(Type: string, Position: Vector3, ExplosionTime: number, Color: Color3)
    -- Get explosion part
    local Explosion = self:Get(Type)
    Explosion.Position = Position
    Explosion.Parent = Explosions

    local Emitter: ParticleEmitter = Explosion:WaitForChild("ParticleEmitter")

    -- Set color
    Emitter.Color = Color

    -- Explode
    Emitter:Emit(16)

    -- After run time, stop & recycle the explosion
    task.delay(ExplosionTime, function()
        self.Recycle(Explosion)
    end)
end

-- // Pool functions

-- Get explosion from pool
function ExplosionHandler:Get(Type: string)
    local Explosion
    if Type == "Standard" then
        Explosion = table.remove(self.StandardPool)
    end

    if not Explosion then
        if Type == "Standard" then
            Explosion = StandardTemplate:Clone()
        end
    end

    return Explosion
end

-- Recycle explosion back into pool
function ExplosionHandler:Recycle(Explosion: Part)
    -- 1) Disconnect any events
    for _, Connection in ipairs(Explosion:GetConnections()) do
        Connection:Disconnect()
    end

    -- 2) Park & return to pool
    Explosion.Parent = ReplicatedStorage
    if Explosion.Name == "Standard" then
        table.insert(self.StandardPool, Explosion)
    end
end

-- // RETURN
return ExplosionHandler