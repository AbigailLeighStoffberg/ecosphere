-- GameHUD: Flat Design 2.0 progress bars, timer, and game state display
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- BUILD HUD
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false -- Hide HUD in the lobby initially
screenGui.Parent = playerGui

-- ========================
-- TIMER DISPLAY (top center)
-- ========================
local timerFrame = Instance.new("Frame")
timerFrame.Name = "TimerFrame"
timerFrame.AnchorPoint = Vector2.new(0.5, 0)
timerFrame.Position = UDim2.new(0.5, 0, 0, 20)
timerFrame.Size = UDim2.new(0, 180, 0, 60)
timerFrame.BackgroundColor3 = Color3.fromHex("#5c4e4e")
timerFrame.BackgroundTransparency = 0.1
timerFrame.BorderSizePixel = 0
timerFrame.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 16)
timerCorner.Parent = timerFrame

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = Color3.fromHex("#596674")
timerStroke.Thickness = 2
timerStroke.Parent = timerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 18)
timerLabel.Position = UDim2.new(0, 0, 0, 6)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "TIME REMAINING"
timerLabel.TextColor3 = Color3.fromHex("#b9a3a0")
timerLabel.TextSize = 11
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Parent = timerFrame

local timerValue = Instance.new("TextLabel")
timerValue.Name = "TimerValue"
timerValue.Size = UDim2.new(1, 0, 0, 32)
timerValue.Position = UDim2.new(0, 0, 0, 24)
timerValue.BackgroundTransparency = 1
timerValue.Text = "1:00"
timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
timerValue.TextSize = 28
timerValue.Font = Enum.Font.GothamBold
timerValue.Parent = timerFrame

-- ========================
-- PROGRESS BARS (bottom center)
-- ========================
local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressFrame"
progressFrame.AnchorPoint = Vector2.new(0.5, 1)
progressFrame.Position = UDim2.new(0.5, 0, 1, -25)
progressFrame.Size = UDim2.new(0, 600, 0, 130)
progressFrame.BackgroundColor3 = Color3.fromHex("#5c4e4e")
progressFrame.BackgroundTransparency = 0.1
progressFrame.BorderSizePixel = 0
progressFrame.Parent = screenGui

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 18)
progCorner.Parent = progressFrame

local progStroke = Instance.new("UIStroke")
progStroke.Color = Color3.fromHex("#596674")
progStroke.Thickness = 2
progStroke.Parent = progressFrame

-- Title
local progTitle = Instance.new("TextLabel")
progTitle.Size = UDim2.new(1, 0, 0, 25)
progTitle.Position = UDim2.new(0, 0, 0, 8)
progTitle.BackgroundTransparency = 1
progTitle.Text = "ECOSPHERE HARMONY"
progTitle.TextColor3 = Color3.fromHex("#b9a3a0")
progTitle.TextSize = 13
progTitle.Font = Enum.Font.GothamBold
progTitle.Parent = progressFrame

-- Build individual progress bars
local classOrder = {"Economist", "Cultivator", "Advocate"}
local barFills = {}
local barLabels = {}
local barPcts = {}

for i, className in ipairs(classOrder) do
	local classData = GameConfig.CLASSES[className]
	local yOffset = 35 + (i - 1) * 30

	-- Class label
	local label = Instance.new("TextLabel")
	label.Name = className .. "Label"
	label.Size = UDim2.new(0, 120, 0, 24)
	label.Position = UDim2.new(0, 15, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Text = classData.DisplayName
	label.TextColor3 = classData.Color
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = progressFrame
	barLabels[className] = label

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Name = className .. "BarBg"
	barBg.Size = UDim2.new(0, 370, 0, 20)
	barBg.Position = UDim2.new(0, 140, 0, yOffset + 2)
	barBg.BackgroundColor3 = Color3.fromHex("#6e5747")
	barBg.BorderSizePixel = 0
	barBg.Parent = progressFrame

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 10)
	barBgCorner.Parent = barBg

	-- Bar fill (chunky, springy)
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = classData.Color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = barFill

	-- 80% threshold marker
	local threshold = Instance.new("Frame")
	threshold.Name = "Threshold"
	threshold.Size = UDim2.new(0, 2, 1, 4)
	threshold.Position = UDim2.new(0.8, 0, 0, -2)
	threshold.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	threshold.BackgroundTransparency = 0.4
	threshold.BorderSizePixel = 0
	threshold.Parent = barBg

	-- Percentage text
	local pctLabel = Instance.new("TextLabel")
	pctLabel.Name = className .. "Pct"
	pctLabel.Size = UDim2.new(0, 55, 0, 24)
	pctLabel.Position = UDim2.new(0, 520, 0, yOffset)
	pctLabel.BackgroundTransparency = 1
	pctLabel.Text = "0%"
	pctLabel.TextColor3 = classData.Color
	pctLabel.TextSize = 14
	pctLabel.Font = Enum.Font.GothamBold
	pctLabel.TextXAlignment = Enum.TextXAlignment.Right
	pctLabel.Parent = progressFrame

	barFills[className] = barFill
	barPcts[className] = pctLabel
