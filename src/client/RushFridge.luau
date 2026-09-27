-- The midnight fridge: Bedtime Rush's food temptation. It creaks open and
-- glows, whispering about leftovers; walk up to it to shut it. If it's open
-- at lights-out, that counts as a late-night snack. Client-only, no collision.
local TweenService = game:GetService("TweenService")

local Fridge = {}

local whispers = {
	"psst... cold pizza?", "leftovers miss you", "just ONE bite", "cheese. at midnight.",
	"you deserve a snack", "the fridge light is on for YOU",
}
local SIZE = Vector3.new(3.2, 5.2, 3)

-- True if solid furniture overlaps the fridge's footprint at this spot.
local function blocked(cframe, ignore)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	for _, part in workspace:GetPartBoundsInBox(cframe, SIZE * 0.9, params) do
		if part.CanCollide and part.Transparency < 1 then return true end
	end
	return false
end

-- Floor height under a point (furniture may have been moved in Studio).
local function floorY(point, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(point + Vector3.new(0, 6, 0), Vector3.new(0, -20, 0), params)
	return if hit then hit.Position.Y else 12.4
end

-- Next to the sideboard (the room's snack zone) if there's space, else any open spot.
local function findSpot(ignore, fallback)
	local room = workspace:FindFirstChild("CozyBedroom101")
	local sideboard = room and room:FindFirstChild("Sideboard")
	local cabinet = sideboard and sideboard:FindFirstChild("Cabinet")
	local candidates = {}
	if cabinet then
		local c = cabinet.Position
		for _, offset in {Vector3.new(0, 0, -11), Vector3.new(0, 0, 11), Vector3.new(-5, 0, -11), Vector3.new(-5, 0, 11)} do
			table.insert(candidates, Vector3.new(c.X, 0, c.Z) + offset)
		end
	end
	table.insert(candidates, Vector3.new(-66, 0, -176))
	table.insert(candidates, Vector3.new(-66, 0, -142))
	for _, spot in candidates do
		local y = floorY(Vector3.new(spot.X, 14, spot.Z), ignore)
		-- Face the middle of the room so the door opens toward the player.
		local center = Vector3.new(spot.X, y + SIZE.Y / 2, spot.Z)
		local cframe = CFrame.lookAt(center, Vector3.new(-84, center.Y, -161))
		if not blocked(cframe, ignore) then return cframe end
	end
	local point = fallback()
	local y = floorY(point, ignore)
	return CFrame.lookAt(Vector3.new(point.X, y + SIZE.Y / 2, point.Z), Vector3.new(-84, y + SIZE.Y / 2, -161))
end

-- folder: parent for parts; ignore: instances excluded from placement checks;
-- fallback(): returns an open floor point if no spot near the sideboard fits.
function Fridge.new(folder, ignore, fallback)
	local base = findSpot(ignore, fallback)
	local function part(name, size, cframe, color, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cframe
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Parent = folder
		return p
	end
	local body = part("MidnightFridge", SIZE, base, Color3.fromRGB(236, 232, 222))
	-- The interior glow shows only while the door is open.
	local inside = part("FridgeGlow", Vector3.new(SIZE.X - 0.5, SIZE.Y - 0.6, 0.1), base * CFrame.new(0, 0, -SIZE.Z / 2 - 0.02), Color3.fromRGB(255, 244, 200), Enum.Material.Neon)
	inside.Transparency = 1
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Range = 18
	light.Angle = 70
	light.Brightness = 0
	light.Color = Color3.fromRGB(255, 240, 200)
	light.Parent = body
	-- The door hinges on its left edge; `hinge` is the closed pose of that edge.
	local hinge = base * CFrame.new(-SIZE.X / 2, 0, -SIZE.Z / 2 - 0.15)
	local door = part("FridgeDoor", Vector3.new(SIZE.X, SIZE.Y, 0.3), hinge * CFrame.new(SIZE.X / 2, 0, 0), Color3.fromRGB(245, 242, 234))
	local handle = part("FridgeHandle", Vector3.new(0.2, 1.4, 0.25), door.CFrame * CFrame.new(SIZE.X / 2 - 0.4, 0.8, -0.25), Color3.fromRGB(150, 150, 160))
	local magnet = part("FridgeMagnet", Vector3.new(1.4, 1, 0.05), door.CFrame * CFrame.new(-0.3, 1.4, -0.17), Color3.fromRGB(247, 233, 212))
	local note = Instance.new("SurfaceGui")
	note.Face = Enum.NormalId.Front
	note.CanvasSize = Vector2.new(140, 100)
	note.Parent = magnet
	local noteText = Instance.new("TextLabel")
	noteText.Size = UDim2.fromScale(1, 1)
	noteText.BackgroundTransparency = 1
	noteText.Text = "kitchen closes\nat 9pm (lol)"
	noteText.TextScaled = true
	noteText.Font = Enum.Font.FredokaOne
	noteText.TextColor3 = Color3.fromRGB(163, 74, 57)
	noteText.Parent = note

	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(190, 42)
	board.StudsOffset = Vector3.new(0, SIZE.Y / 2 + 1.6, 0)
	board.AlwaysOnTop = true
	board.Enabled = false
	board.Parent = body
	local bubble = Instance.new("TextLabel")
	bubble.Size = UDim2.fromScale(1, 1)
	bubble.BackgroundColor3 = Color3.fromRGB(180, 100, 40)
	bubble.TextColor3 = Color3.new(1, 1, 1)
	bubble.Font = Enum.Font.GothamBold
	bubble.TextScaled = true
	bubble.Parent = board
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = bubble

	local state = {open = false, nextWhisper = 0, openedAt = 0}
	local function swing(angle, seconds)
		local pose = hinge * CFrame.Angles(0, angle, 0)
		TweenService:Create(door, TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = pose * CFrame.new(SIZE.X / 2, 0, 0)}):Play()
		TweenService:Create(handle, TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = pose * CFrame.new(SIZE.X - 0.4, 0.8, -0.25)}):Play()
		TweenService:Create(magnet, TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = pose * CFrame.new(SIZE.X / 2 - 0.3, 1.4, -0.17)}):Play()
	end

	local api = {}
	api.position = body.Position
	function api.isOpen()
		return state.open
	end
	function api.open()
		if state.open then return end
		state.open = true
		state.openedAt = os.clock()
		swing(math.rad(100), 0.8)
		inside.Transparency = 0
		TweenService:Create(light, TweenInfo.new(0.6), {Brightness = 3}):Play()
		bubble.Text = whispers[1]
		board.Enabled = true
	end
	function api.close()
		if not state.open then return end
		state.open = false
		swing(0, 0.25)
		inside.Transparency = 1
		light.Brightness = 0
		board.Enabled = false
	end
	-- Call every frame; returns true when the player is close enough to shut it.
	function api.update(now, rootPosition)
		if not state.open then return false end
		if now >= state.nextWhisper then
			state.nextWhisper = now + 2.2
			bubble.Text = whispers[math.random(1, #whispers)]
		end
		-- A slow creak back and forth sells "it wants you".
		inside.Transparency = 0.15 + math.abs(math.sin(now * 3)) * 0.2
		if rootPosition and now - state.openedAt > 0.5 then
			local flat = Vector3.new(rootPosition.X - body.Position.X, 0, rootPosition.Z - body.Position.Z)
			return flat.Magnitude < 6
		end
		return false
	end
	return api
end

return Fridge
