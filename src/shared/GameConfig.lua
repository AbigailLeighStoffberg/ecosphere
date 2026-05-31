-- GameConfig: Shared constants for EcoSphere
local GameConfig = {}

-- Planet
GameConfig.PLANET_CENTER = Vector3.new(0, 0, 0)
GameConfig.PLANET_RADIUS = 512 -- half of 1024

-- Gravity and Physics
GameConfig.GRAVITY_STRENGTH = 300
GameConfig.ROLL_SPEED = 90
GameConfig.MAX_TORQUE = 45000

-- Global UI Palette
GameConfig.Palette = {
	-- The 10-color brand palette
	LimeGreen = Color3.fromHex("#7ED957"),
	SoftGold = Color3.fromHex("#F6D55C"),
	SoftBlue = Color3.fromHex("#3F88C5"),
	PaleTeal = Color3.fromHex("#A7D3D0"),
	MintGreen = Color3.fromHex("#CEEDB4"),
	AmberGold = Color3.fromHex("#E7B10A"),
	CoralPink = Color3.fromHex("#F6757D"),
	Cream = Color3.fromHex("#F3EAB1"),
	SageGreen = Color3.fromHex("#4B9C72"),
	PastelPink = Color3.fromHex("#F9AFAE"),

	-- Compatibility mappings
	LightGreen = Color3.fromHex("#7ED957"),
	SoftGold_Compat = Color3.fromHex("#F6D55C"), -- avoiding key duplication
	BrightOrange = Color3.fromHex("#F6757D"),
	ForestGreen = Color3.fromHex("#4B9C72"),
	PureGold = Color3.fromHex("#E7B10A"),
	DarkTeal = Color3.fromHex("#1C3F3D"), -- Dark Teal background counterpart to PaleTeal
	LightGrey = Color3.fromHex("#F3EAB1"), -- Cream as light text color
}

-- Classes
GameConfig.CLASSES = {
	Economist = {
		DisplayName = "The Economist",
		Color = Color3.fromHex("#E7B10A"),  -- Amber Gold
		Description = "Lays down a glowing network for clean, zero-waste trade. Maps out fair-trade routes and ethical supply chains.",
		Icon = "💰",
	},
	Cultivator = {
		DisplayName = "The Cultivator",
		Color = Color3.fromHex("#4B9C72"),   -- Sage Green
		Description = "Acts as a high-speed seeder. Injects bio-gels to rapidly grow forests, restore soil, and protect the environment.",
		Icon = "🌱",
	},
	Advocate = {
		DisplayName = "The Advocate",
		Color = Color3.fromHex("#F6757D"),  -- Coral Pink
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
GameConfig.GAME_DURATION = 60 -- seconds
GameConfig.WIN_THRESHOLD = 0.80 -- 80%

-- Coverage tracking
GameConfig.GRID_RESOLUTION = 80 -- subdivisions per axis for coverage grid

-- Match / Teleport
GameConfig.MATCH_PLACE_ID = 0 -- SET THIS to your Match Place ID after creating it in Game Explorer
GameConfig.COUNTDOWN_DURATION = 5 -- seconds countdown before teleporting from pad
GameConfig.RETURN_TO_LOBBY_DELAY = 10 -- seconds after match ends before returning to lobby
GameConfig.MATCH_LOAD_TIMEOUT = 30 -- seconds to wait for players to arrive on match server

return GameConfig
