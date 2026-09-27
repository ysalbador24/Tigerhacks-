-- Procedural R6/R15 pose using the current avatar; no uploaded animation required.
local RunService = game:GetService("RunService")
local ReadingInteraction = require(script.Parent:WaitForChild("ReadingInteraction"))
local PhoneInteraction = require(script.Parent:WaitForChild("PhoneInteraction"))
local Action = {}
function Action.play(player, option, phone)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end
	local camera = workspace.CurrentCamera
	local savedCamera = {kind=camera.CameraType, subject=camera.CameraSubject, cf=camera.CFrame, fov=camera.FieldOfView}
	local savedPhone = phone.CFrame
	local joints = {}
	for _,joint in character:GetDescendants() do
		if joint:IsA("Motor6D") then joints[joint] = joint.C0 end
	end
	local props = Instance.new("Model"); props.Name="WindDownHeldBook"; props.Parent=workspace
	local function piece(name,size,color)
		local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Color=color; p.Anchored=true
		p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Material=Enum.Material.SmoothPlastic; p.Parent=props
		return p
	end
	local room=workspace:FindFirstChild("CozyBedroom101")
	local existingBook=room and room:FindFirstChild("ReadingBook",true)
	local coverColor=if existingBook and existingBook:IsA("BasePart") then existingBook.Color else Color3.fromRGB(158,175,153)
	local left,right,page
	if option==1 then
		left=piece("LeftOpenPage",Vector3.new(0.8,0.12,1.1),Color3.fromRGB(247,233,212))
		right=piece("RightOpenPage",left.Size, left.Color)
		page=piece("TurningPage",Vector3.new(0.75,0.025,1.05),Color3.fromRGB(255,247,227))
		piece("BookCover",Vector3.new(1.7,0.12,1.18),coverColor)
	end
	local light
	if option==2 then
		light=Instance.new("PointLight"); light.Name="WindDownScreenGlow"; light.Color=Color3.fromRGB(188,214,235)
		light.Brightness=0.3; light.Range=4; light.Parent=phone
	end
	local animate=character:FindFirstChild("Animate")
	local animateWasEnabled=animate and animate.Enabled
	local activityGui
	local function restore()
		if activityGui then activityGui:Destroy(); activityGui=nil end
		for joint,cf in joints do if joint.Parent then joint.C0=cf end end
		if animate and animate.Parent then animate.Enabled=animateWasEnabled end
		if light then light:Destroy() end
		if phone.Parent then phone.CFrame=savedPhone end
		props:Destroy()
		camera.CameraType=savedCamera.kind
		camera.CameraSubject=if player.Character~=character and player.Character then player.Character:FindFirstChildOfClass("Humanoid") else savedCamera.subject
		camera.CFrame=savedCamera.cf; camera.FieldOfView=savedCamera.fov
	end
	local ok,err=xpcall(function()
		if option==1 then
			activityGui=ReadingInteraction.openBook(player,function()
				if activityGui then activityGui:Destroy(); activityGui=nil end
			end)
		else
			activityGui=PhoneInteraction.open(player)
		end
		if animate then animate.Enabled=false end
		local animator=humanoid:FindFirstChildOfClass("Animator")
		if animator then for _,track in animator:GetPlayingAnimationTracks() do track:Stop(0.1) end end
		camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=55
		local began=os.clock()
		while activityGui and activityGui.Parent and character.Parent and humanoid.Health>0 and player.Character==character do
			local t=os.clock()-began
			local scroll=math.sin(t*6)*0.08
			for joint,cf in joints do
				local name=joint.Name:gsub(" ","")
				local angle=CFrame.identity
				local r6=humanoid.RigType==Enum.HumanoidRigType.R6
				if r6 and (name=="RightShoulder" or name=="RightHip") then angle=CFrame.Angles(0,0,math.rad(65)+scroll)
				elseif r6 and (name=="LeftShoulder" or name=="LeftHip") then angle=CFrame.Angles(0,0,math.rad(-65))
				elseif name=="RightShoulder" then angle=CFrame.Angles(math.rad(65)+scroll,0,math.rad(-18))
				elseif name=="LeftShoulder" then angle=CFrame.Angles(math.rad(60),0,math.rad(18))
				elseif name=="RightElbow" or name=="LeftElbow" then angle=CFrame.Angles(math.rad(-35),0,0)
				elseif name=="RightWrist" then angle=CFrame.Angles(scroll,0,0)
				elseif name=="Neck" then angle=CFrame.Angles(math.rad(-15),0,0)
				elseif name=="RightHip" or name=="LeftHip" then angle=CFrame.Angles(math.rad(65),0,0)
				elseif name=="RightKnee" or name=="LeftKnee" then angle=CFrame.Angles(math.rad(-65),0,0) end
				joint.C0=cf*angle
			end
			local rightHand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
			local leftHand=character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
			local rightPos=if rightHand then (rightHand.CFrame*CFrame.new(0,-rightHand.Size.Y/2,0)).Position else (root.CFrame*CFrame.new(0.5,0.2,-1)).Position
			local leftPos=if leftHand then (leftHand.CFrame*CFrame.new(0,-leftHand.Size.Y/2,0)).Position else (root.CFrame*CFrame.new(-0.5,0.2,-1)).Position
			if option==1 then
				local base=CFrame.new((rightPos+leftPos)/2)*root.CFrame.Rotation*CFrame.Angles(math.rad(-20),0,0)
				left.CFrame=base*CFrame.new(-0.4,0,0); right.CFrame=base*CFrame.new(0.4,0,0)
				props.BookCover.CFrame=base*CFrame.new(0,-0.12,0)
				page.CFrame=base*CFrame.new(0,0.09,0)*CFrame.Angles(0,0,math.sin(t*2)*1.1)*CFrame.new(0.38,0,0)
			else
				phone.CFrame=CFrame.new(leftPos)*root.CFrame.Rotation*CFrame.Angles(math.rad(-25),0,0)
			end
			local focus=root.Position+Vector3.new(0,0.7,0)
			local desired=(root.CFrame*CFrame.new(3,2,-7)).Position
			local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={character,props,phone}
			local hit=workspace:Raycast(focus,desired-focus,params)
			local position=if hit then hit.Position-(desired-focus).Unit*0.4 else desired
			camera.CFrame=CFrame.lookAt(position,focus)
			RunService.RenderStepped:Wait()
		end
	end,debug.traceback)
	restore()
	if not ok then warn("Wind Down animation restored after error:",err) end
end
return Action
