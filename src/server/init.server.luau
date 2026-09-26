-- A walkable college neighborhood, generated when the server starts.
local terrain = workspace.Terrain
local groundHeight = 12
local oldNeighborhood = workspace:FindFirstChild("CollegeNeighborhood")
if oldNeighborhood then
	oldNeighborhood:Destroy()
end

-- Replace the old hills only inside the generated map's original bounds.
terrain:FillBlock(CFrame.new(0, 24, 0), Vector3.new(512, 80, 512), Enum.Material.Air)
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(91, 139, 73))
-- The circular ground below replaces the old square baseplate.
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end

local campus = Instance.new("Model")
campus.Name = "CollegeNeighborhood"
campus.Parent = workspace

local colors = {
	path = Color3.fromRGB(204, 199, 183),
	road = Color3.fromRGB(57, 61, 66),
	trim = Color3.fromRGB(231, 218, 191),
	wall = Color3.fromRGB(211, 190, 162),
	roof = Color3.fromRGB(59, 65, 73),
	glass = Color3.fromRGB(137, 184, 201),
	wood = Color3.fromRGB(130, 91, 58),
	metal = Color3.fromRGB(47, 57, 60),
}

local function part(parent, name, size, position, color, material)
	local object = Instance.new("Part")
	object.Name = name
	object.Anchored = true
	object.Size = size
	object.CFrame = CFrame.new(position)
	object.Color = color
	object.Material = material or Enum.Material.SmoothPlastic
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function sign(board, text)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 180)
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = colors.trim
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = gui
end

local function path(name, x, z, width, depth)
	return part(campus, name, Vector3.new(width, 0.4, depth), Vector3.new(x, groundHeight + 0.2, z), colors.path, Enum.Material.Concrete)
end

local ground = part(campus, "CircularGround", Vector3.new(28, 700, 700), Vector3.new(0, -2, 0), Color3.fromRGB(91, 139, 73), Enum.Material.Grass)
ground.Shape = Enum.PartType.Cylinder
ground.CFrame = CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.pi / 2)

-- A loop road frames the residential blocks; the center stays pedestrian friendly.
for _, z in ipairs({ -210, 210 }) do
	part(campus, "CampusRoad", Vector3.new(444, 0.2, 24), Vector3.new(0, 12.1, z), colors.road, Enum.Material.Asphalt)
	path("RoadsideWalk", 0, z + (if z < 0 then 19 else -19), 396, 10)
	for x = -200, 200, 24 do
		part(campus, "LaneMarking", Vector3.new(12, 0.05, 0.5), Vector3.new(x, 12.225, z), colors.trim)
	end
end
for _, x in ipairs({ -210, 210 }) do
	part(campus, "CampusRoad", Vector3.new(24, 0.2, 396), Vector3.new(x, 12.1, 0), colors.road, Enum.Material.Asphalt)
	path("RoadsideWalk", x + (if x < 0 then 19 else -19), 0, 10, 396)
	for z = -180, 180, 24 do
		part(campus, "LaneMarking", Vector3.new(0.5, 0.05, 12), Vector3.new(x, 12.225, z), colors.trim)
	end
end
path("MainPromenade", 0, 0, 18, 396)
for _, z in ipairs({ -60, 60 }) do
	path("QuadCrosswalk", 0, z, 396, 12)
end
path("WelcomePlaza", 0, 0, 50, 46)
for _, z in ipairs({ -222, 222 }) do
	for x = -8, 8, 4 do
		part(campus, "PedestrianCrossing", Vector3.new(2, 0.05, 24), Vector3.new(x, 12.225, z + (if z < 0 then 12 else -12)), colors.trim)
	end
	path("CampusApproach", 0, z + (if z < 0 then -14 else 14), 18, 28)
end

