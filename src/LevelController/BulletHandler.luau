-- // Bullet Handler, written by KingCreoo on 7-6-2025
-- // Manages bullets (and explosions) in the level :)

-- // DEFINE
local BulletHandler = {}
BulletHandler.__index = BulletHandler

-- // Services, modules, variables

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Settings = require(ReplicatedStorage:WaitForChild("Settings"))

local EnemyModules = ReplicatedStorage:WaitForChild("EnemyModules")
local Bullets = Workspace:WaitForChild("Bullets")
local Explosions = Workspace:WaitForChild("Explosions")

local DueBullets = {}
local DueDeaths = {}

-- // Local functions

-- Calculate the actions for an enemy and return the current action
-- Determines which action an enemy is currently performing based on elapsed time
local function CalculateActions(StartTime, ActionLoop)
    --1) Get the current time, and time elapsed since the unit spawned
    local CurrentTime = os.time()
    local TimeElapsed = CurrentTime - StartTime

    --2) Walk the loop until we find the action we are on
    local LoopTimeElapsed = 0
    local CurrentAction
    local TimeRemaining
    local CurrentActionNum = 0
    for _, ActionTable in ipairs(ActionLoop) do
        CurrentActionNum += 1
        local ActionTime = ActionTable[2]
        LoopTimeElapsed += ActionTime

        if LoopTimeElapsed <= TimeElapsed then
            -- The unit is not on this action, because time has elapsed further down the loop
            continue
        elseif LoopTimeElapsed > TimeElapsed then
            -- The unit is on this action :)
            CurrentAction = ActionTable
            TimeRemaining = math.abs(TimeElapsed - LoopTimeElapsed)

            -- Break
            break
        end
    end

    -- Return the action the unit is on, the time elapsed, and time remaining on this current action
    return CurrentActionNum, CurrentAction, TimeElapsed, TimeRemaining
end

-- Calulate at what tiem this bullet will hit the enemy
-- Calculates the exact time when a bullet will hit an enemy based on movement patterns
local function CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, TimeSinceFired, TimeRemaining, LevelDistance)
    local HitTime

    -- Note enemy's speed, and distance to enemy
    local CurrentSpeed = ((LevelDistance * CurrentAction[3]) / CurrentAction[2])
    local CurrentDistance = math.abs(OriginPosition.Z - Enemy.Z)

    -- Note the time it will take to hit the enemy at this bullet & enemy speed
    local CurrentActionHitTime = CurrentDistance / (BulletSpeed + CurrentSpeed)

    -- CASE 1: bullet arrives before the enemy finishes this action
    if CurrentActionHitTime <= TimeRemaining then
        HitTime = CurrentActionHitTime + TimeSinceFired
    else
        -- CASE 2: bullet doesn’t make it in time → step into the next enemy action
        -- We do this because a new action may have a different movement speed (or no speed at all)

        -- Note the distance travelled up until the enemy switches to new action
        local DistanceTravelled = (BulletSpeed + CurrentSpeed) * TimeRemaining

        -- Note new variables
        local NewTimeSinceFired = TimeSinceFired + TimeRemaining
        local Direction = (Enemy.Z > OriginPosition.Z) and 1 or -1
        local NewZ = OriginPosition.Z + DistanceTravelled * Direction
        local NewOriginPosition = Vector3.new(OriginPosition.X, OriginPosition.Y, NewZ)

        -- Recurse into the next action into the loop
        HitTime = CalculateHitTime(NewOriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum+1, ActionLoop[CurrentActionNum+1], NewTimeSinceFired, ActionLoop[CurrentActionNum+1][2], LevelDistance)
    end

    -- Return the proper hit time :)))
    return HitTime
end

    -- Here we select enemies that are valid, or in the path of the bullet
