-- A clear sky for the evening in the room (instead of a flat white haze), so the
-- sunset through the windows looks warm and then fades into a starry night.
-- Only applies after the player presses Start, so the start screen is unchanged.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local applied = false

local function apply()
	if applied or player:GetAttribute("StartedGame") ~= true then return end
	applied = true
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.StarCount = 3000
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(199, 214, 255)
	atmosphere.Decay = Color3.fromRGB(106, 112, 125)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 0.8
	atmosphere.Parent = Lighting
end

player:GetAttributeChangedSignal("StartedGame"):Connect(apply)
apply()
