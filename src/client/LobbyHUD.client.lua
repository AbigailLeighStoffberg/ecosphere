-- LobbyHUD: Client-side lobby queue UI with countdown and pad status
-- Shows when player is near/on a pad, hidden otherwise
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Skip on match servers (sphere characters don't need lobby HUD)
-- We detect this by checking if PlanetGravity exists on the character,
-- or use a simpler flag: match servers are reserved servers
-- Since we can't easily check PrivateServerId on client, we'll use a state flag
local isInLobby = true

-- ============================================================
-- BUILD LOBBY HUD
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LobbyHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ========================
-- QUEUE STATUS PANEL (bottom center)
-- ========================
local queueFrame = Instance.new("Frame")
queueFrame.Name = "QueueFrame"
queueFrame.AnchorPoint = Vector2.new(0.5, 1)
queueFrame.Position = UDim2.new(0.5, 0, 1, -30)
queueFrame.Size = UDim2.new(0, 320, 0, 90)
queueFrame.BackgroundColor3 = GameConfig.Palette.DarkTeal
queueFrame.BackgroundTransparency = 0.15
queueFrame.BorderSizePixel = 0
queueFrame.Visible = false
queueFrame.Parent = screenGui

local queueCorner = Instance.new("UICorner")
queueCorner.CornerRadius = UDim.new(0, 16)
queueCorner.Parent = queueFrame

local queueStroke = Instance.new("UIStroke")
queueStroke.Color = GameConfig.Palette.LightGreen
queueStroke.Thickness = 2
queueStroke.Transparency = 0.3
queueStroke.Parent = queueFrame

-- Mode name label
local modeLabel = Instance.new("TextLabel")
modeLabel.Name = "ModeLabel"
modeLabel.Size = UDim2.new(1, 0, 0, 28)
modeLabel.Position = UDim2.new(0, 0, 0, 8)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "SOLO MODE"
modeLabel.TextColor3 = GameConfig.Palette.LightGreen
modeLabel.TextSize = 16
modeLabel.Font = Enum.Font.Nunito
modeLabel.Parent = queueFrame

-- Player count / status
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 24)
statusLabel.Position = UDim2.new(0, 0, 0, 34)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Waiting for players... (0/1)"
statusLabel.TextColor3 = GameConfig.Palette.LightGrey
statusLabel.TextSize = 14
statusLabel.Font = Enum.Font.Nunito
statusLabel.Parent = queueFrame

-- Countdown label (big, centered)
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 0, 28)
countdownLabel.Position = UDim2.new(0, 0, 0, 56)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Text = ""
countdownLabel.TextColor3 = GameConfig.Palette.SoftGold
countdownLabel.TextSize = 20
countdownLabel.Font = Enum.Font.Nunito
countdownLabel.Visible = false
countdownLabel.Parent = queueFrame

-- ========================
-- ERROR NOTIFICATION (top center)
-- ========================
local errorFrame = Instance.new("Frame")
errorFrame.Name = "ErrorFrame"
errorFrame.AnchorPoint = Vector2.new(0.5, 0)
errorFrame.Position = UDim2.new(0.5, 0, 0, -60)
errorFrame.Size = UDim2.new(0, 400, 0, 50)
errorFrame.BackgroundColor3 = GameConfig.Palette.BrightOrange
errorFrame.BackgroundTransparency = 0.1
errorFrame.BorderSizePixel = 0
errorFrame.Visible = false
errorFrame.Parent = screenGui

local errorCorner = Instance.new("UICorner")
errorCorner.CornerRadius = UDim.new(0, 12)
errorCorner.Parent = errorFrame

local errorLabel = Instance.new("TextLabel")
errorLabel.Name = "ErrorLabel"
errorLabel.Size = UDim2.new(1, -20, 1, 0)
errorLabel.Position = UDim2.new(0, 10, 0, 0)
errorLabel.BackgroundTransparency = 1
errorLabel.Text = ""
errorLabel.TextColor3 = Color3.fromRGB(255, 220, 220)
errorLabel.TextSize = 14
errorLabel.Font = Enum.Font.GothamBold
errorLabel.TextWrapped = true
errorLabel.Parent = errorFrame

