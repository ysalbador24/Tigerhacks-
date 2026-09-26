local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- REMOVE OLD GUI
--------------------------------------------------

local oldGui = playerGui:FindFirstChild("StartScreen")

if oldGui then
	oldGui:Destroy()
end

--------------------------------------------------
-- COLORS
--------------------------------------------------

local COLORS = {
	Morning = Color3.fromRGB(255, 224, 184),
	Day = Color3.fromRGB(255, 205, 160),
	Sunset = Color3.fromRGB(218, 145, 154),
	Evening = Color3.fromRGB(104, 91, 139),
	Night = Color3.fromRGB(35, 39, 68),

	Cream = Color3.fromRGB(255, 241, 218),
	Pink = Color3.fromRGB(235, 157, 173),
	Blue = Color3.fromRGB(158, 196, 211),
	Dark = Color3.fromRGB(39, 39, 48),
	SoftPurple = Color3.fromRGB(190, 180, 210),
	Yellow = Color3.fromRGB(255, 210, 112),
}

--------------------------------------------------
-- SCREEN
--------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StartScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = COLORS.Morning
background.BorderSizePixel = 0
background.ClipsDescendants = true
background.Parent = screenGui

--------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

local function addStroke(object, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Dark
	stroke.Thickness = thickness
	stroke.Parent = object
	return stroke
end

local function tween(object, duration, properties, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)

	local animation = TweenService:Create(
		object,
		tweenInfo,
		properties
	)

	animation:Play()

	return animation
end

--------------------------------------------------
-- SUN
--------------------------------------------------

local sun = Instance.new("Frame")
sun.Name = "Sun"

sun.AnchorPoint = Vector2.new(0.5, 0.5)
sun.Position = UDim2.fromScale(0.12, 0.70)
sun.Size = UDim2.fromScale(0.09, 0.16)

sun.BackgroundColor3 = COLORS.Yellow
sun.BorderSizePixel = 0

sun.Parent = background

addCorner(sun, 100)
addStroke(sun, 3)

--------------------------------------------------
-- MOON
--------------------------------------------------

local moon = Instance.new("Frame")
moon.Name = "Moon"

moon.AnchorPoint = Vector2.new(0.5, 0.5)
moon.Position = UDim2.fromScale(0.88, 1.15)
moon.Size = UDim2.fromScale(0.07, 0.13)

moon.BackgroundColor3 = COLORS.Cream
moon.BorderSizePixel = 0

moon.Parent = background

addCorner(moon, 100)
addStroke(moon, 3)

--------------------------------------------------
-- STARS
--------------------------------------------------

local stars = {}

local starPositions = {
	{0.10, 0.18},
	{0.20, 0.30},
	{0.31, 0.14},
	{0.70, 0.19},
	{0.82, 0.31},
	{0.91, 0.15},
	{0.64, 0.36},
}

for index, position in ipairs(starPositions) do

	local star = Instance.new("TextLabel")

	star.Name = "Star" .. index
	star.AnchorPoint = Vector2.new(0.5, 0.5)

	star.Position = UDim2.fromScale(
		position[1],
		position[2]
	)

	star.Size = UDim2.fromScale(0.035, 0.06)

	star.BackgroundTransparency = 1

	star.Text = "✦"
	star.TextColor3 = COLORS.Cream
	star.TextTransparency = 1

	star.Font = Enum.Font.GothamBold
	star.TextScaled = true

	star.Parent = background

	table.insert(stars, star)
end

--------------------------------------------------
-- TIME LABEL
--------------------------------------------------

local timeLabel = Instance.new("TextLabel")

timeLabel.Name = "TimeLabel"

timeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
timeLabel.Position = UDim2.fromScale(0.5, 0.13)
timeLabel.Size = UDim2.fromScale(0.30, 0.07)

timeLabel.BackgroundTransparency = 1

timeLabel.Text = "7:12 AM"
timeLabel.TextColor3 = COLORS.Dark

timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextScaled = true

timeLabel.Parent = background

--------------------------------------------------
-- ALARM CLOCK GROUP
--------------------------------------------------

local clockGroup = Instance.new("Frame")

clockGroup.Name = "AlarmClock"

clockGroup.AnchorPoint = Vector2.new(0.5, 0.5)
clockGroup.Position = UDim2.fromScale(0.5, 0.44)
clockGroup.Size = UDim2.fromScale(0.30, 0.25)

clockGroup.BackgroundTransparency = 1

clockGroup.Parent = background

--------------------------------------------------
-- CLOCK BODY
--------------------------------------------------

local clockBody = Instance.new("Frame")

clockBody.Name = "ClockBody"

clockBody.AnchorPoint = Vector2.new(0.5, 0.5)
clockBody.Position = UDim2.fromScale(0.5, 0.55)
clockBody.Size = UDim2.fromScale(0.75, 0.55)

clockBody.BackgroundColor3 = COLORS.Pink
clockBody.BorderSizePixel = 0

clockBody.Parent = clockGroup

addCorner(clockBody, 25)
addStroke(clockBody, 4)

--------------------------------------------------
-- CLOCK FACE
--------------------------------------------------

local clockFace = Instance.new("Frame")

clockFace.Name = "ClockFace"

clockFace.AnchorPoint = Vector2.new(0.5, 0.5)
clockFace.Position = UDim2.fromScale(0.5, 0.5)
clockFace.Size = UDim2.fromScale(0.82, 0.63)

clockFace.BackgroundColor3 = COLORS.Cream
clockFace.BorderSizePixel = 0

clockFace.Parent = clockBody

addCorner(clockFace, 18)
addStroke(clockFace, 3)

--------------------------------------------------
-- CLOCK DISPLAY
--------------------------------------------------

local clockText = Instance.new("TextLabel")

clockText.Name = "ClockText"

clockText.AnchorPoint = Vector2.new(0.5, 0.5)
clockText.Position = UDim2.fromScale(0.5, 0.5)
clockText.Size = UDim2.fromScale(0.85, 0.55)

clockText.BackgroundTransparency = 1

clockText.Text = "7:12 AM"
clockText.TextColor3 = COLORS.Dark

clockText.Font = Enum.Font.GothamBold
clockText.TextScaled = true

clockText.Parent = clockFace

--------------------------------------------------
-- ALARM BELLS
--------------------------------------------------

local leftBell = Instance.new("Frame")

leftBell.AnchorPoint = Vector2.new(0.5, 0.5)
leftBell.Position = UDim2.fromScale(0.25, 0.20)
leftBell.Size = UDim2.fromScale(0.22, 0.22)

leftBell.BackgroundColor3 = COLORS.Blue
leftBell.BorderSizePixel = 0

leftBell.Rotation = -15

leftBell.Parent = clockGroup

addCorner(leftBell, 100)
addStroke(leftBell, 3)


local rightBell = Instance.new("Frame")

rightBell.AnchorPoint = Vector2.new(0.5, 0.5)
rightBell.Position = UDim2.fromScale(0.75, 0.20)
rightBell.Size = UDim2.fromScale(0.22, 0.22)

rightBell.BackgroundColor3 = COLORS.Blue
rightBell.BorderSizePixel = 0

rightBell.Rotation = 15

rightBell.Parent = clockGroup

addCorner(rightBell, 100)
addStroke(rightBell, 3)

--------------------------------------------------
-- CLOCK LEGS
--------------------------------------------------

local leftLeg = Instance.new("Frame")

leftLeg.AnchorPoint = Vector2.new(0.5, 0.5)
leftLeg.Position = UDim2.fromScale(0.35, 0.86)
leftLeg.Size = UDim2.fromScale(0.08, 0.20)

leftLeg.BackgroundColor3 = COLORS.Dark
leftLeg.BorderSizePixel = 0
leftLeg.Rotation = 15

leftLeg.Parent = clockGroup

addCorner(leftLeg, 8)


local rightLeg = Instance.new("Frame")

rightLeg.AnchorPoint = Vector2.new(0.5, 0.5)
rightLeg.Position = UDim2.fromScale(0.65, 0.86)
rightLeg.Size = UDim2.fromScale(0.08, 0.20)

rightLeg.BackgroundColor3 = COLORS.Dark
rightLeg.BorderSizePixel = 0
rightLeg.Rotation = -15

rightLeg.Parent = clockGroup

addCorner(rightLeg, 8)

--------------------------------------------------
-- ZZZ
--------------------------------------------------

local zzz = Instance.new("TextLabel")

zzz.Name = "ZZZ"

zzz.AnchorPoint = Vector2.new(0.5, 0.5)
zzz.Position = UDim2.fromScale(0.68, 0.31)
zzz.Size = UDim2.fromScale(0.12, 0.13)

zzz.BackgroundTransparency = 1

zzz.Text = "z  Z  z"
zzz.TextColor3 = COLORS.Cream
zzz.TextTransparency = 1

zzz.Font = Enum.Font.GothamBold
zzz.TextScaled = true

zzz.Rotation = -10

zzz.Parent = background

--------------------------------------------------
-- BZZZ TEXT
--------------------------------------------------

local buzzText = Instance.new("TextLabel")

buzzText.Name = "Buzz"

buzzText.AnchorPoint = Vector2.new(0.5, 0.5)
buzzText.Position = UDim2.fromScale(0.72, 0.39)
buzzText.Size = UDim2.fromScale(0.18, 0.10)

buzzText.BackgroundTransparency = 1

buzzText.Text = "BZZZ!"
buzzText.TextColor3 = COLORS.Cream
buzzText.TextTransparency = 1

buzzText.Font = Enum.Font.GothamBold
buzzText.TextScaled = true

buzzText.Rotation = 8

buzzText.Parent = background

--------------------------------------------------
-- TITLE
--------------------------------------------------

local title = Instance.new("TextLabel")

title.Name = "Title"

title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.68)
title.Size = UDim2.fromScale(0.68, 0.10)

