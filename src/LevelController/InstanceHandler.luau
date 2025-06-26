-- // INSTANCE HANDLER, written by KingCreoo on 6-26-2025
-- // Handles small instances inside of a level :)

-- // DEFINE
local InstanceHandler = {}

-- // Services, modules, and variables

local TweenService = game:GetService("TweenService")

local Bullets = workspace:WaitForChild("Bullets")
local Explosions = workspace:WaitForChild("Explosions")

-- // Explosion function

function InstanceHandler:SpawnExplosion(Color: Color3, Position: Vector3)
    local EmissionPart = Instance.new("Part")
    EmissionPart.Name = "ExplosionEmitter"
    EmissionPart.Size = Vector3.new(1, 1, 1)
    EmissionPart.CanCollide = false
    EmissionPart.CanTouch = false
    EmissionPart.CanQuery = false
    EmissionPart.Anchored = true
    EmissionPart.Transparency = 1
    EmissionPart.Position = Position
    EmissionPart.Parent = Explosions

    local Emitter: ParticleEmitter = Instance.new("ParticleEmitter")
    Emitter.Color = Color
    Emitter.Brightness = 1
    Emitter.LightInfluence = 0
    Emitter.LightEmission = 1
    Emitter.Orientation = Enum.ParticleOrientation.FacingCamera
    Emitter.Texture = "rbxassetid://290556384"
    Emitter.Transparency = 0

    Emitter.EmissionDirection = Enum.NormalId.Top
    Emitter.Enabled = false
    Emitter.LifeTime = NumberRange.new(.3, .4)
    Emitter.Rate = 15
    Emitter.Rotation = 0
    Emitter.RotSpeed = NumberRange.new(40, 60)
    Emitter.Speed = NumberRange.new(2, 3)

    Emitter.Shape = Enum.ParticleEmitterShape.Sphere

    Emitter.Parent = EmissionPart
    Emitter.Enabled = true
    task.delay(.5, function()
        Emitter.Enabled = false
    end)
    task.delay(2, function()
        EmissionPart:Destroy()
    end)
end

-- // Bullet function

function InstanceHandler:SpawnBullet(BulletFolder: Folder, OriginPosition: Vector3, EndPosition: Vector3, BulletTime: number)
    local Bullet = BulletFolder:WaitForChild(self.Weapon):Clone()
    Bullet.Position = OriginPosition
    Bullet.Orientation = Bullet.Orientation + Vector3.new(0,90,0)
    Bullet.Parent = Bullets
    local Tween = TweenService:Create(Bullet, TweenInfo.new(BulletTime, Enum.EasingStyle.Linear), {Position = EndPosition})
    Tween:Play()
    Tween.Completed:Connect(function()
        if Bullet then
            Bullet:Destroy()
        end
    end)
end

-- // RETURN
return InstanceHandler