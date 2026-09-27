-- A short procedural sofa pose that works with the current R6 or R15 avatar.
local RunService = game:GetService("RunService")
local TVAction = {}

function TVAction.play(player, duration, screen)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or not screen then return end
	local camera = workspace.CurrentCamera
	local savedCamera = {kind = camera.CameraType, subject = camera.CameraSubject, cf = camera.CFrame, fov = camera.FieldOfView}
	local joints = {}
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") then joints[joint] = joint.C0 end
	end
	local animate = character:FindFirstChild("Animate")
	local animateWasEnabled = animate and animate.Enabled
	local function restore()
		for joint, cf in joints do if joint.Parent then joint.C0 = cf end end
		if animate and animate.Parent then animate.Enabled = animateWasEnabled end
		camera.CameraType = savedCamera.kind
		camera.CameraSubject = if player.Character ~= character and player.Character then player.Character:FindFirstChildOfClass("Humanoid") else savedCamera.subject
		camera.CFrame = savedCamera.cf
		camera.FieldOfView = savedCamera.fov
	end
	local ok, err = xpcall(function()
		if animate then animate.Enabled = false end
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then for _, track in animator:GetPlayingAnimationTracks() do track:Stop(0.1) end end
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 58
		local began = os.clock()
		while os.clock() - began < duration and character.Parent and humanoid.Health > 0 and player.Character == character do
			local t = os.clock() - began
			for joint, cf in joints do
				local name = joint.Name:gsub(" ", "")
				local angle = CFrame.identity
				if name == "Neck" then angle = CFrame.Angles(0, math.sin(t * 1.8) * 0.04, 0)
				elseif name == "RightShoulder" then angle = CFrame.Angles(math.rad(35), 0, math.rad(-10))
				elseif name == "LeftShoulder" then angle = CFrame.Angles(math.rad(30), 0, math.rad(10))
				elseif name == "RightElbow" or name == "LeftElbow" then angle = CFrame.Angles(math.rad(-45), 0, 0)
				elseif name == "RightHip" or name == "LeftHip" then angle = CFrame.Angles(math.rad(65), 0, 0)
				elseif name == "RightKnee" or name == "LeftKnee" then angle = CFrame.Angles(math.rad(-65), 0, 0) end
				joint.C0 = cf * angle
			end
			local focus = (root.Position + screen.Position) / 2 + Vector3.new(0, 1.5, 0)
			local side = root.CFrame.RightVector * 7 + Vector3.new(0, 3, 0)
			camera.CFrame = CFrame.lookAt(root.Position + side, focus)
			RunService.RenderStepped:Wait()
		end
	end, debug.traceback)
	restore()
	if not ok then warn("TV action restored after error:", err) end
end

return TVAction