-- ============================================================
-- HANDLE QUEUE UPDATES
-- ============================================================
local lastQueueState = nil
local hideTimer = nil

Remotes.QueueUpdate.OnClientEvent:Connect(function(eventType, data)
	if eventType == "queue" and data then
		-- Show queue frame
		queueFrame.Visible = true

		modeLabel.Text = string.upper(data.padName or "MATCH")
		statusLabel.Text = "Players: " .. (data.current or 0) .. "/" .. (data.required or 1)

		if data.countdown then
			countdownLabel.Visible = true
			countdownLabel.Text = "⏱ TELEPORTING IN " .. data.countdown .. "..."

			-- Pulse animation on countdown
			TweenService:Create(countdownLabel, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {
				TextSize = 24
			}):Play()

			-- Green border glow during countdown
			TweenService:Create(queueStroke, TweenInfo.new(0.3), {
				Color = GameConfig.Palette.SoftGold,
				Transparency = 0
			}):Play()

			if data.current >= data.required then
				statusLabel.Text = "Team ready! ✓"
				statusLabel.TextColor3 = GameConfig.Palette.LightGreen
			end
		else
			countdownLabel.Visible = false
			TweenService:Create(queueStroke, TweenInfo.new(0.3), {
				Color = GameConfig.Palette.LightGreen,
				Transparency = 0.3
			}):Play()

			if data.current >= data.required then
				statusLabel.Text = "Team ready! Starting..."
				statusLabel.TextColor3 = GameConfig.Palette.LightGreen
			else
				statusLabel.TextColor3 = GameConfig.Palette.LightGrey
			end
		end

		lastQueueState = data

		-- Cancel any pending hide
		if hideTimer then
			task.cancel(hideTimer)
			hideTimer = nil
		end

	elseif eventType == "cancelled" then
		-- Countdown was cancelled
		countdownLabel.Text = "❌ Player left — cancelled"
		countdownLabel.TextColor3 = GameConfig.Palette.CoralPink
		countdownLabel.Visible = true

		TweenService:Create(queueStroke, TweenInfo.new(0.3), {
			Color = GameConfig.Palette.CoralPink,
			Transparency = 0
		}):Play()

		hideTimer = task.delay(2, function()
			countdownLabel.Visible = false
			queueFrame.Visible = false
			TweenService:Create(queueStroke, TweenInfo.new(0.3), {
				Color = GameConfig.Palette.LightGreen,
				Transparency = 0.3
			}):Play()
			hideTimer = nil
		end)

	elseif eventType == "error" then
		-- Show error notification
		errorLabel.Text = "⚠ " .. tostring(data)
		errorFrame.Visible = true

		-- Slide in from top
		errorFrame.Position = UDim2.new(0.5, 0, 0, -60)
		TweenService:Create(errorFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, 0, 0, 20)
		}):Play()

		-- Auto-hide after 4 seconds
		task.delay(4, function()
			TweenService:Create(errorFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = UDim2.new(0.5, 0, 0, -60)
			}):Play()
			task.wait(0.35)
			errorFrame.Visible = false
		end)
	end
end)

-- Hide queue panel when player walks away from all pads
-- (server stops sending updates, so we use a timeout)
task.spawn(function()
	while true do
		task.wait(1.5)
		if queueFrame.Visible and not hideTimer then
			-- If we haven't received an update in 1.5s, hide
			-- The server sends updates every heartbeat while on a pad
			hideTimer = task.delay(0.5, function()
				queueFrame.Visible = false
				countdownLabel.Visible = false
				hideTimer = nil
			end)
		end
	end
end)

-- Handle StartGameClient — hide lobby HUD when entering match
Remotes:WaitForChild("StartGameClient").OnClientEvent:Connect(function()
	isInLobby = false
	screenGui.Enabled = false
end)

print("[EcoSphere] LobbyHUD initialized")
