-- Builds the local player's dream from the server's config. Parts are local, so
-- every player sees the dream their own bedtime choices produced.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Dream = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Dream"))

local DreamCourse = {}

local calm = {
	platform = Color3.fromRGB(196, 186, 230),
	checkpoint = Color3.fromRGB(170, 210, 200),
	sky = Color3.fromRGB(28, 30, 64),
}
local glare = {
	platform = Color3.fromRGB(245, 245, 250),
	checkpoint = Color3.fromRGB(230, 236, 240),
	sky = Color3.fromRGB(235, 240, 255),
}
local notificationTexts = {
	"Group chat: 47 unread", "Your ex liked a post from 2019", "Mom: call me. not urgent. URGENT",
	"Your streak dies in 3 min!!", "Someone is typing...", "Breaking: a raccoon learned to skateboard",
	"Rate your last 900 videos", "Screen time: 11 hrs (up 40%)", "Reply to Sam from Tuesday",
}
local algorithmTaunts = {
	"Just one more video!", "You up?", "Sleep is for people without Wi-Fi",
	"Autoplay in 3... 2... 1...", "Don't go! I have 47 more reels", "Your screen time is my love language",
}
local sheepGear = {
	Scrolling = {size = Vector3.new(0.9, 1.4, 0.2), offset = CFrame.new(0, 0.9, -3.1), color = Color3.fromRGB(96, 170, 235), material = Enum.Material.Neon},
	Squinting = {size = Vector3.new(1.8, 0.45, 0.3), offset = CFrame.new(0, 1.35, -2.75), color = Color3.fromRGB(20, 20, 24), material = Enum.Material.SmoothPlastic},
	Snacking = {size = Vector3.new(1.4, 0.25, 1.4), offset = CFrame.new(0, -0.1, -3.2), color = Color3.fromRGB(235, 160, 70), material = Enum.Material.SmoothPlastic},
}

