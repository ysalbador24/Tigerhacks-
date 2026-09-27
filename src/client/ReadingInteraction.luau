local RunService = game:GetService("RunService")

local ReadingInteraction = {}

-- Sleep facts adapted from https://www.cdc.gov/sleep/about/
local chapters = {
	{title = "A steady rhythm", fact = "Going to bed and waking up at consistent times is a helpful sleep habit, including on weekends.", question = "Which habit supports a regular sleep schedule?", choices = {"Keep a consistent wake-up time", "Change bedtime every night"}, correct = 1},
	{title = "Let screens rest", fact = "The CDC recommends switching off electronic devices at least 30 minutes before bedtime.", question = "What belongs in your wind-down routine?", choices = {"One more video in bed", "Put the screen away before bed"}, correct = 2},
	{title = "A peaceful room", fact = "A quiet, relaxing bedroom at a cool temperature can help support sleep.", question = "Which room would you choose for sleep?", choices = {"Cool and quiet", "Hot with a loud TV"}, correct = 1},
	{title = "Think about drinks", fact = "Avoiding caffeine in the afternoon and evening is a helpful sleep habit.", question = "Which is the better evening choice?", choices = {"An energy drink", "Water instead of caffeine"}, correct = 2},
}

local function openBook(player, onClose)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SleepHabitBook"
	gui.DisplayOrder = 15
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local ink = Color3.fromRGB(65, 53, 43)
	local paper = Color3.fromRGB(255, 245, 222)
	local green = Color3.fromRGB(43, 76, 65)
	local gold = Color3.fromRGB(184, 150, 88)
	local function panel(parent, position, size, color)
		local frame = Instance.new("Frame")
		frame.Position = position; frame.Size = size; frame.BackgroundColor3 = color
		frame.BorderSizePixel = 0; frame.Parent = parent
		return frame
	end
	local function text(parent, value, position, size, isButton)
		local item = Instance.new(if isButton then "TextButton" else "TextLabel")
		item.Position = position; item.Size = size; item.Text = value
		item.Font = Enum.Font.Garamond; item.TextColor3 = ink
		item.TextScaled = true; item.TextWrapped = true; item.BorderSizePixel = 0
		item.BackgroundTransparency = if isButton then 0 else 1
		item.BackgroundColor3 = Color3.fromRGB(233, 220, 190)
		item.Parent = parent
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = if isButton then 23 else 28
		limit.Parent = item
		if isButton then
			Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
		end
		return item
	end
	local backdrop = panel(gui, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(16, 24, 23))
	backdrop.Active = true
	backdrop.BackgroundTransparency = 0.16
	local cover = panel(backdrop, UDim2.fromScale(0.5, 0.49), UDim2.fromScale(0.78, 0.64), green)
	cover.AnchorPoint = Vector2.new(0.5, 0.5)
	local bounds = Instance.new("UISizeConstraint", cover)
	bounds.MaxSize = Vector2.new(840, 520)
	Instance.new("UICorner", cover).CornerRadius = UDim.new(0, 12)
	local trim = Instance.new("UIStroke", cover)
	trim.Color = gold; trim.Thickness = 2
	-- Subtle woven cover, stacked signatures, and an inset sewn binding.
	for line = 1, 45 do
		local grain = panel(cover, UDim2.fromScale(0.01, line / 46), UDim2.new(0.98, 0, 0, 1), gold)
		grain.BackgroundTransparency = 0.92
	end
	for layer = 7, 1, -1 do
		panel(cover, UDim2.new(0.018, 0, 0.026, layer * 1.3), UDim2.fromScale(0.964, 0.94),
			if layer % 2 == 0 then Color3.fromRGB(189, 172, 140) else Color3.fromRGB(234, 220, 192))
	end
	local left = panel(cover, UDim2.fromScale(0.02, 0.025), UDim2.fromScale(0.48, 0.94), paper)
	local right = panel(cover, UDim2.fromScale(0.5, 0.025), UDim2.fromScale(0.48, 0.94), paper)
	local function shade(sheet, reverse)
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(166, 147, 112)),
			ColorSequenceKeypoint.new(0.045, Color3.fromRGB(222, 209, 184)),
			ColorSequenceKeypoint.new(0.18, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(232, 221, 199)),
		})
		gradient.Rotation = if reverse then 180 else 0
		gradient.Parent = sheet
	end
	shade(left, true); shade(right, false)
	local spine = panel(cover, UDim2.fromScale(0.498, 0.025), UDim2.fromScale(0.004, 0.94), Color3.fromRGB(130, 108, 77))
	spine.ZIndex = 2
	local ribbon = panel(cover, UDim2.fromScale(0.49, 0.91), UDim2.fromScale(0.02, 0.12), Color3.fromRGB(150, 66, 49))
	ribbon.ZIndex = 3
	local spread = 1
	local learned = {}
	local turning, destroyed = false, false
	local turnConnection
	for _, sheet in {left, right} do
		text(sheet, "THE LITTLE BOOK OF GOOD SLEEP", UDim2.fromScale(0.08, 0.025), UDim2.fromScale(0.84, 0.045))
		panel(sheet, UDim2.fromScale(0.08, 0.085), UDim2.new(0.84, 0, 0, 1), gold)
	end
	local heading = text(left, "", UDim2.fromScale(0.09, 0.16), UDim2.fromScale(0.82, 0.14))
	local fact = text(left, "", UDim2.fromScale(0.09, 0.34), UDim2.fromScale(0.82, 0.38))
	text(left, "Adapted from CDC • About Sleep\ncdc.gov/sleep/about", UDim2.fromScale(0.09, 0.86), UDim2.fromScale(0.82, 0.08))
	text(right, "QUICK QUIZ", UDim2.fromScale(0.09, 0.12), UDim2.fromScale(0.82, 0.09))
	local question = text(right, "", UDim2.fromScale(0.09, 0.24), UDim2.fromScale(0.82, 0.2))
	local choices = {}
	for index = 1, 2 do
		choices[index] = text(right, "", UDim2.fromScale(0.09, 0.49 + (index - 1) * 0.16), UDim2.fromScale(0.82, 0.13), true)
	end
	local feedback = text(right, "", UDim2.fromScale(0.09, 0.82), UDim2.fromScale(0.82, 0.12))
	local previous = text(backdrop, "‹ Previous", UDim2.fromScale(0.05, 0.92), UDim2.fromScale(0.2, 0.055), true)
	local progress = text(backdrop, "", UDim2.fromScale(0.27, 0.92), UDim2.fromScale(0.46, 0.055))
	progress.TextColor3 = paper
	local nextPage = text(backdrop, "Next ›", UDim2.fromScale(0.75, 0.92), UDim2.fromScale(0.2, 0.055), true)
	local close = text(backdrop, "Choose again ×", UDim2.fromScale(0.76, 0.012), UDim2.fromScale(0.19, 0.055), true)
	local function render()
		local count = 0
		for _ in learned do count += 1 end
		local chapter = chapters[spread]
		heading.Text = chapter.title
		fact.Text = chapter.fact
		question.Text = chapter.question
		for index, button in choices do
			button.Text = chapter.choices[index]
			button.BackgroundColor3 = if learned[spread] and index == chapter.correct then Color3.fromRGB(181, 208, 175) else Color3.fromRGB(233, 220, 190)
		end
		feedback.Text = if learned[spread] then "✓ Correct. Keep this habit in mind." else "Pick an answer to check your understanding."
		progress.Text = if count == #chapters then "All habits learned • Sweet dreams!" else count .. " / " .. #chapters .. " habits learned"
		previous.Visible = spread > 1
		nextPage.Text = if spread == #chapters then "Keep reading ↺" else "Turn page ›"
	end
	local function turnPage(target)
		if turning or destroyed or target == spread then return end
		turning = true
		local forward = target > spread
		local source = if forward then right else left
		-- Keep the old spread beneath the turning leaf; reveal the destination
		-- only on the side being uncovered. Each strip projects a curved paper surface.
		local oldLeft, oldRight = left:Clone(), right:Clone()
		oldLeft.Parent = cover; oldRight.Parent = cover
		spread = target
		render()
		local front = (if forward then oldRight else oldLeft):Clone()
		local back = (if forward then left else right):Clone()
		if forward then oldRight:Destroy() else oldLeft:Destroy() end
		local leaf = panel(cover, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), paper)
		leaf.BackgroundTransparency = 1; leaf.ZIndex = 5
		local strips = {}
		local stripCount = 18
		local width, height = source.AbsoluteSize.X, source.AbsoluteSize.Y
		for i = 1, stripCount do
			local clip = panel(leaf, UDim2.new(), UDim2.new(), paper)
			clip.ClipsDescendants = true
			local faces = {}
			for face, template in {front, back} do
				local copy = template:Clone()
				copy.AnchorPoint = Vector2.zero
				copy.Size = UDim2.fromOffset(width, height)
				copy.Parent = clip
				for _, item in copy:GetDescendants() do
					if item:IsA("GuiButton") then item.Interactable = false end
				end
				faces[face] = copy
			end
			strips[i] = {clip = clip, faces = faces}
		end
		front:Destroy(); back:Destroy()
		local started = os.clock()
		turnConnection = RunService.RenderStepped:Connect(function()
			local t = math.min((os.clock() - started) / 0.85, 1)
			local angle = math.pi * (0.5 - 0.5 * math.cos(t * math.pi))
			local reverse = angle > math.pi / 2
			local direction = if forward then 1 else -1
			for i, strip in strips do
				local u0, u1 = (i - 1) / stripCount, i / stripCount
				local function project(u)
					return direction * width * (u * math.cos(angle) + 0.12 * math.sin(math.pi * u) * math.sin(angle))
				end
				local x0, x1 = project(u0), project(u1)
				local lift = math.sin(angle) * math.sin((u0 + u1) * math.pi / 4) * height * 0.035
				strip.clip.Position = UDim2.new(0.5, math.min(x0, x1), 0.025, -lift)
				strip.clip.Size = UDim2.fromOffset(math.max(0.1, math.abs(x1 - x0)) + 0.5, height + lift * 2)
				for face, copy in strip.faces do
					copy.Visible = (face == 2) == reverse
					local fromLeft = if (forward ~= reverse) then u0 else 1 - u1
					local projectedWidth = strip.clip.Size.X.Offset * stripCount
					copy.Size = UDim2.fromOffset(projectedWidth, height + lift * 2)
					copy.Position = UDim2.fromOffset(-fromLeft * projectedWidth, 0)
					local brightness = 1 - 0.22 * math.sin(angle) * (1 - u0)
					copy.BackgroundColor3 = paper:Lerp(Color3.fromRGB(147, 130, 103), 1 - brightness)
				end
			end
			if t >= 1 then
				turnConnection:Disconnect(); turnConnection = nil
				leaf:Destroy(); oldLeft:Destroy(); oldRight:Destroy()
				turning = false
			end
		end)
	end
	for index, button in choices do
		button.Activated:Connect(function()
			if turning or destroyed then return end
			if index == chapters[spread].correct then learned[spread] = true; render()
				-- Stats page: which CDC facts players learned (optional, see Bedtime.server).
				local fact = game:GetService("ReplicatedStorage"):FindFirstChild("ReadingFact"); if fact then fact:FireServer(spread) end
			else feedback.Text = "Try again — the left page has a clue." end
		end)
	end
	previous.Activated:Connect(function() turnPage(math.max(1, spread - 1)) end)
	nextPage.Activated:Connect(function()
		if turning or destroyed then return end
		if spread == #chapters then turnPage(1) else turnPage(spread + 1) end
	end)
	close.Activated:Connect(onClose)
	gui.Destroying:Connect(function()
		destroyed = true
		if turnConnection then turnConnection:Disconnect(); turnConnection = nil end
	end)
	render()
	return gui
