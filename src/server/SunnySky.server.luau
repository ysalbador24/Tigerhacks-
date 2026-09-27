-- A clear, sunny sky instead of the flat white haze: blue sky, soft clouds, and
-- a light atmosphere. It shows on the start screen (afternoon); the evening
-- script later sets the clock to night, when the same sky shows stars.
local Lighting = game:GetService("Lighting")

Lighting.ClockTime = 14
Lighting.GeographicLatitude = 35

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.SunAngularSize = 14
sky.MoonAngularSize = 9
sky.StarCount = 3000
sky.CelestialBodiesShown = true
sky.Parent = Lighting

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.26
atmosphere.Offset = 0.12
atmosphere.Color = Color3.fromRGB(199, 221, 255)
atmosphere.Decay = Color3.fromRGB(92, 124, 170)
atmosphere.Glare = 0.15
atmosphere.Haze = 0.6
atmosphere.Parent = Lighting

local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
clouds.Cover = 0.55
clouds.Density = 0.55
clouds.Color = Color3.fromRGB(255, 255, 255)
clouds.Parent = workspace.Terrain
