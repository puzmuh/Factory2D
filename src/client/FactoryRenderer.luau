--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ro2D = require(ReplicatedStorage:WaitForChild("Ro2DEngine"))

local Draw = Ro2D.Draw
local TILE = Config.TILE
local Renderer = {}
local TerrainArt = require(script.Parent:WaitForChild("TerrainArt"))
local EngineerArt = require(script.Parent:WaitForChild("EngineerArt"))

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
    local pad = math.max(1, s * 0.075)
    local body = s - pad * 2
    local alpha = if ghost then 165 else 255
    local shadow = {32, 27, 22}
    local steel = {81, 84, 82}
    local darkSteel = {43, 46, 44}
    local pale = {217, 208, 180}
    local amber = {204, 157, 74}
    local edge, main = {49, 49, 44}, {97, 96, 86}
    if kind == "miner" then edge, main = {78, 58, 35}, {166, 122, 65} end
    if kind == "furnace" then edge, main = {68, 49, 36}, {118, 96, 75} end
    if kind == "assembler" then edge, main = {37, 61, 57}, {76, 111, 101} end
    if kind == "chest" then edge, main = {68, 49, 32}, {123, 95, 61} end

    rect(x + pad + s * 0.08, y + pad + s * 0.10, body, body * 0.86, shadow, if ghost then 60 else 110)
    rect(x + pad, y + pad + s * 0.03, body, body, edge, alpha)
    rect(x + pad, y + pad, body, body * 0.79, main, alpha)
    rect(x + pad + s * 0.05, y + pad + s * 0.045, body * 0.72, math.max(1, s * 0.055),
        {190, 174, 134}, if ghost then 100 else 90)
    if kind == "belt" then
        rect(x + s * 0.17, y + s * 0.16, s * 0.66, s * 0.60, steel, alpha)
        rect(x + s * 0.22, y + s * 0.20, s * 0.56, s * 0.52, darkSteel, alpha)
        local phase = (seconds * 3.8) % 1
        for i = 0, 2 do
            local offset = (i * 0.26 + phase * 0.26) * s
            if dir % 2 == 0 then
                rect(x + s * 0.21 + offset, y + s * 0.28, s * 0.075, s * 0.36, amber, alpha)
            else
                rect(x + s * 0.28, y + s * 0.21 + offset, s * 0.36, s * 0.075, amber, alpha)
            end
        end
        arrow(x, y, s, dir, pale)
    elseif kind == "miner" then
        rect(x + s * 0.20, y + s * 0.23, s * 0.60, s * 0.46, steel, alpha)
        rect(x + s * 0.28, y + s * 0.31, s * 0.29, s * 0.13, darkSteel, alpha)
        Draw.CircleSDF(x + s * 0.50, y + s * 0.50, s * 0.13, 225, 176, 87, alpha)
        arrow(x, y, s, dir, pale)
    elseif kind == "furnace" then
        rect(x + s * 0.21, y + s * 0.22, s * 0.58, s * 0.49, darkSteel, alpha)
        rect(x + s * 0.30, y + s * 0.14, s * 0.17, s * 0.16, edge, alpha)
        local fire = math.floor(seconds * 6) % 2
        rect(x + s * 0.32, y + s * (if fire == 0 then 0.39 else 0.42), s * 0.36, s * 0.20,
            {244, 164, 68}, alpha)
        rect(x + s * 0.39, y + s * 0.47, s * 0.23, s * 0.04, {255, 215, 134}, alpha)
        arrow(x, y, s, dir, pale)
    elseif kind == "assembler" then
        Draw.CircleSDF(x + s * 0.50, y + s * 0.47, s * 0.23, 40, 61, 55, alpha)
        Draw.CircleSDF(x + s * 0.50, y + s * 0.47, s * 0.16, 171, 187, 129, alpha)
        Draw.CircleSDF(x + s * 0.50, y + s * 0.47, s * 0.08, 39, 58, 54, alpha)
        arrow(x, y, s, dir, pale)
    elseif kind == "chest" then
        rect(x + s * 0.22, y + s * 0.26, s * 0.56, s * 0.45, edge, alpha)
        rect(x + s * 0.25, y + s * 0.29, s * 0.50, s * 0.36, main, alpha)
        rect(x + s * 0.27, y + s * 0.34, s * 0.46, s * 0.08, {165, 134, 83}, alpha)
        rect(x + s * 0.46, y + s * 0.27, s * 0.08, s * 0.38, pale, if ghost then 110 else 180)
    end

    local progress = 0
    if kind == "miner" then progress = (cell.work or 0) / Config.MACHINE_TIME.miner end
    if kind == "furnace" then progress = (cell.work or 0) / Config.MACHINE_TIME.furnace end
    if kind == "assembler" then progress = (cell.work or 0) / Config.MACHINE_TIME.assembler end
    if progress > 0 then
        rect(x + s * 0.14, y + s * 0.84, s * 0.72, s * 0.08, darkSteel)
        rect(x + s * 0.14, y + s * 0.84, s * 0.72 * math.clamp(progress, 0, 1), s * 0.08, amber)
    end
    if cell.item then itemIcon(cell.item, x + s * 0.50, y + s * 0.50, s) end
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

    Draw.Clear(104, 88, 61, 255)
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
            TerrainArt.drawTile(x, y, px, py, s)
            if cache.oreSet[Config.Key(x, y)] then
                TerrainArt.drawOre(x, y, px, py, s)
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

    -- Original placeholder avatar: centered on the view; movement controller comes later.
    EngineerArt.draw(width * 0.5, height * 0.58, s, seconds)

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
