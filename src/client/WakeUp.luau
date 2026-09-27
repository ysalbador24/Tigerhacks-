-- Morning wake-up before Barb's report: the alarm rings, sunrise light fills
-- the room, and the avatar (lying in bed) sits up. Local presentation only;
-- the character's position and camera are restored when it ends.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local WakeUp = {}
WakeUp.DURATION = 3.6

local function alarmSound(parent)
	local ok, ids = pcall(function() return require(ReplicatedStorage.Shared.GameSounds) end)
	local id = ok and type(ids) == "table" and ids.AlarmClock
	if type(id) == "string" and id ~= "" then
		local s = Instance.new("Sound"); s.SoundId = id; s.Volume = 0.7; s.Parent = parent; s:Play()
		task.delay(WakeUp.DURATION, function() s:Destroy() end)
		return
	end
	-- Built-in fallback: two bursts of quick beeps.
	for burst = 0, 1 do
		for beep = 0, 3 do
			task.delay(burst * 0.9 + beep * 0.14, function()
				if not parent.Parent then return end
				local s = Instance.new("Sound"); s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
				s.Volume = 0.5; s.PlaybackSpeed = 1.6; s.Parent = parent; s:Play()
				task.delay(1, function() s:Destroy() end)
			end)
		end
	end
end

-- Starts the sequence and returns how long to wait before showing the report.
function WakeUp.play(player)
	task.spawn(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "WakeUpAlarm"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9; gui.IgnoreGuiInset = true
		gui.Parent = player:WaitForChild("PlayerGui")

		-- Sunrise: start at dawn with a warm tint that fades to normal daylight.
		-- (Same end values as the morning tween, so either one finishing looks right.)
		Lighting.ClockTime = 5.6
		TweenService:Create(Lighting, TweenInfo.new(WakeUp.DURATION + 1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ClockTime = 7.2, Brightness = 2, Ambient = Color3.fromRGB(150, 140, 130)}):Play()
		local tint = Instance.new("ColorCorrectionEffect")
		tint.Name = "WakeUpSunrise"; tint.TintColor = Color3.fromRGB(255, 196, 150); tint.Brightness = 0.06; tint.Parent = Lighting
		TweenService:Create(tint, TweenInfo.new(WakeUp.DURATION + 1.5), {TintColor = Color3.new(1, 1, 1), Brightness = 0}):Play()
		task.delay(WakeUp.DURATION + 1.6, function() tint:Destroy() end)

		-- Alarm clock: ringing label plus sound.
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5); label.Position = UDim2.fromScale(0.5, 0.22); label.Size = UDim2.fromScale(0.5, 0.12)
		label.BackgroundTransparency = 1; label.Text = "⏰ 7:00 AM"; label.TextScaled = true; label.Font = Enum.Font.FredokaOne
		label.TextColor3 = Color3.fromRGB(255, 236, 200); label.TextStrokeTransparency = 0.4; label.Parent = gui
		alarmSound(gui)
		task.spawn(function()
			local started = os.clock()
			while os.clock() - started < 1.9 and label.Parent do
				label.Rotation = math.sin((os.clock() - started) * 40) * 6
				task.wait()
			end
			label.Rotation = 0
			TweenService:Create(label, TweenInfo.new(0.6), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		end)

		-- Lying in bed, then sitting up.
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local room = workspace:FindFirstChild("CozyBedroom101")
		local anchors = room and room:FindFirstChild("LayoutAnchors")
		local bed = anchors and anchors:FindFirstChild("BedSleepTarget")
		local camera = workspace.CurrentCamera
		local saved
		if root and humanoid and bed and bed:IsA("BasePart") then
			saved = {cframe = root.CFrame, anchored = root.Anchored, cameraType = camera.CameraType, subject = camera.CameraSubject}
			root.Anchored = true
			local upright = bed.CFrame * CFrame.new(0, 2.2, 0)
			root.CFrame = bed.CFrame * CFrame.new(0, 0.9, 0) * CFrame.Angles(math.rad(90), 0, 0)
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.lookAt(bed.Position + bed.CFrame.RightVector * 8 + Vector3.new(0, 4.5, 0), bed.Position + Vector3.new(0, 1, 0))
			task.delay(1.9, function()
				if root.Parent then
					TweenService:Create(root, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = upright}):Play()
				end
			end)
		end

		task.wait(WakeUp.DURATION)
		gui:Destroy()
		if saved then
			if root.Parent then root.CFrame = saved.cframe; root.Anchored = saved.anchored end
			camera.CameraType = saved.cameraType
			camera.CameraSubject = saved.subject
		end
	end)
	return WakeUp.DURATION
end

return WakeUp
