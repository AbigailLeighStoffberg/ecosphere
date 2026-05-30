-- BlueprintManager: Handles Holographic Capture & Build mechanic
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GameConfig = require(RS:WaitForChild("GameConfig"))

-- OverlapParams for checking players in CaptureZone
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include

local blueprintColor = Color3.fromRGB(0, 255, 255) -- Neon Teal

local function stylePart(part)
    part.Material = Enum.Material.ForceField
    part.Color = blueprintColor
    part.Transparency = 0.8
    part.CanCollide = false
    part.Anchored = true
    part.CastShadow = false
end

local function addCaptureZone(model)
    local cf, size = model:GetBoundingBox()
    local pivot = model:GetPivot()
    local centerPos = pivot.Position
    
    -- Raycast towards the planet (0,0,0) to find the exact floor surface
    local rayDir = (Vector3.new(0,0,0) - centerPos).Unit * 500
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {model}
    
    local rayResult = Workspace:Raycast(centerPos, rayDir, rayParams)
    
    local floorPos, floorNormal
    if rayResult then
        floorPos = rayResult.Position
        floorNormal = rayResult.Normal
    else
        floorPos = centerPos - (centerPos.Unit * (size.Y/2))
        floorNormal = centerPos.Unit
    end
    
    -- Build a CFrame perfectly aligned with the floor
    local up = floorNormal
    local right = pivot.RightVector
    if math.abs(right:Dot(up)) > 0.99 then
        right = pivot.LookVector
    end
    local forward = right:Cross(up).Unit
    right = up:Cross(forward).Unit
    local surfaceCFrame = CFrame.fromMatrix(floorPos, right, up, forward)
    
    -- Calculate radius based on all dimensions since model might be rotated
    local assetRadius = math.max(size.X, size.Y, size.Z) / 2
    local zoneRadius = assetRadius + 50
    local diameter = zoneRadius * 2

    local captureZone = Instance.new("Part")
    captureZone.Name = "CaptureZone"
    captureZone.Shape = Enum.PartType.Cylinder
    captureZone.Size = Vector3.new(100, diameter, diameter) 
    captureZone.Transparency = 1
    captureZone.CanCollide = false
    captureZone.Anchored = true
    captureZone.Color = Color3.new(1,0,0)
    
    -- Stand it up perfectly at the surface
    captureZone.CFrame = surfaceCFrame * CFrame.Angles(0, 0, math.rad(90))
    captureZone.Parent = model
    
    -- Thin glowing line
    local ringAnchor = Instance.new("Part")
    ringAnchor.Name = "NeonRing"
    ringAnchor.Size = Vector3.new(1,1,1)
    ringAnchor.Transparency = 1
    ringAnchor.CanCollide = false
    ringAnchor.Anchored = true
    ringAnchor.CFrame = surfaceCFrame * CFrame.new(0, 1, 0) -- Hover slightly above ground
    ringAnchor.Parent = model
    
    local line = Instance.new("CylinderHandleAdornment")
    line.Name = "Adornment"
    line.InnerRadius = zoneRadius - 0.5 -- Very thin 0.5 stud line
    line.Radius = zoneRadius
    line.Height = 0.2
    line.Color3 = blueprintColor
    line.Transparency = 0 -- Fully solid glow
    line.AlwaysOnTop = false
    line.Adornee = ringAnchor
    line.CFrame = CFrame.Angles(math.rad(90), 0, 0)
    line.Parent = ringAnchor
    
    local bg = Instance.new("BillboardGui")
    bg.Name = "CaptureUI"
    bg.Size = UDim2.new(0, 100, 0, 15)
    bg.StudsOffset = Vector3.new(0, 20, 0)
    bg.AlwaysOnTop = true
    bg.Enabled = false
    bg.Parent = captureZone
    
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Size = UDim2.new(1, 0, 1, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 40, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = blueprintColor
    fill.BorderSizePixel = 0
    fill.Parent = barBg
end

local function setupBlueprints()
    local blueprintsFolder = Workspace:WaitForChild("Blueprints")
    if not blueprintsFolder then 
        warn("[EcoSphere-Debug] Blueprints folder not found!")
        return 
    end

    task.wait(1) -- Wait for all static objects inside the folder to finish loading

    local children = blueprintsFolder:GetChildren()
    warn("[EcoSphere-Debug] Found " .. #children .. " models in Blueprints")

    for _, model in ipairs(children) do
        if model:IsA("Model") then
            warn("[EcoSphere-Debug] Processing model: " .. model.Name)
            -- Strip original colors and make them holograms
            for _, child in ipairs(model:GetDescendants()) do
                if child:IsA("BasePart") then
                    child:SetAttribute("OriginalColor", child.Color)
                    child:SetAttribute("OriginalMaterial", child.Material.Name)
                    child:SetAttribute("OriginalTransparency", child.Transparency)
                    child.Material = Enum.Material.ForceField
                    child.Color = blueprintColor
                    child.Transparency = 0.8
                    child.CanCollide = false
                    child.Anchored = true
                    child.CastShadow = false
                end
            end
            
            -- Ensure a primary part exists
            if not model.PrimaryPart then
                local parts = {}
                for _, child in ipairs(model:GetDescendants()) do
                    if child:IsA("BasePart") then table.insert(parts, child) end
                end
                if #parts > 0 then model.PrimaryPart = parts[1] end
            end

            warn("[EcoSphere-Debug] Adding capture zone for " .. model.Name)
            addCaptureZone(model)
        end
    end
    
    return blueprintsFolder
end

local function getPlayersInZone(zone)
    local chars = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            table.insert(chars, player.Character)
        end
    end
    overlapParams.FilterDescendantsInstances = chars
    
    if #chars == 0 then return {}, 0, nil end
    
    local parts = Workspace:GetPartsInPart(zone, overlapParams)
    local playersInside = {}
    local uniqueClasses = {}
    local classCount = 0
    local firstClassColor = nil
    
    for _, part in ipairs(parts) do
        local char = part:FindFirstAncestorWhichIsA("Model")
        if char then
            local player = Players:GetPlayerFromCharacter(char)
            if player and not table.find(playersInside, player) then
                table.insert(playersInside, player)
                local pClass = char:GetAttribute("Class")
                if pClass then
                    if not uniqueClasses[pClass] then
                        uniqueClasses[pClass] = true
                        classCount = classCount + 1
                        if not firstClassColor then
                            firstClassColor = GameConfig.CLASSES[pClass].Color
                        end
                    end
                end
            end
        end
    end
    return playersInside, classCount, firstClassColor
end

local function applyArchitectSurge(players)
    for _, player in ipairs(players) do
        local char = player.Character
        if char then
            char:SetAttribute("ArchitectSurge", true)
            task.delay(10, function()
                if char and char:GetAttribute("ArchitectSurge") then
                    char:SetAttribute("ArchitectSurge", nil)
                end
            end)
        end
    end
end

local function blossomBlueprint(model, classCount, firstClassColor, playersInside)
    local isHarmony = (classCount >= 2)
    local finalColor = isHarmony and Color3.new(1, 1, 1) or (firstClassColor or Color3.fromRGB(0, 255, 255))
    local finalMaterial = isHarmony and Enum.Material.Neon or Enum.Material.SmoothPlastic
    
    local duration = 1.0
    local steps = 30
    local stepTime = duration / steps
    
    local parts = {}
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") and child.Name ~= "CaptureZone" and child.Name ~= "NeonRing" then
            table.insert(parts, child)
            child.CanCollide = true
        end
    end
    
    local startColor = Color3.fromRGB(0, 255, 255)
    
    local primary = model.PrimaryPart or parts[1]
    if primary then
        local att = Instance.new("Attachment", primary)
        local emit = Instance.new("ParticleEmitter")
        emit.Lifetime = NumberRange.new(2, 3)
        emit.Speed = NumberRange.new(20, 50)
        emit.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
        emit.SpreadAngle = Vector2.new(180, 180)
        emit.Rate = 0
        emit.Parent = att
        
        if isHarmony then
            emit.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1,0,0)),
                ColorSequenceKeypoint.new(0.33, Color3.new(0,1,0)),
                ColorSequenceKeypoint.new(0.66, Color3.new(0,0,1)),
                ColorSequenceKeypoint.new(1, Color3.new(1,0,1))
            })
            emit:Emit(150)
        else
            emit.Color = ColorSequence.new(Color3.fromRGB(100, 255, 100))
            emit:Emit(80)
        end
        task.delay(4, function() att:Destroy() end)
    end
    
    task.spawn(function()
        for i = 1, steps do
            local alpha = i / steps
            for _, part in ipairs(parts) do
                local origTrans = part:GetAttribute("OriginalTransparency") or 0
                part.Transparency = 0.8 + (origTrans - 0.8) * alpha
                
                local origColor = part:GetAttribute("OriginalColor") or Color3.new(1, 1, 1)
                part.Color = startColor:Lerp(origColor, alpha)
                
                if i == steps then
                    local matName = part:GetAttribute("OriginalMaterial")
                    if matName then
                        part.Material = Enum.Material[matName]
                    else
                        part.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
            task.wait(stepTime)
        end
    end)
    
    applyArchitectSurge(playersInside)
