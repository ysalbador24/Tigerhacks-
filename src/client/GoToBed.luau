-- Reverse the wake-up placement: settle onto the same mattress, then lie down.
local TweenService=game:GetService("TweenService")
local GoToBed={}
function GoToBed.play(player)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local human=character and character:FindFirstChildOfClass("Humanoid")
	local room=workspace:FindFirstChild("CozyBedroom101")
	local raisedBed=room and room:FindFirstChild("RaisedBed")
	local bed=raisedBed and raisedBed:FindFirstChild("Mattress")
	local camera=workspace.CurrentCamera
	if not root or not human or human.Health<=0 or not bed or not bed:IsA("BasePart") or not camera then return function() end end
	local saved={root=root.CFrame,anchored=root.Anchored,auto=human.AutoRotate,camera=camera.CFrame,kind=camera.CameraType,subject=camera.CameraSubject}
	local tween,cleaned
	local function restore()
		if cleaned then return end
		cleaned=true
		if tween then tween:Cancel() end
		if root.Parent then
			root.CFrame=saved.root; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
			root.Anchored=saved.anchored
		end
		if human.Parent then human.AutoRotate=saved.auto end
		camera.CFrame=saved.camera; camera.CameraType=saved.kind
		camera.CameraSubject=if player.Character~=character and player.Character then player.Character:FindFirstChildOfClass("Humanoid") else saved.subject
	end
	local ok,err=xpcall(function()
		local surface=bed.Size.Y/2
		local duvet=raisedBed:FindFirstChild("PeachDuvet")
		if duvet and duvet:IsA("BasePart") then surface=math.max(surface,bed.CFrame:PointToObjectSpace(duvet.Position).Y+duvet.Size.Y/2) end
		local bedPose=bed.CFrame*CFrame.Angles(0,-math.pi/2,0)
		local leg=character:FindFirstChild("Left Leg")
		local height=human.HipHeight+root.Size.Y/2+(if leg then leg.Size.Y else 0)
		local lying=bedPose*CFrame.new(0,surface+root.Size.Z/2+0.15,0)*CFrame.Angles(math.rad(90),0,0)
		root.Anchored=true; human.AutoRotate=false
		root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=bedPose*CFrame.new(0,surface+height+0.15,0)
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt(bed.Position+bed.CFrame.RightVector*8+Vector3.new(0,4.5,0),bed.Position+Vector3.new(0,1,0))
		tween=TweenService:Create(root,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=lying})
		tween:Play()
		local began=os.clock()
		while os.clock()-began<1.8 do
			if player.Character~=character or not root.Parent or human.Health<=0 then restore(); return end
			task.wait()
		end
	end,debug.traceback)
	if not ok then restore(); warn("Getting into bed skipped safely:",err) end
	-- Caller restores under the fade, before the server moves the player into the dream.
	return restore
end
return GoToBed
