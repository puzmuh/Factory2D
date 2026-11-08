--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ro2D = require(ReplicatedStorage:WaitForChild("Ro2DEngine"))

local Draw = Ro2D.Draw
local TILE = Config.TILE
local Renderer = {}

local function rect(x: number, y: number, w: number, h: number, color: {number}, a: number?)
    if w <= 0 or h <= 0 then return end
    Draw.Rect(x, y, w, h, color[1], color[2], color[3], a or 255)
end

local function line(x0: number, y0: number, x1: number, y1: number, thick: number, color: {number})
    Draw.LineSDF(x0, y0, x1, y1, thick, color[1], color[2], color[3])
end

local COLORS = {
    ground = {37, 52, 53}, groundAlt = {41, 57, 56}, grid = {25, 42, 45},
    ore = {108, 143, 152}, oreEdge = {68, 101, 115}, oreLight = {177, 204, 200},
    belt = {42, 68, 73}, beltEdge = {17, 34, 43}, beltTrack = {105, 137, 135},
    miner = {234, 184, 79}, minerEdge = {114, 82, 40},
    furnace = {219, 104, 70}, furnaceEdge = {112, 55, 48},
    assembler = {97, 183, 178}, assemblerEdge = {42, 89, 101},
    chest = {119, 166, 103}, chestEdge = {50, 94, 67},
    white = {235, 243, 226}, dark = {24, 38, 43}, ghost = {94, 231, 177},
    invalid = {255, 103, 95},
}

local function itemIcon(item: string, x: number, y: number, sz: number)
    local rad = math.max(2, sz * 0.16)
    if item == "ore" then
        Draw.CircleSDF(x, y, rad, 159, 190, 206, 255)
        rect(x - rad * 0.48, y - rad * 0.48, rad * 0.8, rad * 0.45, COLORS.white)
    elseif item == "plate" then
        rect(x - rad, y - rad * 0.72, rad * 2, rad * 1.44, {211, 221, 217})
        rect(x - rad * 0.7, y - rad * 0.35, rad * 1.4, rad * 0.3, {129, 151, 159})
    elseif item == "gear" then
        Draw.CircleSDF(x, y, rad, 238, 197, 98, 255)
        Draw.CircleSDF(x, y, rad * 0.38, 39, 55, 57, 255)
        local o = rad * 0.92
        rect(x - 1, y - o - 2, 2, 4, {238, 197, 98})
        rect(x - 1, y + o - 2, 2, 4, {238, 197, 98})
        rect(x - o - 2, y - 1, 4, 2, {238, 197, 98})
        rect(x + o - 2, y - 1, 4, 2, {238, 197, 98})
    end
end

local function arrow(x: number, y: number, s: number, dir: number, color: {number})
    local d = Config.DIRECTIONS[dir + 1]
    local centerX, centerY = x + s / 2, y + s / 2
    local frontX, frontY = centerX + d.x * s * 0.24, centerY + d.y * s * 0.24
    local rearX, rearY = centerX - d.x * s * 0.2, centerY - d.y * s * 0.2
    local stem = math.max(1.3, s * 0.067)
    line(rearX, rearY, frontX, frontY, stem, color)
    line(frontX, frontY, frontX - d.x * s * 0.15 + d.y * s * 0.14,
        frontY - d.y * s * 0.15 - d.x * s * 0.14, stem, color)
    line(frontX, frontY, frontX - d.x * s * 0.15 - d.y * s * 0.14,
        frontY - d.y * s * 0.15 + d.x * s * 0.14, stem, color)
end

local function machine(cell: {[string]: any}, x: number, y: number, s: number, seconds: number, ghost: boolean)
    local kind = cell.kind
    local dir = cell.dir or 0
    local pad = math.max(1, s * 0.08)
    local body = s - pad * 2
    local edge = COLORS.beltEdge
    local main = COLORS.belt
    if kind == "miner" then edge, main = COLORS.minerEdge, COLORS.miner end
    if kind == "furnace" then edge, main = COLORS.furnaceEdge, COLORS.furnace end
    if kind == "assembler" then edge, main = COLORS.assemblerEdge, COLORS.assembler end
    if kind == "chest" then edge, main = COLORS.chestEdge, COLORS.chest end

    rect(x + pad, y + pad + s * 0.04, body, body, edge, if ghost then 180 else 255)
    rect(x + pad, y + pad, body, body * 0.84, main, if ghost then 160 else 255)

    if kind == "belt" then
        rect(x + s * 0.18, y + s * 0.15, s * 0.64, s * 0.7, COLORS.beltTrack, 125)
        local phase = math.floor(seconds * 5) % 2
        for i = 0, 2 do
            local offset = (i + phase * 0.5) * s * 0.23
            if dir % 2 == 0 then
                rect(x + s * 0.18 + offset, y + s * 0.23, s * 0.055, s * 0.52, COLORS.beltEdge)
            else
                rect(x + s * 0.23, y + s * 0.18 + offset, s * 0.52, s * 0.055, COLORS.beltEdge)
            end
        end
        arrow(x, y, s, dir, COLORS.white)
    elseif kind == "miner" then
        rect(x + s * 0.27, y + s * 0.25, s * 0.46, s * 0.44, COLORS.dark)
        Draw.CircleSDF(x + s * 0.5, y + s * 0.47, s * 0.12, 245, 227, 152, 255)
        arrow(x, y, s, dir, COLORS.white)
    elseif kind == "furnace" then
        rect(x + s * 0.24, y + s * 0.20, s * 0.52, s * 0.55, COLORS.dark)
        local pulse = math.floor(seconds * 6) % 2
        rect(x + s * 0.34, y + s * (if pulse == 0 then 0.40 else 0.36),
            s * 0.32, s * 0.26, {253, 187, 90})
        arrow(x, y, s, dir, COLORS.white)
    elseif kind == "assembler" then
        Draw.CircleSDF(x + s * 0.5, y + s * 0.47, s * 0.21, 36, 90, 102, 255)
        Draw.CircleSDF(x + s * 0.5, y + s * 0.47, s * 0.11, 154, 217, 202, 255)
        Draw.CircleSDF(x + s * 0.5, y + s * 0.47, s * 0.052, 36, 90, 102, 255)
        arrow(x, y, s, dir, COLORS.white)
    elseif kind == "chest" then
        rect(x + s * 0.22, y + s * 0.25, s * 0.56, s * 0.53, {42, 82, 69})
        rect(x + s * 0.27, y + s * 0.33, s * 0.46, s * 0.10, COLORS.chest)
        rect(x + s * 0.44, y + s * 0.25, s * 0.12, s * 0.53, COLORS.chest)
    end

    local progress = 0
    if kind == "miner" then progress = (cell.work or 0) / Config.MACHINE_TIME.miner end
    if kind == "furnace" then progress = (cell.work or 0) / Config.MACHINE_TIME.furnace end
    if kind == "assembler" then progress = (cell.work or 0) / Config.MACHINE_TIME.assembler end
    if progress > 0 then
        rect(x + s * 0.15, y + s * 0.85, s * 0.70, s * 0.065, COLORS.dark)
        rect(x + s * 0.15, y + s * 0.85, s * 0.70 * math.clamp(progress, 0, 1), s * 0.065, COLORS.white)
    end
    if cell.item then
        itemIcon(cell.item, x + s * 0.5, y + s * 0.50, s)
    end
    if cell.output and kind ~= "miner" then
        itemIcon(cell.output, x + s * 0.76, y + s * 0.22, s * 0.43)
    end
