-- Bedtime Rush: a 60-second arcade round in room 101. Healthy habits take
-- effort (catch the runaway phone, smack the big light, dodge midnight pizza);
-- unhealthy ones happen by default. Choices are still saved on the server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Rush = {}
Rush.duration = 60

-- Room 101 floor area (x/z) and the height pickups float at.
local ROOM_MIN = Vector3.new(-106, 0, -184)
local ROOM_MAX = Vector3.new(-62, 0, -138)
local FLOAT_Y = 16.2

local phoneTaunts = {
	"catch me if u can", "one more reel!!", "ur streak is dying", "*buzz buzz*",
	"u can't sleep without me", "47 unread lol",
}
local sounds = {
	buzz = "rbxasset://sounds/electronicpingshort.wav",
	click = "rbxasset://sounds/button.wav",
	oof = "rbxasset://sounds/uuhhh.mp3",
	jump = "rbxasset://sounds/action_jump.mp3",
}

local cream = Color3.fromRGB(247, 233, 212)
local ink = Color3.fromRGB(38, 34, 52)

-- True if solid furniture occupies the space around a point.
local function blocked(point, ignore)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	for _, part in workspace:GetPartBoundsInRadius(point, 1.6, params) do
		if part.CanCollide and part.Transparency < 1 then return true end
	end
	return false
end

-- A random open spot in the room (furniture can be rearranged, so check).
local function randomPoint(random, ignore)
	local point
	for _ = 1, 20 do
		point = Vector3.new(random:NextNumber(ROOM_MIN.X, ROOM_MAX.X), FLOAT_Y, random:NextNumber(ROOM_MIN.Z, ROOM_MAX.Z))
		if not ignore or not blocked(point, ignore) then return point end
	end
	return point
end

local function clampToRoom(point)
	return Vector3.new(math.clamp(point.X, ROOM_MIN.X, ROOM_MAX.X), FLOAT_Y, math.clamp(point.Z, ROOM_MIN.Z, ROOM_MAX.Z))
end

