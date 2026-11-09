--!strict
-- Stylized original top-down engineer illustration, used as a temporary avatar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ro2D = require(ReplicatedStorage:WaitForChild("Ro2DEngine"))
local Draw = Ro2D.Draw
local EngineerArt = {}

local SUIT = {177, 129, 65}
local TRIM = {67, 51, 35}
local PACK = {71, 84, 68}
local VISOR = {193, 202, 200}
local METAL = {139, 148, 143}
local SHADOW = {32, 25, 20}

local function rect(x: number, y: number, w: number, h: number, c: {number}, alpha: number?)
    Draw.Rect(x, y, math.max(1, w), math.max(1, h), c[1], c[2], c[3], alpha or 255)
end
local function circle(x: number, y: number, r: number, c: {number}, alpha: number?)
    Draw.CircleSDF(x, y, r, c[1], c[2], c[3], alpha or 255)
end
local function line(x: number, y: number, x2: number, y2: number, width: number, c: {number})
    Draw.LineSDF(x, y, x2, y2, width, c[1], c[2], c[3])
end

function EngineerArt.draw(x: number, y: number, tilePixels: number, time: number)
    local s = tilePixels * 0.88
    if s < 7 then return end
    local idle = math.sin(time * 2.4) * s * 0.012
    -- Shadow lands below the figure, consistent with terrain's light direction.
    circle(x + s * 0.08, y + s * 0.34, s * 0.32, SHADOW, 125)
    -- Boots and suit.
    rect(x - s * 0.17, y + s * 0.08, s * 0.12, s * 0.19, TRIM)
    rect(x + s * 0.05, y + s * 0.08, s * 0.12, s * 0.19, TRIM)
    rect(x - s * 0.24, y - s * 0.13, s * 0.48, s * 0.37, PACK)
    rect(x - s * 0.20, y - s * 0.16 + idle, s * 0.40, s * 0.35, SUIT)
    rect(x - s * 0.05, y - s * 0.10, s * 0.10, s * 0.27, {215, 177, 111})
    -- Arms, backpack straps, and welding tool.
    line(x - s * 0.23, y - s * 0.02, x - s * 0.34, y + s * 0.12, s * 0.09, SUIT)
    line(x + s * 0.23, y - s * 0.02, x + s * 0.31, y + s * 0.08, s * 0.09, SUIT)
    line(x + s * 0.30, y + s * 0.06, x + s * 0.45, y - s * 0.08, s * 0.055, METAL)
    rect(x - s * 0.21, y - s * 0.15, s * 0.08, s * 0.17, TRIM)
    rect(x + s * 0.13, y - s * 0.15, s * 0.08, s * 0.17, TRIM)
    -- Helmet with a small curved implied visor.
    circle(x, y - s * 0.29 + idle, s * 0.19, SUIT)
    rect(x - s * 0.12, y - s * 0.35 + idle, s * 0.24, s * 0.085, VISOR)
    rect(x - s * 0.07, y - s * 0.18 + idle, s * 0.14, s * 0.042, TRIM)
end

return EngineerArt