-- config: {flags, sheep, notifications?}
-- callbacks: {onGoal = fn(), onBuzz = fn(text), onSheep = fn(count, name)}
function DreamCourse.build(config, callbacks)
	local flags = config.flags or {}
	local palette = if flags.Flicker then glare else calm
	local folder = Instance.new("Folder")
	folder.Name = "LocalDream"
	folder.Parent = workspace
	local alive = true
	local connections = {}
	local tweens = {}

	local function part(name, size, position, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = position
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = folder
		return p
	end

	-- Platforms
	local tiles = {}
	for _, platform in Dream.platforms do
		local size, offset, kind = platform[1], platform[2], platform[3]
		local color = if kind == "Tile" then palette.platform else palette.checkpoint
		local p = part("Dream" .. kind, size, Dream.world(offset), color, if kind == "Tile" then Enum.Material.SmoothPlastic else Enum.Material.Neon)
		if kind ~= "Tile" then
			p.Transparency = 0.15
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 24
			light.Brightness = 1.2
			light.Parent = p
		else
			table.insert(tiles, p)
		end
	end

	-- Sunrise goal: walk into the light to wake up.
	local sun = part("Sunrise", Vector3.new(14, 14, 14), Dream.world(Dream.goal), Color3.fromRGB(255, 196, 120), Enum.Material.Neon)
	sun.Shape = Enum.PartType.Ball
	sun.CanCollide = false
	local sunLight = Instance.new("PointLight")
	sunLight.Color = sun.Color
	sunLight.Range = 60
	sunLight.Brightness = 3
	sunLight.Parent = sun
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(220, 50)
	sign.StudsOffset = Vector3.new(0, 11, 0)
	sign.AlwaysOnTop = true
	sign.Parent = sun
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Text = "Morning"
	signText.TextColor3 = Color3.fromRGB(255, 240, 210)
	signText.TextStrokeTransparency = 0.4
	signText.Font = Enum.Font.GothamBold
	signText.TextScaled = true
	signText.Parent = sign

	-- Calm dreams get drifting stars; they never collide.
	if not flags.Flicker then
		local random = Random.new(7)
		for _ = 1, 45 do
			local star = part("DreamStar", Vector3.new(0.8, 0.8, 0.8), Dream.world(Vector3.new(random:NextNumber(-60, 60), random:NextNumber(-10, 40), random:NextNumber(-300, 20))), Color3.fromRGB(255, 244, 200), Enum.Material.Neon)
			star.Shape = Enum.PartType.Ball
			star.CanCollide = false
			star.CanTouch = false
		end
	end

	-- Late heavy meal: tiles drift up and down.
	if flags.Heavy then
		for index, tile in tiles do
			local tween = TweenService:Create(tile, TweenInfo.new(1.8 + (index % 3) * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, (index % 4) * 0.4), {Position = tile.Position + Vector3.new(0, 2.5, 0)})
			tween:Play()
			table.insert(tweens, tween)
		end
	end

	-- Bright light: tiles blink out on a staggered cycle, with a warning flash.
	if flags.Flicker then
		for index, tile in tiles do
			task.spawn(function()
				task.wait((index % 3) * 1.4)
				while alive do
					task.wait(3)
					for _ = 1, 4 do
						if not alive then return end
						tile.Transparency = 0.5
						task.wait(0.1)
						tile.Transparency = 0
						task.wait(0.1)
					end
					tile.Transparency = 0.85
					tile.CanCollide = false
					task.wait(1.2)
					tile.Transparency = 0
					tile.CanCollide = true
				end
			end)
		end
	end

	-- Scrolling / notifications: glowing cards sweep across the path.
	local cards = {}
	if flags.Notifications then
		local chosen = if flags.ExtraNotifications then {1, 2, 3, 4, 5, 6, 7, 8, 9} else {1, 3, 5, 7, 9}
		for n, tileIndex in chosen do
			local tile = tiles[tileIndex]
			if tile then
				local card = part("Notification", Vector3.new(7, 4, 0.4), tile.Position + Vector3.new(0, 4, 0), Color3.fromRGB(96, 170, 235), Enum.Material.Neon)
				card.CanCollide = false
				card.CanTouch = false
				local gui = Instance.new("SurfaceGui")
				gui.Face = Enum.NormalId.Back -- faces the player walking toward -Z
				gui.CanvasSize = Vector2.new(350, 200)
				gui.Parent = card
				local text = Instance.new("TextLabel")
				text.Size = UDim2.fromScale(1, 1)
				text.BackgroundTransparency = 1
				local texts = if config.notifications and #config.notifications > 0 then config.notifications else notificationTexts
				text.Text = texts[(n - 1) % #texts + 1]
				text.TextColor3 = Color3.new(1, 1, 1)
				text.Font = Enum.Font.GothamBold
				text.TextScaled = true
				text.Parent = gui
				table.insert(cards, {part = card, center = tile.Position, phase = n * 1.3, speed = if flags.ExtraNotifications then 2.6 else 1.9})
			end
		end
	end

	local function bubble(parent, text, height)
		local board = Instance.new("BillboardGui")
		board.Size = UDim2.fromOffset(200, 44)
		board.StudsOffset = Vector3.new(0, height, 0)
		board.MaxDistance = 60
		board.Parent = parent
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		label.BackgroundTransparency = 0.1
		label.TextColor3 = Color3.fromRGB(40, 36, 50)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = text
		label.Parent = board
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = label
		return label
	end

	-- Counting sheep: walk up to a sheep to count it. Distracted sheep can't be counted.
	local sheepList = {}
	local counted = 0
	for index, info in config.sheep or {} do
		local tile = tiles[info.platform - 1]
		if tile then
			local model = Instance.new("Model")
			model.Name = "Sheep_" .. info.name
			local body = part("Wool", Vector3.new(3.4, 3, 4), Vector3.zero, Color3.fromRGB(250, 248, 240), Enum.Material.Fabric)
			body.Shape = Enum.PartType.Ball
			local pieces = {{body, CFrame.new()}}
			table.insert(pieces, {part("Head", Vector3.new(1.5, 1.6, 1.5), Vector3.zero, Color3.fromRGB(60, 56, 62)), CFrame.new(0, 0.8, -2.2)})
			for _, leg in {{-0.9, -0.9}, {0.9, -0.9}, {-0.9, 0.9}, {0.9, 0.9}} do
				table.insert(pieces, {part("Leg", Vector3.new(0.45, 1.4, 0.45), Vector3.zero, Color3.fromRGB(60, 56, 62)), CFrame.new(leg[1], -1.6, leg[2])})
			end
			local gear = info.kind and sheepGear[info.kind]
			if gear then
				table.insert(pieces, {part(info.kind, gear.size, Vector3.zero, gear.color, gear.material), gear.offset})
			end
			for _, piece in pieces do
				piece[1].CanCollide = false
				piece[1].CanTouch = false
				piece[1].Parent = model
			end
			model.PrimaryPart = body
			model.Parent = folder
			bubble(body, if info.kind then info.name .. ": " .. info.label else info.name, 3.2)
			table.insert(sheepList, {model = model, pieces = pieces, tile = tile, info = info, side = if index % 2 == 0 then -3 else 3, phase = index * 0.7})
		end
	end

	-- Kept scrolling: The Algorithm, a giant phone with googly eyes, follows you.
	local algorithm
	if flags.Algorithm then
		local screen = part("TheAlgorithm", Vector3.new(7, 12, 1), Dream.world(Vector3.new(0, 9, 30)), Color3.fromRGB(25, 25, 32), Enum.Material.SmoothPlastic)
		screen.CanCollide = false
		screen.CanTouch = false
		local display = Instance.new("SurfaceGui")
		display.Face = Enum.NormalId.Front
		display.CanvasSize = Vector2.new(280, 480)
		display.Parent = screen
		local feed = Instance.new("TextLabel")
		feed.Size = UDim2.fromScale(1, 1)
		feed.BackgroundColor3 = Color3.fromRGB(255, 70, 110)
		feed.TextColor3 = Color3.new(1, 1, 1)
		feed.Font = Enum.Font.GothamBlack
		feed.TextScaled = true
		feed.Text = "FOR\nYOU\n▶"
		feed.Parent = display
		local eyes = {}
		for _, x in {-1.7, 1.7} do
			local eye = part("GooglyEye", Vector3.new(2.4, 2.4, 2.4), screen.Position, Color3.new(1, 1, 1))
			eye.Shape = Enum.PartType.Ball
			eye.CanCollide = false
			eye.CanTouch = false
			local pupil = part("Pupil", Vector3.new(1.1, 1.1, 1.1), screen.Position, Color3.new(0, 0, 0))
			pupil.Shape = Enum.PartType.Ball
			pupil.CanCollide = false
			pupil.CanTouch = false
			table.insert(eyes, {eye = eye, pupil = pupil, x = x})
		end
		algorithm = {screen = screen, eyes = eyes, taunt = bubble(screen, algorithmTaunts[1], 8.5), tauntIndex = 1, nextTaunt = 3, frozenUntil = 0, startAt = 4}
	end
	local saved = {
		ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
	}
	local effects = {}
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "DreamColor"
	table.insert(effects, correction)
	if flags.Flicker then
		Lighting.ClockTime = 12
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(200, 200, 210)
		Lighting.OutdoorAmbient = Color3.fromRGB(220, 220, 230)
		Lighting.FogColor = palette.sky
		Lighting.FogEnd = 450
		correction.Brightness = 0.12
		correction.Contrast = 0.3
		correction.Saturation = -0.4
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "DreamGlare"
		bloom.Intensity = 1.4
		bloom.Size = 40
		bloom.Threshold = 0.8
		table.insert(effects, bloom)
	else
		Lighting.ClockTime = 0
		Lighting.Brightness = 1
		Lighting.Ambient = Color3.fromRGB(90, 85, 130)
		Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 120)
		Lighting.FogColor = palette.sky
		Lighting.FogEnd = 700
		correction.TintColor = Color3.fromRGB(215, 210, 255)
		correction.Saturation = 0.1
	end
	for _, effect in effects do effect.Parent = Lighting end

	-- Sluggish movement after a heavy meal.
	local player = Players.LocalPlayer
	local function humanoid()
		return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	end
	local savedSpeed = humanoid() and humanoid().WalkSpeed or 16
	local baseSpeed = if flags.Heavy then 12 else savedSpeed
	if humanoid() then humanoid().WalkSpeed = baseSpeed end

	-- Per-frame: move cards, check knockback, check the goal.
	local clock = 0
	local lastBuzz = 0
	local reachedGoal = false
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		clock += dt
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		for _, card in cards do
			local x = math.sin(clock * card.speed + card.phase) * 8
			card.part.Position = card.center + Vector3.new(x, 4, 0)
			if root and clock - lastBuzz > 1 then
				local delta = root.Position - card.part.Position
				if math.abs(delta.X) < 4.5 and math.abs(delta.Y) < 4.5 and math.abs(delta.Z) < 2.5 then
					lastBuzz = clock
					root.AssemblyLinearVelocity = Vector3.new(0, 30, 32)
					if callbacks.onBuzz then callbacks.onBuzz("Bzzt! A notification pulled you back.") end
				end
			end
		end
		-- Sheep ride along on their tiles (tiles can drift) and hop in place.
		for _, sheep in sheepList do
			if sheep.model.Parent then
				local hop = math.abs(math.sin(clock * 3 + sheep.phase)) * 0.8
				local base = CFrame.lookAt(sheep.tile.Position, sheep.tile.Position + Vector3.new(0, 0, 1)) * CFrame.new(sheep.side, sheep.tile.Size.Y / 2 + 2.4 + hop, 0)
				for _, piece in sheep.pieces do piece[1].CFrame = base * piece[2] end
				if root and not sheep.info.kind and not sheep.counted and (root.Position - base.Position).Magnitude < 6 then
					sheep.counted = true
					counted += 1
					if callbacks.onSheep then callbacks.onSheep(counted, sheep.info.name) end
					local model = sheep.model
					task.delay(0.6, function() model:Destroy() end)
					sheep.pieces = {}
				end
			end
		end
		-- The Algorithm drifts toward you; if it catches you, you're stuck watching a video.
		if algorithm and root and clock > algorithm.startAt then
			local screen = algorithm.screen
			local target = root.Position + Vector3.new(0, 5, 0)
			local toTarget = target - screen.Position
			local distance = toTarget.Magnitude
			local position = screen.Position
			if distance > 0.1 then position += toTarget.Unit * math.min(distance, 9 * dt) end
			position += Vector3.new(0, math.sin(clock * 2) * 0.03, 0)
			-- Direct vertical alignment has no horizontal facing direction. Avoid a
			-- degenerate lookAt CFrame, which can send the phone outside the level.
			local facing = Vector3.new(root.Position.X - position.X, 0, root.Position.Z - position.Z)
			if facing.Magnitude < 0.01 then facing = Vector3.new(0, 0, 1) end
			screen.CFrame = CFrame.lookAt(position, position + facing)
			for _, eye in algorithm.eyes do
				eye.eye.CFrame = screen.CFrame * CFrame.new(eye.x, 3.5, -0.9)
				local wobble = Vector3.new(math.sin(clock * 7 + eye.x) * 0.4, math.cos(clock * 5 + eye.x) * 0.4, -0.9)
				eye.pupil.CFrame = eye.eye.CFrame * CFrame.new(wobble)
			end
			if clock >= algorithm.nextTaunt then
				algorithm.tauntIndex = algorithm.tauntIndex % #algorithmTaunts + 1
				algorithm.taunt.Text = algorithmTaunts[algorithm.tauntIndex]
				algorithm.nextTaunt = clock + 3
			end
			local human = humanoid()
			if distance < 6 and clock > algorithm.frozenUntil + 2 and human then
				algorithm.frozenUntil = clock + 2
				algorithm.taunt.Text = "Caught you! Enjoy this 45-minute video essay."
				algorithm.nextTaunt = clock + 3
				human.WalkSpeed = 0
				if callbacks.onBuzz then callbacks.onBuzz("The Algorithm caught you. Watching a video essay...") end
				-- Knock it back so you can escape once you can move again.
				screen.Position = screen.Position + Vector3.new(0, 0, 30)
			end
			if human and human.WalkSpeed == 0 and clock > algorithm.frozenUntil then human.WalkSpeed = baseSpeed end
		end
		sun.CFrame = CFrame.new(sun.Position) * CFrame.Angles(0, clock * 0.3, 0)
		if root and not reachedGoal and (root.Position - sun.Position).Magnitude <= Dream.goalRadius then
			reachedGoal = true
			if callbacks.onGoal then callbacks.onGoal() end
		end
	end))

	local controller = {}
	-- Allows the goal to trigger again if the server rejected the first attempt.
	function controller.resetGoal()
		reachedGoal = false
	end
	function controller.sheepCounted()
		return counted
	end
	function controller.destroy()
		if not alive then return end
		alive = false
		for _, connection in connections do connection:Disconnect() end
		for _, tween in tweens do tween:Cancel() end
		for _, effect in effects do effect:Destroy() end
		for property, value in saved do Lighting[property] = value end
		if humanoid() then humanoid().WalkSpeed = savedSpeed end
		folder:Destroy()
	end
	return controller
end

return DreamCourse
