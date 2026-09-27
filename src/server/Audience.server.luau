-- Anonymous audience info for the stats page: each player's country/region
-- code (from Roblox) and device type (reported by DeviceReport.client).
-- Only these short codes are saved with a night; no age, gender, or names.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")

local DEVICES = {phone = true, tablet = true, computer = true, console = true}

local deviceReport = Instance.new("RemoteEvent")
deviceReport.Name = "DeviceReport"
deviceReport.Parent = ReplicatedStorage
deviceReport.OnServerEvent:Connect(function(player, device)
	if type(device) == "string" and DEVICES[device] then player:SetAttribute("Device", device) end
end)

local function lookUpCountry(player)
	local ok, code = pcall(LocalizationService.GetCountryRegionForPlayerAsync, LocalizationService, player)
	if ok and type(code) == "string" and string.match(code, "^%u%u$") then player:SetAttribute("Country", code) end
end
Players.PlayerAdded:Connect(lookUpCountry)
for _, player in Players:GetPlayers() do task.spawn(lookUpCountry, player) end
