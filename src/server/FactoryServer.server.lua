--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FactoryWorld = require(script.Parent:WaitForChild("FactoryWorld"))

local remote = Instance.new("RemoteEvent")
remote.Name = "FactoryRemote"
remote.Parent = ReplicatedStorage

local worlds: {[Player]: any} = {}
local lastRequest: {[Player]: number} = {}
local lastGet: {[Player]: number} = {}

local function send(player: Player)
    local world = worlds[player]
    if world then remote:FireClient(player, "Snapshot", FactoryWorld.snapshot(world)) end
end

local function onJoin(player: Player)
    worlds[player] = FactoryWorld.new()
end

Players.PlayerAdded:Connect(onJoin)
for _, player in ipairs(Players:GetPlayers()) do onJoin(player) end
Players.PlayerRemoving:Connect(function(player)
    worlds[player] = nil
    lastRequest[player] = nil
    lastGet[player] = nil
end)

remote.OnServerEvent:Connect(function(player: Player, action: any, x: any, y: any, tool: any, facing: any)
    local world = worlds[player]
    if world == nil or typeof(action) ~= "string" then return end
    if action == "Get" then
        local now = os.clock()
        if now - (lastGet[player] or -10) >= 0.75 then
            lastGet[player] = now
            send(player)
        end
        return
    end
    if typeof(x) ~= "number" or typeof(y) ~= "number" then return end
    if x ~= math.floor(x) or y ~= math.floor(y) or not Config.Inside(x, y) then return end
    local now = os.clock()
    if now - (lastRequest[player] or 0) < 0.08 then return end
    lastRequest[player] = now
    local changed = false
    if action == "Place" then
        if typeof(tool) ~= "string" or typeof(facing) ~= "number" then return end
        if facing ~= math.floor(facing) or facing < 0 or facing > 3 then return end
        changed = FactoryWorld.place(world, x, y, tool, facing)
    elseif action == "Remove" then
        changed = FactoryWorld.remove(world, x, y)
    elseif action == "Rotate" then
        changed = FactoryWorld.rotate(world, x, y)
    end
    if changed then send(player) end
end)

local accumulated = 0
local broadcastTimer = 0
RunService.Heartbeat:Connect(function(dt: number)
    accumulated += math.min(dt, 0.25)
    while accumulated >= Config.STEP do
        accumulated -= Config.STEP
        for _, world in pairs(worlds) do
            FactoryWorld.step(world, Config.STEP)
        end
    end
    broadcastTimer += dt
    if broadcastTimer >= 0.25 then
        broadcastTimer = 0
        for player in pairs(worlds) do send(player) end
    end
end)
