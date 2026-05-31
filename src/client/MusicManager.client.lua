-- MusicManager: Handles smooth transition of background music between Lobby and In-Game
-- Uses game state events instead of distance-based checking
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

-- Default: start with lobby music
-- On match servers, StartGameClient will switch to game music
playTrack("orbital")

-- Listen to StartGameClient (fires when player enters match)
Remotes:WaitForChild("StartGameClient").OnClientEvent:Connect(function()
	playTrack("titanium")
end)

-- Listen to Game State changes
Remotes.GameStateChanged.OnClientEvent:Connect(function(state, timeLeft)
	if state == "playing" then
		playTrack("titanium")
	elseif state == "victory" or state == "defeat" then
		playTrack("none")
	end
end)

-- Listen to ReturnToLobby
Remotes:WaitForChild("ReturnToLobby").OnClientEvent:Connect(function()
	playTrack("orbital")
end)

print("[EcoSphere] MusicManager initialized")
