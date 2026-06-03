-- LobbyManager: Queue system with countdown and TeleportService
-- Only runs on the LOBBY server (start place)
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

-- Skip this script entirely on match (reserved) servers
if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
	print("[EcoSphere] LobbyManager: Skipping — this is a match server")
	return
end

local Lobby = Workspace:WaitForChild("Lobby")
local classOptions = {"Economist", "Cultivator", "Advocate"}

-- Dynamically discover ALL pads in the Lobby (supports multiple Solo/Duo/Trio Mode models)
local padQueues = {} -- each entry: { model, requiredPlayers, pad, playersInZone, countdown, countdownThread }

local function discoverPads()
	for _, child in ipairs(Lobby:GetChildren()) do
		if child:IsA("Model") then
			local pad = child:FindFirstChild("Pad")
			if pad then
				local req = child:GetAttribute("RequiredPlayers")
				if not req then
					-- Infer from name
					if child.Name == "Solo Mode" then
						req = 1
					elseif child.Name == "Duo Mode" then
						req = 2
					elseif child.Name == "Trio Mode" then
						req = 3
					end
				end
				if req then
					table.insert(padQueues, {
						model = child,
						requiredPlayers = req,
						pad = pad,
						playersInZone = {},
						countdown = -1, -- -1 = not counting down
						countdownThread = nil,
						teleporting = false,
					})

					-- Adjust BillboardGui height offset to float above head height
					local bgui = pad:FindFirstChild("Info")
					if bgui and bgui:IsA("BillboardGui") then
						bgui.StudsOffset = Vector3.new(0, 7, 0)
					end
				end
			end
		end
	end
	print("[EcoSphere] LobbyManager: Discovered", #padQueues, "pads")
end

discoverPads()

-- Teleport effect (visual cue before actual teleport)
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

-- Assign classes to a team
local function assignClasses(players)
	local available = {table.unpack(classOptions)}
	-- Shuffle
	for i = #available, 2, -1 do
		local j = math.random(i)
		available[i], available[j] = available[j], available[i]
	end

	local assignments = {}
	for index, player in ipairs(players) do
		assignments[player] = available[(index - 1) % #available + 1]
	end
	return assignments
end

-- Teleport a team to a match server
local function teleportTeam(padData)
	if padData.teleporting then return end
	padData.teleporting = true

	local playersToTeleport = {}
	for _, player in ipairs(padData.playersInZone) do
		if player.Parent then -- still connected
			table.insert(playersToTeleport, player)
		end
	end

	if #playersToTeleport < padData.requiredPlayers then
		padData.teleporting = false
		return
	end

	-- Assign classes and include in teleport data
	local classAssignments = assignClasses(playersToTeleport)
	local teleportData = {
		matchMode = padData.model.Name,
		requiredPlayers = padData.requiredPlayers,
		lobbyPlaceId = game.PlaceId, -- So match server can teleport players back
		classAssignments = {},
	}

	for player, className in pairs(classAssignments) do
		teleportData.classAssignments[tostring(player.UserId)] = className
	end

	-- Notify players they are about to teleport (shows custom loading screen)
	for _, player in ipairs(playersToTeleport) do
		pcall(function()
			Remotes.QueueUpdate:FireClient(player, "teleporting", {
				matchMode = teleportData.matchMode,
				assignedClass = classAssignments[player]
			})
		end)
	end

	-- Wait for the client to process the event and create the loading screen GUI
	-- BEFORE creating VFX parts (which replicate immediately and would be visible)
	task.wait(0.15)

	-- Play teleport effects (now hidden behind the loading screen)
	for player, className in pairs(classAssignments) do
		local char = player.Character
		if char and char.PrimaryPart then
			playTeleportEffect(char:GetPivot().Position, GameConfig.CLASSES[className].Color)
		end
	end

	task.wait(0.35) -- Brief wait for SetTeleportGui registration

	-- Check MATCH_PLACE_ID is set
	if GameConfig.MATCH_PLACE_ID == 0 then
		warn("[EcoSphere] MATCH_PLACE_ID not set! Cannot teleport. Set it in GameConfig.lua")
		for _, player in ipairs(playersToTeleport) do
			-- Notify players of the error
			Remotes.QueueUpdate:FireClient(player, "error", "Match server not configured! Please set MATCH_PLACE_ID.")
		end
		padData.teleporting = false
		return
	end

	-- Reserve a private server and teleport
	local success, result = pcall(function()
		local accessCode = TeleportService:ReserveServer(GameConfig.MATCH_PLACE_ID)
		TeleportService:TeleportToPrivateServer(
			GameConfig.MATCH_PLACE_ID,
			accessCode,
			playersToTeleport,
			nil, -- spawnName
			teleportData
		)
		return true
	end)

	if not success then
		warn("[EcoSphere] TeleportService failed:", result)
		for _, player in ipairs(playersToTeleport) do
			Remotes.QueueUpdate:FireClient(player, "error", "Teleport failed: " .. tostring(result))
		end
	else
		print("[EcoSphere] Teleported", #playersToTeleport, "players to match server")
	end

	-- Reset pad state after a delay (let teleport complete)
	task.delay(3, function()
		padData.teleporting = false
		padData.countdown = -1
		padData.playersInZone = {}
	end)
end

-- Get players standing on a specific pad
local function getPlayersOnPad(pad)
	local charsInZone = {}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	local charList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			table.insert(charList, p.Character)
		end
	end
	if #charList == 0 then return {} end
	overlapParams.FilterDescendantsInstances = charList

	-- Since the pad is rotated (RightVector/local X is vertical, local Y and Z are horizontal):
	-- we expand X (vertical height) by 8 studs, and Y/Z (horizontal boundaries) by 2 studs.
	local detectorSize = Vector3.new(pad.Size.X + 8, pad.Size.Y + 2, pad.Size.Z + 2)
	local parts = Workspace:GetPartBoundsInBox(pad.CFrame, detectorSize, overlapParams)
	local playersInZone = {}
	local seen = {}
	for _, part in ipairs(parts) do
		local char = part:FindFirstAncestorWhichIsA("Model")
		if char then
			local player = Players:GetPlayerFromCharacter(char)
			if player and not seen[player] then
				seen[player] = true
				table.insert(playersInZone, player)
			end
		end
	end
	return playersInZone
end

-- Main heartbeat loop — scan pads and manage countdowns
RunService.Heartbeat:Connect(function()
	for _, padData in ipairs(padQueues) do
		if padData.teleporting then continue end

		local pad = padData.pad
		if not pad or not pad.Parent then continue end

		-- Get current players on this pad
		local playersOnPad = getPlayersOnPad(pad)
		padData.playersInZone = playersOnPad

		-- Update the BillboardGui text
		local bgui = pad:FindFirstChild("Info")
		local txt = bgui and bgui:FindFirstChild("TextLabel")

		local count = #playersOnPad
		local req = padData.requiredPlayers

		if txt then
			if padData.countdown > 0 then
				txt.Text = "⏱ " .. math.ceil(padData.countdown)
			else
				txt.Text = "(" .. count .. "/" .. req .. ")"
			end
		end

		-- Update dynamic icon lighting based on players on the pad
		local iconsFrame = bgui and bgui:FindFirstChild("IconsFrame")
		if iconsFrame then
			for i = 1, req do
				local icon = iconsFrame:FindFirstChild("PersonIcon_" .. i)
				if icon and icon:IsA("ImageLabel") then
					if i <= count then
						icon.ImageTransparency = 0 -- fully lit when occupied
					else
						icon.ImageTransparency = 0.75 -- dimmed/semi-transparent when empty
					end
				end
			end
		end

		-- Send queue updates to players on the pad
		for _, player in ipairs(playersOnPad) do
			Remotes.QueueUpdate:FireClient(player, "queue", {
				padName = padData.model.Name,
				current = count,
				required = req,
				countdown = padData.countdown > 0 and math.ceil(padData.countdown) or nil,
			})
		end

		-- Check if we should start/continue/cancel countdown
		if count >= req then
			-- Start countdown if not already
			if padData.countdown < 0 and not padData.countdownThread then
				padData.countdown = GameConfig.COUNTDOWN_DURATION
				padData.countdownThread = task.spawn(function()
					while padData.countdown > 0 do
						task.wait(0.1)
						padData.countdown = padData.countdown - 0.1

						-- Re-check if enough players are still on pad
						local currentPlayers = getPlayersOnPad(pad)
						if #currentPlayers < req then
							-- Someone left — cancel countdown
							padData.countdown = -1
							padData.countdownThread = nil

							-- Notify remaining players
							for _, p in ipairs(currentPlayers) do
								Remotes.QueueUpdate:FireClient(p, "cancelled", nil)
							end
							return
						end
					end

					-- Countdown finished — teleport!
					padData.countdownThread = nil
					teleportTeam(padData)
				end)
			end
		else
			-- Not enough players — cancel any active countdown
			if padData.countdown > 0 or padData.countdownThread then
				padData.countdown = -1
				if padData.countdownThread then
					task.cancel(padData.countdownThread)
					padData.countdownThread = nil
				end
			end
		end
	end
end)

print("[EcoSphere] LobbyManager initialized with", #padQueues, "pads")
