-- MatchBootstrap: Initializes the match server when players arrive via TeleportService
-- Only runs on MATCH servers (reserved private servers)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

-- Only run on reserved (match) servers
if game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then
	print("[EcoSphere] MatchBootstrap: Skipping — this is NOT a reserved match server")
	return
end

print("[EcoSphere] MatchBootstrap: Running on match server:", game.PrivateServerId)

-- Class options for assignment
local classOptions = {"Economist", "Cultivator", "Advocate"}
local playerClasses = {} -- [player] = className

-- Teleport data from the lobby (shared across all arriving players)
local teleportData = nil

-- Spawn a player as a sphere character with assigned class
local function spawnAsSphere(player, assignedClass)
	local oldChar = player.Character

	local newChar = RS:WaitForChild("SphereCharacter"):Clone()
	newChar.Name = player.Name

	local root = newChar:WaitForChild("HumanoidRootPart")
	root.Anchored = true
	newChar:PivotTo(CFrame.new(0, 515, 0))

	-- Create Humanoid BEFORE parenting (camera needs it)
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = newChar

	newChar.Parent = workspace
	player.Character = newChar

	if oldChar then oldChar:Destroy() end

	-- Create physics objects for planetary movement
	local att = Instance.new("Attachment")
	att.Parent = root

	local gravityForce = Instance.new("VectorForce")
	gravityForce.Name = "PlanetGravity"
	gravityForce.RelativeTo = Enum.ActuatorRelativeTo.World
	gravityForce.Force = Vector3.new(0, 0, 0)
	gravityForce.Attachment0 = att
	gravityForce.Parent = root

	local att2 = Instance.new("Attachment")
	att2.Parent = root

	local rollTorque = Instance.new("AngularVelocity")
	rollTorque.Name = "RollTorque"
	rollTorque.RelativeTo = Enum.ActuatorRelativeTo.World
	rollTorque.AngularVelocity = Vector3.new(0, 0, 0)
	rollTorque.MaxTorque = 0
	rollTorque.Attachment0 = att2
	rollTorque.Parent = root

	-- Create visual shell (the actual visible sphere)
	local shell = Instance.new("Part")
	shell.Name = "VisualShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(6, 6, 6)
	shell.Color = GameConfig.CLASSES[assignedClass].Color
	shell.Material = Enum.Material.Glass
	shell.Transparency = 0.5
	shell.CanCollide = false
	shell.Massless = true
	shell.CastShadow = true

	local shellWeld = Instance.new("Weld")
	shellWeld.Name = "ShellWeld"
	shellWeld.Part0 = root
	shellWeld.Part1 = shell
	shellWeld.C0 = CFrame.new()
	shellWeld.Parent = shell

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "VisualMesh"
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = shell

	shell.Parent = newChar

	-- Set class attribute for PaintingSystem and SphereVisuals
	newChar:SetAttribute("Class", assignedClass)
	playerClasses[player] = assignedClass

	-- Release the sphere after a brief delay
	task.delay(0.35, function()
		if root and root.Parent then
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			root.Anchored = false
			pcall(function() root:SetNetworkOwner(player) end)
		end
	end)

	-- Fire SelectClass to the PaintingSystem via the RemoteEvent
	-- On the server we simulate the client-fired event by directly invoking
	-- PaintingSystem's handler through the SelectClass remote
	-- Since we're the server, we fire it as if the client sent it
	task.defer(function()
		Remotes.SelectClass:FireClient(player, assignedClass) -- Tells client
	end)

	-- Tell the client to start the game (triggers HUD, controls, etc.)
	Remotes.StartGameClient:FireClient(player, assignedClass)

	print("[EcoSphere] MatchBootstrap: Spawned", player.DisplayName, "as", assignedClass)
end

-- Handle arriving players
local arrivedPlayers = {}