-- ctx: {request = fn(key, option), apply = fn(key, option), onFinished = fn(reason)}
function Rush.start(ctx)
	local player = Players.LocalPlayer
	local random = Random.new()
	local alive = true
	local connections = {}
	local folder = Instance.new("Folder")
	folder.Name = "BedtimeRushObjects"
	folder.Parent = workspace
	local ignore = {folder}
	if player.Character then table.insert(ignore, player.Character) end

	local function play(name, volume)
		local sound = Instance.new("Sound")
		sound.SoundId = sounds[name]
		sound.Volume = volume or 0.6
		sound.Parent = SoundService
		sound:Play()
		task.delay(3, function() sound:Destroy() end)
	end

	-- UI --------------------------------------------------------------
	local gui = Instance.new("ScreenGui")
	gui.Name = "BedtimeRushHUD"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")
	local function corner(object, radius)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius)
		c.Parent = object
	end
	local function text(parent, value, position, size, textSize, font)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Text = value
		t.TextColor3 = cream
		t.Font = font or Enum.Font.GothamBold
		t.TextSize = textSize
		t.TextWrapped = true
		t.Position = position
		t.Size = size
		t.Parent = parent
		return t
	end

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 10)
	bar.Size = UDim2.fromOffset(420, 58)
	bar.BackgroundColor3 = ink
	bar.BackgroundTransparency = 0.1
	bar.Parent = gui
	corner(bar, 14)
	local clockText = text(bar, "10:59 PM • 60s until lights out", UDim2.fromOffset(0, 4), UDim2.new(1, 0, 0, 24), 18)
	local track = Instance.new("Frame")
	track.Position = UDim2.new(0, 14, 0, 34)
	track.Size = UDim2.new(1, -28, 0, 12)
	track.BackgroundColor3 = Color3.fromRGB(80, 72, 95)
	track.BorderSizePixel = 0
	track.Parent = bar
	corner(track, 6)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(150, 205, 170)
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 6)

	local goals = Instance.new("Frame")
	goals.Position = UDim2.new(0, 16, 0, 80)
	goals.Size = UDim2.fromOffset(300, 150)
	goals.BackgroundColor3 = ink
	goals.BackgroundTransparency = 0.1
	goals.Parent = gui
	corner(goals, 14)
	text(goals, "BEDTIME RUSH", UDim2.fromOffset(0, 6), UDim2.new(1, 0, 0, 22), 18, Enum.Font.GothamBlack)
	local objectives = {}
	local function objective(key, label, y)
		local line = text(goals, "○  " .. label, UDim2.new(0, 14, 0, y), UDim2.new(1, -20, 0, 24), 15, Enum.Font.Gotham)
		line.TextXAlignment = Enum.TextXAlignment.Left
		objectives[key] = {line = line, label = label}
	end
	objective("Phone", "Catch your runaway phone", 32)
	objective("Lighting", "Smack the big light off", 60)
	objective("Food", "Dodge the midnight pizza", 88)
	objective("Bed", "Get to bed (early = bonus)", 116)
	local function mark(key, state, suffix)
		local o = objectives[key]
		o.line.Text = (if state == "done" then "✓  " elseif state == "failed" then "✗  " else "○  ") .. o.label .. (suffix or "")
		o.line.TextColor3 = if state == "done" then Color3.fromRGB(170, 230, 180) elseif state == "failed" then Color3.fromRGB(255, 160, 140) else cream
	end
	mark("Food", "done")

	local big = text(gui, "", UDim2.fromScale(0.1, 0.3), UDim2.fromScale(0.8, 0.2), 64, Enum.Font.GothamBlack)
	big.TextStrokeTransparency = 0.2
	big.TextStrokeColor3 = ink
	local popCount = 0
	-- Big bouncy text in the middle of the screen.
	local function pop(message, color, hold)
		popCount += 1
		local mine = popCount
		big.Text = message
		big.TextColor3 = color or cream
		big.TextTransparency = 0
		big.TextStrokeTransparency = 0.2
		big.TextSize = 20
		TweenService:Create(big, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 52}):Play()
		task.delay(hold or 1.4, function()
			if mine == popCount then
				TweenService:Create(big, TweenInfo.new(0.4), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
			end
		end)
	end

	local function root()
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end
	local function humanoid()
		local character = player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end
	local function shake()
		local human = humanoid()
		if not human then return end
		task.spawn(function()
			for _ = 1, 8 do
				human.CameraOffset = Vector3.new(random:NextNumber(-0.5, 0.5), random:NextNumber(-0.5, 0.5), 0)
				task.wait(0.03)
			end
			human.CameraOffset = Vector3.zero
		end)
	end

	local function bubble(parent, value, color)
		local board = Instance.new("BillboardGui")
		board.Size = UDim2.fromOffset(170, 40)
		board.StudsOffset = Vector3.new(0, 2.4, 0)
		board.AlwaysOnTop = true
		board.Parent = parent
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = color
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = value
		label.Parent = board
		corner(label, 10)
		return label
	end

	local function object(name, size, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.Neon
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CastShadow = false
		if shape then p.Shape = shape end
		p.Parent = folder
		return p
	end

	-- The unhealthy defaults: phone out, big light on.
	ctx.apply("Phone", 2)
	ctx.apply("Lighting", 2)
	ctx.apply("Food", 1)

	-- Runaway phone ---------------------------------------------------
	local phone = object("RunawayPhone", Vector3.new(1.3, 2.3, 0.3), Color3.fromRGB(96, 170, 235))
	phone.Position = randomPoint(random, ignore)
	local phoneLabel = bubble(phone, phoneTaunts[1], Color3.fromRGB(60, 120, 220))
	local phoneTarget = phone.Position
	local phoneCaught = false
	local nextTaunt = 0

	-- Big light bulb ---------------------------------------------------
	local bulb = object("BigLight", Vector3.new(2.2, 2.2, 2.2), Color3.fromRGB(255, 236, 140), Enum.PartType.Ball)
	bulb.Position = randomPoint(random, ignore)
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 2
	glow.Color = bulb.Color
	glow.Parent = bulb
	bubble(bulb, "BIG LIGHT: smack me", Color3.fromRGB(200, 150, 30))
	local roommateAt = nil
	local roommateDone = false

	-- Pizza ------------------------------------------------------------
	local pizzas = {}
	local stuffed = false
	local nextPizza = 3

	-- Round state -------------------------------------------------------
	local started = false
	local startTime = 0
	local finished = false
	local function secondsLeft()
		if not started then return Rush.duration end
		return math.max(0, Rush.duration - (os.clock() - startTime))
	end
	local function finish(reason)
		if finished then return end
		finished = true
		alive = false
		if reason == "timeout" then
			pop("11:00 PM! You passed out on the floor.", Color3.fromRGB(255, 190, 150), 2)
		else
			mark("Bed", "done", string.format(" (%ds early!)", math.floor(secondsLeft())))
			pop("Lights out! Sweet dreams...", Color3.fromRGB(190, 210, 255), 2)
		end
		task.delay(1.2, function() ctx.onFinished(reason) end)
	end

	local function save(key, option)
		task.spawn(function() ctx.request(key, option) end)
		ctx.apply(key, option)
	end

	local function catchPhone()
		phoneCaught = true
		save("Phone", 1)
		mark("Phone", "done")
		play("click")
		pop("PHONE DOCKED! 📵", Color3.fromRGB(170, 230, 180))
		phone:Destroy()
	end

	local function smackLight()
		save("Lighting", 1)
		mark("Lighting", "done")
		play("click")
		pop("BIG LIGHT: DEFEATED ✨", Color3.fromRGB(255, 236, 160))
		bulb.Parent = nil
		if not roommateDone then roommateAt = os.clock() + random:NextNumber(8, 14) end
	end

	local function roommate()
		roommateDone = true
		save("Lighting", 2)
		mark("Lighting", "failed", " (roommate!)")
		play("oof", 0.5)
		pop("Your roommate turned the big light back on 🙄", Color3.fromRGB(255, 220, 140), 2.2)
		bulb.Position = randomPoint(random, ignore)
		bulb.Parent = folder
	end

	local function pizzaHit()
		shake()
		play("oof", 0.7)
		if not stuffed then
			stuffed = true
			save("Food", 2)
			mark("Food", "failed", " (pizza'd)")
			pop("MIDNIGHT PIZZA'D! 🍕", Color3.fromRGB(255, 180, 110))
		else
			pop("*burp*", Color3.fromRGB(255, 200, 150), 0.8)
		end
	end

	local function spawnPizza(from)
		local slice = object("MidnightPizza", Vector3.new(2.2, 0.4, 2.2), Color3.fromRGB(245, 165, 70))
		slice.Position = from
		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.fromOffset(40, 40)
		tag.AlwaysOnTop = true
		tag.Parent = slice
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.fromScale(1, 1)
		icon.BackgroundTransparency = 1
		icon.Text = "🍕"
		icon.TextScaled = true
		icon.Parent = tag
		table.insert(pizzas, {part = slice, velocity = Vector3.zero, born = os.clock()})
		return pizzas[#pizzas]
	end

	-- Main loop -------------------------------------------------------
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not started or finished then return end
		local now = os.clock()
		local left = secondsLeft()
		local r = root()

		-- Timer bar: calm green to panic red.
		local fraction = left / Rush.duration
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.BackgroundColor3 = Color3.fromRGB(150, 205, 170):Lerp(Color3.fromRGB(235, 90, 90), 1 - fraction)
		clockText.Text = string.format("10:%02d PM • %ds until lights out", math.min(59, 60 - math.ceil(left)), math.ceil(left))
		if left <= 0 then finish("timeout"); return end

		-- Phone flees when you get close, but its battery runs down.
		if not phoneCaught and phone.Parent then
			local elapsed = now - startTime
			local speed = if elapsed > 30 then 6 else 10
			if r then
				local away = Vector3.new(phone.Position.X - r.Position.X, 0, phone.Position.Z - r.Position.Z)
				if away.Magnitude < 15 and (phoneTarget - phone.Position).Magnitude < 2 then
					local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
					local candidate = clampToRoom(phone.Position + dir * 10 + Vector3.new(random:NextNumber(-4, 4), 0, random:NextNumber(-4, 4)))
					-- Cornered? Dash somewhere random instead.
					if (candidate - phone.Position).Magnitude < 4 or blocked(candidate, ignore) then candidate = randomPoint(random, ignore) end
					phoneTarget = candidate
				end
			end
			local step = phoneTarget - phone.Position
			local base = if step.Magnitude > 0.05 then phone.Position + step.Unit * math.min(step.Magnitude, speed * dt) else phone.Position
			phone.CFrame = CFrame.new(Vector3.new(base.X, FLOAT_Y + math.abs(math.sin(now * 6)) * 0.8, base.Z)) * CFrame.Angles(0, now * 3, math.sin(now * 20) * 0.15)
			if now >= nextTaunt then
				nextTaunt = now + 2.5
				phoneLabel.Text = if elapsed > 30 then "battery 3%... so tired" else phoneTaunts[random:NextInteger(1, #phoneTaunts)]
				if elapsed <= 30 then play("buzz", 0.25) end
			end
			if r and (r.Position - phone.Position).Magnitude < 4.5 then catchPhone() end
		end

		-- Big light: smack it; your roommate may turn it back on once.
		if bulb.Parent then
			bulb.CFrame = CFrame.new(bulb.Position.X, FLOAT_Y + 0.8 + math.sin(now * 3) * 0.6, bulb.Position.Z)
			if r and (r.Position - bulb.Position).Magnitude < 4.5 then smackLight() end
		elseif roommateAt and now >= roommateAt and left > 8 then
			roommateAt = nil
			roommate()
		end

		-- Pizza: slices launch from the walls and fly at where you are now.
		local elapsed = now - startTime
		if r and elapsed >= nextPizza then
			nextPizza = elapsed + math.max(1.3, 3 - elapsed / 30)
			local edge = random:NextInteger(1, 4)
			local from = if edge == 1 then Vector3.new(ROOM_MIN.X, FLOAT_Y, random:NextNumber(ROOM_MIN.Z, ROOM_MAX.Z))
				elseif edge == 2 then Vector3.new(ROOM_MAX.X, FLOAT_Y, random:NextNumber(ROOM_MIN.Z, ROOM_MAX.Z))
				elseif edge == 3 then Vector3.new(random:NextNumber(ROOM_MIN.X, ROOM_MAX.X), FLOAT_Y, ROOM_MIN.Z)
				else Vector3.new(random:NextNumber(ROOM_MIN.X, ROOM_MAX.X), FLOAT_Y, ROOM_MAX.Z)
			local pizza = spawnPizza(from)
			local aim = Vector3.new(r.Position.X, FLOAT_Y, r.Position.Z) - from
			pizza.velocity = if aim.Magnitude > 0.1 then aim.Unit * (16 + elapsed / 6) else Vector3.zero
		end
		for index = #pizzas, 1, -1 do
			local pizza = pizzas[index]
			local position = pizza.part.Position + pizza.velocity * dt
			pizza.part.CFrame = CFrame.new(position) * CFrame.Angles(0, now * 8, 0)
			local hit = r and (r.Position - position).Magnitude < 3.2
			if hit then pizzaHit() end
			if hit or now - pizza.born > 5 then
				pizza.part:Destroy()
				table.remove(pizzas, index)
			end
		end
	end))

	-- Countdown, then go.
	task.spawn(function()
		for _, value in {"3", "2", "1"} do
			if not alive then return end
			pop(value, cream, 0.7)
			play("click", 0.4)
			task.wait(0.8)
		end
		if not alive then return end
		pop("BEDTIME RUSH!", Color3.fromRGB(255, 210, 120), 1.2)
		play("jump", 0.6)
		task.spawn(function() ctx.request("RushStart") end)
		started = true
		startTime = os.clock()
	end)

	local controller = {}
	controller.secondsLeft = secondsLeft
	function controller.goToBed()
		finish("bed")
	end
	function controller.stop()
		alive = false
		finished = true
		for _, connection in connections do connection:Disconnect() end
		folder:Destroy()
		gui:Destroy()
		local human = humanoid()
		if human then human.CameraOffset = Vector3.zero end
	end
	return controller
end

return Rush
