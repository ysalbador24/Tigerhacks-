local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Dark background
local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
background.BorderSizePixel = 0
background.Parent = screenGui

-- Game title
local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.7, 0.15)
title.Position = UDim2.fromScale(0.15, 0.27)
title.BackgroundTransparency = 1
title.Text = "YOUR GAME TITLE"
title.TextColor3 = Color3.fromRGB(235, 235, 235)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = background

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.fromScale(0.5, 0.06)
subtitle.Position = UDim2.fromScale(0.25, 0.43)
subtitle.BackgroundTransparency = 1
subtitle.Text = "It's getting late."
subtitle.TextColor3 = Color3.fromRGB(160, 165, 180)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = background

-- Play button
local playButton = Instance.new("TextButton")
playButton.Size = UDim2.fromScale(0.18, 0.075)
playButton.Position = UDim2.fromScale(0.41, 0.56)
playButton.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
playButton.TextColor3 = Color3.fromRGB(20, 20, 25)
playButton.Text = "PLAY"
playButton.TextScaled = true
playButton.Font = Enum.Font.GothamBold
playButton.Parent = background

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = playButton

playButton.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)