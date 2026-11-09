--!strict
-- Original, procedurally drawn wasteland terrain; no external texture assets.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ro2D = require(ReplicatedStorage:WaitForChild("Ro2DEngine"))
local Draw = Ro2D.Draw
local TerrainArt = {}

local function rand(x: number, y: number, seed: number): number
    local a = math.sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453
    return a - math.floor(a)
end

local function fill(x: number, y: number, w: number, h: number, c: {number}, a: number?)
    if w < 1 or h < 1 then return end
    Draw.Rect(x, y, w, h, c[1], c[2], c[3], a or 255)
end

local function circle(x: number, y: number, radius: number, c: {number}, a: number?)
    Draw.CircleSDF(x, y, radius, c[1], c[2], c[3], a or 255)
end

local SOIL = {
    {136, 109, 75}, {126, 101, 68}, {145, 118, 80},
    {117, 94, 64}, {107, 90, 62}, {153, 124, 84},
}
local PEBBLE = {81, 68, 48}
local SCRUB = {77, 89, 49}
local SCRUB_DARK = {46, 58, 32}
local BRIGHT = {180, 151, 104}
local SHADOW = {43, 37, 28}

function TerrainArt.drawTile(tx: number, ty: number, x: number, y: number, s: number)
    -- Two spatial scales of variation make the ground patchy without a checkerboard.
    local macro = rand(math.floor(tx / 3), math.floor(ty / 3), 1)
    local fine = rand(tx, ty, 2)
    local index = 1 + math.floor(math.min(0.999, macro * 0.7 + fine * 0.3) * #SOIL)
    local c = SOIL[index]
    fill(x, y, math.ceil(s), math.ceil(s), c)
    if fine > 0.38 then
        fill(x + s * 0.08, y + s * 0.63, s * (0.34 + fine * 0.24), math.max(1, s * 0.10), SHADOW, 45)
    end
    if rand(tx, ty, 3) > 0.62 then
        fill(x + s * 0.39, y + s * 0.25, math.max(1, s * 0.22), math.max(1, s * 0.06), BRIGHT, 41)
    end
    if rand(tx, ty, 4) > 0.78 then
        fill(x + s * 0.17, y + s * 0.18, math.max(1, s * 0.09), math.max(1, s * 0.10), PEBBLE, 145)
        fill(x + s * 0.64, y + s * 0.55, math.max(1, s * 0.06), math.max(1, s * 0.05), PEBBLE, 120)
    end
    -- Brush is deliberately sparse; dense plants would camouflage machines.
    if rand(tx, ty, 5) > 0.87 and s >= 12 then
        local px = x + s * (0.23 + rand(tx, ty, 6) * 0.46)
        local py = y + s * (0.24 + rand(tx, ty, 7) * 0.45)
        circle(px + s * 0.05, py + s * 0.07, s * 0.12, SHADOW, 105)
        circle(px, py, s * 0.09, SCRUB, 229)
        circle(px + s * 0.085, py - s * 0.015, s * 0.075, SCRUB_DARK, 218)
    end
    -- Almost invisible build grid. No alternating filled squares.
    fill(x, y, math.ceil(s), math.max(1, s * 0.023), SHADOW, 18)
    fill(x, y, math.max(1, s * 0.023), math.ceil(s), SHADOW, 18)
end

function TerrainArt.drawOre(tx: number, ty: number, x: number, y: number, s: number)
    local ox = x + s * (0.45 + rand(tx, ty, 8) * 0.13)
    local oy = y + s * (0.48 + rand(tx, ty, 9) * 0.10)
    circle(ox + s * 0.08, oy + s * 0.10, s * 0.30, SHADOW, 122)
    circle(ox, oy, s * 0.28, {56, 66, 70}, 255)
    circle(ox - s * 0.06, oy - s * 0.06, s * 0.20, {115, 133, 136}, 255)
    circle(ox + s * 0.11, oy + s * 0.06, s * 0.13, {82, 99, 107}, 255)
    circle(ox - s * 0.11, oy + s * 0.04, s * 0.08, {167, 181, 177}, 240)
end

return TerrainArt
