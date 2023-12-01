Config = {}

Config.Debug = false                                    -- Spawns the train in their location and stops them permanently (doesn't spawn west train). Also deletes trains on script ensure.

Config.UseNetwork = false                               -- Whether to use networked trains or not. If you are having problems with trains syncing and spawning correctly, set this to false.

Config.UseEastTrain = true                              -- Use east line or not
Config.UseWestTrain = true                              -- Use west line or not
Config.UseTrams = true                                  -- Use tram or not

Config.eastLoc = vector3(2598.31, -1477.08, 45.87)      -- Spawn location for east line
Config.tramLoc = vector3(2608.38, -1203.12, 53.16)      -- Spawn location for tram line
Config.westLoc = vector3(-3766.98, -2787.98, -14.44)    -- Spawn location for west line

Config.UseChristmasTrainEast = false                    -- Whether or not to use Christmas trains
Config.UseChristmasTrainWest = false

Config.UseFancyTrainEast = true                         -- Whether or not to use fancy trains
Config.UseFancyTrainWest = true

Config.EnablePassengers = true                          -- Enable passengers or not

Config.UseRandomJunctions = false                       -- Use random junctions or not
Config.RandomJunctionstime = 900000                     -- Time between random junctions (in milliseconds) 15 minutes = 900000
Config.RandomizeWestJunctions = false                   -- Randomize west junctions or not
Config.RandomizeEastJunctions = false                   -- Randomize east junctions or not
Config.RandomizeTramJunctions = false                   -- Randomize tram junctions or not

Config.EastTrainMaxSpeed = 10.0                         -- Max speed for train
Config.EastTrainBlipName = "BGS East Line"              -- Blip name for train
Config.EastTrainStationWait = 30                        -- Time that train waits at a station (in seconds)

Config.WestTrainMaxSpeed = 10.0
Config.WestTrainBlipName = "BGS West Line"
Config.WestTrainStationWait = 30

                                                        -- TROLLEY TYPES I HAVE FOUND (use hash value):
Config.Trolley = 0xBF69518F                             --trolley_config (Cornwall) = 0xBF69518F,
                                                        --trolley_config2 (Pacific Union) = 0x09B679D6,

                                                        -- TRAIN TYPES (use hash value):
Config.EastTrain = 0xCD2C7CA1                           -- appleseed_config = 0x8EAC625C,
Config.WestTrain = 0x10461E19                           -- bountyhunter_config = 0xF9B038FC,
                                                        -- dummy_engine_config = 0x26509FBB,
                                                        -- engine_config = 0x3260CE89,
                                                        -- ghost_train_config = 0x0E62D710,
                                                        -- gunslinger3_config = 0x3D72571D,
                                                        -- gunslinger4_config = 0x5AA369CA,
                                                        -- handcart_config = 0x3EDA466D,
                                                        -- minecart_config = 0xC75AA08C,
                                                        -- prisoner_escort_config = 0x515E31ED,
                                                        -- trolley_config = 0xBF69518F,
                                                        -- trolley_config2 = 0x09B679D6,
                                                        -- winter4_config = 0x487B2BE7,
                                                        -- SouthEastBlueAndWhitePassenger = 0x10461E19,
                                                        -- central_closed_doors = 0x005E03AD,
                                                        -- lannahachee_cargo_armored = 0x0392C83A,
                                                        -- central_cargo = 0x0660E567,
                                                        -- south_east_cargo = 0x0941ADB7,
                                                        -- lannahachee_cargo = 0x0CCC2F70,
                                                        -- south_east_cargo = 0x0D03C58D,
                                                        -- central_passenger = 0x124A1F89,
                                                        -- central_cargo = 0x19A0A288,
                                                        -- SouthEastBlueAndWhitePassenger = 0x1C043595,
                                                        -- South_east_mixed_use = 0x1C9936BB,
                                                        -- central_cargo = 0x1EEC5C2A,
                                                        -- lannahachee_cargo_refrigerated = 0x1EF82A51,
                                                        -- us_army_with_beds = 0x25E5D8FF,
                                                        -- private_open_sleeper(interior_only) = 0x29C81ACB,
                                                        -- central_cargo = 0x2D1A6F0C,
                                                        -- pacific_passenger = 0x2D3645FA,
                                                        -- lannahachee_cargo = 0x31656D23,
                                                        -- South_east_mixed_use = 0x35D17C43,
                                                        -- SOUTH_EAST_FANCY_SLEEPERS = 0x3ADC4DA9,
                                                        -- central_mixed_use = 0x41436136,
                                                        -- central_passenger_long = 0x4A73E49C,
                                                        -- central_passenger_long = 0x4C9CCB22,
                                                        -- central_mixed_use = 0x57C209C4,
                                                        -- central_passenger_short = 0x592A5CD0,
                                                        -- lannahachee_cargo = 0x5D9928A4,
                                                        -- central_cargo = 0x68CF495F,
                                                        -- south_east_cargo = 0x6CC26E27,
                                                        -- south_east_cargo = 0x6D69A954,
                                                        -- trolley_config7 = 0x73722125,
                                                        -- central_cargo = 0x761CE0AD,
                                                        -- lannahachee_cargo = 0x7BD58C4D,
                                                        -- south_east_short = 0x8864D73A,
                                                        -- central_cargo = 0x8D0766BC,
                                                        -- trolley_config6 = 0x90CB53CA,
                                                        -- lannahachee_cargo = 0x9296570E,
                                                        -- handcart_config = 0x96563327,
                                                        -- central_passenger_short = 0x98427740,
                                                        -- central_cargo = 0x9897FF51,
                                                        -- SouthEastBlueAndWhitePassenger = 0x998A0CBC,
                                                        -- central_passenger_short = 0x9CBE6FEC,
                                                        -- trolley_config5 = 0x9E096E46,
                                                        -- central_mixed_use = 0xA3BF0BEB,
                                                        -- central_passenger_ransacked = 0xA8B1CEB7,
                                                        -- central_passenger_med = 0xA91041A2,
                                                        -- lannahachee_cargo = 0xAA3E691E,
                                                        -- armored_cars = 0xAC18A9F4,
                                                        -- trolley_config4 = 0xAEE0ECF5,
                                                        -- US_Army(glitched) = 0xC1F1DD80,
                                                        -- central_passenger_short = 0xC732CDC8,
                                                        -- central_passenger_long = 0xCA19C62A,
                                                        -- SOUTH_EAST_FANCY_CABINS = 0xCD2C7CA1,
                                                        -- central_mixed_use = 0xD233B18D,
                                                        -- central_cargo = 0xD42DD3EE,
                                                        -- central_cargo = 0xD5DF2D82,
                                                        -- central_mixed_use = 0xD8CF6395,
                                                        -- central_mixed_use = 0xD92B16AE,
                                                        -- central_cargo = 0xD93C36C2,
                                                        -- green_pacific_cargo = 0xDA2EDE2F,
                                                        -- SOUTH_EAST_BAR_CAR = 0xDC9DD041,
                                                        -- central_one_fancy_car = 0xDD920DAF,
                                                        -- central_cargo = 0xE0898B89,
                                                        -- pacific_passenger = 0xE16CA3EF,
                                                        -- central_machinery = 0xEB8B2439,
                                                        -- central_one_fancy_car = 0xEF9FC71D,
                                                        -- trolly_config3 = 0xEFBFBDD8,
                                                        -- green_pacific_cargo = 0xF19E48CA,
                                                        -- central_mixed_use = 0xF6AA98F4,
                                                        -- SouthEastBlueAndWhitePassenger = 0xFAB2FFB9,
                                                        -- green_pacific_cargo = 0xFAC328F0,
                                                        -- 4_car_coal_train = 0xFD8810E8,

-- Best not to mess with these unless you know what you're doing =)
Config.RouteOneTramSwitches = {
    { coords = vector3(2775.01, -1350.06, 46.14),       trainTrack = -1739625337,  junctionIndex = 0,  enabled = 0 },
    -- { coords = vector3(2686.55, -1385.46, 46.36679),    trainTrack = -1739625337,  junctionIndex = 3,  enabled = 1 },
    { coords = vector3(2621.25, -1295.36, 52.01),       trainTrack = -1739625337,  junctionIndex = 5,  enabled = 0 },
    -- { coords = vector3(2615.05, -1281.2, 52.34358),     trainTrack = -1739625337,  junctionIndex = 6,  enabled = 1 },
    -- { coords = vector3(2608.49, -1254.66, 52.66566),    trainTrack = -1739625337,  junctionIndex = 7,  enabled = 1 },
    { coords = vector3(2608.6, -1155.59, 51.69),        trainTrack = -1739625337,  junctionIndex = 10, enabled = 1 },
    { coords = vector3(2624.4, -1139.85, 51.51707),     trainTrack = -1739625337,  junctionIndex = 11, enabled = 1 },
    { coords = vector3(2700.96, -1139.82, 50.29),       trainTrack = -1739625337,  junctionIndex = 13, enabled = 1 },
    { coords = vector3(2625.46, -1284.62, 52.14),       trainTrack = 1751550675,   junctionIndex = 1,  enabled = 1 },
    -- { coords = vector3(2738.41, -1414.91, 45.85),       trainTrack = -1748581154,  junctionIndex = 1,  enabled = 1 },
    -- { coords = vector3(2599.47, -1137.39, 51.3),        trainTrack = -1716490906,  junctionIndex = 4,  enabled = 1 },
}

Config.EastJunctions = {
    { coords = vector3(-281.1323, -319.6579, 89.02458), trainTrack = -705539859,  junctionIndex = 2,  enabled = 1 },
    { coords = vector3(357.959, 596.374, 115.6759),     trainTrack = 1499637393,  junctionIndex = 4,  enabled = 1 },
    { coords = vector3(1481.54, 648.331, 92.30682),     trainTrack = 1499637393,  junctionIndex = 2,  enabled = 1 },
    { coords = vector3(2464.55, -1475.74, 46.15192),    trainTrack = -760570040,  junctionIndex = 5,  enabled = 1 },
    { coords = vector3(2654.026, -1477.149, 45.75834),  trainTrack = -1242669618, junctionIndex = 2,  enabled = 1 },
    { coords = vector3(2659.79, -435.7114, 43.38848),   trainTrack = -705539859,  junctionIndex = 13, enabled = 0 },
    { coords = vector3(610.3571, 1661.904, 187.3867),   trainTrack = -705539859,  junctionIndex = 8,  enabled = 1 },
    { coords = vector3(556.65, 1725.99, 187.7966),      trainTrack = -705539859,  junctionIndex = 7,  enabled = 1 },
    { coords = vector3(2588.54, -1482.19, 46.04693),    trainTrack = -705539859,  junctionIndex = 18, enabled = 1 },
}

Config.WestJunctions = {
    { coords = vector3(-2187.18, -2517.21, 65.7),       trainTrack = -988268728,  junctionIndex = 0,  enabled = 1 },
    { coords = vector3(-2214.62, -2519.47, 65.51),       trainTrack = -1763976500,  junctionIndex = 1,  enabled = 1 },
    { coords = vector3(-2214.62, -2519.47, 65.51),       trainTrack = -1467515357,  junctionIndex = 0,  enabled = 1 }
}

-- Custom stops - simply add coords here and the trains will stop there!
Config.CustomStops = {
    { coords = vector3(565.44, 1707.59, 187.47)},
}