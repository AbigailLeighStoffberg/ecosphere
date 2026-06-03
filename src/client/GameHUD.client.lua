-- GameHUD: Flat Design 2.0 progress bars, timer, and game state display
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
timerFrame.Size = UDim2.new(0, 130, 0, 50)
timerFrame.BackgroundColor3 = GameConfig.Palette.DarkTeal
timerFrame.BackgroundTransparency = 0.1
timerFrame.BorderSizePixel = 0
timerFrame.Parent = screenGui

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 12)
timerCorner.Parent = timerFrame

local timerStroke = Instance.new("UIStroke")
timerStroke.Color = GameConfig.Palette.PaleTeal
timerStroke.Thickness = 2
timerStroke.Parent = timerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(1, 0, 0, 12)
timerLabel.Position = UDim2.new(0, 0, 0, 4)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "TIME REMAINING"
timerLabel.TextColor3 = GameConfig.Palette.Cream
timerLabel.TextSize = 9
timerLabel.Font = Enum.Font.Nunito
timerLabel.Parent = timerFrame

local timerValue = Instance.new("TextLabel")
timerValue.Name = "TimerValue"
timerValue.Size = UDim2.new(1, 0, 0, 28)
timerValue.Position = UDim2.new(0, 0, 0, 18)
timerValue.BackgroundTransparency = 1
timerValue.Text = "1:00"
timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
timerValue.TextSize = 22
timerValue.Font = Enum.Font.Nunito
timerValue.Parent = timerFrame

-- ========================
-- PROGRESS BARS (compact top right)
-- ========================
local progressFrame = Instance.new("Frame")
progressFrame.Name = "ProgressFrame"
progressFrame.AnchorPoint = Vector2.new(1, 0)
progressFrame.Position = UDim2.new(1, -20, 0, 20)
progressFrame.Size = UDim2.new(0, 240, 0, 105) -- Compact size
progressFrame.BackgroundColor3 = GameConfig.Palette.DarkTeal
progressFrame.BackgroundTransparency = 0.1
progressFrame.BorderSizePixel = 0
progressFrame.Parent = screenGui

local progCorner = Instance.new("UICorner")
progCorner.CornerRadius = UDim.new(0, 14)
progCorner.Parent = progressFrame

local progStroke = Instance.new("UIStroke")
progStroke.Color = GameConfig.Palette.PaleTeal
progStroke.Thickness = 2
progStroke.Parent = progressFrame

-- Title
local progTitle = Instance.new("TextLabel")
progTitle.Size = UDim2.new(1, 0, 0, 20)
progTitle.Position = UDim2.new(0, 0, 0, 4)
progTitle.BackgroundTransparency = 1
progTitle.Text = "HARMONY PROGRESS"
progTitle.TextColor3 = GameConfig.Palette.Cream
progTitle.TextSize = 11
progTitle.Font = Enum.Font.Nunito
progTitle.Parent = progressFrame

-- Build individual progress bars
local classOrder = {"Economist", "Cultivator", "Advocate"}
local barFills = {}
local barLabels = {}
local barPcts = {}

for i, className in ipairs(classOrder) do
	local classData = GameConfig.CLASSES[className]
	local yOffset = 22 + (i - 1) * 25

	-- Class label (compact)
	local label = Instance.new("TextLabel")
	label.Name = className .. "Label"
	label.Size = UDim2.new(0, 75, 0, 20)
	label.Position = UDim2.new(0, 10, 0, yOffset)
	label.BackgroundTransparency = 1
	label.Text = classData.DisplayName
	label.TextColor3 = classData.Color
	label.TextSize = 10
	label.Font = Enum.Font.Nunito
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = progressFrame
	barLabels[className] = label

	-- Bar background (slender)
	local barBg = Instance.new("Frame")
	barBg.Name = className .. "BarBg"
	barBg.Size = UDim2.new(0, 110, 0, 10)
	barBg.Position = UDim2.new(0, 90, 0, yOffset + 5)
	barBg.BackgroundColor3 = GameConfig.Palette.PaleTeal
	barBg.BackgroundTransparency = 0.8
	barBg.BorderSizePixel = 0
	barBg.Parent = progressFrame

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 5)
	barBgCorner.Parent = barBg

	-- Bar fill (chunky, springy)
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = classData.Color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = barFill

	-- 80% threshold marker
	local threshold = Instance.new("Frame")
	threshold.Name = "Threshold"
	threshold.Size = UDim2.new(0, 2, 1, 2)
	threshold.Position = UDim2.new(0.8, 0, 0, -1)
	threshold.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	threshold.BackgroundTransparency = 0.4
	threshold.BorderSizePixel = 0
	threshold.Parent = barBg

	-- Percentage text (compact)
	local pctLabel = Instance.new("TextLabel")
	pctLabel.Name = className .. "Pct"
	pctLabel.Size = UDim2.new(0, 30, 0, 20)
	pctLabel.Position = UDim2.new(0, 205, 0, yOffset)
	pctLabel.BackgroundTransparency = 1
	pctLabel.Text = "0%"
	pctLabel.TextColor3 = classData.Color
	pctLabel.TextSize = 10
	pctLabel.Font = Enum.Font.Nunito
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
puLabel.Font = Enum.Font.Nunito
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
stateText.Font = Enum.Font.Nunito
stateText.TextWrapped = true
stateText.ZIndex = 11
stateText.Parent = stateOverlay

