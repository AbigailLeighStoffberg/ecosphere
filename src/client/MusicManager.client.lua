-- MusicManager: Handles smooth transition of background music between Lobby and In-Game
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Remotes = RS:WaitForChild("Remotes")

local player = Players.LocalPlayer

-- Wait for sounds in Workspace
local soundOrbital = workspace:WaitForChild("Orbital Dawn")
local soundTitanium = workspace:WaitForChild("Titanium (Underscore A)")

-- Configure sounds
soundOrbital.Looped = true
soundTitanium.Looped = true

-- Target volumes
local LOBBY_VOLUME = 0.5
local GAME_VOLUME = 0.5
local FADE_DURATION = 1.5

local currentTrack = nil -- "orbital" or "titanium" or "none"

local function playTrack(trackName)
	if currentTrack == trackName then return end
	currentTrack = trackName
	
	if trackName == "orbital" then
		-- Fade in Orbital Dawn, fade out Titanium
		local t1 = TweenService:Create(soundOrbital, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = LOBBY_VOLUME})
		if not soundOrbital.IsPlaying then
			soundOrbital.Volume = 0
			soundOrbital:Play()
		end
		t1:Play()
		
		local t2 = TweenService:Create(soundTitanium, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = 0})
		t2:Play()
		task.spawn(function()
			t2.Completed:Wait()
			if currentTrack == "orbital" and soundTitanium.IsPlaying then
				soundTitanium:Stop()
			end
		end)
		
	elseif trackName == "titanium" then
		-- Fade in Titanium, fade out Orbital Dawn
		local t1 = TweenService:Create(soundTitanium, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = GAME_VOLUME})
		if not soundTitanium.IsPlaying then
			soundTitanium.Volume = 0
			soundTitanium:Play()
		end
		t1:Play()
		
		local t2 = TweenService:Create(soundOrbital, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = 0})
		t2:Play()
		task.spawn(function()
			t2.Completed:Wait()
			if currentTrack == "titanium" and soundOrbital.IsPlaying then
				soundOrbital:Stop()
			end
		end)
		
	elseif trackName == "none" then
		-- Fade out both
		local t1 = TweenService:Create(soundOrbital, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = 0})
		local t2 = TweenService:Create(soundTitanium, TweenInfo.new(FADE_DURATION, Enum.EasingStyle.Linear), {Volume = 0})
		t1:Play()
		t2:Play()
		task.spawn(function()
			t1.Completed:Wait()
			if currentTrack == "none" and soundOrbital.IsPlaying then
				soundOrbital:Stop()
			end
		end)
		task.spawn(function()
			t2.Completed:Wait()
			if currentTrack == "none" and soundTitanium.IsPlaying then
				soundTitanium:Stop()
			end
		end)
	end
end

-- Lobby center to check distance
local LOBBY_CENTER = Vector3.new(1427.67, -205.44, 634.32)
local LOBBY_RADIUS = 500

-- Check player location
local function updateMusicBasedOnLocation()
	local char = player.Character
	if char and char.PrimaryPart then
		local pos = char:GetPivot().Position
		local dist = (pos - LOBBY_CENTER).Magnitude
		if dist <= LOBBY_RADIUS then
			playTrack("orbital")
		else
			-- If in game, play Titanium unless game has ended
			-- We will default to "titanium" if far from lobby.
			playTrack("titanium")
		end
	else
		-- Default to lobby track if no character
		playTrack("orbital")
	end
end

-- Listen to Game State changes
Remotes.GameStateChanged.OnClientEvent:Connect(function(state, timeLeft)
	if state == "playing" then
		playTrack("titanium")
	elseif state == "victory" or state == "defeat" then
		playTrack("none")
	end
end)

-- Periodically check location to handle respawns/teleportation fallback
task.spawn(function()
	while true do
		task.wait(1)
		updateMusicBasedOnLocation()
	end
end)

print("[EcoSphere] MusicManager initialized")