-- One spacious residence with eight real rooms and an open central corridor.
local building = Instance.new("Model")
building.Name = "TigerHall"
building.Parent = campus
local function piece(name, size, offset, color, material)
	return part(building, name, size, Vector3.new(0, groundHeight, -119) + offset, color, material)
end
local brick = Color3.fromRGB(211, 190, 162)
-- Larger bedrooms share a cathedral roof: 28-stud eaves and a 52-stud ridge.
local wallHeight = 28
local halfDepth = 70
local roofRise = 24
local roofAngle = math.atan(roofRise / halfDepth)
local roofLength = math.sqrt(halfDepth ^ 2 + roofRise ^ 2)
piece("Floor", Vector3.new(224, 0.4, 140), Vector3.new(0, 0.2, 0), colors.path, Enum.Material.Concrete)

-- WedgeParts rise toward their local +Z end, closing the vaulted wall tops.
local function gable(name, x, thickness, z, run, lowHeight, rise, side, material, color)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.Size = Vector3.new(thickness, rise, run)
	wedge.CFrame = CFrame.new(x, groundHeight + lowHeight + rise / 2, -119 + z)
		* CFrame.Angles(0, if side > 0 then math.pi else 0, 0)
	wedge.Material = material
	wedge.Color = color
	wedge.Parent = building
end
for _, side in ipairs({ -1, 1 }) do
	if side == -1 then
		-- Six-stud opening connects room 101 to its ensuite bathroom.
		piece("SideWall", Vector3.new(2, wallHeight, 45), Vector3.new(-111, wallHeight / 2, -47.5), brick, Enum.Material.Brick)
		piece("SideWall", Vector3.new(2, wallHeight, 89), Vector3.new(-111, wallHeight / 2, 25.5), brick, Enum.Material.Brick)
		piece("BathroomDoorHeader", Vector3.new(2, 18, 6), Vector3.new(-111, 19, -22), brick, Enum.Material.Brick)
	else
		piece("SideWall", Vector3.new(2, wallHeight, 140), Vector3.new(side * 111, wallHeight / 2, 0), brick, Enum.Material.Brick)
	end
	for _, slope in ipairs({ -1, 1 }) do
		gable("EndGable", side * 111, 2, slope * 35, 70, wallHeight, roofRise, slope, Enum.Material.Brick, brick)
	end
	local roof = piece("CathedralRoof", Vector3.new(228, 1.5, roofLength + 3), Vector3.new(0, 40, side * 35), colors.roof, Enum.Material.Slate)
	roof.CFrame *= CFrame.Angles(side * roofAngle, 0, 0)
end
piece("RidgeBeam", Vector3.new(226, 2, 2), Vector3.new(0, 51, 0), colors.wood, Enum.Material.Wood)
-- Exterior walls are built around each window, leaving actual openings.
for _, side in ipairs({ -1, 1 }) do
	for _, x in ipairs({ -84, -28, 28, 84 }) do
		local z = side * 69
		piece("WindowSillWall", Vector3.new(56, 6, 2), Vector3.new(x, 3, z), brick, Enum.Material.Brick)
		piece("WindowHeaderWall", Vector3.new(56, 6, 2), Vector3.new(x, 25, z), brick, Enum.Material.Brick)
		for _, dx in ipairs({ -21, 21 }) do
			-- The two front posts beside the entrance leave a 16-stud opening.
			local besideEntry = side == 1 and math.abs(x + dx) == 7
			if not besideEntry then
				piece("WindowWallPost", Vector3.new(14, 16, 2), Vector3.new(x + dx, 14, z), brick, Enum.Material.Brick)
			else
				piece("EntrySidePost", Vector3.new(6, 16, 2), Vector3.new(if x < 0 then -11 else 11, 14, z), brick, Enum.Material.Brick)
			end
		end
	end