end

-- ========================
-- POWERUP INDICATOR (top right)
-- ========================
local powerupFrame = Instance.new("Frame")
powerupFrame.Name = "PowerupFrame"
powerupFrame.AnchorPoint = Vector2.new(1, 0)
powerupFrame.Position = UDim2.new(1, -20, 0, 20)
powerupFrame.Size = UDim2.new(0, 200, 0, 45)
powerupFrame.BackgroundColor3 = GameConfig.COIN_COLOR
powerupFrame.BackgroundTransparency = 1
powerupFrame.BorderSizePixel = 0
powerupFrame.Visible = false
powerupFrame.Parent = screenGui

local puCorner = Instance.new("UICorner")
puCorner.CornerRadius = UDim.new(0, 12)
puCorner.Parent = powerupFrame

local puLabel = Instance.new("TextLabel")
puLabel.Size = UDim2.new(1, 0, 1, 0)
puLabel.BackgroundTransparency = 1
puLabel.Text = "⚡ WIDE PAINT ACTIVE"
puLabel.TextColor3 = Color3.fromRGB(20, 20, 30)
puLabel.TextSize = 16
puLabel.Font = Enum.Font.GothamBold
puLabel.Parent = powerupFrame

-- ========================
-- GAME STATE OVERLAY (win/lose)
-- ========================
local stateOverlay = Instance.new("Frame")
stateOverlay.Name = "StateOverlay"
stateOverlay.Size = UDim2.new(1, 0, 1, 0)
stateOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
stateOverlay.BackgroundTransparency = 1
stateOverlay.BorderSizePixel = 0
stateOverlay.Visible = false
stateOverlay.ZIndex = 10
stateOverlay.Parent = screenGui

local stateText = Instance.new("TextLabel")
stateText.Name = "StateText"
stateText.AnchorPoint = Vector2.new(0.5, 0.5)
stateText.Position = UDim2.new(0.5, 0, 0.4, 0)
stateText.Size = UDim2.new(0, 600, 0, 100)
stateText.BackgroundTransparency = 1
stateText.TextColor3 = Color3.fromRGB(255, 255, 255)
stateText.TextSize = 52
stateText.Font = Enum.Font.GothamBold
stateText.TextWrapped = true
stateText.ZIndex = 11
stateText.Parent = stateOverlay

local stateSubtext = Instance.new("TextLabel")
stateSubtext.Name = "StateSubtext"
stateSubtext.AnchorPoint = Vector2.new(0.5, 0)
stateSubtext.Position = UDim2.new(0.5, 0, 0.55, 0)
stateSubtext.Size = UDim2.new(0, 500, 0, 40)
stateSubtext.BackgroundTransparency = 1
stateSubtext.TextColor3 = Color3.fromRGB(180, 185, 200)
stateSubtext.TextSize = 20
stateSubtext.Font = Enum.Font.Gotham
stateSubtext.ZIndex = 11
stateSubtext.Parent = stateOverlay

-- ========================
-- CLASS SWITCHER UI (bottom left)
-- ========================
local switchFrame = Instance.new("Frame")
switchFrame.Name = "SwitchFrame"
switchFrame.AnchorPoint = Vector2.new(0, 1)
switchFrame.Position = UDim2.new(0, 20, 1, -20)
switchFrame.Size = UDim2.new(0, 220, 0, 85)
switchFrame.BackgroundColor3 = Color3.fromHex("#5c4e4e")
switchFrame.BackgroundTransparency = 0.1
switchFrame.BorderSizePixel = 0
switchFrame.Parent = screenGui

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 16)
switchCorner.Parent = switchFrame

