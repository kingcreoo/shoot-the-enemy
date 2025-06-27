-- // BULLET HANDLER, written by KingCreoo on 5-26-2025
-- // Manages pooling of bullets

-- // DEFINE
local BulletHandler = {}
BulletHandler.__index = BulletHandler

-- // Services, modules, and variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BulletTemplates = ReplicatedStorage:WaitForChild("BulletTemplates")
local SmallTemplate: Part = BulletTemplates:WaitForChild("Small")
local LargeTemplate: Part = BulletTemplates:WaitForChild("Large")

local Bullets = workspace:WaitForChild("Bullets")

local ActiveTweens = {}

-- // Module functions

-- Constructor
function BulletHandler.new()
    local self = setmetatable({}. BulletHandler)

    self.SmallSize = 500
    self.SmallPool = {}
    self.SmallActive = {}

    self.LargeSize = 500
    self.LargePool = {}
    self.LargeActive = {}

    -- Pre-warm the small pool
    for _ = 1, self.SmallSize do
        local Bullet = SmallTemplate:Clone()
        Bullet.Parent = ReplicatedStorage
        table.insert(self.SmallPool, Bullet)
    end

    -- Pre-warm the large pool
    for _ = 1, self.LargeSize do
        local Bullet = LargeTemplate:Clone()
        Bullet.parent = ReplicatedStorage
        table.insert(self.LargePool, Bullet)
    end

    return self
end

-- Create bullet
function BulletHandler:Create(Type: string, OriginPosition: Vector3, EndPosition: Vector3, BulletTime: number)
    local Bullet = self:Get(Type)
    Bullet.Position = OriginPosition
    Bullet.Orientation = Bullet.Orientation + Vector3.new(0,90,0)
    Bullet.Parent = Bullets

    local Tween = TweenService:Create(Bullet, TweenInfo.new(BulletTime, Enum.EasingStyle.Linear), {Position = EndPosition})
    ActiveTweens[Bullet] = Tween
    Tween:Play()
    Tween.Completed:Connect(function()
        self:Recycle(Bullet)
    end)
end

-- // Pool functions

function BulletHandler:Get(Type: string)
    local Bullet
    if Type == "Large" then
        Bullet = table.remove(self.LargePool)
    elseif Type == "Small" then
        Bullet = table.remove(self.SmallPool)
    end

    if not Bullet then
        if Type == "Large" then
            Bullet = LargeTemplate:Clone()
        elseif Type == "Small" then
            Bullet = SmallTemplate:Clone()
        end
    end

    return Bullet
end

function BulletHandler:Recycle(Bullet: Part)
    -- 1) Stop tween
    local ActiveTween = ActiveTweens[Bullet]
    if ActiveTween then
        ActiveTweens[Bullet] = nil
        ActiveTween:Destroy()
    end

    -- 2) Disconnect any events
    for _, Connection in ipairs(Bullet:GetConnections()) do
        Connection:Disconnect()
    end

    -- 3) Park & return to pool
    Bullet.Parent = ReplicatedStorage
    if Bullet.Name == "Small" then
        table.insert(self.SmallPool, Bullet)
    elseif Bullet.Name == "Large" then
        table.insert(self.LargePool, Bullet)
    end
end

-- // RETURN
return BulletHandler