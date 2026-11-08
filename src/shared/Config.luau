--!strict
-- All gameplay uses integer tiles and deterministic server-side steps.
local Config = {}

Config.WIDTH = 64
Config.HEIGHT = 40
Config.TILE = 32
Config.STEP = 0.2
Config.CANVAS = Vector2.new(960, 540)
Config.MAX_ZOOM = 2.0
Config.MIN_ZOOM = 0.65

Config.DIRECTIONS = {
    {x = 1, y = 0},  -- 0: right
    {x = 0, y = 1},  -- 1: down
    {x = -1, y = 0}, -- 2: left
    {x = 0, y = -1}, -- 3: up
}

Config.TOOLS = {"belt", "miner", "furnace", "assembler", "chest", "erase"}
Config.TOOL_NAMES = {
    belt = "Conveyor",
    miner = "Drill",
    furnace = "Furnace",
    assembler = "Assembler",
    chest = "Storage",
    erase = "Remove",
}
Config.VALID = {belt = true, miner = true, furnace = true, assembler = true, chest = true}
Config.MACHINE_TIME = {miner = 0.8, furnace = 1.4, assembler = 1.6}

function Config.Key(x: number, y: number): string
    return tostring(x) .. ":" .. tostring(y)
end

function Config.Inside(x: number, y: number): boolean
    return x >= 1 and x <= Config.WIDTH and y >= 1 and y <= Config.HEIGHT
end

function Config.Next(x: number, y: number, dir: number): (number, number)
    local d = Config.DIRECTIONS[dir + 1]
    return x + d.x, y + d.y
end

return Config