local switchStroke = Instance.new("UIStroke")
switchStroke.Color = Color3.fromHex("#596674")
switchStroke.Thickness = 2
switchStroke.Parent = switchFrame

local switchTitle = Instance.new("TextLabel")
switchTitle.Size = UDim2.new(1, 0, 0, 20)
switchTitle.Position = UDim2.new(0, 0, 0, 8)
switchTitle.BackgroundTransparency = 1
switchTitle.Text = "SWITCH CLASS"
switchTitle.TextColor3 = Color3.fromHex("#b9a3a0")
switchTitle.TextSize = 12
switchTitle.Font = Enum.Font.GothamBold
switchTitle.Parent = switchFrame

local switchContainer = Instance.new("Frame")
switchContainer.Size = UDim2.new(1, 0, 0, 40)
switchContainer.Position = UDim2.new(0, 0, 0, 32)
switchContainer.BackgroundTransparency = 1
switchContainer.Parent = switchFrame

local switchLayout = Instance.new("UIListLayout")
switchLayout.FillDirection = Enum.FillDirection.Horizontal
switchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
switchLayout.Padding = UDim.new(0, 15)
switchLayout.Parent = switchContainer

local function createSwitchBtn(className, hotkey)
	local classData = GameConfig.CLASSES[className]
	local btn = Instance.new("TextButton")
	btn.Name = className .. "Btn"
	btn.Size = UDim2.new(0, 40, 0, 40)
	btn.BackgroundColor3 = classData.Color
	btn.Text = classData.Icon
	btn.TextSize = 20
	btn.Font = Enum.Font.GothamBold
	btn.Parent = switchContainer
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(1, 0)
	btnCorner.Parent = btn
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 15)
	label.Position = UDim2.new(0, 0, 1, 2)
	label.BackgroundTransparency = 1
	label.Text = "[" .. hotkey .. "]"
	label.TextColor3 = Color3.fromHex("#b9a3a0")
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		if not _G.ClassSelected then return end
		
		-- In case PlanetaryMovement hotkeys are also firing, this is specifically for mouse clicks!
		Remotes.SelectClass:FireServer(className)
		
		-- Simple click animation
		local ts = game:GetService("TweenService")
		ts:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 35, 0, 35)}):Play()
		task.wait(0.1)
		ts:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 40, 0, 40)}):Play()
	end)
end

createSwitchBtn("Economist", "1")
createSwitchBtn("Cultivator", "2")
createSwitchBtn("Advocate", "3")

-- ============================================================
-- EVENT HANDLING
-- ============================================================

-- Update progress bars
Remotes.UpdateProgress.OnClientEvent:Connect(function(coverage)
	for className, pct in pairs(coverage) do
		if barFills[className] then
			local targetWidth = math.clamp(pct, 0, 1)
			-- Springy tween for chunky feel
			TweenService:Create(barFills[className], TweenInfo.new(0.4, Enum.EasingStyle.Back), {
				Size = UDim2.new(targetWidth, 0, 1, 0)
			}):Play()

			barPcts[className].Text = math.floor(pct * 100) .. "%"

			-- Color flash when crossing 80%
			if pct >= 0.8 then
				barPcts[className].TextColor3 = Color3.fromHex("#bdbc69")
			end
		end
	end
end)

-- Timer updates
Remotes.GameStateChanged.OnClientEvent:Connect(function(state, timeLeft)
	if state == "timer" then
		local mins = math.floor(timeLeft / 60)
		local secs = math.floor(timeLeft % 60)
		timerValue.Text = string.format("%d:%02d", mins, secs)

		-- Urgency color
		if timeLeft <= 30 then
			timerValue.TextColor3 = Color3.fromHex("#c66e6e")
			-- Pulse effect
			TweenService:Create(timerValue, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextSize = 34
			}):Play()
		elseif timeLeft <= 60 then
			timerValue.TextColor3 = Color3.fromHex("#e1c074")
		else
			timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

	elseif state == "playing" then
		timerValue.Text = "1:00"

	elseif state == "victory" then
		stateOverlay.Visible = true
		TweenService:Create(stateOverlay, TweenInfo.new(0.8), {BackgroundTransparency = 0.3}):Play()
		stateText.Text = "✨ HARMONY ACHIEVED! ✨"
		stateText.TextColor3 = Color3.fromRGB(100, 255, 180)
		if timeLeft and timeLeft > 0 then
			stateSubtext.Text = "With " .. math.floor(timeLeft) .. " seconds to spare!"
		else
			stateSubtext.Text = "The EcoSphere is in perfect balance."
		end

	elseif state == "defeat" then
		stateOverlay.Visible = true
		TweenService:Create(stateOverlay, TweenInfo.new(1.5), {BackgroundTransparency = 0.4}):Play()
		stateText.Text = "ECOSYSTEM COLLAPSED"
		stateText.TextColor3 = Color3.fromRGB(180, 80, 80)
		stateSubtext.Text = "The balance was not maintained..."
	end
