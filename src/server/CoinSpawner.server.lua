-- CoinSpawner: Spawns glowing coins around the planet and handles collection
-- Only runs on match servers
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

-- Skip on lobby servers
if game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then
	print("[EcoSphere] CoinSpawner: Skipping — lobby server")
	return
end

local coinsFolder = Workspace:WaitForChild("Coins")
local planet = Workspace:WaitForChild("PlanetBase")

local function randomPointOnSphere(radius)
	local theta = math.random() * 2 * math.pi
	local phi = math.acos(2 * math.random() - 1)
	local x = radius * math.sin(phi) * math.cos(theta)
	local y = radius * math.sin(phi) * math.sin(theta)
	local z = radius * math.cos(phi)
	return Vector3.new(x, y, z)
end

local function createCoin(index)
	local surfaceRadius = GameConfig.PLANET_RADIUS + 5
	local pos = GameConfig.PLANET_CENTER + randomPointOnSphere(surfaceRadius)

	local coin = Instance.new("Part")
	coin.Name = "Coin_" .. index
	coin.Shape = Enum.PartType.Block
	coin.Size = Vector3.new(3, 3, 3)
	coin.Material = Enum.Material.Neon
	coin.Color = Color3.fromRGB(150, 255, 100) -- Glowing nature green
	coin.Anchored = true
	coin.CanCollide = false
	coin.TopSurface = Enum.SurfaceType.Smooth
	coin.BottomSurface = Enum.SurfaceType.Smooth

	-- Orient coin to face outward from planet
	local upDir = (pos - GameConfig.PLANET_CENTER).Unit
	local rightDir = upDir:Cross(Vector3.new(0, 1, 0))
	if rightDir.Magnitude < 0.01 then
		rightDir = upDir:Cross(Vector3.new(1, 0, 0))
	end
	rightDir = rightDir.Unit
	local lookDir = rightDir:Cross(upDir).Unit

	coin.CFrame = CFrame.new(pos) * CFrame.fromMatrix(Vector3.zero, rightDir, upDir, -lookDir)

	-- Add a PointLight for glow
	local light = Instance.new("PointLight")
	light.Color = GameConfig.COIN_COLOR
	light.Brightness = 2
	light.Range = 12
	light.Parent = coin

	coin.Parent = coinsFolder

	-- Spin animation
	task.spawn(function()
		local startCF = coin.CFrame
		local t = math.random() * math.pi * 2
		while coin and coin.Parent do
			t = t + 0.02
			local bobOffset = upDir * math.sin(t * 2) * 1.5
			-- Spin on multiple axes for a floating crystal look
			coin.CFrame = CFrame.new(pos + bobOffset) * CFrame.fromMatrix(Vector3.zero, rightDir, upDir, -lookDir) * CFrame.Angles(math.pi/4, t, math.pi/4)
			task.wait()
		end
	end)

	return coin
end

-- Touch detection for coins
local function setupCoinTouch(coin)
	coin.Touched:Connect(function(hit)
		if not coin.Parent then return end
		local character = hit.Parent
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Collect the coin
		local coinPos = coin.Position
		coin:Destroy()

		-- Notify client for powerup
		Remotes.CoinCollected:FireClient(player)
		Remotes.PowerupActivated:FireClient(player, GameConfig.POWERUP_DURATION)
		player:SetAttribute("PowerupEndTime", tick() + GameConfig.POWERUP_DURATION)

		-- Respawn coin after delay
		task.delay(GameConfig.COIN_RESPAWN_TIME, function()
			local newCoin = createCoin(math.random(1000, 9999))
			setupCoinTouch(newCoin)
		end)
	end)
end

-- Spawn initial coins
for i = 1, GameConfig.COIN_COUNT do
	local coin = createCoin(i)
	setupCoinTouch(coin)
end

print("[EcoSphere] Coins spawned:", GameConfig.COIN_COUNT)