end

local blueprintsFolder = setupBlueprints()

if blueprintsFolder then
    for _, model in ipairs(blueprintsFolder:GetChildren()) do
        local zone = model:FindFirstChild("CaptureZone")
        if zone then
            local bg = zone:FindFirstChild("CaptureUI")
            local fill = bg and bg:FindFirstChild("BarBg") and bg.BarBg:FindFirstChild("Fill")
            
            local progress = 0
            local captured = false
            
            task.spawn(function()
                while not captured and model.Parent do
                    local dt = task.wait(0.1)
                    local playersInside, classCount, firstClassColor = getPlayersInZone(zone)
                    local numPlayers = #playersInside
                    
                    if numPlayers > 0 then
                        bg.Enabled = true
                        local speedMult = numPlayers
                        progress = math.clamp(progress + (dt * speedMult * 0.2), 0, 1)
                        
                        if fill then
                            TweenService:Create(fill, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {
                                Size = UDim2.new(progress, 0, 1, 0)
                            }):Play()
                        end
                        
                        if progress >= 1.0 then
                            captured = true
                            bg:Destroy()
                            zone:Destroy()
                            local ring = model:FindFirstChild("NeonRing")
                            if ring then ring:Destroy() end
                            blossomBlueprint(model, classCount, firstClassColor, playersInside)
                        end
                    else
                        if progress > 0 then
                            progress = 0
                            bg.Enabled = false
                            if fill then fill.Size = UDim2.new(0, 0, 1, 0) end
                        end
                    end
                end
            end)
        end
    end
end
print("[EcoSphere] BlueprintManager initialized")