end
-- Remove the bottom wall sections across the entrance by splitting them.
for _, wall in ipairs(building:GetChildren()) do
	if wall.Name == "WindowSillWall" and wall.Position.Z > -60 and math.abs(wall.Position.X) == 28 then
		local side = if wall.Position.X < 0 then -1 else 1
		wall.Size = Vector3.new(48, 6, 2)
		wall.Position = Vector3.new(side * 32, wall.Position.Y, wall.Position.Z)
	end
end
piece("EntryLintel", Vector3.new(16, 10, 2), Vector3.new(0, 23, 69), brick, Enum.Material.Brick)
piece("Canopy", Vector3.new(26, 1, 12), Vector3.new(0, 14, 73), colors.trim)
local hallSign = piece("HallSign", Vector3.new(38, 4, 0.5), Vector3.new(0, 25, 70.2), colors.metal)
hallSign.CFrame *= CFrame.Angles(0, math.pi, 0)
sign(hallSign, "TIGER HALL • 8 ROOMS")
path("DormEntranceWalk", 0, -44, 16, 20)
local roomNumber = 100
for _, side in ipairs({ -1, 1 }) do
	for _, x in ipairs({ -84, -28, 28, 84 }) do
		roomNumber += 1
		local z = side * 42
		local doorX = if roomNumber == 101 then x - 17 else x
		-- Offset room 101's entrance to keep the staircase out of the doorway.
		if roomNumber == 101 then
			piece("RoomDoorWall", Vector3.new(7, 47.2, 1), Vector3.new(x - 24.5, 23.6, side * 14), colors.wall)
			piece("RoomDoorWall", Vector3.new(41, 47.2, 1), Vector3.new(x + 7.5, 23.6, side * 14), colors.wall)
		else
		for _, dx in ipairs({ -16, 16 }) do
			local entryEdge = side == 1 and ((x == -28 and dx == 16) or (x == 28 and dx == -16))
			piece("RoomDoorWall", Vector3.new(if entryEdge then 16 else 24, 47.2, 1), Vector3.new(if entryEdge then (if x < 0 then -16 else 16) else x + dx, 23.6, side * 14), colors.wall)
		end
		end
		piece("DoorLintel", Vector3.new(8, 36.2, 1), Vector3.new(doorX, 29.1, side * 14), colors.wall)
		local door = piece("BedroomDoor" .. roomNumber, Vector3.new(7.8, 10.6, 0.6), Vector3.new(doorX, 5.7, side * 14), colors.wood, Enum.Material.WoodPlanks)
		local closedCFrame = door.CFrame
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Room " .. roomNumber
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = door
		local opened = false
		local moving = false
		prompt.Triggered:Connect(function()
			if moving then return end
			moving = true
			opened = not opened
			local target = if opened then closedCFrame * CFrame.new(-3.9, 0, 0) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(3.9, 0, 0) else closedCFrame
			local animation = game:GetService("TweenService"):Create(door, TweenInfo.new(0.35), { CFrame = target })
			animation:Play()
			animation.Completed:Wait()
			prompt.ActionText = if opened then "Close" else "Open"
			moving = false
		end)
		-- Each divider follows the roof slope, keeping the tall bedrooms enclosed.
		if x == -84 then
			if roomNumber == 101 then
				piece("RoomPartition", Vector3.new(1, 28, 45), Vector3.new(x - 28, 14, -47.5), colors.wall)
				piece("RoomPartition", Vector3.new(1, 28, 5), Vector3.new(x - 28, 14, -16.5), colors.wall)
				piece("BathroomPartitionHeader", Vector3.new(1, 18, 6), Vector3.new(x - 28, 19, -22), colors.wall)
			else
				piece("RoomPartition", Vector3.new(1, 28, 56), Vector3.new(x - 28, 14, z), colors.wall)
			end
			gable("VaultPartition", x - 28, 1, z, 56, 28, 19.2, side, Enum.Material.SmoothPlastic, colors.wall)
		end
		local partitionX = if side == 1 and x == -28 then -8 else x + 28
		piece("RoomPartition", Vector3.new(1, 28, 56), Vector3.new(partitionX, 14, z), colors.wall)
		gable("VaultPartition", partitionX, 1, z, 56, 28, 19.2, side, Enum.Material.SmoothPlastic, colors.wall)
		if side == 1 and x == 28 then
			piece("EntryPassageWall", Vector3.new(1, 28, 56), Vector3.new(8, 14, z), colors.wall)
			gable("EntryPassageVault", 8, 1, z, 56, 28, 19.2, side, Enum.Material.SmoothPlastic, colors.wall)
		end
		local plate = piece("RoomNumber", Vector3.new(7, 2, 0.3), Vector3.new(doorX, 12, side * 13.3), colors.metal)
		if side == -1 then plate.CFrame *= CFrame.Angles(0, math.pi, 0) end
		sign(plate, tostring(roomNumber))
		if roomNumber ~= 101 then
		piece("BedFrame", Vector3.new(9, 2, 16), Vector3.new(x - 9, 1.4, z + side * 5), colors.wood, Enum.Material.WoodPlanks)
		piece("Mattress", Vector3.new(9, 1.2, 16), Vector3.new(x - 9, 3, z + side * 5), colors.trim, Enum.Material.Fabric)
		piece("Blanket", Vector3.new(9.1, 0.3, 10), Vector3.new(x - 9, 3.75, z + side * 2), Color3.fromRGB(73, 112, 137), Enum.Material.Fabric)
		piece("Pillow", Vector3.new(6, 0.7, 3), Vector3.new(x - 9, 3.8, z + side * 11), Color3.fromRGB(245, 240, 223), Enum.Material.Fabric)
		piece("Desk", Vector3.new(10, 0.7, 5), Vector3.new(x + 8, 4, z + side * 12), colors.wood, Enum.Material.WoodPlanks)
		for _, dx in ipairs({ 4, 12 }) do
			piece("DeskLeg", Vector3.new(0.6, 4, 4), Vector3.new(x + dx, 2, z + side * 12), colors.metal)
		end
		piece("ChairSeat", Vector3.new(4, 3, 4), Vector3.new(x + 8, 1.9, z + side * 6), colors.wood, Enum.Material.Wood)
		piece("Wardrobe", Vector3.new(6, 10, 5), Vector3.new(x + 10, 5.4, z - side * 8), colors.wood, Enum.Material.WoodPlanks)
		end
		for _, dx in ipairs({ -14, 14 }) do
			piece("WindowJamb", Vector3.new(0.8, 16, 2.4), Vector3.new(x + dx, 14, side * 69), colors.trim)
		end
		for _, y in ipairs({ 6, 22 }) do
			piece("WindowRail", Vector3.new(28.8, 0.8, 2.4), Vector3.new(x, y, side * 69), colors.trim)
		end
		if roomNumber == 101 then
			-- Two distinct windows share the existing exterior opening.
			piece("DoubleWindowPier", Vector3.new(1.5, 16, 2), Vector3.new(x, 14, side * 69), colors.trim)
			for _, offset in ipairs({ -7.4, 7.4 }) do
				local pane = piece("Room101Window", Vector3.new(12.5, 15.2, 0.4), Vector3.new(x + offset, 14, side * 69), colors.glass, Enum.Material.Glass)
				pane.Transparency = 0.65
				pane.CastShadow = false
				piece("WindowCrossbar", Vector3.new(12.5, 0.5, 0.8), Vector3.new(x + offset, 14, side * 69), colors.trim)
			end
			piece("Room101WindowLedge", Vector3.new(29, 0.5, 4), Vector3.new(x, 6.75, side * 67), colors.wood, Enum.Material.Wood)
		else
		local window = piece("Window", Vector3.new(27.2, 15.2, 0.4), Vector3.new(x, 14, side * 69), colors.glass, Enum.Material.Glass)
		window.Transparency = 0.65
		window.CastShadow = false
		piece("WindowMullion", Vector3.new(0.5, 16, 0.8), Vector3.new(x, 14, side * 69), colors.trim)
		piece("WindowCrossbar", Vector3.new(28, 0.5, 0.8), Vector3.new(x, 14, side * 69), colors.trim)
		end
		piece("PendantCord", Vector3.new(0.2, 8, 0.2), Vector3.new(x, 32, z), colors.metal)
		local fixture = piece("RoomLight", Vector3.new(5, 0.5, 5), Vector3.new(x, 28, z), colors.trim, Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Brightness = 1.5
		light.Range = 65
		light.Parent = fixture
	end
end

local bedroom = require(script:WaitForChild("CozyBedroom")).build()
require(script:WaitForChild("Bathroom")).build(bedroom)

-- Smaller homes outside the campus road form the surrounding neighborhood.
local function house(x, z, rotation, index)
	local home = Instance.new("Model")
	home.Name = "NeighborhoodHome" .. index
	home.Parent = campus
	local origin = CFrame.new(x, groundHeight, z) * CFrame.Angles(0, rotation, 0)
	local palette = { Color3.fromRGB(181, 139, 104), Color3.fromRGB(132, 157, 158), Color3.fromRGB(184, 173, 139) }
	local function hp(name, size, offset, color, material)
		local object = part(home, name, size, Vector3.zero, color, material)
		object.CFrame = origin * CFrame.new(offset)
		return object
	end
	hp("House", Vector3.new(34, 22, 30), Vector3.new(0, 11, 0), palette[index % 3 + 1], Enum.Material.Brick)
	for _, side in ipairs({ -1, 1 }) do
		local roof = hp("PitchedRoof", Vector3.new(21, 1.5, 35), Vector3.new(side * 9, 25, 0), colors.roof, Enum.Material.Slate)
		roof.CFrame *= CFrame.Angles(0, 0, -side * math.rad(20))
		hp("WindowFrame", Vector3.new(8, 8, 0.5), Vector3.new(side * 10, 12, -15.3), colors.trim)
		hp("Window", Vector3.new(6, 6, 0.6), Vector3.new(side * 10, 12, -15.6), colors.glass, Enum.Material.Glass)
	end
	hp("FrontDoor", Vector3.new(5, 10, 0.5), Vector3.new(0, 5, -15.4), colors.wood, Enum.Material.WoodPlanks)
	hp("Porch", Vector3.new(14, 0.5, 6), Vector3.new(0, 0.25, -18), colors.path, Enum.Material.Concrete)
	hp("GardenWalk", Vector3.new(6, 0.4, 26), Vector3.new(0, 0.2, -32), colors.path, Enum.Material.Concrete)
	hp("Chimney", Vector3.new(5, 10, 5), Vector3.new(10, 26, 6), brick, Enum.Material.Brick)
end
local houseIndex = 0
for _, side in ipairs({ -1, 1 }) do
	for _, offset in ipairs({ -140, -70, 0, 70, 140 }) do
		houseIndex += 1
		house(offset, side * 265, if side > 0 then 0 else math.pi, houseIndex)
		houseIndex += 1
		house(side * 265, offset, if side > 0 then math.pi / 2 else -math.pi / 2, houseIndex)
	end
end

local function tree(x, z, scale)
	part(campus, "TreeTrunk", Vector3.new(2.5, 12, 2.5) * scale, Vector3.new(x, 12 + 6 * scale, z), colors.wood, Enum.Material.Wood)
	local crown = part(campus, "TreeCanopy", Vector3.new(17, 19, 17) * scale, Vector3.new(x, 12 + 17 * scale, z), Color3.fromRGB(65, 112, 64), Enum.Material.Grass)
	crown.Shape = Enum.PartType.Ball
	crown.CanCollide = false
end

-- A tree belt follows the round edge, with groves beside the dorm and quad.
for index = 0, 47 do
	local angle = index * math.pi * 2 / 48
	local radius = 320 + (index % 3) * 4
	tree(math.cos(angle) * radius, math.sin(angle) * radius, 0.9 + (index % 4) * 0.12)
end
for _, x in ipairs({ -168, -118, 118, 168 }) do
	for _, z in ipairs({ -160, -95, 5, 100, 160 }) do
		if not (math.abs(x) < 130 and z < -40) then tree(x, z, 1.1) end
	end
end

for _, x in ipairs({ -28, 28 }) do
	for _, z in ipairs({ 30, 90, 150 }) do
		part(campus, "Lamppost", Vector3.new(0.8, 16, 0.8), Vector3.new(x, 20, z), colors.metal, Enum.Material.Metal)
		local lantern = part(campus, "Lantern", Vector3.new(2.5, 3, 2.5), Vector3.new(x, 29, z), Color3.fromRGB(255, 226, 169), Enum.Material.Neon)
		part(campus, "LanternCap", Vector3.new(3.5, 0.5, 3.5), Vector3.new(x, 30.75, z), colors.metal, Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = lantern.Color
		light.Range = 28
		light.Brightness = 1.2
		light.Parent = lantern
	end
	for _, z in ipairs({ -40, 40 }) do
		part(campus, "BenchSeat", Vector3.new(10, 0.6, 3), Vector3.new(x, 14.3, z), colors.wood, Enum.Material.WoodPlanks)
		part(campus, "BenchBack", Vector3.new(10, 3, 0.5), Vector3.new(x, 15.5, z + 1.5), colors.wood, Enum.Material.WoodPlanks)
		for _, dx in ipairs({ -3.5, 3.5 }) do
			part(campus, "BenchLeg", Vector3.new(0.6, 2, 2.5), Vector3.new(x + dx, 13, z), colors.metal, Enum.Material.Metal)
		end
	end
end

local welcome = part(campus, "CampusSign", Vector3.new(25, 6, 1), Vector3.new(0, 18, 19), colors.metal)
sign(welcome, "TIGER COMMONS\nSTUDENT RESIDENCES")
for _, x in ipairs({ -10, 10 }) do
	part(campus, "SignPost", Vector3.new(1, 6, 1), Vector3.new(x, 15, 19), colors.wood, Enum.Material.Wood)
end

-- Hold players in bedroom 101 until the intro's START transition completes.
local Players = game:GetService("Players")
local bedroomStart = CFrame.lookAt(Vector3.new(-101, groundHeight + 3.5, -139), Vector3.new(-101, groundHeight + 3.5, -161))
local spawn = workspace:FindFirstChild("SpawnLocation")
if spawn and spawn:IsA("SpawnLocation") then
	spawn.Size = Vector3.new(2, 1, 2)
	spawn.CFrame = bedroomStart
end

local function prepareCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	character:PivotTo(bedroomStart)
	root.Anchored = player:GetAttribute("StartedGame") ~= true
	character:SetAttribute("BedroomReady", true)
end
local function preparePlayer(player)
	player.CharacterAdded:Connect(function(character)
		prepareCharacter(player, character)
	end)
	if player.Character then task.spawn(prepareCharacter, player, player.Character) end
end
Players.PlayerAdded:Connect(preparePlayer)
for _, player in ipairs(Players:GetPlayers()) do preparePlayer(player) end

local startGame = Instance.new("RemoteFunction")
startGame.Name = "StartGame"
startGame.OnServerInvoke = function(player)
	local character = player.Character
	if not character or not character:GetAttribute("BedroomReady") then return nil end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return nil end
	if not player:GetAttribute("StartedGame") then
		character:PivotTo(bedroomStart)
		player:SetAttribute("StartedGame", true)
		root.Anchored = false
	end
	return root.CFrame
end
startGame.Parent = game:GetService("ReplicatedStorage")
