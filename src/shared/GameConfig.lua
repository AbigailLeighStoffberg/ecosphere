-- GameConfig: Shared constants for EcoSphere
local GameConfig = {}

-- Planet
GameConfig.PLANET_CENTER = Vector3.new(0, 0, 0)
GameConfig.PLANET_RADIUS = 512 -- half of 1024

-- Gravity
GameConfig.GRAVITY_STRENGTH = 400
GameConfig.ROLL_SPEED = 80
GameConfig.MAX_TORQUE = 30000

-- Global UI Palette
GameConfig.Palette = {
	LightGreen = Color3.fromHex("#A8D9A3"),
	SoftGold = Color3.fromHex("#F2D35B"),
	BrightOrange = Color3.fromHex("#FF6F20"),
	ForestGreen = Color3.fromHex("#2A7A3D"),
	PureGold = Color3.fromHex("#FFD700"),
	DarkTeal = Color3.fromHex("#1C3F3D"),
	LightGrey = Color3.fromHex("#E2E3E5"),
}

-- Classes
GameConfig.CLASSES = {
	Economist = {
		DisplayName = "The Economist",
		Color = Color3.fromHex("#d4af37"),  -- Rich Metallic Gold
		Description = "Lays down a glowing network for clean, zero-waste trade. Maps out fair-trade routes and ethical supply chains.",
		Icon = "💰",
	},
	Cultivator = {
		DisplayName = "The Cultivator",
		Color = Color3.fromHex("#699254"),   -- Palette Green
		Description = "Acts as a high-speed seeder. Injects bio-gels to rapidly grow forests, restore soil, and protect the environment.",
		Icon = "🌱",
	},
	Advocate = {
		DisplayName = "The Advocate",
		Color = Color3.fromHex("#d06a49"),  -- Palette Coral/Red
		Description = "Uses smart-dust to create safe zones. Maps out cultural spaces and ensures resources are shared equally for a fair community.",
		Icon = "💜",
	},
}

-- Painting
GameConfig.PAINT_SIZE_DEFAULT = 12
GameConfig.PAINT_SIZE_POWERUP = 28
GameConfig.PAINT_INTERVAL = 0.08
GameConfig.POWERUP_DURATION = 5

-- Coins
GameConfig.COIN_COLOR = Color3.fromHex("#ff8a27")
GameConfig.COIN_COUNT = 160
GameConfig.COIN_RESPAWN_TIME = 12

-- Debris
GameConfig.DEBRIS_COUNT = 120
GameConfig.DEBRIS_ORBIT_HEIGHT = 20 -- above planet surface

-- Game
GameConfig.GAME_DURATION = 180 -- seconds
GameConfig.WIN_THRESHOLD = 0.80 -- 80%

-- Coverage tracking
GameConfig.GRID_RESOLUTION = 80 -- subdivisions per axis for coverage grid

return GameConfig