local stateSubtext = Instance.new("TextLabel")
stateSubtext.Name = "StateSubtext"
stateSubtext.AnchorPoint = Vector2.new(0.5, 0)
stateSubtext.Position = UDim2.new(0.5, 0, 0.55, 0)
stateSubtext.Size = UDim2.new(0, 500, 0, 40)
stateSubtext.BackgroundTransparency = 1
stateSubtext.TextColor3 = GameConfig.Palette.Cream
stateSubtext.TextSize = 20
stateSubtext.Font = Enum.Font.Nunito
stateSubtext.ZIndex = 11
stateSubtext.Parent = stateOverlay

-- ========================
-- CLASS SWITCHER UI (top left)
-- ========================
local UIS = game:GetService("UserInputService")
local switchFrame = Instance.new("Frame")
switchFrame.Name = "SwitchFrame"
switchFrame.AnchorPoint = Vector2.new(0, 0)
switchFrame.Position = UDim2.new(0, 20, 0, 75) -- Shifted down to clear Roblox's default top-left menu bar
switchFrame.Size = UDim2.new(0, 160, 0, 65) -- Compact size
switchFrame.BackgroundColor3 = GameConfig.Palette.DarkTeal
switchFrame.BackgroundTransparency = 0.1
switchFrame.BorderSizePixel = 0
switchFrame.Parent = screenGui

local switchCorner = Instance.new("UICorner")
switchCorner.CornerRadius = UDim.new(0, 12)
switchCorner.Parent = switchFrame

local switchStroke = Instance.new("UIStroke")
switchStroke.Color = GameConfig.Palette.PaleTeal
switchStroke.Thickness = 2
switchStroke.Parent = switchFrame

local switchTitle = Instance.new("TextLabel")
switchTitle.Size = UDim2.new(1, 0, 0, 15)
switchTitle.Position = UDim2.new(0, 0, 0, 4)
switchTitle.BackgroundTransparency = 1
switchTitle.Text = "SWITCH CLASS"
switchTitle.TextColor3 = GameConfig.Palette.Cream
switchTitle.TextSize = 10
switchTitle.Font = Enum.Font.Nunito
switchTitle.Parent = switchFrame

local switchContainer = Instance.new("Frame")
switchContainer.Size = UDim2.new(1, 0, 0, 34)
switchContainer.Position = UDim2.new(0, 0, 0, 22)
switchContainer.BackgroundTransparency = 1
switchContainer.Parent = switchFrame

local switchLayout = Instance.new("UIListLayout")
switchLayout.FillDirection = Enum.FillDirection.Horizontal
switchLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
switchLayout.Padding = UDim.new(0, 10)
switchLayout.Parent = switchContainer

local function createSwitchBtn(className, hotkey)
	local classData = GameConfig.CLASSES[className]
	local btn = Instance.new("TextButton")
	btn.Name = className .. "Btn"
	btn.Size = UDim2.new(0, 34, 0, 34)
	btn.BackgroundColor3 = classData.Color
	btn.Text = classData.Icon
	btn.TextSize = 16
	btn.Font = Enum.Font.Nunito
	btn.Parent = switchContainer
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(1, 0)
	btnCorner.Parent = btn
	
	-- Only create key labels if not on touch screen (mobile)
	if not UIS.TouchEnabled then
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 12)
		label.Position = UDim2.new(0, 0, 1, 2)
		label.BackgroundTransparency = 1
		
		local gpKeys = { ["1"] = "←", ["2"] = "↑", ["3"] = "→" }
		local gpKey = gpKeys[hotkey]
		if gpKey then
			label.Text = "[" .. hotkey .. "] / [" .. gpKey .. "]"
		else
			label.Text = "[" .. hotkey .. "]"
		end
		
		label.TextColor3 = GameConfig.Palette.Cream
		label.TextSize = 9
		label.Font = Enum.Font.Nunito
		label.Parent = btn
	end
	
	btn.MouseButton1Click:Connect(function()
		if not _G.ClassSelected then return end
		
		Remotes.SelectClass:FireServer(className)
		
		-- Simple click animation
		local ts = game:GetService("TweenService")
		ts:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 28, 0, 28)}):Play()
		task.wait(0.1)
		ts:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {Size = UDim2.new(0, 34, 0, 34)}):Play()
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

			-- Color flash when crossing 80% (using LimeGreen from brand)
			if pct >= 0.8 then
				barPcts[className].TextColor3 = GameConfig.Palette.LimeGreen
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

		-- Urgency color (using brand colors)
		if timeLeft <= 30 then
			timerValue.TextColor3 = GameConfig.Palette.CoralPink
			-- Pulse effect
			TweenService:Create(timerValue, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextSize = 34
			}):Play()
		elseif timeLeft <= 60 then
			timerValue.TextColor3 = GameConfig.Palette.SoftGold
		else
			timerValue.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

	elseif state == "playing" then
		timerValue.Text = "1:00"

	elseif state == "victory" then
		stateOverlay.Visible = true
		TweenService:Create(stateOverlay, TweenInfo.new(0.8), {BackgroundTransparency = 0.3}):Play()
		stateText.Text = "✨ HARMONY ACHIEVED! ✨"
		stateText.TextColor3 = GameConfig.Palette.LimeGreen
		if timeLeft and timeLeft > 0 then
			stateSubtext.Text = "With " .. math.floor(timeLeft) .. " seconds to spare!"
		else
			stateSubtext.Text = "The EcoSphere is in perfect balance."
		end

	elseif state == "defeat" then
		stateOverlay.Visible = true
		TweenService:Create(stateOverlay, TweenInfo.new(1.5), {BackgroundTransparency = 0.4}):Play()
		stateText.Text = "ECOSYSTEM COLLAPSED"
		stateText.TextColor3 = GameConfig.Palette.CoralPink
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

