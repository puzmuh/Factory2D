--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Ro2D = require(ReplicatedStorage:WaitForChild("Ro2DEngine"))
local FactoryRenderer = require(script.Parent:WaitForChild("FactoryRenderer"))
local remote = ReplicatedStorage:WaitForChild("FactoryRemote") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "Factory2DGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 15
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local canvas = Instance.new("Frame")
canvas.Name = "CanvasFrame"
canvas.Size = UDim2.fromScale(1, 1)
canvas.BackgroundColor3 = Color3.fromRGB(92, 76, 52)
canvas.BorderSizePixel = 0
canvas.Parent = gui

-- Parallel rendering is intentionally off for first-time setup / debugging.
-- Once the project is stable try Parallel=true, WorkerCount=4.
Ro2D.System.Init(canvas, {
    Isolate2D = true,
    Resolution = Config.CANVAS,
    AntiAliasing = false,
    Parallel = false,
})

local function rounded(parent: GuiObject, radius: number)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
end

local function stroke(parent: GuiObject)
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(135, 108, 77)
    border.Transparency = 0.6
    border.Thickness = 1
    border.Parent = parent
end

local function newFrame(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(31, 26, 22)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    rounded(frame, 12)
    stroke(frame)
    frame.Parent = parent
    return frame
end

local function textLabel(parent: Instance, name: string, text: string, size: UDim2,
    position: UDim2, textSize: number, color: Color3, bold: boolean): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Size = size
    label.Position = position
    label.Font = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 5
    label.Parent = parent
    return label
end

local header = newFrame(gui, "Header", UDim2.fromOffset(435, 66), UDim2.fromOffset(16, 16))
textLabel(header, "Title", "FACTORY / 2D", UDim2.fromOffset(280, 25), UDim2.fromOffset(18, 9),
    20, Color3.fromRGB(242, 246, 228), true)
local statusLabel = textLabel(header, "Status", "Connecting to factory...", UDim2.fromOffset(403, 22),
    UDim2.fromOffset(18, 37), 12, Color3.fromRGB(184, 164, 133), false)

local counter = newFrame(gui, "Counter", UDim2.fromOffset(208, 66),
    UDim2.new(1, -224, 0, 16))
textLabel(counter, "Caption", "GEARS PRODUCED", UDim2.fromOffset(180, 20),
    UDim2.fromOffset(15, 10), 11, Color3.fromRGB(149, 177, 163), true)
local gearLabel = textLabel(counter, "Number", "0", UDim2.fromOffset(180, 28),
    UDim2.fromOffset(15, 29), 23, Color3.fromRGB(237, 192, 99), true)

local hint = newFrame(gui, "Hint", UDim2.fromOffset(530, 42),
    UDim2.new(0.5, -265, 1, -130))
local hintText = textLabel(hint, "Text", "WASD pan  |  Mouse wheel zoom  |  R turn  |  F rotate machine  |  RMB remove",
    UDim2.new(1, -24, 1, 0), UDim2.fromOffset(12, 0), 11, Color3.fromRGB(191, 174, 145), false)
hintText.TextXAlignment = Enum.TextXAlignment.Center
hintText.TextScaled = false

local toolbar = newFrame(gui, "Toolbar", UDim2.fromOffset(584, 82),
    UDim2.new(0.5, -292, 1, -94))

local selectedTool = "belt"
local facing = 0
local snapshot: {[string]: any}? = nil
local cache: {[string]: any}? = nil
local buttons: {[string]: TextButton} = {}
local selectedColors = {
    Color3.fromRGB(214, 166, 86), Color3.fromRGB(118, 149, 100),
}

local function renderToolbar()
    for tool, button in pairs(buttons) do
        local selected = tool == selectedTool
        button.BackgroundColor3 = if selected then selectedColors[1] else Color3.fromRGB(72, 58, 43)
        button.TextColor3 = if selected then Color3.fromRGB(30, 26, 20) else Color3.fromRGB(225, 215, 194)
    end
end

for i, tool in ipairs(Config.TOOLS) do
    local button = Instance.new("TextButton")
    button.Name = tool
    button.AutoButtonColor = true
    button.Text = tostring(i) .. "\n" .. Config.TOOL_NAMES[tool]
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextWrapped = true
    button.Size = UDim2.fromOffset(86, 60)
    button.Position = UDim2.fromOffset(10 + (i - 1) * 95, 11)
    button.ZIndex = 5
    button.BorderSizePixel = 0
    rounded(button, 9)
    button.Parent = toolbar
    buttons[tool] = button
    button.Activated:Connect(function()
        selectedTool = tool
        renderToolbar()
    end)
end
renderToolbar()

local inspect = newFrame(gui, "Inspect", UDim2.fromOffset(235, 76),
    UDim2.new(1, -251, 1, -109))
local inspectTitle = textLabel(inspect, "InspectTitle", "SELECT A TILE", UDim2.fromOffset(210, 23),
    UDim2.fromOffset(12, 9), 14, Color3.fromRGB(233, 243, 229), true)
local inspectBody = textLabel(inspect, "InspectBody", "Hover over a machine", UDim2.fromOffset(210, 37),
    UDim2.fromOffset(12, 32), 11, Color3.fromRGB(153, 190, 181), false)
inspectBody.TextWrapped = true

local cameraX = 0
local cameraY = 118
local zoom = 1
local hoverX: number? = nil
local hoverY: number? = nil
local previousLeft = false
local previousRight = false
local elapsed = 0
local lastImageCheck = 0

local function clampCamera()
    local w = if Ro2D.Width > 0 then Ro2D.Width else Config.CANVAS.X
    local h = if Ro2D.Height > 0 then Ro2D.Height else Config.CANVAS.Y
    cameraX = math.clamp(cameraX, 0, math.max(0, Config.WIDTH * Config.TILE * zoom - w))
    cameraY = math.clamp(cameraY, 0, math.max(0, Config.HEIGHT * Config.TILE * zoom - h))
end

local function zoomAt(delta: number, mx: number, my: number)
    local old = zoom
    local nextZoom = math.clamp(zoom + delta * 0.125, Config.MIN_ZOOM, Config.MAX_ZOOM)
    cameraX = (cameraX + mx) * (nextZoom / old) - mx
    cameraY = (cameraY + my) * (nextZoom / old) - my
    zoom = nextZoom
    clampCamera()
end

local keys = {
    [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
}
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if processed then return end
    local index = keys[input.KeyCode]
    if index then
        selectedTool = Config.TOOLS[index]
        renderToolbar()
    elseif input.KeyCode == Enum.KeyCode.R then
        facing = (facing + 1) % 4
    elseif input.KeyCode == Enum.KeyCode.F and hoverX and hoverY then
        remote:FireServer("Rotate", hoverX, hoverY)
    elseif input.KeyCode == Enum.KeyCode.E then
        zoomAt(1, Config.CANVAS.X * 0.5, Config.CANVAS.Y * 0.5)
    elseif input.KeyCode == Enum.KeyCode.Q then
        zoomAt(-1, Config.CANVAS.X * 0.5, Config.CANVAS.Y * 0.5)
    end
end)

remote.OnClientEvent:Connect(function(action: string, data: any)
    if action ~= "Snapshot" or typeof(data) ~= "table" then return end
    snapshot = data
    cache = FactoryRenderer.prepare(data)
    gearLabel.Text = tostring(data.totals.gear or 0)
    statusLabel.Text = ("Creative mode  |  Tick %d  |  %d structures")
        :format(data.tick or 0, #(data.cells or {}))
end)
remote:FireServer("Get")

RunService.RenderStepped:Connect(function(dt: number)
    elapsed += dt
    if elapsed > 3 and elapsed - lastImageCheck > 2 then
        lastImageCheck = elapsed
        local reason = Ro2D.System.ImageError()
        if reason then statusLabel.Text = "Canvas error: " .. reason end
    end
    if not Ro2D.IsReady then return end
    local cameraSpeed = 290 * zoom * dt
    if Ro2D.Input.IsKeyDown(Enum.KeyCode.A) or Ro2D.Input.IsKeyDown(Enum.KeyCode.Left) then
        cameraX -= cameraSpeed
    end
    if Ro2D.Input.IsKeyDown(Enum.KeyCode.D) or Ro2D.Input.IsKeyDown(Enum.KeyCode.Right) then
        cameraX += cameraSpeed
    end
    if Ro2D.Input.IsKeyDown(Enum.KeyCode.W) or Ro2D.Input.IsKeyDown(Enum.KeyCode.Up) then
        cameraY -= cameraSpeed
    end
    if Ro2D.Input.IsKeyDown(Enum.KeyCode.S) or Ro2D.Input.IsKeyDown(Enum.KeyCode.Down) then
        cameraY += cameraSpeed
    end
    clampCamera()

    local mx, my = Ro2D.Input.GetMousePosition()
    local scroll = Ro2D.Input.GetScrollDelta()
    if scroll ~= 0 then zoomAt(if scroll > 0 then 1 else -1, mx, my) end
    local width = Ro2D.Width
    local height = Ro2D.Height
    local inCanvas = mx >= 0 and my >= 0 and mx < width and my < height
    -- Ignore input where the native HUD overlays the Ro2D image.
    local overlay = my < 85 and (mx < 460 or mx > width - 240)
        or my > height - 152 and mx > width * 0.5 - 300 and mx < width * 0.5 + 300
        or my > height - 113 and mx > width - 255
    hoverX, hoverY = nil, nil
    if inCanvas and not overlay then
        local x = math.floor((mx + cameraX) / (Config.TILE * zoom)) + 1
        local y = math.floor((my + cameraY) / (Config.TILE * zoom)) + 1
        if Config.Inside(x, y) then hoverX, hoverY = x, y end
    end
    local left = Ro2D.Input.IsMouseDown(1)
    local right = Ro2D.Input.IsMouseDown(2)
    if hoverX and hoverY then
        local cell = cache and cache.byTile[Config.Key(hoverX, hoverY)]
        if cell then
            inspectTitle.Text = string.upper(Config.TOOL_NAMES[cell.kind] or cell.kind)
            inspectBody.Text = if cell.kind == "chest" then
                ("Ore: %d    Plates: %d    Gears: %d"):format(
                    cell.stored.ore or 0, cell.stored.plate or 0, cell.stored.gear or 0)
                else ("Tile %d, %d    Facing %d    Input: %d")
                    :format(hoverX, hoverY, cell.dir, cell.raw or 0)
        else
            inspectTitle.Text = "EMPTY TILE"
            inspectBody.Text = ("Tile %d, %d  |  %s"):format(hoverX, hoverY,
                if cache and cache.oreSet[Config.Key(hoverX, hoverY)] then "Ore deposit" else "Buildable")
        end
        if left and not previousLeft then
            if selectedTool == "erase" then
                remote:FireServer("Remove", hoverX, hoverY)
            else
                remote:FireServer("Place", hoverX, hoverY, selectedTool, facing)
            end
        elseif right and not previousRight then
            remote:FireServer("Remove", hoverX, hoverY)
        end
    end
    previousLeft = left
    previousRight = right
    FactoryRenderer.draw(snapshot, cache, cameraX, cameraY, zoom,
        hoverX, hoverY, selectedTool, facing, elapsed)
end)
