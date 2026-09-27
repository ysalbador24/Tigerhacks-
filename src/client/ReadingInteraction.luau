local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
	local green = Color3.fromRGB(48, 83, 70)
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
		item.BackgroundColor3 = Color3.fromRGB(225, 212, 181)
		item.Parent = parent
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = if isButton then 25 else 34
		limit.Parent = item
		return item
	end
	local backdrop = panel(gui, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Color3.fromRGB(20, 30, 29))
	backdrop.Active = true
	backdrop.BackgroundTransparency = 0.25
	local shadow = panel(backdrop, UDim2.fromScale(0.5, 0.515), UDim2.fromScale(0.86, 0.8), Color3.fromRGB(10, 17, 15))
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 0.45
	Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 18)
	local cover = panel(backdrop, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.86, 0.8), green)
	cover.AnchorPoint = Vector2.new(0.5, 0.5)
	Instance.new("UICorner", cover).CornerRadius = UDim.new(0, 16)
	for layer = 3, 1, -1 do
		local edge = panel(cover, UDim2.new(0.015, 0, 0.025, layer * 2), UDim2.fromScale(0.97, 0.95), Color3.fromRGB(216 + layer * 5, 202 + layer * 5, 176 + layer * 5))
		edge.Name = "PageEdge"
	end
	local left = panel(cover, UDim2.fromScale(0.015, 0.025), UDim2.fromScale(0.48, 0.95), Color3.fromRGB(248, 237, 212))
	local right = panel(cover, UDim2.fromScale(0.505, 0.025), UDim2.fromScale(0.48, 0.95), Color3.fromRGB(255, 246, 225))
	for _, sheet in {left, right} do
		local shading = Instance.new("UIGradient")
		shading.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(207, 193, 167)),
			ColorSequenceKeypoint.new(0.12, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
		})
		shading.Rotation = if sheet == left then 180 else 0
		shading.Parent = sheet
	end
	panel(cover, UDim2.fromScale(0.493, 0.025), UDim2.fromScale(0.012, 0.95), Color3.fromRGB(183, 160, 121))
	text(left, "THE LITTLE BOOK OF GOOD SLEEP", UDim2.fromScale(0.08, 0.05), UDim2.fromScale(0.84, 0.08))
	local heading = text(left, "", UDim2.fromScale(0.08, 0.2), UDim2.fromScale(0.84, 0.16))
	local fact = text(left, "", UDim2.fromScale(0.09, 0.4), UDim2.fromScale(0.82, 0.34))
	text(left, "Sleep facts: CDC • About Sleep", UDim2.fromScale(0.08, 0.81), UDim2.fromScale(0.84, 0.05))
	local previous = text(left, "< Previous", UDim2.fromScale(0.08, 0.9), UDim2.fromScale(0.4, 0.07), true)
	local progress = text(right, "", UDim2.fromScale(0.08, 0.05), UDim2.fromScale(0.58, 0.08))
	local close = text(right, "Close", UDim2.fromScale(0.73, 0.04), UDim2.fromScale(0.22, 0.08), true)
	local question = text(right, "", UDim2.fromScale(0.08, 0.2), UDim2.fromScale(0.84, 0.19))
	local choices = {}
	for index = 1, 2 do
		choices[index] = text(right, "", UDim2.fromScale(0.08, 0.42 + (index - 1) * 0.15), UDim2.fromScale(0.84, 0.12), true)
	end
	local feedback = text(right, "", UDim2.fromScale(0.08, 0.72), UDim2.fromScale(0.84, 0.14))
	local nextPage = text(right, "Next >", UDim2.fromScale(0.52, 0.9), UDim2.fromScale(0.4, 0.07), true)
	local leftNumber = text(left, "", UDim2.fromScale(0.46, 0.91), UDim2.fromScale(0.1, 0.05))
	local rightNumber = text(right, "", UDim2.fromScale(0.44, 0.91), UDim2.fromScale(0.1, 0.05))
	local page = 1
	local learned = {}
	local turning = false
	local destroyed = false
	local activeTween
	gui.Destroying:Connect(function()
		destroyed = true
		if activeTween then activeTween:Cancel() end
	end)
	local function render()
		local chapter = chapters[page]
		heading.Text = chapter.title; fact.Text = chapter.fact; question.Text = chapter.question
		local count = 0
		for _ in learned do count += 1 end
		progress.Text = "Chapter " .. page .. " / " .. #chapters .. " • " .. count .. " learned"
		for index, button in choices do button.Text = chapter.choices[index] end
		feedback.Text = if count == #chapters then "All four habits learned! Sweet dreams." elseif learned[page] then "Correct! A good habit to remember." else "Read the page, then pick a habit."
		previous.Visible = page > 1
		nextPage.Text = if page == #chapters then "Finish reading" else "Next >"
		leftNumber.Text = tostring(page * 2 - 1)
		rightNumber.Text = tostring(page * 2)
	end
	local function turnPage(target)
		if turning or destroyed or target == page then return end
		turning = true
		local forward = target > page
		-- Clip a full-size sheet as it pivots toward the spine, then unfold its reverse.
		local flap = panel(cover, UDim2.fromScale(if forward then 0.505 else 0.495, 0.025), UDim2.fromScale(0.48, 0.95), right.BackgroundColor3)
		flap.AnchorPoint = Vector2.new(if forward then 0 else 1, 0)
		flap.ClipsDescendants = true
		flap.ZIndex = 5
		flap.Active = true
		local function copySheet(source, anchor)
			local copy = source:Clone()
			copy.AnchorPoint = Vector2.new(anchor, 0)
			copy.Position = UDim2.fromScale(anchor, 0)
			copy.Size = UDim2.fromOffset(source.AbsoluteSize.X, source.AbsoluteSize.Y)
			copy.Parent = flap
			for _, item in copy:GetDescendants() do
				if item:IsA("GuiButton") then item.Interactable = false end
			end
			return copy
		end
		local front = copySheet(if forward then right else left, if forward then 0 else 1)
		local function animate(width, direction)
			activeTween = TweenService:Create(flap, TweenInfo.new(0.22, Enum.EasingStyle.Sine, direction), {Size = UDim2.fromScale(width, 0.95)})
			activeTween:Play()
			activeTween.Completed:Wait()
			activeTween = nil
		end
		animate(0, Enum.EasingDirection.In)
		if destroyed then return end
		front:Destroy()
		page = target
		render()
		flap.AnchorPoint = Vector2.new(if forward then 1 else 0, 0)
		flap.Position = UDim2.fromScale(if forward then 0.495 else 0.505, 0.025)
		copySheet(if forward then left else right, if forward then 1 else 0)
		animate(0.48, Enum.EasingDirection.Out)
		if destroyed then return end
		flap:Destroy()
		turning = false
	end
	for index, button in choices do
		button.Activated:Connect(function()
			if turning or destroyed then return end
			if index == chapters[page].correct then learned[page] = true; render()
			else feedback.Text = "Try again! The facing page has a clue." end
		end)
	end
	previous.Activated:Connect(function() turnPage(math.max(1, page - 1)) end)
	nextPage.Activated:Connect(function()
		if turning or destroyed then return end
		if page == #chapters then onClose() else turnPage(page + 1) end
	end)
	close.Activated:Connect(onClose)
	render()
	return gui
end

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