Players.PlayerAdded:Connect(function(player)
	print("[EcoSphere] MatchBootstrap: Player arrived:", player.DisplayName)
	table.insert(arrivedPlayers, player)

	-- Get teleport data for this player
	local joinData = player:GetJoinData()
	if joinData and joinData.TeleportData then
		teleportData = joinData.TeleportData
	end

	-- Determine this player's assigned class from teleport data
	local assignedClass = nil
	if teleportData and teleportData.classAssignments then
		assignedClass = teleportData.classAssignments[tostring(player.UserId)]
	end

	-- Fallback: assign randomly if no teleport data
	if not assignedClass then
		assignedClass = classOptions[math.random(1, #classOptions)]
		warn("[EcoSphere] MatchBootstrap: No teleport data for", player.DisplayName, "— assigned random class:", assignedClass)
	end

	-- Listen for character loads (Connect instead of Once to support death/respawn in match)
	player.CharacterAdded:Connect(function(character)
		-- Avoid infinite loop: check if character is already a sphere
		if character:FindFirstChild("PlanetGravity", true) or character:FindFirstChild("VisualShell", true) then
			return
		end

		task.wait(0.5) -- Let the character fully load
		
		-- Ensure character is still active and alive
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			spawnAsSphere(player, assignedClass)
		end
	end)

	-- If character already exists, verify health and status
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			if not player.Character:FindFirstChild("PlanetGravity", true) then
				spawnAsSphere(player, assignedClass)
			end
		end
	end
end)

-- Handle players leaving mid-match
Players.PlayerRemoving:Connect(function(player)
	playerClasses[player] = nil

	-- If all players leave, just let the server shut down naturally
	if #Players:GetPlayers() <= 1 then
		print("[EcoSphere] MatchBootstrap: Last player leaving, server will shut down")
	end
end)

-- Return all players to lobby after match ends
local function returnToLobby()
	print("[EcoSphere] MatchBootstrap: Returning all players to lobby")

	local playersToReturn = Players:GetPlayers()
	if #playersToReturn == 0 then return end

	-- Fire return event to clients (starts the countdown UI)
	Remotes.ReturnToLobby:FireAllClients(GameConfig.RETURN_TO_LOBBY_DELAY)

	task.wait(GameConfig.RETURN_TO_LOBBY_DELAY)

	-- Get the lobby PlaceId from teleport data
	local lobbyPlaceId = teleportData and teleportData.lobbyPlaceId

	if not lobbyPlaceId then
		-- Fallback: In Roblox multi-place experiences, the start place
		-- can be determined from game.GameId, but the simplest approach
		-- is to use the value sent in teleportData from the lobby.
		-- If missing, we kick players so they rejoin the start place automatically.
		warn("[EcoSphere] MatchBootstrap: No lobby PlaceId in teleport data, kicking to rejoin")
		for _, player in ipairs(Players:GetPlayers()) do
			player:Kick("Match ended! Rejoin to return to the lobby.")
		end
		return
	end

	-- Teleport all players back to the lobby
	playersToReturn = Players:GetPlayers() -- Re-fetch in case someone left during countdown
	if #playersToReturn == 0 then return end

	local success, err = pcall(function()
		TeleportService:Teleport(lobbyPlaceId, playersToReturn)
	end)

	if not success then
		warn("[EcoSphere] MatchBootstrap: Failed to teleport back:", err)
		for _, player in ipairs(Players:GetPlayers()) do
			player:Kick("Match ended! Rejoin to return to the lobby.")
		end
	else
		print("[EcoSphere] MatchBootstrap: Teleported", #playersToReturn, "players back to lobby")
	end
end

-- Expose returnToLobby for GameManager via BindableEvent
local returnEvent = Instance.new("BindableEvent")
returnEvent.Name = "ReturnToLobby"
returnEvent.Event:Connect(returnToLobby)
returnEvent.Parent = script

-- Timeout: if no players arrive, just log it (server will shut down naturally)
task.delay(GameConfig.MATCH_LOAD_TIMEOUT, function()
	if #arrivedPlayers == 0 then
		warn("[EcoSphere] MatchBootstrap: No players arrived within timeout, server will shut down")
	end
end)

print("[EcoSphere] MatchBootstrap initialized — waiting for players")
