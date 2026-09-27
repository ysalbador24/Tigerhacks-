-- Cozy bedtime outfit: every player gets a fluffy robe and slippers when they
-- spawn. Built from simple welded parts (no uploaded assets), sized to the
-- avatar's own body parts, so it fits R15 and R6 and follows every animation.
-- Uses Welds only (not Motor6Ds), so the reading/TV pose scripts ignore it.
local Players = game:GetService("Players")

local ROBE = Color3.fromRGB(196, 178, 232)    -- soft lavender
local TRIM = Color3.fromRGB(247, 233, 212)    -- cream, matches the game's UI
local SLIPPER = Color3.fromRGB(248, 214, 224) -- pastel pink
local POM = Color3.fromRGB(255, 250, 245)

local function attach(outfit, limb, name, size, offset, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Fabric
	part.Shape = shape or Enum.PartType.Block
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	part.CFrame = limb.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = limb
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = outfit
	return part
end

-- Robe top on a torso part: body, V-neck lapels, and a collar at the back.
local function robeTop(outfit, torso)
	local s = torso.Size
	attach(outfit, torso, "Robe", s + Vector3.new(0.16, 0.06, 0.16), CFrame.new(), ROBE)
	for side = -1, 1, 2 do
		attach(outfit, torso, "Lapel", Vector3.new(0.26, s.Y * 0.9, 0.05),
			CFrame.new(side * s.X * 0.14, 0, -(s.Z / 2 + 0.1)) * CFrame.Angles(0, 0, math.rad(side * 18)), TRIM)
	end
	attach(outfit, torso, "Collar", Vector3.new(s.X * 0.8, 0.22, s.Z * 0.55), CFrame.new(0, s.Y / 2 + 0.03, s.Z * 0.28), TRIM)
end

-- A tied belt at height y on a torso part.
local function belt(outfit, torso, y)
	local s = torso.Size
	local front = -(s.Z / 2 + 0.12)
	attach(outfit, torso, "Belt", Vector3.new(s.X + 0.22, 0.16, s.Z + 0.22), CFrame.new(0, y, 0), TRIM)
	attach(outfit, torso, "BeltKnot", Vector3.new(0.28, 0.28, 0.12), CFrame.new(s.X * 0.22, y, front), TRIM)
	attach(outfit, torso, "BeltTail", Vector3.new(0.12, 0.5, 0.06), CFrame.new(s.X * 0.18, y - 0.32, front) * CFrame.Angles(0, 0, math.rad(8)), TRIM)
	attach(outfit, torso, "BeltTail", Vector3.new(0.12, 0.42, 0.06), CFrame.new(s.X * 0.28, y - 0.28, front) * CFrame.Angles(0, 0, math.rad(-12)), TRIM)
end

-- Fluffy slipper around a foot; bottomY is the sole's height in the limb's space.
local function slipper(outfit, limb, size, bottomY, forward)
	local center = bottomY + size.Y / 2
	attach(outfit, limb, "Slipper", size, CFrame.new(0, center, -forward), SLIPPER)
	attach(outfit, limb, "SlipperPom", Vector3.new(0.34, 0.34, 0.34),
		CFrame.new(0, bottomY + size.Y, -(size.Z / 2 + forward) + 0.2), POM, Enum.PartType.Ball)
end

local function dressR15(outfit, character)
	local function limb(name) return character:WaitForChild(name, 5) end
	local upper, lower = limb("UpperTorso"), limb("LowerTorso")
	if upper then robeTop(outfit, upper) end
	if lower then
		attach(outfit, lower, "Robe", lower.Size + Vector3.new(0.18, 0.06, 0.18), CFrame.new(), ROBE)
		belt(outfit, lower, lower.Size.Y / 2 - 0.08)
	end
	for _, side in {"Left", "Right"} do
		local upperArm, lowerArm = limb(side .. "UpperArm"), limb(side .. "LowerArm")
		if upperArm then attach(outfit, upperArm, "Sleeve", upperArm.Size + Vector3.new(0.12, 0.02, 0.12), CFrame.new(), ROBE) end
		if lowerArm then
			local s = lowerArm.Size
			attach(outfit, lowerArm, "Sleeve", s + Vector3.new(0.14, 0, 0.14), CFrame.new(), ROBE)
			attach(outfit, lowerArm, "Cuff", Vector3.new(s.X + 0.2, 0.16, s.Z + 0.2), CFrame.new(0, -s.Y / 2 + 0.1, 0), TRIM)
		end
		-- The robe hangs to the knees.
		local upperLeg = limb(side .. "UpperLeg")
		if upperLeg then attach(outfit, upperLeg, "RobeSkirt", upperLeg.Size + Vector3.new(0.18, 0, 0.18), CFrame.new(), ROBE) end
		local foot = limb(side .. "Foot")
		if foot then
			local s = foot.Size
			slipper(outfit, foot, Vector3.new(s.X + 0.2, s.Y + 0.16, s.Z + 0.3), -s.Y / 2 - 0.04, 0.08)
		end
	end
end

local function dressR6(outfit, character)
	local torso = character:WaitForChild("Torso", 5)
	if torso then
		robeTop(outfit, torso)
		belt(outfit, torso, -torso.Size.Y * 0.22)
	end
	for _, side in {"Left", "Right"} do
		local arm = character:WaitForChild(side .. " Arm", 5)
		if arm then
			local s = arm.Size
			attach(outfit, arm, "Sleeve", Vector3.new(s.X + 0.12, s.Y * 0.78, s.Z + 0.12), CFrame.new(0, s.Y * 0.11, 0), ROBE)
			attach(outfit, arm, "Cuff", Vector3.new(s.X + 0.18, 0.16, s.Z + 0.18), CFrame.new(0, s.Y * 0.11 - s.Y * 0.39, 0), TRIM)
		end
		local leg = character:WaitForChild(side .. " Leg", 5)
		if leg then
			local s = leg.Size
			attach(outfit, leg, "RobeSkirt", Vector3.new(s.X + 0.12, s.Y * 0.5, s.Z + 0.14), CFrame.new(0, s.Y * 0.25, 0), ROBE)
			slipper(outfit, leg, Vector3.new(s.X + 0.14, 0.42, s.Z + 0.32), -s.Y / 2 - 0.04, 0.12)
		end
	end
end

local function dress(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	-- Wait (briefly) for the avatar's scaling so the outfit matches its size.
	local started = os.clock()
	while not player:HasAppearanceLoaded() and os.clock() - started < 6 do task.wait(0.2) end
	if not character.Parent then return end
	local old = character:FindFirstChild("CozyOutfit")
	if old then old:Destroy() end
	local outfit = Instance.new("Model")
	outfit.Name = "CozyOutfit"
	outfit.Parent = character
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		dressR15(outfit, character)
	else
		dressR6(outfit, character)
	end
end

local function watch(player)
	player.CharacterAdded:Connect(function(character) dress(player, character) end)
	if player.Character then task.spawn(dress, player, player.Character) end
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do task.spawn(watch, player) end