local function enableHUD()
	screenGui.Enabled = true
end

local function disableHUD()
	screenGui.Enabled = false
end

Remotes:WaitForChild("StartGameClient").OnClientEvent:Connect(enableHUD)

local function monitorCharacter(char)
	local function check()
		if char:GetAttribute("Class") then
			enableHUD()
		else
			disableHUD()
		end
	end
	
	local conn = char:GetAttributeChangedSignal("Class"):Connect(check)
	check()
	
	local destroyConn
	destroyConn = char.Destroying:Connect(function()
		conn:Disconnect()
		destroyConn:Disconnect()
	end)
end

player.CharacterAdded:Connect(monitorCharacter)
if player.Character then
	task.spawn(monitorCharacter, player.Character)
end

print("[EcoSphere] GameHUD initialized")

-- ========================
-- BOOST HUD (bottom center)
-- ========================
local boostBg = Instance.new("Frame")
boostBg.Name = "BoostBg"
boostBg.AnchorPoint = Vector2.new(0.5, 1)
boostBg.Position = UDim2.new(0.5, 0, 1, -25) -- Floating at bottom center
boostBg.Size = UDim2.new(0, 160, 0, 6) -- Subtle thin bar
boostBg.BackgroundColor3 = GameConfig.Palette.DarkTeal
boostBg.BackgroundTransparency = 0.5
boostBg.BorderSizePixel = 0
boostBg.Parent = screenGui

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(1, 0)
bgCorner.Parent = boostBg

local boostFill = Instance.new("Frame")
boostFill.Name = "BoostFill"
boostFill.Size = UDim2.new(1, 0, 1, 0)
boostFill.BackgroundColor3 = GameConfig.Palette.SoftBlue
boostFill.BorderSizePixel = 0
boostFill.Parent = boostBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = boostFill

local function getBoostPrompt()
	if UIS.TouchEnabled then
		return "BOOST READY"
	elseif UIS.GamepadEnabled or UIS:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		return "L2 TO BOOST"
	else
		return "SHIFT TO BOOST"
	end
end

local boostText = Instance.new("TextLabel")
boostText.Name = "BoostText"
boostText.AnchorPoint = Vector2.new(0.5, 1)
boostText.Position = UDim2.new(0.5, 0, 0, -4)
boostText.Size = UDim2.new(1, 0, 0, 18)
boostText.BackgroundTransparency = 1
boostText.Text = getBoostPrompt()
boostText.TextColor3 = Color3.new(1,1,1)
boostText.Font = Enum.Font.Nunito
boostText.TextSize = 12 -- Increased for legibility
boostText.Parent = boostBg

local boostTextStroke = Instance.new("UIStroke")
boostTextStroke.Color = Color3.new(0, 0, 0)
boostTextStroke.Thickness = 2
boostTextStroke.Parent = boostText

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
		boostFill.BackgroundColor3 = GameConfig.Palette.SoftBlue
		boostText.Text = getBoostPrompt()
	end
end)

-- ========================
-- RETURN TO LOBBY (after match ends)
-- ========================
local returnLabel = Instance.new("TextLabel")
returnLabel.Name = "ReturnLabel"
returnLabel.AnchorPoint = Vector2.new(0.5, 0)
returnLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
returnLabel.Size = UDim2.new(0, 400, 0, 30)
returnLabel.BackgroundTransparency = 1
returnLabel.TextColor3 = GameConfig.Palette.Cream
returnLabel.TextSize = 16
returnLabel.Font = Enum.Font.Nunito
returnLabel.Text = ""
returnLabel.Visible = false
returnLabel.ZIndex = 12
returnLabel.Parent = stateOverlay

Remotes:WaitForChild("ReturnToLobby").OnClientEvent:Connect(function(delay)
	if not delay then delay = 10 end
	returnLabel.Visible = true

	task.spawn(function()
		local remaining = delay
		while remaining > 0 do
			returnLabel.Text = "Returning to Lobby in " .. math.ceil(remaining) .. "..."
			task.wait(0.5)
			remaining = remaining - 0.5
		end
		returnLabel.Text = "Teleporting..."
	end)
end)

print("[EcoSphere] GameHUD initialized")