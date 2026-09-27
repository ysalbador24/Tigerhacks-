-- Tells the server which kind of device this player is on (for the stats page).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local device = "computer"
if GuiService:IsTenFootInterface() then
	device = "console"
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	local size = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
	device = if math.min(size.X, size.Y) < 600 then "phone" else "tablet"
end
ReplicatedStorage:WaitForChild("DeviceReport"):FireServer(device)
