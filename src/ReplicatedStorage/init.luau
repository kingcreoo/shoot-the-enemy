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
        ["C1"] = CFrame.new(0, -0.062, -0.489)
    }
}

-- // Return module
return SETTINGS