title.BackgroundTransparency = 1

title.Text = "SNOOZE YOU CHOOSE"
title.TextColor3 = COLORS.Cream
title.TextTransparency = 1

title.Font = Enum.Font.GothamBold
title.TextScaled = true

title.Parent = background

--------------------------------------------------
-- SUBTITLE
--------------------------------------------------

local subtitle = Instance.new("TextLabel")

subtitle.Name = "Subtitle"

subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.Position = UDim2.fromScale(0.5, 0.755)
subtitle.Size = UDim2.fromScale(0.45, 0.04)

subtitle.BackgroundTransparency = 1

subtitle.Text = "your night. your choices."
subtitle.TextColor3 = COLORS.SoftPurple
subtitle.TextTransparency = 1

subtitle.Font = Enum.Font.Gotham
subtitle.TextScaled = true

subtitle.Parent = background

--------------------------------------------------
-- START BUTTON
--------------------------------------------------

local startButton = Instance.new("TextButton")

startButton.Name = "StartButton"

startButton.AnchorPoint = Vector2.new(0.5, 0.5)
startButton.Position = UDim2.fromScale(0.5, 0.86)

startButton.Size = UDim2.fromScale(0.19, 0.075)

startButton.BackgroundColor3 = COLORS.Blue
startButton.BackgroundTransparency = 1