-- Filters enemies to find only those that can be hit by a bullet
local function SelectValidEnemies(EnemyTable, OriginPosition, BulletSpeed, LevelDistance)
    local ValidEnemies = {}
    for _, Enemy in pairs(EnemyTable) do
        -- If this enemy is due to die, then check the next enemy
        if table.find(DueDeaths, Enemy.Enemy) then
            print('case 1', os.time())
            continue
        end

        -- We check if the bullet will hit the enemy
        if Enemy.Type == "Laneswapper" then
            -- TODO Create laneswapper type validation based off of what lane it will be in at the hit time
            -- Holding off on this because we haven't yet coded the laneswapper type itself!

            --[[local EnemyModule = require(EnemyModules:WaitForChild(Enemy.Name))
            local ActionLoop = EnemyModule.ACTION_LOOP

            local CurrentActionNum, CurrentAction, _, TimeRemaining = CalculateActions(Enemy.StartTime, ActionLoop)

            local HitTime = CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, 0, TimeRemaining, LevelDistance)

            --]]
            print('todo later')
        else
            if math.abs(OriginPosition.X - Enemy.X) > Enemy.HitboxRadius then
                -- If the bullet is further away from the center of the enemy than the hitbox is, then this enemy is invalid so we continue
                continue
            else
                -- Enemy comes out as valid, so we add it to the table
                table.insert(ValidEnemies, Enemy)
            end
        end
    end

    return ValidEnemies
end

-- Chooses the closest-to-impact enemy from the valid list
-- Selects the optimal target from valid enemies based on hit time
local function SelectTarget(ValidEnemies, OriginPosition, BulletSpeed, LevelDistance)
    local Target, TargetHitTime = nil, math.huge
    for _, Enemy in pairs(ValidEnemies) do
        -- Get the enemies current action
        local EnemyModule = require(EnemyModules:WaitForChild(Enemy.Enemy.Name))
        local ActionLoop = EnemyModule.ACTION_LOOP
        local CurrentActionNum, CurrentAction, _, TimeRemaining = CalculateActions(Enemy.StartTime, ActionLoop)

        -- Trap protection
        if not CurrentAction then
            continue
        end

        -- Note how long it will take to hit this enemy
        local HitTime = CalculateHitTime(OriginPosition, BulletSpeed, Enemy, ActionLoop, CurrentActionNum, CurrentAction, 0, TimeRemaining, LevelDistance)

        -- If hit time is longer than the time it takes for the unit to reach the end, then coninue to the next option
        local TimeElapsed = tick() - Enemy.StartTick
        local TimeToEnd = Enemy.TotalDuration - TimeElapsed
        if HitTime >= TimeToEnd then
            print("HitTime >= TimeToEnd")
            continue
        end

        -- If this enemy has a shorter hit time then the currently selected target, then make this enemy the selected target
        if HitTime < TargetHitTime then
            Target = Enemy
            TargetHitTime = HitTime
        end
    end

    return Target, TargetHitTime
end

-- Creates visual explosion effects at specified position
local function CreateExplosion(EntityHandler, Position, Color, Amount)
    local Explosion1 = EntityHandler:Create("StandardExplosion")
    Explosion1.Parent = Explosions
    Explosion1.CFrame = CFrame.new(Position)
    Explosion1:WaitForChild("ParticleEmitter").Color = Color
    Explosion1:WaitForChild("ParticleEmitter"):Emit(Amount)
    task.delay(1, function()
        Explosion1.Parent = ReplicatedStorage
        EntityHandler:Recycle(Explosion1)
    end)
end

-- // Module functions

-- Creates a new bullet handler instance for managing projectile physics
function BulletHandler.new(EnemyRegistry, EntityHandler, TeamHandler, Distance)
    local self = setmetatable({}, BulletHandler)

    self.EnemyRegistry = EnemyRegistry
    self.EntityHandler = EntityHandler
    self.TeamHandler = TeamHandler
    self.Distance = Distance

    self:Manager()

    return self
end

