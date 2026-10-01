-- A cozy armchair beside the Tiger Hall front door, under the entrance canopy.
-- It sits next to the right entry post, clear of the 16-stud walkway, and faces
-- out toward the quad. Players can sit in it.
local NAME = "DormEntranceChair"
local GROUND = 12

local old = workspace:FindFirstChild(NAME)
if old then old:Destroy() end

local chair = Instance.new("Model")
chair.Name = NAME

-- Front of the chair (local -Z) points away from the building (+Z in the world).
local base = CFrame.lookAt(Vector3.new(11.5, GROUND, -45.5), Vector3.new(11.5, GROUND, -30))

local fabric = Color3.fromRGB(239, 222, 192)
local cushion = Color3.fromRGB(247, 236, 214)
local wood = Color3.fromRGB(130, 91, 58)
local pillowColor = Color3.fromRGB(210, 168, 143)

local function piece(className, name, size, offset, color, material)
	local p = Instance.new(className)
	p.Name = name
	p.Size = size
	p.CFrame = base * offset
	p.Color = color
	p.Material = material or Enum.Material.Fabric
	p.Anchored = true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = chair
	return p
end

for _, x in {-2.1, 2.1} do
	for _, z in {-1.9, 1.9} do
		piece("Part", "Leg", Vector3.new(0.5, 0.6, 0.5), CFrame.new(x, 0.3, z), wood, Enum.Material.Wood)
	end
end
piece("Part", "Base", Vector3.new(5, 1.4, 4.6), CFrame.new(0, 1.3, 0), fabric)
piece("Seat", "SeatCushion", Vector3.new(3.4, 0.7, 3.6), CFrame.new(0, 2.35, -0.3), cushion)
piece("Part", "Backrest", Vector3.new(5, 3.6, 1), CFrame.new(0, 3.6, 1.8), fabric)
piece("Part", "BackCushion", Vector3.new(3.4, 2.4, 0.6), CFrame.new(0, 3.7, 1.05) * CFrame.Angles(math.rad(-8), 0, 0), cushion)
for _, x in {-2.1, 2.1} do
	piece("Part", "Arm", Vector3.new(0.8, 1.6, 4.6), CFrame.new(x, 2.8, 0), fabric)
end
piece("Part", "ThrowPillow", Vector3.new(1.6, 1.4, 0.5), CFrame.new(0.9, 3.3, 0.55) * CFrame.Angles(math.rad(-10), 0, math.rad(12)), pillowColor)

chair.PrimaryPart = chair:FindFirstChild("Base")
chair.Parent = workspace