startButton.Text = "START"
startButton.TextColor3 = COLORS.Dark
startButton.TextTransparency = 1

startButton.Font = Enum.Font.GothamBold
startButton.TextScaled = true

startButton.AutoButtonColor = false

startButton.Parent = background

addCorner(startButton, 18)

local buttonStroke = addStroke(startButton, 3)
buttonStroke.Transparency = 1

--------------------------------------------------
-- CLOCK SHAKE
--------------------------------------------------

local function shakeClock()

	buzzText.TextTransparency = 0

	local originalPosition = clockGroup.Position

	local movements = {
		{position = UDim2.fromScale(0.485, 0.44), rotation = -6},
		{position = UDim2.fromScale(0.515, 0.44), rotation = 6},
		{position = UDim2.fromScale(0.487, 0.44), rotation = -5},
		{position = UDim2.fromScale(0.513, 0.44), rotation = 5},
		{position = UDim2.fromScale(0.49, 0.44), rotation = -3},
		{position = UDim2.fromScale(0.51, 0.44), rotation = 3},
		{position = originalPosition, rotation = 0},
	}

	for _, movement in ipairs(movements) do

		local shakeTween = tween(
			clockGroup,
			0.055,
			{
				Position = movement.position,
				Rotation = movement.rotation
			},
			Enum.EasingStyle.Linear
		)

		shakeTween.Completed:Wait()
	end

	tween(
		buzzText,
		0.25,
		{
			TextTransparency = 1
		}
	)
