-- Bedtime Rush: a 60-second arcade round in room 101. Healthy habits take
-- effort (catch the runaway phone, smack the big light, shut the midnight fridge);
-- unhealthy ones happen by default. Choices are still saved on the server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Rush = {}
Rush.duration = 60

-- Room 101 floor area (x/z) and the height pickups float at.
local ROOM_MIN = Vector3.new(-106, 0, -184)
local ROOM_MAX = Vector3.new(-62, 0, -138)
local FLOAT_Y = 16.2

local phoneTaunts = {
	"catch me if u can", "one more reel!!", "ur streak is dying", "*buzz buzz*",
	"u can't sleep without me", "47 unread lol", "the group chat needs me", "I have commitment issues",
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
	-- A deterministic fallback never knowingly spawns an objective in furniture.
	for x = ROOM_MIN.X + 2, ROOM_MAX.X - 2, 4 do
		for z = ROOM_MIN.Z + 2, ROOM_MAX.Z - 2, 4 do
			local candidate = Vector3.new(x, FLOAT_Y, z)
			if not blocked(candidate, ignore or {}) then return candidate end
		end
	end
	return nil
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
		sound.Name = "RushSound"
		sound.Parent = folder
		sound:Play()
		task.delay(3, function() sound:Destroy() end)
	end

	-- Isolated UI/room presentation; existing game rules remain here.
	local presentation = require(script.Parent.RushPresentation).new(player)
		local pop = presentation.pop
	local mark = presentation.mark
	local function corner(object, radius)
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, radius) c.Parent = object
	end
	mark("Food", "pending")

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
		p.Material = Enum.Material.SmoothPlastic
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
	presentation.lightState(2)
	ctx.apply("Food", 1)

	-- Runaway phone ---------------------------------------------------
	local phone = object("RunawayPhone", Vector3.new(1.3, 2.3, 0.3), Color3.fromRGB(96, 170, 235))
	phone.Position = randomPoint(random, ignore) or Vector3.new(-94, FLOAT_Y, -145)
	local phoneLabel = bubble(phone, phoneTaunts[1], Color3.fromRGB(60, 120, 220))
	local screen = Instance.new("SurfaceGui")
	screen.Face = Enum.NormalId.Front; screen.CanvasSize = Vector2.new(180,300); screen.Parent = phone
	local feed = Instance.new("Frame")
	feed.Size = UDim2.fromScale(.86,.9); feed.Position = UDim2.fromScale(.07,.05)
	feed.BackgroundColor3 = Color3.fromRGB(32,35,48); feed.BorderSizePixel = 0; feed.Parent = screen
	local battery = Instance.new("TextLabel")
	battery.BackgroundTransparency = 1; battery.Position = UDim2.fromScale(0,.7); battery.Size = UDim2.fromScale(1,.25)
	battery.Text = "99%"; battery.TextScaled = true; battery.Font = Enum.Font.GothamBold; battery.TextColor3 = cream; battery.Parent = feed
	for _, x in {.1,.55} do
		local eye = Instance.new("Frame") eye.Position = UDim2.fromScale(x,.25); eye.Size = UDim2.fromScale(.35,.24)
		eye.BackgroundColor3 = cream; eye.BorderSizePixel = 0; eye.Parent = feed; corner(eye,40)
		local pupil = Instance.new("Frame") pupil.Position = UDim2.fromScale(.4,.3); pupil.Size = UDim2.fromScale(.35,.4)
		pupil.BackgroundColor3 = ink; pupil.BorderSizePixel = 0; pupil.Parent = eye; corner(pupil,40)
	end
	local phoneTarget = phone.Position
	local phoneCaught = false
	local nextTaunt = 0
	-- Gemini writes some of the phone's taunts when the backend is reachable;
	-- a small tag says so, so judges can see the AI doing something.
	local geminiTaunts = nil
	local aiBoard = Instance.new("BillboardGui")
	aiBoard.Size = UDim2.fromOffset(150, 18)
	aiBoard.StudsOffset = Vector3.new(0, 4.3, 0)
	aiBoard.AlwaysOnTop = true
	aiBoard.Enabled = false
	aiBoard.Parent = phone
	local aiTag = Instance.new("TextLabel")
	aiTag.Size = UDim2.fromScale(1, 1)
	aiTag.BackgroundTransparency = 1
	aiTag.Text = "✨ written by Gemini for you"
	aiTag.TextColor3 = Color3.fromRGB(215, 200, 255)
	aiTag.TextStrokeTransparency = 0.3
	aiTag.Font = Enum.Font.GothamBold
	aiTag.TextScaled = true
	aiTag.Parent = aiBoard

	-- Big light bulb ---------------------------------------------------
	local bulb = object("BigLight", Vector3.new(2.2, 2.2, 2.2), Color3.fromRGB(255, 236, 140), Enum.PartType.Ball)
	bulb.Position = randomPoint(random, ignore) or Vector3.new(-80, FLOAT_Y, -149)
	local glow = Instance.new("PointLight")
	glow.Range = 14
	glow.Brightness = 2
	glow.Color = bulb.Color
	glow.Parent = bulb
	bubble(bulb, "BIG LIGHT: smack me", Color3.fromRGB(200, 150, 30))
	local roommateAt = nil
	local roommateDone = false

	-- Midnight fridge --------------------------------------------------
	local fridge = require(script.Parent.RushFridge).new(folder, ignore, function()
		return randomPoint(random, ignore) or Vector3.new(-66, FLOAT_Y, -176)
	end)
	-- It creaks open early, then keeps coming back as the night gets worse.
	local nextFridge = 7
	local fridgeOpens = 0
	local lastPhase = 0
	local lastCountdown = 6
	local lightOff = false
	local pendingSaves = 0
	local saveQueue = {}
	local saving = false
	local stallTime = 0
	local lastPhonePosition = phone.Position

	-- Round state -------------------------------------------------------
	local started = false
	local startTime = 0
	local finished = false
	local restingHuman, oldWalkSpeed, oldAutoRotate
	local function secondsLeft()
		if not started then return Rush.duration end
		return math.max(0, Rush.duration - (os.clock() - startTime))
	end
	local save -- defined below; finish() records the final fridge state
	local function finish(reason)
		if finished then return end
		finished = true
		alive = false
		-- An open fridge at lights-out means a late-night snack.
		if fridge.isOpen() then
			save("Food", 2)
			mark("Food", "failed", " (midnight snack)")
		else
			mark("Food", "done")
		end
		if reason == "timeout" then
			pop("11:00 PM. FLOOR NAP.", Color3.fromRGB(255, 190, 150), 2, "not your finest work. still counts as sleep.")
		else
			mark("Bed", "done", string.format(" (%ds early!)", math.floor(secondsLeft())))
			pop("FINALLY. PEACE.", Color3.fromRGB(190, 210, 255), 1.5, "tomorrow can wait.")
		end
		-- Freeze every distraction before the quiet beat. Flush choices before Sleep.
		phoneLabel.Text = "zzzz" phone.Transparency = 1 bulb.Parent = nil aiBoard.Enabled = false
		presentation.peace()
		if reason == "bed" then
			local room=workspace:FindFirstChild("CozyBedroom101")
			local bed=room and room:FindFirstChild("RaisedBed")
			local mattress=bed and bed:FindFirstChild("Mattress")
			restingHuman=humanoid()
			if restingHuman then
				oldWalkSpeed=restingHuman.WalkSpeed; oldAutoRotate=restingHuman.AutoRotate
				restingHuman.WalkSpeed=0; restingHuman.AutoRotate=false
			end
			if mattress and player.Character then player.Character:PivotTo(mattress.CFrame*CFrame.new(0,mattress.Size.Y/2+2.5,0)) end
		end
		for _, sound in ipairs(folder:GetChildren()) do if sound:IsA("Sound") then sound:Stop() end end
		task.spawn(function()
			task.wait(1.2)
			while pendingSaves > 0 do task.wait(.05) end
			if finished and folder.Parent then ctx.onFinished(reason) end
		end)
	end

	function save(key, option)
		-- Ordered saves prevent an old roommate update overtaking a later light smack.
		pendingSaves += 1
		table.insert(saveQueue, {key, option})
		ctx.apply(key, option)
		if key=="Lighting" then presentation.lightState(option) end
		if saving then return end
		saving = true
		task.spawn(function()
			while #saveQueue > 0 do
				local item = table.remove(saveQueue, 1)
				ctx.request(item[1], item[2])
				pendingSaves -= 1
			end
			saving = false
		end)
	end

	local function catchPhone()
		phoneCaught = true
		save("Phone", 1)
		mark("Phone", "done")
		play("click")
		play("buzz",.12)
		pop("PHONE DEFEATED", Color3.fromRGB(170, 230, 180), 1.2, "your streak... *one very weak buzz*")
		presentation.burst(phone.Position, Color3.fromRGB(96,170,235))
		phoneLabel.Text = "your streak..."
		TweenService:Create(phone,TweenInfo.new(.3),{Size=Vector3.new(.2,.35,.1),Transparency=1}):Play()
		task.delay(.35,function() if phone.Parent then phone:Destroy() end end)
		presentation.bedReady(lightOff)
	end

	local function smackLight()
		lightOff = true
		presentation.burst(bulb.Position, Color3.fromRGB(255,206,112))
		presentation.bedReady(phoneCaught)
		save("Lighting", 1)
		mark("Lighting", "done")
		play("click")
		pop("BIG LIGHT: DEFEATED", Color3.fromRGB(255, 236, 160), 1.2, "oh. this is actually cozy.")
		bulb.Parent = nil
		if not roommateDone then roommateAt = os.clock() + random:NextNumber(8, 14) end
	end

	local function roommate()
		lightOff = false
		presentation.bedReady(false)
		presentation.flash(Color3.fromRGB(255,236,140))
		roommateDone = true
		save("Lighting", 2)
		mark("Lighting", "failed", " (roommate!)")
		play("oof", 0.5)
		shake()
		presentation.roommate()
		pop("THE BIG LIGHT. AGAIN?!", Color3.fromRGB(255, 220, 140), 1.8, "your roommate has entered the chat.")
		bulb.Position = randomPoint(random, ignore) or Vector3.new(-80,FLOAT_Y,-149)
		bulb.Parent = folder
	end

	local function openFridge()
		fridgeOpens += 1
		fridge.open()
		mark("Food", "pending", if fridgeOpens > 1 then " (it's back)" else nil)
		presentation.burst(fridge.position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 240, 200))
		pop(if fridgeOpens == 1 then "THE FRIDGE IS OPEN" else "THE FRIDGE. AGAIN.", Color3.fromRGB(255, 210, 120), 1.3,
			if fridgeOpens == 1 then "it's whispering about leftovers. go shut it." else "it's always back. it knows.")
	end

	local function shutFridge()
		fridge.close()
		mark("Food", "done")
		play("click")
		presentation.burst(fridge.position + Vector3.new(0, 2, 0), Color3.fromRGB(170, 210, 180))
		pop("KITCHEN CLOSED", Color3.fromRGB(170, 230, 180), 1.1, "the leftovers will survive until breakfast.")
	end

	-- Main loop -------------------------------------------------------
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not started or finished then return end
		local now = os.clock()
		local left = secondsLeft()
		local r = root()

		local elapsed = now - startTime
		presentation.update(left, elapsed)
		local phase = if elapsed < 15 then 0 elseif elapsed < 30 then 1 elseif elapsed < 45 then 2 else 3
		if phase > lastPhase then
			lastPhase = phase
			if phase == 1 then pop("15 SECONDS IN. VIBES: CHAOTIC.", Color3.fromRGB(255,210,120), 1.1, "the fridge is plotting something.")
			elseif phase == 2 then pop("30 SECONDS. ZERO CHILL.", cream, 1, "phone battery: emotionally unavailable.")
			else pop("BEDTIME PANIC!", Color3.fromRGB(255,160,140), 1, "the bed is your exit.") end
		end
		if left <= 5 and math.ceil(left) < lastCountdown and left > 0 then
			lastCountdown = math.ceil(left)
			pop(tostring(lastCountdown).."!",Color3.fromRGB(255,160,140),.55)
			play("click",.35)
		end
		if left <= 0 then finish("timeout"); return end

		-- Phone flees when you get close, but its battery runs down.
		if not phoneCaught and phone.Parent then
			local elapsed = now - startTime
			local speed = if elapsed > 30 then 3.5 else 9
			-- A short hesitation makes it mischievous and gives the player a fair catch window.
			if elapsed % 6 > 4.8 then speed *= .2 end
			if r then
				local away = Vector3.new(phone.Position.X - r.Position.X, 0, phone.Position.Z - r.Position.Z)
				if away.Magnitude < 15 and (phoneTarget - phone.Position).Magnitude < 2 then
					local dir = if away.Magnitude > 0.1 then away.Unit else Vector3.new(1, 0, 0)
					local candidate = clampToRoom(phone.Position + dir * 10 + Vector3.new(random:NextNumber(-4, 4), 0, random:NextNumber(-4, 4)))
					-- Cornered? Dash somewhere random instead.
					if (candidate - phone.Position).Magnitude < 4 or blocked(candidate, ignore) then candidate = randomPoint(random, ignore) or phone.Position end
					phoneTarget = candidate
				end
			end
			local step = phoneTarget - phone.Position
			local base = if step.Magnitude > 0.05 then phone.Position + step.Unit * math.min(step.Magnitude, speed * dt) else phone.Position
			if blocked(Vector3.new(base.X,FLOAT_Y,base.Z),ignore) then
				base=phone.Position phoneTarget=randomPoint(random,ignore) or phone.Position
			end
			if (Vector3.new(base.X,0,base.Z)-Vector3.new(lastPhonePosition.X,0,lastPhonePosition.Z)).Magnitude < .01 then stallTime += dt else stallTime=0 end
			if stallTime > 1.2 then phoneTarget=randomPoint(random,ignore) or phone.Position stallTime=0 end
			lastPhonePosition=base
			local floating = Vector3.new(base.X, FLOAT_Y + math.abs(math.sin(now * 6)) * 0.8, base.Z)
			local facing = if r then Vector3.new(r.Position.X-floating.X,0,r.Position.Z-floating.Z) else Vector3.new(0,0,1)
			if facing.Magnitude < .01 then facing=Vector3.new(0,0,1) end
			phone.CFrame = CFrame.lookAt(floating,floating+facing) * CFrame.Angles(0,0,math.sin(now * 15)*.09)
			battery.Text = if elapsed>30 then "3%" else tostring(math.max(4,99-math.floor(elapsed*3))).."%"
			if now >= nextTaunt then
				nextTaunt = now + 2.5
				local useGemini = elapsed <= 30 and geminiTaunts ~= nil and random:NextNumber() < 0.6
				aiBoard.Enabled = useGemini
				phoneLabel.Text = if elapsed > 30 then (if elapsed % 8 < 4 then "battery 3%..." else "tell my charger I loved them")
					elseif useGemini then geminiTaunts[random:NextInteger(1, #geminiTaunts)]
					else phoneTaunts[random:NextInteger(1, #phoneTaunts)]
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

		-- Fridge: opens on a schedule that tightens as the round escalates.
		if not fridge.isOpen() and elapsed >= nextFridge and left > 6 and fridgeOpens < 3 then
			openFridge()
		end
		if fridge.update(now, if r then r.Position else nil) then
			shutFridge()
			nextFridge = elapsed + (if elapsed < 30 then 12 else 8)
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
		pop("BEDTIME RUSH!", Color3.fromRGB(255, 210, 120), 1.2, "catch your phone • smack the light • shut the fridge • bed")
		play("jump", 0.6)
		save("Phone",2) save("Lighting",2) save("Food",1)
		ctx.request("RushStart")
		-- Non-blocking: if Gemini answers in time, the phone starts using its lines.
		task.spawn(function()
			local reply = ctx.request("PhoneTaunts")
			if alive and type(reply) == "table" and type(reply.taunts) == "table" and #reply.taunts > 0 then
				geminiTaunts = reply.taunts
			end
		end)
		if not alive then return end
		started = true
		startTime = os.clock()
	end)

	local controller = {}
	controller.secondsLeft = secondsLeft
	function controller.goToBed()
		if started and not finished then finish("bed") end
	end
	function controller.stop()
		alive = false
		finished = true
		for _, connection in connections do connection:Disconnect() end
		bulb:Destroy()
		folder:Destroy()
		presentation.stop()
		local human = humanoid()
		if human then human.CameraOffset = Vector3.zero end
		if restingHuman and restingHuman.Parent then
			restingHuman.WalkSpeed=oldWalkSpeed; restingHuman.AutoRotate=oldAutoRotate
		end
	end
	return controller
end

return Rush
