-- Shared, asset-free food props for choice previews and a short R6/R15 bite pose.
local RunService=game:GetService("RunService")
local Food={}
local function makeFood(parent,option)
	local model=Instance.new("Model"); model.Name=if option==1 then "CherryBowl" else "PizzaSlice"
	local function piece(name,size,cf,color,shape)
		local p=Instance.new(if shape=="Wedge" then "WedgePart" else "Part")
		p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color; p.Material=Enum.Material.SmoothPlastic
		p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
		if shape=="Ball" then p.Shape=Enum.PartType.Ball end
		p.Parent=model; return p
	end
	local function stem(a,b)
		piece("CurvedStem",Vector3.new(0.035,0.035,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(103,133,60))
	end
	if option==1 then
		for i=1,5 do
			local a=i*2.4; local x,z=math.cos(a)*0.36,math.sin(a)*0.36
			local center=Vector3.new(x,0.43+(i%2)*0.06,z)
			local cherry=piece("Cherry",Vector3.new(0.55,0.52,0.53),CFrame.new(center),Color3.fromRGB(139+i*6,19,43),"Ball")
			cherry.Reflectance=0.08
			piece("StemDimple",Vector3.new(0.13,0.035,0.12),CFrame.new(center+Vector3.new(0,0.245,0)),Color3.fromRGB(92,24,35),"Ball")
			local start=center+Vector3.new(0,0.25,0)
			local finish=Vector3.new(x*0.25,1.15,z*0.25)
			local previous=start
			for segment=1,5 do
				local t=segment/5
				local point=start:Lerp(finish,t)+Vector3.new(math.sin(t*math.pi)*0.12,0,0)
				stem(previous,point); previous=point
			end
			if i==1 then
				piece("CherryLeaf",Vector3.new(0.24,0.045,0.5),CFrame.new(finish+Vector3.new(0.13,0,0.1))*CFrame.Angles(0,i*1.4,0.3),Color3.fromRGB(94,144,63),"Ball")
			end
		end
	else
		-- Mirrored wedges meet at the center seam and taper to one pointed tip.
		for _,side in {-1,1} do
			local pose=CFrame.new(side*0.38,0,0)*CFrame.Angles(0,0,-side*math.pi/2)
			piece("BakedBase",Vector3.new(0.2,0.76,1.8),pose-Vector3.new(0,0.1,0),Color3.fromRGB(214,142,61),"Wedge")
			piece("TomatoSauce",Vector3.new(0.06,0.76,1.8),pose+Vector3.new(0,0.02,0),Color3.fromRGB(177,57,35),"Wedge")
			local cheesePose=CFrame.new(side*0.33,0.08,0.04)*CFrame.Angles(0,0,-side*math.pi/2)
			piece("Cheese",Vector3.new(0.08,0.66,1.58),cheesePose,Color3.fromRGB(255,207,127),"Wedge")
		end
		for i=-5,5 do
			local x=i*0.145
			piece("RoundedGoldenCrust",Vector3.new(0.3,0.28,0.3),CFrame.new(x,0.07,0.8+0.09*(1-(i/5)^2)),Color3.fromRGB(234,166,57),"Ball")
		end
		for _,p in {Vector3.new(-0.36,0.15,0.51),Vector3.new(0.32,0.15,0.47),Vector3.new(0,0.15,0.06),Vector3.new(0,0.15,-0.43)} do
			piece("PepperoniEdge",Vector3.new(0.34,0.07,0.34),CFrame.new(p),Color3.fromRGB(180,46,42),"Ball")
			piece("Pepperoni",Vector3.new(0.32,0.055,0.32),CFrame.new(p+Vector3.new(0,0.03,0)),Color3.fromRGB(227,100,49),"Ball")
		end
	end
	model.WorldPivot=CFrame.identity; model.Parent=parent
	if option==1 then model:ScaleTo(0.7) end
	return model
end
function Food.preview(button,option)
	-- Reserve room for the illustration without shrinking the choice text.
	local padding=Instance.new("UIPadding"); padding.Parent=button
	local view=Instance.new("ViewportFrame"); view.Name="FoodPreview"; view.BackgroundTransparency=1
	view.Position=UDim2.new(0,-56,0,0); view.Size=UDim2.new(0,52,1,0); view.Active=false; view.Parent=button
	view:GetPropertyChangedSignal("Visible"):Connect(function() padding.PaddingLeft=UDim.new(0,if view.Visible then 64 else 0) end)
	view.Ambient=Color3.fromRGB(220,210,195); view.LightColor=Color3.fromRGB(255,244,220)
	local cam=Instance.new("Camera"); cam.CFrame=CFrame.lookAt(Vector3.new(2,2.8,-3),Vector3.new(0,0.2,0)); cam.FieldOfView=35; cam.Parent=view; view.CurrentCamera=cam
	makeFood(view,option)
	return view
end
function Food.play(player,option,cancelled)
	local character=player.Character
	local head=character and character:FindFirstChild("Head")
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local human=character and character:FindFirstChildOfClass("Humanoid")
	if not head or not root or not human or human.Health<=0 then return end
	local cam=workspace.CurrentCamera
	local saved={anchored=root.Anchored,auto=human.AutoRotate,kind=cam.CameraType,cf=cam.CFrame,subject=cam.CameraSubject,fov=cam.FieldOfView}
	local prop, joints=nil,{}
	local ok,err=xpcall(function()
		prop=makeFood(workspace,option)
		local scale=math.clamp(head.Size.Y,0.6,1.8); prop:ScaleTo(prop:GetScale()*scale)
		for _,j in character:GetDescendants() do
			if j:IsA("Motor6D") and j.Name:gsub(" ",""):find("Shoulder") then joints[j]=j.C0 end
		end
		root.Anchored=true; human.AutoRotate=false; cam.CameraType=Enum.CameraType.Scriptable; cam.FieldOfView=55
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances={character,prop}
		local steadyCamera
		local began=os.clock()
		while os.clock()-began<2.8 do
			if cancelled() or player.Character~=character or not head.Parent or not root.Parent or human.Health<=0 then break end
			local t=(os.clock()-began)/2.8
			local bite=(1-math.cos(t*4*math.pi))/2
			local mouth=head.CFrame*CFrame.new(0,-head.Size.Y*0.22,-head.Size.Z/2-0.28*scale)
			local foodPose=mouth*CFrame.new(0,-(1-bite)*0.9*scale,-(1-bite)*0.45*scale)*CFrame.Angles(bite*0.2,0,0)
			-- Present the pointed end to the mouth, with the crust farther away.
			if option==2 then foodPose=foodPose*CFrame.new(0,0,-0.9*scale)*CFrame.Angles(0,math.pi,0) end
			prop:PivotTo(foodPose)
			for j,cf in joints do
				local right=j.Name:find("Right")~=nil
				local angle=math.rad(45+25*bite)
				j.C0=cf*(if human.RigType==Enum.HumanoidRigType.R6 then CFrame.Angles(0,0,if right then angle else -angle) else CFrame.Angles(angle,0,if right then -0.2 else 0.2))
			end
			-- Choose the pizza shot once; head motion must not flip camera sides.
			if option~=2 or not steadyCamera then
				local focus=head.Position-Vector3.new(0,0.3*scale,0)
				local best,clearance=nil,-1
				for _,side in {-1,1} do
					local direction=(head.CFrame.LookVector*4+head.CFrame.RightVector*side*3+Vector3.new(0,1,0))*scale
					local hit=workspace:Raycast(focus,direction,params)
					local distance=if hit then math.max(0.2,hit.Distance-0.3) else direction.Magnitude
					if distance>clearance then best=focus+direction.Unit*distance; clearance=distance end
				end
				steadyCamera=CFrame.lookAt(best,focus)
			end
			cam.CFrame=steadyCamera
			RunService.RenderStepped:Wait()
		end
	end,debug.traceback)
	if prop then prop:Destroy() end
	for j,cf in joints do if j.Parent then j.C0=cf end end
	if root.Parent then root.Anchored=saved.anchored; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
	if human.Parent then human.AutoRotate=saved.auto end
	cam.CFrame=saved.cf; cam.FieldOfView=saved.fov; cam.CameraType=saved.kind
	cam.CameraSubject=if player.Character~=character and player.Character then player.Character:FindFirstChildOfClass("Humanoid") else saved.subject
	if not ok then warn("Eating animation cleaned up:",err) end
end
return Food