end

--------------------------------------------------
-- TITLE REVEAL
--------------------------------------------------

local function revealTitle()

	title.Text = "SNOOZE YOU CHOOSE"
	title.TextTransparency = 0

	title.MaxVisibleGraphemes = 0

	local length = utf8.len(title.Text)

	for i = 1, length do

		title.MaxVisibleGraphemes = i

		task.wait(0.045)
	end

	task.wait(0.5)

	--------------------------------------------------
	-- GLITCH
	--------------------------------------------------

	title.Text = "SNOOZE YOU LOOSE"

	title.Position = UDim2.fromScale(0.505, 0.68)

	task.wait(0.07)

	title.Position = UDim2.fromScale(0.495, 0.68)

	task.wait(0.07)

	title.Text = "SNOOZE YOU CHOOSE"

	title.Position = UDim2.fromScale(0.5, 0.68)

	task.wait(0.25)

	--------------------------------------------------
	-- SUBTITLE
	--------------------------------------------------

	tween(
		subtitle,
		0.8,
		{
			TextTransparency = 0
		}
	)

	task.wait(0.35)

	--------------------------------------------------
	-- START BUTTON
	--------------------------------------------------

	startButton.Size = UDim2.fromScale(0.14, 0.055)

	tween(
		startButton,
		0.4,
		{
			Size = UDim2.fromScale(0.19, 0.075),
			BackgroundTransparency = 0,
			TextTransparency = 0
		},
		Enum.EasingStyle.Back
	)

	tween(
		buttonStroke,
		0.4,
		{
			Transparency = 0
		}
	)
end

--------------------------------------------------
-- DAY -> NIGHT ANIMATION
--------------------------------------------------

local function playDayNightAnimation()

	--------------------------------------------------
	-- MORNING
	--------------------------------------------------

	timeLabel.Text = "7:12 AM"
	clockText.Text = "7:12 AM"

	task.wait(0.5)

	--------------------------------------------------
	-- LATE MORNING
	--------------------------------------------------

	timeLabel.Text = "10:34 AM"
	clockText.Text = "10:34 AM"

	tween(
		background,
		0.7,
		{
			BackgroundColor3 = COLORS.Day
		}
	)

	tween(
		sun,
		0.7,
		{
			Position = UDim2.fromScale(0.32, 0.25)
		}
	)

	task.wait(0.7)

	--------------------------------------------------
	-- AFTERNOON
	--------------------------------------------------

	timeLabel.Text = "2:18 PM"
	clockText.Text = "2:18 PM"

	tween(
		sun,
		0.7,
		{
			Position = UDim2.fromScale(0.52, 0.14)
		}
	)

	task.wait(0.7)

	--------------------------------------------------
	-- SUNSET
	--------------------------------------------------

	timeLabel.Text = "6:42 PM"
	clockText.Text = "6:42 PM"

	tween(
		background,
		0.8,
		{
			BackgroundColor3 = COLORS.Sunset
		}
	)

	tween(
		sun,
		0.8,
		{
			Position = UDim2.fromScale(0.75, 0.40)
		}
	)

	task.wait(0.8)

	--------------------------------------------------
	-- EVENING
	--------------------------------------------------

	timeLabel.Text = "9:53 PM"
	clockText.Text = "9:53 PM"

	tween(
		background,
		0.8,
		{
			BackgroundColor3 = COLORS.Evening
		}
	)

	tween(
		sun,
		0.8,
		{
			Position = UDim2.fromScale(0.88, 1.12)
		}
	)

	tween(
		moon,
		0.8,
		{
			Position = UDim2.fromScale(0.83, 0.18)
		}
	)

	task.wait(0.8)

	--------------------------------------------------
	-- NIGHT
	--------------------------------------------------

	timeLabel.Text = "10:47 PM"
	clockText.Text = "10:47 PM"

	tween(
		background,
		0.8,
		{
			BackgroundColor3 = COLORS.Night
		}
	)

	timeLabel.TextColor3 = COLORS.Cream

	for _, star in ipairs(stars) do

		tween(
			star,
			0.6,
			{
				TextTransparency = 0
			}
		)

		task.wait(0.04)
	end

	tween(
		zzz,
		0.6,
		{
			TextTransparency = 0
		}
	)

	task.wait(0.8)

	--------------------------------------------------
	-- ALARM
	--------------------------------------------------

	tween(
		zzz,
		0.2,
		{
			TextTransparency = 1
		}
	)

	shakeClock()

	task.wait(0.25)

	revealTitle()
