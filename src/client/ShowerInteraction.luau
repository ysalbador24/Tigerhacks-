-- Local shower presentation. Completion and once-per-evening state live on the server.
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Shower = {}
-- Set this to a permitted shower/dripping-water audio asset, e.g. rbxassetid://123456.
local SHOWER_WATER_SOUND_ID = "rbxassetid://127567048109598"
local activeController
function Shower.start(player, bathroom, finish)
	if activeController then activeController.stop(true) end
	local tray, mirror = bathroom:FindFirstChild("ShowerTray"), bathroom:FindFirstChild("Mirror")
	if not tray or not mirror then return nil end
	local controller = {}
	local stopped, submitting, adjusted, wiped = false, false, false, false
	local temperature = 0.5
	local connections, cells, water = {}, {}, {}
	local steamAnchor = Instance.new("Attachment")
	steamAnchor.Name = "ShowerSteam"; steamAnchor.Position = Vector3.new(0, 2, 0); steamAnchor.Parent = tray
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Color = ColorSequence.new(Color3.fromRGB(232, 233, 224))
	steam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.25,0.8),NumberSequenceKeypoint.new(1,1)})
	steam.Size = NumberSequence.new(2,5); steam.Lifetime = NumberRange.new(0.7,1.2)
	steam.Speed = NumberRange.new(1,2); steam.SpreadAngle = Vector2.new(35,35)
	steam.Rate = 8; steam.Parent = steamAnchor
	for _, part in bathroom:GetChildren() do
		if part.Name == "ShowerWater" then water[part] = part.Transparency; part.Transparency = 1 end
	end
	-- Client-created drops and audio are visible/audible only for this player.
	local effects=Instance.new("Folder"); effects.Name="LocalShowerWater"; effects.Parent=bathroom
	local head=bathroom:FindFirstChild("ShowerHead")
	local drops={}
	if head then
		for i=1,18 do
			local drop=Instance.new("Part"); drop.Name="WaterDrop"; drop.Size=Vector3.new(0.045,0.35,0.045)
			drop.Anchored=true; drop.CanCollide=false; drop.CanTouch=false; drop.CanQuery=false; drop.CastShadow=false
			drop.Color=Color3.fromRGB(166,210,225); drop.Material=Enum.Material.SmoothPlastic; drop.Transparency=0.38
			drop.Position=head.Position-Vector3.new(0,0.3,0)
			drop.Parent=effects
			table.insert(drops,{part=drop,offset=Vector3.new(((i-1)%3-1)*0.65,-head.Size.Y/2,((math.floor((i-1)/3))%3-1)*0.65),phase=i/18})
		end
	end
	local sound=Instance.new("Sound"); sound.Name="ShowerWaterLoop"; sound.SoundId=SHOWER_WATER_SOUND_ID
	sound.Volume=0.15; sound.Looped=true; sound.Parent=effects
	if SHOWER_WATER_SOUND_ID~="" then sound:Play() end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ShowerInteraction"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9; gui.Parent = player.PlayerGui
	local panel = Instance.new("Frame")
	panel.Position = UDim2.fromScale(0.28,0.26); panel.Size = UDim2.fromScale(0.44,0.62)
	panel.BackgroundColor3 = Color3.fromRGB(247,233,212); panel.Parent = gui
	Instance.new("UICorner",panel).CornerRadius = UDim.new(0,24)
	local border=Instance.new("UIStroke",panel); border.Color=Color3.fromRGB(183,203,190); border.Thickness=3
	-- Soft soap bubbles decorate the edges without covering the controls.
	for i=1,5 do
		local bubble=Instance.new("Frame"); bubble.Size=UDim2.fromOffset(9+i*3,9+i*3)
		bubble.Position=UDim2.fromScale(if i%2==0 then 0.93 else 0.02,0.08+i*0.12)
		bubble.BackgroundColor3=Color3.fromRGB(209,224,221); bubble.BackgroundTransparency=0.25; bubble.BorderSizePixel=0; bubble.Parent=panel
		Instance.new("UICorner",bubble).CornerRadius=UDim.new(1,0)
	end
	local function text(content,y,height)
		local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Text=content
		t.Position=UDim2.fromScale(0.05,y); t.Size=UDim2.fromScale(0.9,height)
		t.TextColor3=Color3.fromRGB(68,65,74); t.TextScaled=true; t.Font=Enum.Font.Gotham; t.Parent=panel
		local cap=Instance.new("UITextSizeConstraint",t); cap.MaxTextSize=19; return t
	end
	local heading=text("Bubble break • optional",0.02,0.08); heading.Font=Enum.Font.FredokaOne
	local temperatureText=text("Water: Just right • 50%",0.12,0.07)
	local track=Instance.new("TextButton"); track.Text=""; track.AutoButtonColor=false
	track.Position=UDim2.fromScale(0.1,0.24); track.Size=UDim2.fromScale(0.8,0.06)
	track.BackgroundColor3=Color3.new(1,1,1); track.Parent=panel
	Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
	local gradient=Instance.new("UIGradient",track)
	gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(160,198,220)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(186,212,163)),ColorSequenceKeypoint.new(1,Color3.fromRGB(235,166,148))})
	local range=Instance.new("Frame"); range.BorderSizePixel=0; range.Position=UDim2.fromScale(0.4,0); range.Size=UDim2.fromScale(0.25,1)
	range.BackgroundColor3=Color3.fromRGB(186,212,163); range.Parent=track
	local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(0.5,0.2); knob.Size=UDim2.fromScale(0.045,1.4)
	knob.Position=UDim2.fromScale(temperature,0); knob.BackgroundColor3=Color3.fromRGB(255,250,237); knob.Parent=track
	Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)
	local knobBorder=Instance.new("UIStroke",knob); knobBorder.Color=Color3.fromRGB(86,107,99); knobBorder.Thickness=2
	text("Too chilly  •  Just right  •  Too steamy",0.31,0.06)
	local instruction=text("Adjust the slider, then drag across the fogged mirror.",0.39,0.09)
	local mirrorView=Instance.new("TextButton"); mirrorView.Text=""; mirrorView.AutoButtonColor=false
	mirrorView.Position=UDim2.fromScale(0.15,0.5); mirrorView.Size=UDim2.fromScale(0.7,0.26)
	mirrorView.BackgroundColor3=mirror.Color; mirrorView.ClipsDescendants=true; mirrorView.Parent=panel
	local mirrorBorder=Instance.new("UIStroke",mirrorView); mirrorBorder.Color=Color3.fromRGB(182,151,92); mirrorBorder.Thickness=3
	local surface=Instance.new("SurfaceGui"); surface.Name="ShowerCondensation"; surface.Adornee=mirror
	surface.Face=Enum.NormalId.Back; surface.CanvasSize=Vector2.new(400,300); surface.Parent=gui
	-- The close-up wipe and the real mirror share the same condensation patches.
	for y=0,7 do for x=0,11 do
		local pair={x=x,y=y,cleared=false}
		for _,parent in {mirrorView,surface} do
			local cell=Instance.new("Frame"); cell.BorderSizePixel=0
			cell.Position=UDim2.fromScale(x/12,y/8); cell.Size=UDim2.new(1/12,1,1/8,1)
			cell.BackgroundColor3=Color3.fromRGB(235,239,231); cell.BackgroundTransparency=1; cell.Parent=parent
			table.insert(pair,cell)
		end
		table.insert(cells,pair)
	end end
	local finishButton=Instance.new("TextButton"); finishButton.Text="Finish Shower"; finishButton.Active=false; finishButton.AutoButtonColor=false
	finishButton.Position=UDim2.fromScale(0.1,0.8); finishButton.Size=UDim2.fromScale(0.8,0.09)
	finishButton.BackgroundColor3=Color3.fromRGB(218,218,204); finishButton.TextColor3=Color3.fromRGB(105,109,104)
	finishButton.TextScaled=true; finishButton.Font=Enum.Font.GothamBold; finishButton.Parent=panel
	Instance.new("UICorner",finishButton).CornerRadius=UDim.new(0,14)
	local finishCap=Instance.new("UITextSizeConstraint",finishButton); finishCap.MaxTextSize=22
	local cancel=Instance.new("TextButton"); cancel.Text="Back to evening"; cancel.Position=UDim2.fromScale(0.2,0.91)
	cancel.Size=UDim2.fromScale(0.6,0.07); cancel.BackgroundTransparency=1; cancel.TextColor3=Color3.fromRGB(83,101,93)
	cancel.Font=Enum.Font.Gotham; cancel.TextSize=15; cancel.Parent=panel
	function controller.stop(immediate)
		if stopped then
			if immediate and steamAnchor.Parent then steam:Clear(); steamAnchor:Destroy() end
			return
		end
		stopped=true
		if activeController==controller then activeController=nil end
		for _,connection in connections do connection:Disconnect() end
		sound:Stop(); effects:Destroy()
		for part,transparency in water do if part.Parent then part.Transparency=transparency end end
		steam.Enabled=false
		if immediate then steam:Clear(); steamAnchor:Destroy() else task.delay(1.3,function() steamAnchor:Destroy() end) end
		gui:Destroy()
	end
	local function connect(signal,callback) table.insert(connections,signal:Connect(callback)) end
	activeController=controller
	connect(gui.Destroying,function() controller.stop(true) end)
	connect(gui:GetPropertyChangedSignal("Enabled"),function() if not gui.Enabled then controller.stop(true) end end)
	connect(player.CharacterRemoving,function() controller.stop(true) end)
	connect(bathroom.Destroying,function() controller.stop(true) end)
	local function adjust(position)
		if stopped or submitting then return end
		temperature=math.clamp((position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
		knob.Position=UDim2.fromScale(temperature,0); steam.Rate=3+temperature*32
		local comfortable=temperature>=0.4 and temperature<=0.65
		temperatureText.Text=string.format("Water: %s • %d%%",if comfortable then "Just right" elseif temperature<0.4 then "Too chilly" else "Too steamy",math.floor(temperature*100+0.5))
		if not adjusted then
			adjusted=true
			for _,pair in cells do for _,cell in ipairs(pair) do TweenService:Create(cell,TweenInfo.new(0.25),{BackgroundTransparency=0.18}):Play() end end
		end
	end
	local previousWipe=nil
	local cleared=0
	local function wipe(position)
		if not adjusted or stopped or submitting then return end
		local relative=Vector2.new(position.X,position.Y)-mirrorView.AbsolutePosition
		local point=Vector2.new(relative.X/mirrorView.AbsoluteSize.X,relative.Y/mirrorView.AbsoluteSize.Y)
		if point.X<0 or point.X>1 or point.Y<0 or point.Y>1 then return end
		if not previousWipe then previousWipe=point; return end
		if (point-previousWipe).Magnitude<0.015 then return end
		previousWipe=point
		for _,pair in cells do
			if not pair.cleared and (Vector2.new((pair.x+0.5)/12,(pair.y+0.5)/8)-point).Magnitude<0.15 then
				pair.cleared=true; cleared+=1
				for _,cell in ipairs(pair) do TweenService:Create(cell,TweenInfo.new(0.15),{BackgroundTransparency=1}):Play() end
			end
		end
		if cleared>=4 then
			wiped=true; finishButton.Active=true; finishButton.AutoButtonColor=true
			finishButton.Text="Finish Shower"; finishButton.BackgroundColor3=Color3.fromRGB(164,193,164); finishButton.TextColor3=Color3.fromRGB(43,63,51)
			instruction.Text="Lovely! A clear little window. All done?"
		end
	end
	local dragging,dragInput=nil,nil
	local function startDrag(kind,input)
		if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		dragging=kind; dragInput=input; previousWipe=nil
		if kind=="slider" then adjust(input.Position) else wipe(input.Position) end
	end
	connect(track.InputBegan,function(input) startDrag("slider",input) end)
	connect(mirrorView.InputBegan,function(input) startDrag("mirror",input) end)
	connect(Input.InputChanged,function(input)
		if not dragging then return end
		if input.UserInputType==Enum.UserInputType.MouseMovement or input==dragInput then
			if dragging=="slider" then adjust(input.Position) else wipe(input.Position) end
		end
	end)
	connect(Input.InputEnded,function(input)
		if input==dragInput or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil; dragInput=nil end
	end)
	connect(finishButton.Activated,function()
		if stopped or submitting or not adjusted or not wiped then return end
		submitting=true; finishButton.Text="Finishing..."
		local accepted=finish(temperature)
		if stopped then return end
		if accepted then controller.stop(false) else submitting=false; finishButton.Text="Try Finish Shower again" end
	end)
	connect(cancel.Activated,function() controller.stop(false) end)
	connect(RunService.Heartbeat,function()
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid=player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
		if not gui.Parent or not root or not humanoid or humanoid.Health<=0 or (root.Position-tray.Position).Magnitude>16 then controller.stop(true); return end
		if head and head.Parent then
			for _,drop in drops do
				local top=head.CFrame:PointToWorldSpace(drop.offset)
				local height=math.max(0.1,top.Y-(tray.Position.Y+tray.Size.Y/2+0.18))
				local progress=(os.clock()*12/height+drop.phase)%1
				drop.part.Position=top-Vector3.new(0,height*progress,0)
			end
		end
	end)
	return controller
end
return Shower