-- Main bullet management loop that handles targeting and firing
function BulletHandler:Manager()
    task.spawn(function()
        while true do
            local Weapon = self.TeamHandler.Weapon
            local BulletSpeed = Settings["WEAPON_DATA"][Weapon]["BulletSpeed"]
            local Damage = Settings["WEAPON_DATA"][Weapon]["Damage"]

            local EnemyTable: table = self.EnemyRegistry:GetEnemyInfo()

            -- Loop through each soldier and create a bullet with an identified target (or no target0
            for _, Soldier in ipairs(self.TeamHandler.Team) do
                local OriginPosition = Soldier:WaitForChild("Weapon"):WaitForChild("Fire").Position

                local ValidEnemies = SelectValidEnemies(EnemyTable, OriginPosition, BulletSpeed, self.Distance)
                local Target, TargetHitTime = SelectTarget(ValidEnemies, OriginPosition, BulletSpeed, self.Distance)

                local Bullet = self.EntityHandler:Create("SmallBullet")
                Bullet.Position = Soldier:WaitForChild("Weapon"):WaitForChild("Fire").Position
                Bullet.Orientation = Bullet.Orientation + Vector3.new(0,90,0)
                Bullet.Parent = Bullets

                local Distance = BulletSpeed * TargetHitTime
                local FireCF = Soldier:WaitForChild("Weapon"):WaitForChild("Fire").CFrame
                local RawDirection = (FireCF).LookVector
                local Direction = Vector3.new(RawDirection.X, 0, RawDirection.Z)

                local EndPosition = OriginPosition + Direction * Distance

                if Target then
                    -- If we found a target, create the bullet with a crash course towards the enemy
                    if not DueBullets[Target.Enemy] then
                        DueBullets[Target.Enemy] = {}
                    end
                    local BulletNumber = #DueBullets[Target.Enemy]+1
                    table.insert(DueBullets[Target.Enemy], Damage)
                    local TotalDamage = 0
                    for _, BulletDamage in pairs(DueBullets[Target.Enemy]) do
                        TotalDamage += BulletDamage
                    end
                    if TotalDamage >= Target.Controller.Health then
                        table.insert(DueDeaths, Target.Enemy)
                    end

                    -- Create and play the bullet's tween
                    local BulletTween = TweenService:Create(Bullet, TweenInfo.new(TargetHitTime, Enum.EasingStyle.Linear), {Position = EndPosition})
                    BulletTween:Play()

                    -- Create explosions right before the hit
                    task.delay(TargetHitTime-.25, function()
                        CreateExplosion(self.EntityHandler, EndPosition, ColorSequence.new(Color3.fromRGB(255, 70, 70)), 6)
                        CreateExplosion(self.EntityHandler, EndPosition, ColorSequence.new(Color3.fromRGB(255, 200, 70)), 6)
                    end)

                    -- After the bullet completes it's tween and hits the enemy, we clean it up & damage the enemy
                    BulletTween.Completed:Connect(function()
                        Bullet.Orientation = Bullet.Orientation - Vector3.new(0,90,0)
                        self.EntityHandler:Recycle(Bullet)

                        table.remove(DueBullets[Target.Enemy], BulletNumber)

                        if Target and Target.Controller then
                            local Death = Target.Controller:TakeDamage(Damage)
                            if Death then
                                self.EnemyRegistry:Remove(Target.Enemy)
                                DueBullets[Target.Enemy] = nil
                                DueDeaths[Target.Enemy] = nil
                            end
                        end
                    end)
                else
                    -- If the bullet doesn't have a target, we just fire it off into the distance
                    local MaxTime = self.Distance / BulletSpeed
                    local MaxPosition = OriginPosition + Direction * self.Distance

                    local BulletTween = TweenService:Create(Bullet, TweenInfo.new(MaxTime, Enum.EasingStyle.Linear), {Position = MaxPosition})
                    BulletTween:Play()
                    BulletTween.Completed:Connect(function()
                        Bullet.Orientation = Bullet.Orientation - Vector3.new(0,90,0)
                        self.EntityHandler:Recycle(Bullet)
                    end)
                end
            end

            -- Wait so that we only loop at the speed of the equipped weapon's firerate
            task.wait(Settings["WEAPON_DATA"][Weapon]["Firerate"])
        end
    end)
end

-- // RETURN
return BulletHandler