end)

-- Powerup indicator
local currentPowerupId = 0
Remotes.PowerupActivated.OnClientEvent:Connect(function(duration)
	currentPowerupId = currentPowerupId + 1
	local thisPowerupId = currentPowerupId

	powerupFrame.Visible = true
	powerupFrame.BackgroundTransparency = 0
	
	-- Pop in animation
	TweenService:Create(powerupFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
		Position = UDim2.new(1, -20, 0, 80)
	}):Play()
	
	task.spawn(function()
		-- Flashing effect
		for i = 1, math.floor(duration * 2) do
			if currentPowerupId ~= thisPowerupId then return end
			powerupFrame.BackgroundTransparency = 0.5
			task.wait(0.25)
			if currentPowerupId ~= thisPowerupId then return end
			powerupFrame.BackgroundTransparency = 0
			task.wait(0.25)
		end
		
		if currentPowerupId ~= thisPowerupId then return end
		-- Fade out
		TweenService:Create(powerupFrame, TweenInfo.new(0.3), {
			Position = UDim2.new(1, -20, 0, 20),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.3)
		
		if currentPowerupId == thisPowerupId then
			powerupFrame.Visible = false
			powerupFrame.Size = UDim2.new(0, 200, 0, 45)
		end
	end)
end)

Remotes:WaitForChild("StartGameClient").OnClientEvent:Connect(function()
	screenGui.Enabled = true
end)

-- ========================
-- BOOST HUD (bottom center)
-- ========================
local boostBg = Instance.new("Frame")
boostBg.Name = "BoostBg"
boostBg.AnchorPoint = Vector2.new(0.5, 1)
boostBg.Position = UDim2.new(0.5, 0, 1, -25)
boostBg.Size = UDim2.new(0, 180, 0, 8)
boostBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
boostBg.BorderSizePixel = 0
boostBg.Parent = screenGui

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = boostBg

local boostFill = Instance.new("Frame")
boostFill.Name = "BoostFill"
boostFill.Size = UDim2.new(1, 0, 1, 0)
boostFill.BackgroundColor3 = Color3.fromHex("#42a5f5")
boostFill.BorderSizePixel = 0
boostFill.Parent = boostBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = boostFill

local boostText = Instance.new("TextLabel")
boostText.Name = "BoostText"
boostText.AnchorPoint = Vector2.new(0.5, 1)
boostText.Position = UDim2.new(0.5, 0, 0, -4)
boostText.Size = UDim2.new(1, 0, 0, 20)
boostText.BackgroundTransparency = 1
boostText.Text = "SHIFT TO BOOST"
boostText.TextColor3 = Color3.new(1,1,1)
boostText.Font = Enum.Font.GothamBold
boostText.TextSize = 12
boostText.Parent = boostBg

RunService.RenderStepped:Connect(function()
	local player = Players.LocalPlayer
	local cd = player and player:GetAttribute("BoostCooldown") or 0
	local now = tick()
	if now < cd then
		local remaining = cd - now
		local pct = 1 - (remaining / 6) -- 6 is the total cooldown
		boostFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
		boostFill.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		boostText.Text = string.format("RECHARGING: %.1f", remaining)
	else
		boostFill.Size = UDim2.new(1, 0, 1, 0)
		boostFill.BackgroundColor3 = Color3.fromHex("#42a5f5")
		boostText.Text = "SHIFT TO BOOST"
	end
end)

print("[EcoSphere] GameHUD initialized")