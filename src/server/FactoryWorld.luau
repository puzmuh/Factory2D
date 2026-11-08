--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

type Cell = {
    x: number, y: number, kind: string, dir: number,
    item: string?, output: string?, raw: number, work: number,
    stored: {[string]: number}?,
}

type Factory = {
    cells: {[string]: Cell}, ores: {[string]: boolean}, oreList: {{x: number, y: number}},
    tick: number,
}

local FactoryWorld = {}

local function newCell(x: number, y: number, kind: string, dir: number): Cell
    return {x = x, y = y, kind = kind, dir = dir, raw = 0, work = 0, item = nil, output = nil,
        stored = if kind == "chest" then {ore = 0, plate = 0, gear = 0} else nil}
end

local function put(world: Factory, x: number, y: number, kind: string, dir: number)
    world.cells[Config.Key(x, y)] = newCell(x, y, kind, dir)
end

local function addOre(world: Factory, x: number, y: number)
    if not Config.Inside(x, y) then return end
    local key = Config.Key(x, y)
    if not world.ores[key] then
        world.ores[key] = true
        table.insert(world.oreList, {x = x, y = y})
    end
end

function FactoryWorld.new(): Factory
    local world: Factory = {cells = {}, ores = {}, oreList = {}, tick = 0}
    -- Fixed, repeatable ore locations. Main tutorial deposit at 8,12.
    for x = 6, 9 do
        for y = 10, 14 do
            if (x - 7.5)^2 + (y - 12)^2 <= 6 then addOre(world, x, y) end
        end
    end
    local clusters = {{24, 10}, {36, 23}, {18, 30}, {51, 12}, {50, 33}, {9, 34}}
    for _, p in ipairs(clusters) do
        for dx = -3, 3 do
            for dy = -3, 3 do
                local dist = dx * dx + dy * dy
                local noise = (p[1] * 13 + p[2] * 7 + dx * 19 + dy * 23) % 7
                if dist <= 7 and noise < 6 then addOre(world, p[1] + dx, p[2] + dy) end
            end
        end
    end

    -- Immediately productive demonstration line:
    -- ore drill > 3 belts > furnace > 2 belts > assembler > belt > storage.
    put(world, 8, 12, "miner", 0)
    for x = 9, 11 do put(world, x, 12, "belt", 0) end
    put(world, 12, 12, "furnace", 0)
    for x = 13, 14 do put(world, x, 12, "belt", 0) end
    put(world, 15, 12, "assembler", 0)
    put(world, 16, 12, "belt", 0)
    put(world, 17, 12, "chest", 0)
    return world
end

function FactoryWorld.place(world: Factory, x: number, y: number, kind: string, dir: number): boolean
    if not Config.Inside(x, y) or not Config.VALID[kind] then return false end
    if world.cells[Config.Key(x, y)] then return false end
    if kind == "miner" and not world.ores[Config.Key(x, y)] then return false end
    put(world, x, y, kind, dir)
    return true
end

function FactoryWorld.remove(world: Factory, x: number, y: number): boolean
    local key = Config.Key(x, y)
    if not world.cells[key] then return false end
    world.cells[key] = nil
    return true
end

function FactoryWorld.rotate(world: Factory, x: number, y: number): boolean
    local cell = world.cells[Config.Key(x, y)]
    if not cell or cell.kind == "chest" then return false end
    cell.dir = (cell.dir + 1) % 4
    return true
end

local function receiver(world: Factory, x: number, y: number, item: string): Cell?
    local c = world.cells[Config.Key(x, y)]
    if c == nil then return nil end
    if c.kind == "belt" and c.item == nil then return c end
    if c.kind == "furnace" and item == "ore" and c.raw < 1 and c.output == nil then return c end
    if c.kind == "assembler" and item == "plate" and c.raw < 2 and c.output == nil then return c end
    if c.kind == "chest" then return c end
    return nil
end

local function deliver(target: Cell, item: string)
    if target.kind == "belt" then
        target.item = item
    elseif target.kind == "chest" then
        local stored = target.stored
        if stored then stored[item] = (stored[item] or 0) + 1 end
    else
        target.raw += 1
    end
end

function FactoryWorld.step(world: Factory, dt: number)
    world.tick += 1

    -- Two-phase belts: a resource cannot travel several tiles within one tick.
    local departures: {{from: Cell, to: Cell, item: string}} = {}
    local reserved: {[string]: boolean} = {}
    for _, cell in pairs(world.cells) do
        if cell.kind ~= "belt" or cell.item == nil then continue end
        local x, y = Config.Next(cell.x, cell.y, cell.dir)
        local key = Config.Key(x, y)
        local target = receiver(world, x, y, cell.item)
        if target and not reserved[key] then
            reserved[key] = true
            table.insert(departures, {from = cell, to = target, item = cell.item})
        end
    end
    for _, move in ipairs(departures) do move.from.item = nil end
    for _, move in ipairs(departures) do deliver(move.to, move.item) end

    -- Factories store outputs until there is room in their facing tile.
    for _, cell in pairs(world.cells) do
        if cell.kind == "miner" then
            if cell.output == nil then
                cell.work += dt
                if cell.work >= Config.MACHINE_TIME.miner then
                    cell.work = 0
                    cell.output = "ore"
                end
            end
        elseif cell.kind == "furnace" then
            if cell.raw >= 1 and cell.output == nil then
                cell.work += dt
                if cell.work >= Config.MACHINE_TIME.furnace then
                    cell.work = 0
                    cell.raw -= 1
                    cell.output = "plate"
                end
            else
                cell.work = 0
            end
        elseif cell.kind == "assembler" then
            if cell.raw >= 2 and cell.output == nil then
                cell.work += dt
                if cell.work >= Config.MACHINE_TIME.assembler then
                    cell.work = 0
                    cell.raw -= 2
                    cell.output = "gear"
                end
            else
                cell.work = 0
            end
        end
    end

    for _, cell in pairs(world.cells) do
        if cell.output == nil then continue end
        local x, y = Config.Next(cell.x, cell.y, cell.dir)
        local target = receiver(world, x, y, cell.output)
        if target then
            deliver(target, cell.output)
            cell.output = nil
        end
    end
end

function FactoryWorld.snapshot(world: Factory): {[string]: any}
    local cells = {}
    local totals = {ore = 0, plate = 0, gear = 0}
    for _, c in pairs(world.cells) do
        local copy = {x = c.x, y = c.y, kind = c.kind, dir = c.dir,
            item = c.item, output = c.output, raw = c.raw, work = c.work}
        if c.stored then
            copy.stored = table.clone(c.stored)
            for item, count in pairs(c.stored) do
                totals[item] = (totals[item] or 0) + count
            end
        end
        table.insert(cells, copy)
    end
    return {width = Config.WIDTH, height = Config.HEIGHT, cells = cells,
        ores = world.oreList, totals = totals, tick = world.tick}
end

return FactoryWorld
