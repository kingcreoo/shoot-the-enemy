-- // Settings, created by KingCreoo on 5-27-2025
-- // Lists basic game settings

-- // Define module
local SETTINGS = {}

SETTINGS.DEFAULT_DATA = {
    ["leaderstats"] = {
        ["Gold"] = 100,
        ["Gems"] = 10
    },
    ["Worlds"] = {
        ["Tactile"] = {
            ["Level1"] = 0,
            ["Level2"] = 0,
            ["Level3"] = 0,
            ["Level4"] = 0,
            ["Level5"] = 0
        }
    },
    ["Operators"] = {
        ["Gatling"] = 0
    }
}

SETTINGS.WEAPON_DATA = {
    ["M4"] = {
        ["C0"] = CFrame.new(-0.697, -2.093, 0.167) * CFrame.Angles(math.rad(-90), 0, 0),
        ["C1"] = CFrame.new(0, -0.062, -0.489),
        ["BulletInfo"] = {
            ["Color"] = Color3.fromRGB(255, 176, 0),
            ["Material"] = Enum.Material.Neon,
            ["Size"] = Vector3.new(4, .3, .3)
        },
        ["Firerate"] = 1.75,
        ["BulletSpeed"] = 100,
        ["Damage"] = 1
    }
}

SETTINGS.LEVEL_DATA = {
    ["TactileWorld"] = {
        ["Level1"] = {
            ["Type"] = "Defense",
            ["LevelModel"] = "Level1",
            ["TotalTime"] = 90,
            ["StartTeam"] = 5,
            ["StartWeapon"] = "M4",
            ["Lanes"] = {
                [1] = "Standard",
                [2] = "Standard",
                [3] = "Standard"
            },
            ["Enemies"] = {
                {"Grunt", 1, 1, Vector3.new(0,0,0)}
            },
            ["Orientations"] = {
                [1] = Vector3.new(5,0,-3),
                [2] = Vector3.new(-5,0,-3),
                [3] = Vector3.new(0,0,4),
                [4] = Vector3.new(10,0,-6),
                [5] = Vector3.new(-10,0,-6),
                [6] = Vector3.new(-15,0,-9),
            },
            ["EntityTypes"] = {"SmallBullet", "LargeBullet", "StandardExplosion"}
        }
    }
}

SETTINGS.ENEMY_DATA = {
    ["Grunt"] = {
        ["MovementMode"] = "Straightline",
        ["HitboxRadius"] = 2,
        ["Weapon"] = "M4",
        ["Health"] = 3,
        ["ACTION_LOOP"] = {
            [1] = {"March", 22, 1}
        },
        ["TotalDuration"] = 22,
        ["Animations"] = {
            ["Weapon"] = "M4Idle",
            ["March"] = "M4March"
        }
    }
}

-- // Return module
return SETTINGS