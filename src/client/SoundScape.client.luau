-- Ambient sound for the whole night: crickets/rain in the evening, a click when
-- the light changes, muffled TV noise while the TV is on, and dream music
-- (calm, or tense once The Algorithm shows up). Only watches game state; it
-- never changes gameplay. Sound ids live in ReplicatedStorage.Shared.GameSounds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ok, ids = pcall(function() return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameSounds")) end)
if not ok or type(ids) ~= "table" then ids = {} end

local function sound(id, looped, parent)
	if type(id) ~= "string" or id == "" then return nil end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = looped
	s.Volume = 0
	s.Parent = parent or SoundService
	return s
end

-- Looping tracks fade toward a target volume instead of cutting in and out.
local loops = {
	night = {sound = sound(ids.NightAmbience, true), volume = 0.35},
	calm = {sound = sound(ids.DreamCalm, true), volume = 0.4},
	tense = {sound = sound(ids.DreamTense, true), volume = 0.45},
}
local function fade(loop, on, dt)
	local s = loop.sound
	if not s then return end
	local target = if on then loop.volume else 0
	s.Volume += (target - s.Volume) * math.min(1, dt * 2)
	if on and not s.IsPlaying then s:Play() end
	if not on and s.IsPlaying and s.Volume < 0.01 then s:Stop() end
end

-- Light switch click (built-in fallback so it always works).
local click = sound(if ids.LampClick ~= "" then ids.LampClick else "rbxasset://sounds/button.wav", false)
if click and ids.LampClick == "" then click.PlaybackSpeed = 1.8 end

local lastDream, lastClick = -math.huge, 0
local function inRoom()
	return player:GetAttribute("StartedGame") == true
		and player:GetAttribute("DreamSeverity") == nil
		and not playerGui:FindFirstChild("RushMorningReport")
		and os.clock() - lastDream > 2
end
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
	if click and inRoom() and os.clock() - lastClick > 0.6 then
		lastClick = os.clock()
		click.Volume = 0.6
		click:Play()
	end
end)

-- Muffled TV: a 3D sound on the screen, played while the TV glow is on.
local tvSound
local function tvGlow()
	local room = workspace:FindFirstChild("CozyBedroom101")
	local expansion = room and room:FindFirstChild("CottageExpansion")
	local console = expansion and expansion:FindFirstChild("TelevisionConsole")
	local screen = console and console:FindFirstChild("TVScreen")
	return screen, screen and screen:FindFirstChild("EveningTVGlow")
end

while true do
	local dt = task.wait(0.2)
	local dreaming = player:GetAttribute("DreamSeverity") ~= nil
	if dreaming then lastDream = os.clock() end
	local chasing = player:GetAttribute("AlgorithmChasing") == true
	local severe = (player:GetAttribute("DreamSeverity") or 0) >= 2
	fade(loops.night, inRoom(), dt)
	fade(loops.calm, dreaming and not chasing and not severe, dt)
	fade(loops.tense, dreaming and (chasing or severe), dt)

	if ids.TVNoise ~= "" then
		local screen, glow = tvGlow()
		if screen and not tvSound then
			tvSound = sound(ids.TVNoise, true, screen)
			if tvSound then
				tvSound.RollOffMaxDistance = 45
				tvSound.RollOffMode = Enum.RollOffMode.InverseTapered
				local muffle = Instance.new("EqualizerSoundEffect")
				muffle.HighGain = -18; muffle.MidGain = -4; muffle.LowGain = 2
				muffle.Parent = tvSound
			end
		end
		if tvSound then fade({sound = tvSound, volume = 0.6}, glow ~= nil and glow.Brightness > 0.3 and inRoom(), dt) end
	end
end
