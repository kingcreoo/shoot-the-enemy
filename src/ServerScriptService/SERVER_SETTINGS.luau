-- // SERVER SETTINGS written by KingCreoo on 5-27-2025
-- // Holds server settings we wouldn't want exploiters to see :)

-- // Define module
local SERVER_SETTINGS = {}

-- // Settings

SERVER_SETTINGS.LEVEL_INFO = {
    ["TactileWorld"] = {
        ["Level1"] = {
            ["Type"] = "Defense",
            ["TotalTime"] = 90,
            ["StartEntities"] = {
                ["Team"] = 5,
                ["Enemies"] = {

                }
            },
            ["EntitySequence"] = {

            },
            ["Orientation"] = {
                [1] = Vector3.new(5,0,-3),
                [2] = Vector3.new(-5,0,-3),
                [3] = Vector3.new(0,0,4),
                [4] = Vector3.new(10,0,-6),
                [5] = Vector3.new(-10,0,-6),
                [6] = Vector3.new(-15,0,-9),
            }
        }
    }
}

-- // Return module
return SERVER_SETTINGS