end

--------------------------------------------------
-- BUTTON HOVER
--------------------------------------------------

local normalButtonSize = UDim2.fromScale(0.19, 0.075)
local hoverButtonSize = UDim2.fromScale(0.205, 0.082)

startButton.MouseEnter:Connect(function()

	if startButton.TextTransparency >= 1 then
		return
	end

	tween(
		startButton,
		0.15,
		{
			Size = hoverButtonSize,
			Rotation = -1
		}
	)
end)

startButton.MouseLeave:Connect(function()

	tween(
		startButton,
		0.15,
		{
			Size = normalButtonSize,
			Rotation = 0
		}
	)
end)

--------------------------------------------------
-- START CLICK
--------------------------------------------------

local started = false

startButton.MouseButton1Click:Connect(function()

	if started or startButton.TextTransparency > 0 then
		return
	end

	started = true
	startButton.Active = false

	--------------------------------------------------
	-- BUTTON PRESS
	--------------------------------------------------

	local pressTween = tween(
		startButton,
		0.1,
		{
			Size = UDim2.fromScale(0.17, 0.065)
		}
	)

	pressTween.Completed:Wait()

	tween(
		startButton,
		0.15,
		{
			Size = normalButtonSize
		},
		Enum.EasingStyle.Back
	)

	--------------------------------------------------
	-- FINAL CLOCK SHAKE
	--------------------------------------------------

	shakeClock()

	--------------------------------------------------
	-- FADE OUT
	--------------------------------------------------

	local fade = Instance.new("Frame")

	fade.Name = "Fade"
	fade.Size = UDim2.fromScale(1, 1)

	fade.BackgroundColor3 = Color3.fromRGB(15, 16, 25)
	fade.BackgroundTransparency = 1

	fade.BorderSizePixel = 0
	fade.ZIndex = 100

	fade.Parent = screenGui

	local fadeTween = tween(
		fade,
		0.8,
		{
			BackgroundTransparency = 0
		}
	)

	fadeTween.Completed:Wait()

	--------------------------------------------------
	-- REMOVE START SCREEN
	--------------------------------------------------

	-- Bound the entire handshake, including a server invocation that never returns.
	local startCFrame
	local character
	local finished = false
	local cancelled = false
	local startupError
	task.spawn(function()
		local ok, err = pcall(function()
			local startGame = game:GetService("ReplicatedStorage"):WaitForChild("StartGame", 10)
			assert(startGame, "StartGame is unavailable")
			repeat
				if cancelled then return end
				character = player.Character
				if character and character:GetAttribute("BedroomReady") then
					startCFrame = startGame:InvokeServer()
				end
				if not startCFrame then task.wait(0.1) end
			until startCFrame
		end)
		if not ok then startupError = err end
		finished = true
	end)
	local deadline = os.clock() + 12
	repeat task.wait() until finished or os.clock() >= deadline
	if not finished or startupError or not startCFrame then
		cancelled = true
		warn("Unable to start game: " .. tostring(startupError or "startup timed out"))
		fade:Destroy()
		subtitle.Text = "Room could not load. Please try again."
		startButton.Text = "RETRY"
		startButton.Active = true
		started = false
		return
	end

	local camera = workspace.CurrentCamera
	local humanoid = character:WaitForChild("Humanoid")
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 12
	camera.CameraSubject = humanoid
	camera.CameraType = Enum.CameraType.Custom
	local focus = startCFrame.Position + Vector3.new(0, 2, 0)
	camera.CFrame = CFrame.lookAt(focus - startCFrame.LookVector * 8 + Vector3.new(0, 2, 0), focus + startCFrame.LookVector * 8)
	background.Visible = false
	tween(fade, 0.6, { BackgroundTransparency = 1 }).Completed:Wait()
	screenGui:Destroy()
end)

--------------------------------------------------
-- BEGIN
--------------------------------------------------

task.spawn(playDayNightAnimation)
