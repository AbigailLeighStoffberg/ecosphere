-- GameManager: Master timer, win/fail logic, game state coordination
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local paintSystem = SSS:WaitForChild("PaintingSystem")
local getCoverage = paintSystem:WaitForChild("GetCoverage")
local drainPaint = paintSystem:WaitForChild("DrainPaint")

local gameState = "waiting" -- waiting, playing, victory, defeat
local timeRemaining = GameConfig.GAME_DURATION
local gameStartTime = 0

-- Wait for at least one player to select a class before starting
local classSelected = false
Remotes.SelectClass.OnServerEvent:Connect(function(player, className)
	if not classSelected and gameState == "waiting" then
		classSelected = true
		-- Start the game after a brief delay
		task.delay(3, function()
			if gameState == "waiting" then
				gameState = "playing"
				gameStartTime = tick()
				timeRemaining = GameConfig.GAME_DURATION
				Remotes.GameStateChanged:FireAllClients("playing", timeRemaining)
				print("[EcoSphere] Game started! Timer:", GameConfig.GAME_DURATION, "seconds")
			end
		end)
	end
end)

-- Game loop
task.spawn(function()
	while true do
		task.wait(0.5)

		if gameState == "playing" then
			timeRemaining = GameConfig.GAME_DURATION - (tick() - gameStartTime)

			if timeRemaining <= 0 then
				timeRemaining = 0

				-- Check coverage
				local coverage = getCoverage:Invoke()
				local allAbove = true
				for className, pct in pairs(coverage) do
					if pct < GameConfig.WIN_THRESHOLD then
						allAbove = false
						break
					end
				end

				if allAbove then
					-- VICTORY
					gameState = "victory"
					Remotes.GameStateChanged:FireAllClients("victory", 0)
					print("[EcoSphere] VICTORY! All classes reached", GameConfig.WIN_THRESHOLD * 100, "% coverage!")

					-- Spawn confetti particles on all players
					for _, player in ipairs(Players:GetPlayers()) do
						local char = player.Character
						if char then
							local root = char:FindFirstChild("HumanoidRootPart")
							if root then
								local confetti = Instance.new("ParticleEmitter")
								confetti.Name = "VictoryConfetti"
								confetti.Rate = 200
								confetti.Lifetime = NumberRange.new(2, 4)
								confetti.Speed = NumberRange.new(20, 50)
								confetti.SpreadAngle = Vector2.new(180, 180)
								confetti.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromHex("#e1c074")),
									ColorSequenceKeypoint.new(0.33, Color3.fromHex("#699254")),
									ColorSequenceKeypoint.new(0.66, Color3.fromHex("#d06a49")),
									ColorSequenceKeypoint.new(1, Color3.fromHex("#7faec6")),
								})
								confetti.Size = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 1),
									NumberSequenceKeypoint.new(1, 0),
								})
								confetti.RotSpeed = NumberRange.new(-180, 180)
								confetti.Parent = root
							end
						end
					end

					-- Play victory sound
					local chord = Instance.new("Sound")
					chord.Name = "VictoryChord"
					chord.SoundId = "rbxassetid://1837849285" -- triumphant chord
					chord.Volume = 0.8
					chord.Playing = true
					chord.Parent = Workspace
				else
					-- DEFEAT
					gameState = "defeat"
					Remotes.GameStateChanged:FireAllClients("defeat", 0)
					print("[EcoSphere] DEFEAT! Time ran out.")

					-- Drain paint to grayscale
					drainPaint:Fire()

					-- Play sad sound
					local failSound = Instance.new("Sound")
					failSound.Name = "DefeatSound"
					failSound.SoundId = "rbxassetid://5229717430" -- defeat sound
					failSound.Volume = 0.6
					failSound.Playing = true
					failSound.Parent = Workspace
				end

			else
				-- Check for early win
				local coverage = getCoverage:Invoke()
				local allAbove = true
				for className, pct in pairs(coverage) do
					if pct < GameConfig.WIN_THRESHOLD then
						allAbove = false
						break
					end
				end

				if allAbove then
					-- EARLY VICTORY
					gameState = "victory"
					Remotes.GameStateChanged:FireAllClients("victory", timeRemaining)
					print("[EcoSphere] EARLY VICTORY with", math.floor(timeRemaining), "seconds remaining!")

					-- Spawn confetti
					for _, player in ipairs(Players:GetPlayers()) do
						local char = player.Character
						if char then
							local root = char:FindFirstChild("HumanoidRootPart")
							if root then
								local confetti = Instance.new("ParticleEmitter")
								confetti.Rate = 200
								confetti.Lifetime = NumberRange.new(2, 4)
								confetti.Speed = NumberRange.new(20, 50)
								confetti.SpreadAngle = Vector2.new(180, 180)
								confetti.Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
									ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 100)),
									ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255, 80, 150)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
								})
								confetti.Size = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 1),
									NumberSequenceKeypoint.new(1, 0),
								})
								confetti.Parent = root
							end
						end
					end

					local chord = Instance.new("Sound")
					chord.SoundId = "rbxassetid://1837849285"
					chord.Volume = 0.8
					chord.Playing = true
					chord.Parent = Workspace
				end

				-- Broadcast timer
				Remotes.GameStateChanged:FireAllClients("timer", timeRemaining)
			end
		end
	end
end)

print("[EcoSphere] GameManager initialized")