end

ReadingInteraction.openBook = openBook

-- Local presentation, like the other evening activities; no animation asset required.
function ReadingInteraction.start(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	if not humanoid or not torso then return nil end
	local camera = workspace.CurrentCamera
	local cameraType, cameraFrame = camera.CameraType, camera.CFrame
	local speed, jumpPower, jumpHeight, autoRotate = humanoid.WalkSpeed, humanoid.JumpPower, humanoid.JumpHeight, humanoid.AutoRotate
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	camera.CameraType = Enum.CameraType.Scriptable
	local book = Instance.new("Model")
	book.Name = "ReadingBook"
	book.Parent = workspace
	local pieces = {}
	local function piece(name, size, offset, color)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = book
		table.insert(pieces, {part = part, offset = offset})
		return part
	end
	for _, side in {-1, 1} do
		local offset = CFrame.new(side * 0.48, 0, 0) * CFrame.Angles(0, 0, side * math.rad(8))
		piece("Cover", Vector3.new(0.98, 0.09, 1.3), offset, Color3.fromRGB(62, 103, 89))
		piece("Pages", Vector3.new(0.89, 0.09, 1.19), offset * CFrame.new(0, 0.08, 0), Color3.fromRGB(249, 237, 208))
		for line = 1, 7 do
			piece("PrintedLine", Vector3.new(if line == 7 then 0.39 else 0.65, 0.006, 0.018), offset * CFrame.new(0, 0.129, -0.46 + line * 0.115), Color3.fromRGB(105, 94, 78))
		end
	end
	piece("Spine", Vector3.new(0.12, 0.12, 1.3), CFrame.new(), Color3.fromRGB(46, 78, 68))
	local joints = {}
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") and (joint.Name == "LeftShoulder" or joint.Name == "RightShoulder" or joint.Name == "Left Shoulder" or joint.Name == "Right Shoulder") then
			table.insert(joints, {joint = joint, c0 = joint.C0, transform = joint.Transform, side = if string.find(joint.Name, "Left") then -1 else 1})
		end
	end
	local stopped = false
	local connection
	local deathConnection
	local removingConnection
	local bookGui
	local function stop()
		if stopped then return end
		stopped = true
		if connection then connection:Disconnect() end
		if deathConnection then deathConnection:Disconnect() end
		if removingConnection then removingConnection:Disconnect() end
		book:Destroy()
		if bookGui then bookGui:Destroy() end
		for _, saved in joints do
			if saved.joint.Parent then saved.joint.C0 = saved.c0; saved.joint.Transform = saved.transform end
		end
		if humanoid.Parent then
			humanoid.WalkSpeed = speed; humanoid.JumpPower = jumpPower; humanoid.JumpHeight = jumpHeight; humanoid.AutoRotate = autoRotate
		end
		camera.CameraType = cameraType
		camera.CFrame = cameraFrame
	end
	bookGui = openBook(player, stop)
	local started = os.clock()
	connection = RunService.PreSimulation:Connect(function()
		if not torso.Parent then stop(); return end
		local sway = math.sin((os.clock() - started) * 1.8) * 0.025
		local bookFrame = torso.CFrame * CFrame.new(0, -0.5 + sway, -1.45) * CFrame.Angles(math.rad(20), 0, 0)
		for _, item in pieces do item.part.CFrame = bookFrame * item.offset end
		for _, saved in joints do
			local joint = saved.joint
			if joint.Part0 then
				local shoulder = joint.Part0.CFrame * saved.c0
				local target = bookFrame:PointToWorldSpace(Vector3.new(saved.side * 0.85, -0.1, 0.25))
				local pose = CFrame.lookAt(shoulder.Position, target, torso.CFrame.UpVector) * CFrame.Angles(math.pi / 2, 0, 0)
				joint.C0 = joint.Part0.CFrame:ToObjectSpace(pose * joint.C1.Rotation)
				joint.Transform = CFrame.identity
			end
		end
		local focus = torso.Position + torso.CFrame.LookVector * 0.5
		camera.CFrame = CFrame.lookAt(torso.CFrame:PointToWorldSpace(Vector3.new(4, 2.4, -6)), focus)
	end)
	deathConnection = humanoid.Died:Connect(stop)
	removingConnection = player.CharacterRemoving:Connect(stop)
	return {stop = stop, isActive = function() return not stopped end}
end

return ReadingInteraction