end

function Renderer.prepare(snapshot: {[string]: any})
    local oreSet: {[string]: boolean} = {}
    for _, ore in ipairs(snapshot.ores or {}) do
        oreSet[Config.Key(ore.x, ore.y)] = true
    end
    local byTile: {[string]: {[string]: any}} = {}
    for _, cell in ipairs(snapshot.cells or {}) do
        byTile[Config.Key(cell.x, cell.y)] = cell
    end
    return {oreSet = oreSet, byTile = byTile}
end

function Renderer.draw(snapshot: {[string]: any}?, cache: {[string]: any}?, cameraX: number,
    cameraY: number, zoom: number, hoverX: number?, hoverY: number?, tool: string,
    dir: number, seconds: number)

    Draw.Clear(24, 36, 40, 255)
    if not snapshot or not cache then return end

    local width = Ro2D.Width
    local height = Ro2D.Height
    if width <= 0 or height <= 0 then return end
    local s = TILE * zoom
    local loX = math.max(1, math.floor(cameraX / s) + 1)
    local loY = math.max(1, math.floor(cameraY / s) + 1)
    local hiX = math.min(snapshot.width, math.ceil((cameraX + width) / s) + 1)
    local hiY = math.min(snapshot.height, math.ceil((cameraY + height) / s) + 1)

    for y = loY, hiY do
        local py = math.floor((y - 1) * s - cameraY)
        for x = loX, hiX do
            local px = math.floor((x - 1) * s - cameraX)
            local shade = if (x + y) % 2 == 0 then COLORS.ground else COLORS.groundAlt
            rect(px, py, math.ceil(s), math.ceil(s), shade)
            rect(px, py, math.ceil(s), math.max(1, zoom), COLORS.grid, 120)
            rect(px, py, math.max(1, zoom), math.ceil(s), COLORS.grid, 120)
            if cache.oreSet[Config.Key(x, y)] then
                Draw.CircleSDF(px + s * 0.50, py + s * 0.54, s * 0.31,
                    COLORS.oreEdge[1], COLORS.oreEdge[2], COLORS.oreEdge[3], 255)
                Draw.CircleSDF(px + s * 0.48, py + s * 0.47, s * 0.24,
                    COLORS.ore[1], COLORS.ore[2], COLORS.ore[3], 255)
                rect(px + s * 0.37, py + s * 0.34, s * 0.19, s * 0.10, COLORS.oreLight)
            end
        end
    end
    for y = loY, hiY do
        for x = loX, hiX do
            local cell = cache.byTile[Config.Key(x, y)]
            if cell then
                machine(cell, math.floor((x - 1) * s - cameraX),
                    math.floor((y - 1) * s - cameraY), s, seconds, false)
            end
        end
    end

    if hoverX and hoverY and Config.Inside(hoverX, hoverY) then
        local px = math.floor((hoverX - 1) * s - cameraX)
        local py = math.floor((hoverY - 1) * s - cameraY)
        local occupied = cache.byTile[Config.Key(hoverX, hoverY)] ~= nil
        local valid = tool == "erase" and occupied
            or (not occupied and (tool ~= "miner" or cache.oreSet[Config.Key(hoverX, hoverY)] == true))
        local c = if valid then COLORS.ghost else COLORS.invalid
        rect(px + 1, py + 1, s - 2, s - 2, c, 44)
        rect(px + 1, py + 1, s - 2, math.max(2, s * 0.045), c)
        rect(px + 1, py + s - math.max(3, s * 0.045), s - 2, math.max(2, s * 0.045), c)
        rect(px + 1, py + 1, math.max(2, s * 0.045), s - 2, c)
        rect(px + s - math.max(3, s * 0.045), py + 1, math.max(2, s * 0.045), s - 2, c)
        if valid and tool ~= "erase" then
            machine({kind = tool, dir = dir, work = 0}, px, py, s, seconds, true)
        end
    end
end

return Renderer
