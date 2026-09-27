-- Sleep-deprivation effects layered over the dream. The worse tonight's bedtime
-- choices (the server's DreamSeverity attribute, 0-3), the stranger it gets:
-- pulsing blur, drained colors, tunnel vision, microsleep blinks, whispers,
-- and sleep-paralysis shadow figures that vanish when you look at them.
-- These mirror real effects of sleep deprivation; nothing here affects scoring.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local whispers = {
	"why is it 3 AM?", "just five more minutes...", "did you reply to them?",
	"you should be asleep", "is someone there?", "your alarm is in 4 hours",
	"one more video...", "what was that?",
}

-- Per-severity tuning: {base blur, blur pulse, vignette darkness, seconds between blinks}
local levels = {
	[0] = {0, 0, 0.8, nil},
	[1] = {0, 0, 0.6, 14},
	[2] = {0, 1, 0.45, 9},
	[3] = {0.5, 1.5, 0.3, 6}, -- max blur 14 keeps the course playable
}

local function start(severity, flags)
	local level = levels[math.clamp(severity, 0, 3)]
	local random = Random.new()
	local alive = true
	local connections = {}
	local camera = workspace.CurrentCamera
	local savedFov = camera.FieldOfView
	local savedExposure = Lighting.ExposureCompensation

	local blur = Instance.new("BlurEffect")
	blur.Name = "SleepDebtBlur"
	blur.Size = 0
	blur.Parent = Lighting
	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "SleepDebtColor"
	color.Parent = Lighting
	-- The bright-light dream washes out to white; pull the exposure down so it's glaring, not blank.
	if string.find(flags, "Flicker") then
		Lighting.ExposureCompensation = -1.4; Lighting.FogEnd = 1500; local glare = Lighting:FindFirstChild("DreamGlare"); if glare then glare.Intensity = 0.35 end
		color.Contrast = 0.25
	end

	-- Screen overlays (below the fade-to-black, which uses DisplayOrder 20).
	local gui = Instance.new("ScreenGui")
	gui.Name = "SleepDebtOverlay"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 15
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Tunnel vision: dark gradients creeping in from each edge.
	local edges = {}
	for _, edge in {
		{UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3), 90},
		{UDim2.fromScale(0, 0.7), UDim2.fromScale(1, 0.3), -90},
		{UDim2.fromScale(0, 0), UDim2.fromScale(0.25, 1), 0},
		{UDim2.fromScale(0.75, 0), UDim2.fromScale(0.25, 1), 180},
	} do
		local frame = Instance.new("Frame")
		frame.Position = edge[1]
		frame.Size = edge[2]
		frame.BackgroundColor3 = Color3.fromRGB(8, 6, 18)
		frame.BorderSizePixel = 0
		frame.Parent = gui
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = edge[3]
		gradient.Transparency = NumberSequence.new(level[3], 1)
		gradient.Parent = frame
		table.insert(edges, gradient)
	end

	-- Eyelids for microsleep blinks.
	local lids = {}
	for _, top in {true, false} do
		local lid = Instance.new("Frame")
		lid.AnchorPoint = Vector2.new(0, if top then 0 else 1)
		lid.Position = UDim2.fromScale(0, if top then 0 else 1)
		lid.Size = UDim2.fromScale(1, 0)
		lid.BackgroundColor3 = Color3.new(0, 0, 0)
		lid.BorderSizePixel = 0
		lid.ZIndex = 5
		lid.Parent = gui
		table.insert(lids, lid)
	end
	local lidNote = Instance.new("TextLabel")
	lidNote.Size = UDim2.fromScale(1, 0.1)
	lidNote.Position = UDim2.fromScale(0, 0.45)
	lidNote.BackgroundTransparency = 1
	lidNote.TextColor3 = Color3.fromRGB(200, 190, 230)
	lidNote.Font = Enum.Font.GothamBold
	lidNote.TextSize = 22
	lidNote.TextTransparency = 1
	lidNote.Text = "microsleep"
	lidNote.ZIndex = 6
	lidNote.Parent = gui

	local function blink(long)
		local close = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		for _, lid in lids do TweenService:Create(lid, close, {Size = UDim2.fromScale(1, 0.52)}):Play() end
		task.wait(0.25)
		if long then TweenService:Create(lidNote, TweenInfo.new(0.2), {TextTransparency = 0.2}):Play() end
		task.wait(if long then 1.1 else 0.25 + severity * 0.1)
		TweenService:Create(lidNote, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		local open = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, lid in lids do TweenService:Create(lid, open, {Size = UDim2.fromScale(1, 0)}):Play() end
	end

	-- Intrusive-thought whispers drifting across the screen.
	local function whisper()
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(360, 40)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(random:NextNumber(0.2, 0.8), random:NextNumber(0.25, 0.8))
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 22
		label.TextColor3 = Color3.fromRGB(215, 205, 240)
		label.TextStrokeTransparency = 0.6
		label.TextTransparency = 1
		label.Text = whispers[random:NextInteger(1, #whispers)]
		label.Parent = gui
		TweenService:Create(label, TweenInfo.new(1.2), {TextTransparency = 0.35}):Play()
		TweenService:Create(label, TweenInfo.new(4, Enum.EasingStyle.Linear), {Position = label.Position + UDim2.fromOffset(random:NextNumber(-40, 40), -30)}):Play()
		task.delay(2.8, function()
			TweenService:Create(label, TweenInfo.new(1.2), {TextTransparency = 1}):Play()
			task.delay(1.3, function() label:Destroy() end)
		end)
	end

	-- Sleep-paralysis shadow figures: appear in your peripheral vision and
	-- vanish when you look straight at them.
	local shadowFolder = Instance.new("Folder")
	shadowFolder.Name = "SleepDebtShadows"
	shadowFolder.Parent = workspace
	local shadows = {}
	local function shadowFigure()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local look = camera.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 0.1 then return end
		-- 70-100 degrees off to one side of where you're looking.
		local angle = math.rad(random:NextNumber(70, 100)) * (if random:NextInteger(0, 1) == 0 then 1 else -1)
		local direction = CFrame.Angles(0, angle, 0):VectorToWorldSpace(flat.Unit)
		local base = root.Position + direction * random:NextNumber(18, 28)
		local figure = Instance.new("Model")
		figure.Name = "ShadowFigure"
		local parts = {}
		for _, piece in {
			{Vector3.new(2.2, 6, 1), Vector3.new(0, 0, 0), Enum.PartType.Block},
			{Vector3.new(1.8, 1.8, 1.8), Vector3.new(0, 4, 0), Enum.PartType.Ball},
			{Vector3.new(0.5, 5.5, 0.5), Vector3.new(-1.5, -0.5, 0), Enum.PartType.Block},
			{Vector3.new(0.5, 5.5, 0.5), Vector3.new(1.5, -0.5, 0), Enum.PartType.Block},
		} do
			local part = Instance.new("Part")
			part.Size = piece[1]
			part.Shape = piece[3]
			part.Color = Color3.fromRGB(6, 4, 12)
			part.Material = Enum.Material.SmoothPlastic
			part.Transparency = 1
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CastShadow = false
			part.CFrame = CFrame.lookAt(base, Vector3.new(root.Position.X, base.Y, root.Position.Z)) * CFrame.new(piece[2])
			part.Parent = figure
			table.insert(parts, part)
			TweenService:Create(part, TweenInfo.new(1.5), {Transparency = 0.15}):Play()
		end
		figure.Parent = shadowFolder
		table.insert(shadows, {model = figure, parts = parts, center = base, born = os.clock()})
	end
	local function vanish(shadow)
		shadow.vanishing = true
		for _, part in shadow.parts do TweenService:Create(part, TweenInfo.new(0.25), {Transparency = 1}):Play() end
		task.delay(0.3, function() shadow.model:Destroy() end)
	end

	-- Per-frame: pulsing blur, drained colors, breathing field of view, shadows.
	local clock = 0
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		clock += dt
		local pulse = (math.sin(clock * 0.9) + 1) / 2
		blur.Size = level[1] + level[2] * pulse
		color.Saturation = -0.12 * severity - 0.1 * pulse * severity
		color.TintColor = Color3.fromRGB(255, 255, 255):Lerp(Color3.fromRGB(200, 190, 255), 0.25 + 0.1 * severity)
		camera.FieldOfView = savedFov + math.sin(clock * 0.6) * (2 + severity * 3)
		for _, gradient in edges do
			gradient.Transparency = NumberSequence.new(math.clamp(level[3] - 0.15 * pulse * severity, 0, 1), 1)
		end
		local look = camera.CFrame.LookVector
		for index = #shadows, 1, -1 do
			local shadow = shadows[index]
			local toShadow = shadow.center - camera.CFrame.Position
			local seen = toShadow.Magnitude > 0 and look:Dot(toShadow.Unit) > math.cos(math.rad(22))
			if not shadow.vanishing and (seen or os.clock() - shadow.born > 7) then vanish(shadow) end
			if shadow.vanishing then table.remove(shadows, index) end
		end
	end))

	-- Timed events: microsleeps, whispers, shadow figures.
	if level[4] then
		task.spawn(function()
			while alive do
				task.wait(level[4] + random:NextNumber(-2, 2))
				if not alive then break end
				blink(severity >= 3 and random:NextNumber() < 0.35)
			end
		end)
		task.spawn(function()
			while alive do
				task.wait(random:NextNumber(5, 9) - severity)
				if alive then whisper() end
			end
		end)
	end
	if severity >= 2 then
		task.spawn(function()
			task.wait(6)
			while alive do
				shadowFigure()
				task.wait(random:NextNumber(10, 14) - (severity - 2) * 3)
			end
		end)
	end

	return function()
		alive = false
		for _, connection in connections do connection:Disconnect() end
		blur:Destroy()
		color:Destroy()
		gui:Destroy()
		shadowFolder:Destroy()
		camera.FieldOfView = savedFov
		Lighting.ExposureCompensation = savedExposure
	end
end

local stop
local function update()
	if stop then stop(); stop = nil end
	local severity = player:GetAttribute("DreamSeverity")
	if type(severity) == "number" then
		stop = start(severity, player:GetAttribute("DreamFlags") or "")
	end
end
player:GetAttributeChangedSignal("DreamSeverity"):Connect(update)
update()
