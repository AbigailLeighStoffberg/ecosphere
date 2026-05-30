-- CoinClient: Client-side coin collection feedback
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GameConfig = require(RS:WaitForChild("GameConfig"))
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create screen GUI for coin collect flash
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoinFXGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Coin collect notification (geometric, no pouch)
local collectLabel = Instance.new("TextLabel")
collectLabel.Name = "CoinCollectLabel"
collectLabel.AnchorPoint = Vector2.new(0.5, 0.5)
collectLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
collectLabel.Size = UDim2.new(0, 300, 0, 60)
collectLabel.BackgroundTransparency = 1
collectLabel.Text = ""
collectLabel.TextColor3 = GameConfig.COIN_COLOR
collectLabel.TextSize = 28
collectLabel.Font = Enum.Font.GothamBold
collectLabel.TextTransparency = 1
collectLabel.Parent = screenGui

-- Geometric diamond indicator (not a pouch)
local diamond = Instance.new("Frame")
diamond.Name = "Diamond"
diamond.AnchorPoint = Vector2.new(0.5, 0.5)
diamond.Position = UDim2.new(0.5, 0, 0.28, 0)
diamond.Size = UDim2.new(0, 30, 0, 30)
diamond.Rotation = 45
diamond.BackgroundColor3 = GameConfig.COIN_COLOR
diamond.BackgroundTransparency = 1
diamond.BorderSizePixel = 0
diamond.Parent = screenGui

local diamondCorner = Instance.new("UICorner")
diamondCorner.CornerRadius = UDim.new(0, 4)
diamondCorner.Parent = diamond

Remotes.CoinCollected.OnClientEvent:Connect(function()
	-- Flash the geometric diamond + text
	collectLabel.Text = "⚡ PAINT BOOST!"
	collectLabel.TextTransparency = 0
	collectLabel.TextSize = 28
	diamond.BackgroundTransparency = 0
	diamond.Size = UDim2.new(0, 10, 0, 10)

	-- Spring pop
	TweenService:Create(diamond, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 40, 0, 40),
	}):Play()

	TweenService:Create(collectLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		TextSize = 34,
	}):Play()

	task.wait(1.2)

	-- Fade out
	TweenService:Create(collectLabel, TweenInfo.new(0.5), {
		TextTransparency = 1
	}):Play()
	TweenService:Create(diamond, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	}):Play()
end)

print("[EcoSphere] CoinClient initialized")
