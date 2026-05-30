local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local Lobby = Workspace:WaitForChild("Lobby")
local classOptions = {"Economist", "Cultivator", "Advocate"}
local debounce = {}

local portals = {
    {model = Lobby:WaitForChild("Solo Mode"), req = 1},
    {model = Lobby:WaitForChild("Duo Mode"), req = 2},
    {model = Lobby:WaitForChild("Trio Mode"), req = 3},
}

local function playTeleportEffect(position, classColor)
    local beam = Instance.new("Part")
    beam.Name = "TeleportBeam"
    beam.Shape = Enum.PartType.Cylinder
    beam.Size = Vector3.new(80, 8, 8)
    beam.Color = classColor
    beam.Material = Enum.Material.Neon
    beam.Transparency = 0.2
    beam.CanCollide = false
    beam.Anchored = true
    beam.CFrame = CFrame.new(position + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90))
    beam.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(-40, 0, 0)
    attachment.Parent = beam
    
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Color = ColorSequence.new(classColor)
    sparkles.Texture = "rbxassetid://258129767"
    sparkles.Rate = 120
    sparkles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.4),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparkles.Lifetime = NumberRange.new(0.4, 1.0)
    sparkles.Speed = NumberRange.new(12, 25)
    sparkles.SpreadAngle = Vector2.new(45, 45)
    sparkles.Acceleration = Vector3.new(0, 12, 0)
    sparkles.Parent = attachment
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://8413626241"
    sound.Volume = 0.75
    sound.Parent = beam
    sound:Play()
    
    task.spawn(function()
        local TweenService = game:GetService("TweenService")
        local tween = TweenService:Create(beam, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(80, 0, 0),
            Transparency = 1
        })
        tween:Play()
        tween.Completed:Wait()
        beam:Destroy()
    end)
end

local function teleportPlayer(player, assignedClass)
    local oldChar = player.Character
    local classColor = GameConfig.CLASSES[assignedClass].Color
    
    local newChar = RS:WaitForChild("SphereCharacter"):Clone()
    newChar.Name = player.Name
    
    local root = newChar:WaitForChild("HumanoidRootPart")
    root.Anchored = true
    newChar:PivotTo(CFrame.new(0, 515, 0))
    
    if oldChar and oldChar.PrimaryPart then
        playTeleportEffect(oldChar:GetPivot().Position, classColor)
    else
        playTeleportEffect(Vector3.new(0, 512, 0), classColor)
    end
    
    newChar.Parent = workspace
    player.Character = newChar
    
    if oldChar then oldChar:Destroy() end
    
    task.delay(0.35, function()
        if root and root.Parent then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            root.Anchored = false
            pcall(function() root:SetNetworkOwner(player) end)
        end
    end)
    
    Remotes.StartGameClient:FireClient(player, assignedClass)
end

RunService.Heartbeat:Connect(function()
    for _, portalData in ipairs(portals) do
        local pad = portalData.model:FindFirstChild("Pad")
        if not pad then continue end
        local bgui = pad:FindFirstChild("Info")
        local txt = bgui and bgui:FindFirstChild("TextLabel")
        
        local charsInZone = {}
        local overlapParams = OverlapParams.new()
        overlapParams.FilterType = Enum.RaycastFilterType.Include
        local charList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(charList, p.Character)
            end
        end
        if #charList == 0 then continue end
        overlapParams.FilterDescendantsInstances = charList
        
        local parts = Workspace:GetPartBoundsInBox(pad.CFrame, pad.Size + Vector3.new(2, 4, 2), overlapParams)
        local playersInZone = {}
        for _, part in ipairs(parts) do
            local char = part:FindFirstAncestorWhichIsA("Model")
            if char then
                local player = Players:GetPlayerFromCharacter(char)
                if player and not charsInZone[player] then
                    charsInZone[player] = true
                    table.insert(playersInZone, player)
                end
            end
        end
        
        if txt then
            txt.Text = portalData.model.Name .. "\n(" .. #playersInZone .. "/" .. portalData.req .. ")"
        end
        
        if #playersInZone == portalData.req then
            local available = {table.unpack(classOptions)}
            -- shuffle available classes
            for i = #available, 2, -1 do
                local j = math.random(i)
                available[i], available[j] = available[j], available[i]
            end
            
            for index, player in ipairs(playersInZone) do
                if not debounce[player] then
                    debounce[player] = true
                    
                    local assignedClass = available[(index - 1) % #available + 1]
                    task.spawn(teleportPlayer, player, assignedClass)
                    task.delay(5, function() debounce[player] = nil end)
                end
            end
        end
    end
end)
