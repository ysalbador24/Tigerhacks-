-- Additive decor upgrade: never replace the player's existing furniture.
local Expansion = {}
-- Patch baked rooms as well as newly generated rooms without replacing decor.
function Expansion.ensureLanding(expansion)
	local loft=expansion:FindFirstChild("ReadingLoft")
	local floor=loft and loft:FindFirstChild("LoftFloor")
	if not floor or loft:FindFirstChild("StairLanding") then return end
	local function piece(name,size,offset)
		local p=Instance.new("Part")
		p.Name=name; p.Size=size; p.CFrame=floor.CFrame*CFrame.new(offset)
		p.Color=floor.Color; p.Material=Enum.Material.WoodPlanks
		p.Anchored=true; p.CanCollide=true
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		p.Parent=loft
		return p
	end
	-- Overlap the last stair and loft floor; keep the approach side open.
	piece("StairLanding",Vector3.new(6,0.6,4),Vector3.new(-11.5,0,-0.5))
	piece("LandingOuterRail",Vector3.new(0.2,0.2,3),Vector3.new(-14.5,3.8,0))
	piece("LandingEndRail",Vector3.new(5,0.2,0.2),Vector3.new(-12,3.8,1.5))
	for _,offset in {Vector3.new(-14.5,2.05,-1.5),Vector3.new(-14.5,2.05,0),Vector3.new(-14.5,2.05,1.5),Vector3.new(-12.5,2.05,1.5),Vector3.new(-10.5,2.05,1.5)} do
		piece("LandingRailPost",Vector3.new(0.15,3.5,0.15),offset)
	end
end
function Expansion.ensureReadingWall(expansion)
	local loft=expansion:FindFirstChild("ReadingLoft")
	local floor=loft and loft:FindFirstChild("LoftFloor")
	if not floor or loft:FindFirstChild("BuiltInBookshelf") then return end
	local model=Instance.new("Model"); model.Name="BuiltInBookshelf"
	local cream=Color3.fromRGB(231,218,195)
	local oak=Color3.fromRGB(164,135,98)
	local sage=Color3.fromRGB(155,165,132)
	local function p(name,size,offset,color)
		local a=Instance.new("Part");a.Name=name;a.Size=size;a.CFrame=floor.CFrame*CFrame.new(offset)
		a.Color=color;a.Material=Enum.Material.Wood;a.Anchored=true;a.TopSurface=Enum.SurfaceType.Smooth;a.BottomSurface=Enum.SurfaceType.Smooth;a.Parent=model;return a
	end
	-- A wall surround encloses the shelf cavity, so the shelves sit inside the wall face.
	p("RecessBack",Vector3.new(0.2,10,12),Vector3.new(10.65,5.3,-1),oak)
	for _,z in {-7.4,5.4} do p("WallSurround",Vector3.new(2.6,11,0.8),Vector3.new(9.45,5.3,z),cream) end
	for _,y in {0.3,10.3} do p("WallSurround",Vector3.new(2.6,0.8,12),Vector3.new(9.45,y,-1),cream) end
	for row=0,4 do
		p("RecessedShelf",Vector3.new(2.5,0.25,12),Vector3.new(9.45,0.65+row*2.25,-1),oak)
		if row<4 then for book=1,13 do
			local height=1.1+(book%3)*0.2
			p("Book",Vector3.new(1.65,height,0.5),Vector3.new(9.1,0.8+row*2.25+height/2,-6.3+book*0.78),({cream,sage,Color3.fromRGB(188,151,127),Color3.fromRGB(105,124,119)})[book%4+1])
		end end
	end
	local plate=p("UpstairsSwitchPlate",Vector3.new(0.2,2,1.3),Vector3.new(8,3.8,-7.4),cream)
	p("UpstairsSwitch",Vector3.new(0.25,1.1,0.6),Vector3.new(7.8,3.8,-7.4),oak)
	plate:SetAttribute("RoomControl","Lighting")
	local prompt=Instance.new("ProximityPrompt");prompt.Name="RoomControlPrompt";prompt.ObjectText="Upstairs light switch";prompt.ActionText="Choose lighting";prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=9;prompt.Enabled=false;prompt.Parent=plate
	local book=p("ReadingBook",Vector3.new(1.8,0.25,2),Vector3.new(8.5,0.95,-2),sage)
	book:SetAttribute("BedtimeActivity","Reading")
	model.Parent=loft
end
-- Versioned migration for both baked rooms and newly generated rooms.
-- Keep the old hierarchy/names: ReadingLoft also owns its downstairs library pieces.
function Expansion.applyLayout(room, expansion)
	if (room:GetAttribute("LayoutVersion") or 0) >= 1 then return end
	local loft = expansion:FindFirstChild("ReadingLoft")
	local floor = loft and loft:FindFirstChild("LoftFloor")
	local bed = room:FindFirstChild("RaisedBed")
	local platform = bed and bed:FindFirstChild("Platform")
	local shelf = loft and loft:FindFirstChild("BuiltInBookshelf")
	local desk = room:FindFirstChild("WritingDesk")
	local desktop = desk and desk:FindFirstChild("Desktop")
	local woodFloor = room:FindFirstChild("WoodFloor")
	local board = woodFloor and woodFloor:FindFirstChild("Floorboard")
	assert(floor and platform and shelf and desktop and board, "Bedroom layout needs loft, bed, bookshelf, desk and floor")
	local groundY = board.Position.Y + board.Size.Y / 2
	local libraryDelta = Vector3.new(0, groundY - (floor.Position.Y + floor.Size.Y / 2), -27)
	local function translate(object, delta)
		if object:IsA("Model") then object:PivotTo(object:GetPivot()+delta)
		elseif object:IsA("BasePart") then object.CFrame += delta end
	end
	translate(shelf, libraryDelta)
	-- Reuse the seat, table, rug and books in the space vacated by the bed.
	for _, p in loft:GetChildren() do
		if p:IsA("BasePart") and (p.Name == "WindowReadingSeat" or p.Name == "NookBackrest"
			or p.Name == "ReadingTable" or p.Name == "ReadingBook" or p.Name == "ReadingRug") then
			local extra = if p.Name == "WindowReadingSeat" or p.Name == "NookBackrest" then Vector3.new(-3,0,-2)
				elseif p.Name == "ReadingTable" or p.Name == "ReadingBook" then Vector3.new(-3,0,-1) else Vector3.zero
			translate(p, libraryDelta + extra)
		end
	end
	-- Keep the upstairs switch upstairs even though its bookshelf moves downstairs.
	for name, offset in {UpstairsSwitchPlate=Vector3.new(-8,3.8,7), UpstairsSwitch=Vector3.new(-8,3.8,6.8)} do
		local p = shelf:FindFirstChild(name)
		if p then p.CFrame = floor.CFrame * CFrame.new(offset) end
	end
	-- Move the loft's existing lantern and its caps into the downstairs library.
	local extras = expansion:FindFirstChild("CozyAccessories")
	if extras then
		local lantern
		for _, p in extras:GetChildren() do
			if p.Name == "LanternGlow" and p.Position.Y > floor.Position.Y then lantern = p; break end
		end
		if lantern then
			local home = lantern.Position
			for _, p in extras:GetChildren() do
				if p:IsA("BasePart") and (p == lantern or (p.Name == "LanternCap" and (p.Position-home).Magnitude < 2)) then
					translate(p, libraryDelta)
				end
			end
		end
	end
	-- Resize the complete bed arrangement together to fit inside the 19x20 loft.
	local bottom = platform.Position.Y
	for _, p in bed:GetChildren() do
		if p:IsA("BasePart") then bottom = math.min(bottom, p.Position.Y-p.Size.Y/2) end
	end
	local from = CFrame.new(platform.Position.X, bottom, platform.Position.Z) * platform.CFrame.Rotation
	local destination = floor.CFrame * CFrame.new(0.5, floor.Size.Y/2, 3)
	local scale = math.min(0.6, (floor.Size.X-4)/platform.Size.X, (floor.Size.Z-10)/platform.Size.Z)
	local function moveBedGroup(object)
		if not object then return end
		local pivot = from:ToObjectSpace(object:GetPivot())
		for _, p in object:GetDescendants() do
			if p:IsA("BasePart") then
				local relative = from:ToObjectSpace(p.CFrame)
				p.Size *= scale
				p.CFrame = destination * CFrame.new(relative.Position*scale) * relative.Rotation
			end
		end
		if not object.PrimaryPart then
			object.WorldPivot = destination * CFrame.new(pivot.Position*scale) * pivot.Rotation
		end
	end
	moveBedGroup(bed)
	for i=1,3 do moveBedGroup(room:FindFirstChild("Pillow"..i)) end
	for i=1,4 do moveBedGroup(room:FindFirstChild("UnderBedBasket"..i)) end
	moveBedGroup(expansion:FindFirstChild("SageLayeredBedding"))
	local function piece(parent, name, size, cf, color, material)
		local p = parent:FindFirstChild(name)
		if not p then p = Instance.new("Part"); p.Name=name; p.Parent=parent end
		p.Size=size; p.CFrame=cf; p.Color=color; p.Material=material or Enum.Material.Wood
		p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		return p
	end
	local oak, cream = Color3.fromRGB(164,135,98), Color3.fromRGB(241,232,214)
	local nightstand = loft:FindFirstChild("BedsideTable")
	if not nightstand then nightstand=Instance.new("Model"); nightstand.Name="BedsideTable"; nightstand.Parent=loft end
	local top = piece(nightstand,"Tabletop",Vector3.new(3,0.4,2.5),floor.CFrame*CFrame.new(5,3.3,-3),oak)
	piece(nightstand,"Base",Vector3.new(2.5,2.8,2),floor.CFrame*CFrame.new(5,1.7,-3),cream)
	local candle = room:FindFirstChild("WindowCandle1")
	if candle then
		local wax = candle:FindFirstChild("Wax")
		if wax then translate(candle, top.Position+Vector3.new(0,top.Size.Y/2+wax.Size.Y/2,0)-wax.Position) end
		local flame = candle:FindFirstChild("Flame")
		if flame and not flame:FindFirstChild("BedsideLight") then
			local light=Instance.new("PointLight"); light.Name="BedsideLight"; light.Color=Color3.fromRGB(255,217,150)
			light.Brightness=0.7; light.Range=14; light.Parent=flame
		end
	end
	-- Close the unrailed east edge, while retaining the six-stud west stair opening.
	local rails = loft:FindFirstChild("LoftSafetyRail")
	if not rails then rails=Instance.new("Model"); rails.Name="LoftSafetyRail"; rails.Parent=loft end
	piece(rails,"EastTopRail",Vector3.new(0.2,0.2,20),floor.CFrame*CFrame.new(9.5,3.8,0),oak)
	for i=0,12 do piece(rails,"EastPost"..i,Vector3.new(0.15,3.5,0.15),floor.CFrame*CFrame.new(9.5,2.05,-9.5+i*19/12),cream) end
	local guard=piece(rails,"EastSafetyGuard",Vector3.new(0.15,3.5,20),floor.CFrame*CFrame.new(9.5,2.05,0),cream)
	guard.Transparency=1
	-- The final decorative spiral rails crossed the landing approach. Keep their
	-- appearance, but let players pass through them onto the existing landing.
	local stairs=expansion:FindFirstChild("SpiralStaircase")
	if stairs then for _, p in stairs:GetChildren() do
		if p:IsA("BasePart") and (p.Name=="Baluster" or p.Name=="SpiralHandrail") then
			local q=floor.CFrame:PointToObjectSpace(p.Position)
			if q.Y>0 and q.X < -8 and q.Z > -5 and q.Z < 1 then p.CanCollide=false end
		end
	end end
	local anchors=room:FindFirstChild("LayoutAnchors")
	if not anchors then anchors=Instance.new("Folder"); anchors.Name="LayoutAnchors"; anchors.Parent=room end
	local function anchor(name, cf)
		local p=piece(anchors,name,Vector3.new(0.25,0.25,0.25),cf,cream)
		p.Transparency=1; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
	end
	anchor("BedSleepTarget",floor.CFrame*CFrame.new(0.5,3.3,-4.5))
	local mattress=bed:FindFirstChild("Mattress")
	anchor("PhoneBedAnchor",mattress.CFrame*CFrame.new(0,mattress.Size.Y/2+0.12,0))
	anchor("PhoneDeskAnchor",desktop.CFrame*CFrame.new(0,desktop.Size.Y/2+0.12,2))
	local tablePart=loft:FindFirstChild("ReadingTable")
	anchor("LibraryInteractionAnchor",CFrame.new(tablePart.Position+Vector3.new(0,2,0)))
	room:SetAttribute("LayoutVersion",1)
end
function Expansion.build(room)
	local existing = room:FindFirstChild("CottageExpansion")
	if existing then
		Expansion.ensureLanding(existing); Expansion.ensureReadingWall(existing)
		Expansion.applyLayout(room, existing)
		return existing
	end
	local root = Instance.new("Model")
	root.Name = "CottageExpansion"
	local origin = Vector3.new(-84, 12.4, -161)
	local cream, sage, oak = Color3.fromRGB(241,232,214), Color3.fromRGB(155,165,132), Color3.fromRGB(164,135,98)
	local dark, gold = Color3.fromRGB(66,61,50), Color3.fromRGB(255,217,150)
	local function model(name)
		local m=Instance.new("Model"); m.Name=name; m.Parent=root; return m
	end
	local function part(m,name,size,pos,color,material,shape)
		local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=origin+pos; p.Color=color
		p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=true
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		if shape then p.Shape=shape end
		p.Parent=m; return p
	end
	local function rod(m,name,a,b,width,color)
		local p=part(m,name,Vector3.new(width,width,(b-a).Magnitude),(a+b)/2,color)
		p.CFrame=CFrame.lookAt(origin+(a+b)/2,origin+b); return p
	end
	local function prompt(p,key,action)
		p:SetAttribute("RoomControl",key)
		local q=Instance.new("ProximityPrompt"); q.Name="RoomControlPrompt"; q.ObjectText=key; q.ActionText=action
		q.RequiresLineOfSight=false; q.MaxActivationDistance=10; q.Enabled=false; q.Parent=p
	end
	local function glow(p,brightness,range)
		local light=Instance.new("PointLight"); light.Color=gold; light.Brightness=brightness; light.Range=range; light.Parent=p
	end
	local function plant(m,x,y,z,scale)
		part(m,"CeramicPlanter",Vector3.new(1.6,1.8,1.6)*scale,Vector3.new(x,y+0.9*scale,z),cream,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
		for i=1,6 do
			local a=i*2.4; local tip=Vector3.new(x+math.cos(a)*scale,y+(2.4+i*0.2)*scale,z+math.sin(a)*scale)
			rod(m,"Stem",Vector3.new(x,y+scale,z),tip,0.08,sage).CanCollide=false
			local leaf=part(m,"Leaf",Vector3.new(0.8,1.5,0.15)*scale,tip,sage,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
			leaf.CFrame*=CFrame.Angles(0,a,0.6); leaf.CanCollide=false
		end
	end
	local function seat(m,name,pos,size)
		local p=Instance.new("Seat"); p.Name=name; p.Size=size; p.Position=origin+pos; p.Color=cream; p.Material=Enum.Material.Fabric; p.Anchored=true; p.Parent=m; return p
	end
	-- Warm plaster liners soften the brick shell without covering the windows.
	local walls=model("BeigeWallPanels")
	local beige=Color3.fromRGB(221,207,184)
	part(walls,"LeftPlasterWall",Vector3.new(0.12,27,43.5),Vector3.new(-25.85,13.5,-4.75),beige)
	part(walls,"BathroomDoorSide",Vector3.new(0.12,27,3.5),Vector3.new(-25.85,13.5,24.75),beige)
	part(walls,"BathroomDoorHeader",Vector3.new(0.12,17,6),Vector3.new(-25.85,18.5,20),beige)
	for _,x in {-20.7,20.7} do part(walls,"WindowSidePanel",Vector3.new(12.7,27,0.12),Vector3.new(x,13.5,-26.6),beige) end
	part(walls,"WindowLowerPanel",Vector3.new(28.5,6,0.12),Vector3.new(0,3,-26.6),beige)
	part(walls,"WindowUpperPanel",Vector3.new(28.5,5,0.12),Vector3.new(0,24.5,-26.6),beige)
	part(walls,"LeftSkirting",Vector3.new(0.3,0.8,43.5),Vector3.new(-25.65,0.4,-4.75),cream,Enum.Material.Wood)
	part(walls,"WindowSkirting",Vector3.new(52,0.8,0.3),Vector3.new(0,0.4,-26.35),cream,Enum.Material.Wood)
	-- Lounge sits under the mezzanine; the middle of the room stays navigable.
	local couch=model("CreamSofa")
	part(couch,"OakBase",Vector3.new(14,0.7,6),Vector3.new(15,1.3,15),oak,Enum.Material.Wood)
	part(couch,"UpholsteredBack",Vector3.new(14,4.5,1.2),Vector3.new(15,4,18),cream,Enum.Material.Fabric)
	for _,x in {8.5,21.5} do part(couch,"RoundedArm",Vector3.new(1.4,3.4,6),Vector3.new(x,3,15),cream,Enum.Material.Fabric) end
	for _,x in {11.5,15,18.5} do
		seat(couch,"SofaSeat",Vector3.new(x,2.5,14.5),Vector3.new(3.3,1,5))
		local pillow=part(couch,"SageCushion",Vector3.new(2.8,2.8,1),Vector3.new(x,4.2,16.7),sage,Enum.Material.Fabric,Enum.PartType.Ball)
		pillow.CFrame*=CFrame.Angles(-0.2,0,0.12)
	end
	part(couch,"KnittedThrow",Vector3.new(2.8,0.18,4.8),Vector3.new(18.5,3.08,14.5),Color3.fromRGB(215,202,178),Enum.Material.Fabric).CanCollide=false
	local lounge=model("LoungeRugAndTable")
	part(lounge,"WovenRug",Vector3.new(16,0.12,13),Vector3.new(15,0.3,11),cream,Enum.Material.Fabric)
	for i=0,15 do part(lounge,"RugStripe",Vector3.new(0.15,0.02,12),Vector3.new(7.5+i,0.37,11),oak,Enum.Material.Fabric).CanCollide=false end
	part(lounge,"CoffeeTable",Vector3.new(8,0.5,3.8),Vector3.new(15,2.5,8),oak,Enum.Material.Wood)
	for _,x in {12,18} do for _,z in {6.6,9.4} do part(lounge,"TableLeg",Vector3.new(0.4,2.2,0.4),Vector3.new(x,1.2,z),oak,Enum.Material.Wood) end end
	for i=1,3 do part(lounge,"StackedBook",Vector3.new(2.5,0.3,1.8),Vector3.new(13,2.8+i*0.3,8),if i==2 then sage else cream) end
	local tv=model("TelevisionConsole")
	part(tv,"MediaCabinet",Vector3.new(11,3,3),Vector3.new(13,1.8,0),cream,Enum.Material.Wood)
	for _,x in {9.5,13,16.5} do
		part(tv,"CabinetFront",Vector3.new(3.2,2.5,0.2),Vector3.new(x,1.8,1.6),oak,Enum.Material.Wood)
		part(tv,"BrassHandle",Vector3.new(0.8,0.15,0.2),Vector3.new(x,2,1.8),gold,Enum.Material.Metal)
	end
	part(tv,"TVStand",Vector3.new(4,0.3,2),Vector3.new(13,3.5,0),dark)
	part(tv,"TVFrame",Vector3.new(10,6,0.5),Vector3.new(13,6.6,0),dark)
	local screen=part(tv,"TVScreen",Vector3.new(9.4,5.4,0.12),Vector3.new(13,6.6,0.32),Color3.fromRGB(22,28,27))
	local surface=Instance.new("SurfaceGui"); surface.Name="TVDisplay"; surface.Face=Enum.NormalId.Back; surface.CanvasSize=Vector2.new(800,450); surface.Enabled=false; surface.Parent=screen
	local title=Instance.new("TextLabel"); title.Size=UDim2.fromScale(1,1); title.BackgroundColor3=Color3.fromRGB(89,115,102); title.Text=""; title.TextColor3=cream; title.TextSize=42; title.Font=Enum.Font.Gotham; title.Parent=surface
	local remote=part(tv,"TVRemote",Vector3.new(0.8,0.2,1.6),Vector3.new(17,2.95,8),dark); prompt(remote,"TV","Turn on")
	-- A full-turn spiral rises 18 studs, with low risers and a continuous outer handrail.
	local stairs=model("SpiralStaircase")
	part(stairs,"CenterColumn",Vector3.new(0.55,21,0.55),Vector3.new(0,10.5,13),cream,Enum.Material.Metal)
	local previous
	for i=1,36 do
		local a=i/36*math.pi*2
		local y=i*0.5
		local tread=part(stairs,"Tread"..i,Vector3.new(7,0.5,1.7),Vector3.new(math.cos(a)*4,y-0.25,13+math.sin(a)*4),oak,Enum.Material.Wood)
		tread.CFrame*=CFrame.Angles(0,-a,0)
		tread.CanCollide=false
		local previousAngle=(i-1)/36*math.pi*2
		local from=Vector3.new(math.cos(previousAngle)*4,(i-1)*0.5-0.12,13+math.sin(previousAngle)*4)
		local to=Vector3.new(math.cos(a)*4,y-0.12,13+math.sin(a)*4)
		local ramp=part(stairs,"WalkRamp"..i,Vector3.new(7,0.2,(to-from).Magnitude+0.12),(from+to)/2,oak)
		ramp.CFrame=CFrame.lookAt(origin+(from+to)/2,origin+to)
		ramp.Transparency=1
		local edge=Vector3.new(math.cos(a)*7.5,y,13+math.sin(a)*7.5)
		local top=edge+Vector3.new(0,3.5,0)
		rod(stairs,"Baluster",edge,top,0.14,cream)
		if previous then rod(stairs,"SpiralHandrail",previous,top,0.22,oak) end
		previous=top
	end
	local loft=model("ReadingLoft")
	part(loft,"LoftFloor",Vector3.new(19,0.6,20),Vector3.new(16.5,17.7,15),oak,Enum.Material.WoodPlanks)
	for _,x in {8,25} do for _,z in {6,24} do part(loft,"SupportPost",Vector3.new(0.6,17.4,0.6),Vector3.new(x,8.7,z),cream,Enum.Material.Wood) end end
	local function rail(a,b)
		rod(loft,"TopRail",a+Vector3.new(0,3.5,0),b+Vector3.new(0,3.5,0),0.24,oak)
		local n=math.ceil((b-a).Magnitude/1.5)
		for i=0,n do local q=a:Lerp(b,i/n); rod(loft,"RailPost",q,q+Vector3.new(0,3.5,0),0.14,cream) end
	end
	rail(Vector3.new(7,18,5),Vector3.new(26,18,5))
	rail(Vector3.new(7,18,25),Vector3.new(26,18,25))
	rail(Vector3.new(7,18,5),Vector3.new(7,18,10))
	rail(Vector3.new(7,18,16),Vector3.new(7,18,25))
	part(loft,"ReadingRug",Vector3.new(12,0.1,12),Vector3.new(17,18.06,16),cream,Enum.Material.Fabric)
	seat(loft,"WindowReadingSeat",Vector3.new(21,19.3,20),Vector3.new(7,1,4))
	part(loft,"NookBackrest",Vector3.new(7,3,0.7),Vector3.new(21,20.4,22),sage,Enum.Material.Fabric)
	part(loft,"ReadingTable",Vector3.new(3,2,3),Vector3.new(15,19,20),oak,Enum.Material.Wood)
	for i=1,4 do part(loft,"ReadingBook",Vector3.new(2,0.25,1.5),Vector3.new(15,20+i*0.25,20),if i%2==0 then cream else sage) end
	plant(loft,23,18,8,1)
	-- Linen curtains cover the two existing window panes and retain visible folds when open.
	local curtains=model("LinenCurtains")
	rod(curtains,"CurtainRod",Vector3.new(-15,23,-25.5),Vector3.new(15,23,-25.5),0.2,oak)
	for _,side in {-1,1} do
		for i=1,12 do
			local closed=Vector3.new(side*((i-0.5)*1.15),14.5,-25.4+0.15*(i%2))
			local opened=Vector3.new(side*(12+(i-0.5)*0.22),14.5,closed.Z)
			local fold=part(curtains,"LinenFold",Vector3.new(0.28,16,0.35),opened,cream,Enum.Material.Fabric)
			fold.CanCollide=false; fold:SetAttribute("ClosedPosition",origin+closed); fold:SetAttribute("OpenPosition",origin+opened)
		end
	end
	local pull=part(curtains,"CurtainPull",Vector3.new(0.15,7,0.15),Vector3.new(-15,10,-24),oak); pull.CanCollide=false
	pull:SetAttribute("BedtimeActivity","Curtains")
	local switch=model("WallLightSwitch")
	local plate=part(switch,"SwitchPlate",Vector3.new(2,2.8,0.2),Vector3.new(-11,5,26.5),cream)
	local rocker=part(switch,"Switch",Vector3.new(0.7,1.4,0.3),Vector3.new(-11,5,26.3),oak)
	plate:SetAttribute("BedtimeActivity","Lighting")
	-- Battery-style decorative candle: toggle flame and warm glow.
	local candle=model("InteractiveCandle")
	local wax=part(candle,"CandleJar",Vector3.new(1.2,1.8,1.2),Vector3.new(16,3.7,8),cream)
	local flame=part(candle,"Flame",Vector3.new(0.25,0.55,0.25),Vector3.new(16,4.9,8),gold,Enum.Material.Neon,Enum.PartType.Ball); flame.CanCollide=false
	glow(flame,0.7,14); prompt(wax,"Candle","Extinguish")
	-- Ivy wall, framed botanical prints, leaning mirror, baskets, and lanterns.
	local ivy=model("TrailingIvyWall")
	for row=0,12 do
		local z=-23+row*2.3
		for i=0,11 do
			local y=25-i*1.55; local x=-25.55+math.sin(i*1.2+row)*0.08
			rod(ivy,"Vine",Vector3.new(x,y,z),Vector3.new(x,y-1.6,z+0.2),0.05,sage).CanCollide=false
			for _,side in {-1,1} do
				local leaf=part(ivy,"IvyLeaf",Vector3.new(0.18,1.3,1.05),Vector3.new(x+0.15,y,z+side*0.4),if i%3==0 then Color3.fromRGB(104,130,84) else sage,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
				leaf.CFrame*=CFrame.Angles(side*0.6,0,0); leaf.CanCollide=false
			end
		end
	end
	local gallery=model("BotanicalGallery")
	for i=1,4 do
		local x=7+i*4
		part(gallery,"OakFrame",Vector3.new(3.2,4.3,0.3),Vector3.new(x,12+(i%2)*2,26.3),oak,Enum.Material.Wood)
		part(gallery,"ArtPaper",Vector3.new(2.8,3.9,0.12),Vector3.new(x,12+(i%2)*2,26.1),cream)
		rod(gallery,"BotanicalStem",Vector3.new(x,10.5+(i%2)*2,25.98),Vector3.new(x,13+(i%2)*2,25.98),0.08,sage)
		for j=1,3 do part(gallery,"PaintedLeaf",Vector3.new(0.7,0.4,0.05),Vector3.new(x+(if j%2==0 then 0.35 else -0.35),11+j*0.6+(i%2)*2,25.94),sage,Enum.Material.SmoothPlastic,Enum.PartType.Ball).CanCollide=false end
	end
	local extras=model("CozyAccessories")
	for _,pos in {Vector3.new(-11,0,24),Vector3.new(24,0,-10)} do
		part(extras,"WovenBasket",Vector3.new(3.5,3,3.5),pos+Vector3.new(0,1.5,0),oak,Enum.Material.Fabric)
		part(extras,"FoldedBlanket",Vector3.new(3.3,0.8,3.2),pos+Vector3.new(0,3,0),cream,Enum.Material.Fabric)
	end
	plant(extras,-21,0,10,1.2)
	plant(extras,24,0,22,1.3)
	plant(extras,10,3.4,0,0.6)
	for _,pos in {Vector3.new(-12,1.5,21),Vector3.new(23,19.5,12)} do
		local lantern=part(extras,"LanternGlow",Vector3.new(1.3,2,1.3),pos,gold,Enum.Material.Neon); glow(lantern,0.35,12)
		for _,dy in {-1.2,1.2} do part(extras,"LanternCap",Vector3.new(2,0.2,2),pos+Vector3.new(0,dy,0),cream) end
	end
	-- Existing furniture remains editable; add a sage throw over the peach bedding.
	local bedding=model("SageLayeredBedding")
	part(bedding,"SageThrow",Vector3.new(9,0.15,11.8),Vector3.new(11,7.76,-19),sage,Enum.Material.Fabric).CanCollide=false
	for i=0,8 do part(bedding,"BlanketStripe",Vector3.new(0.09,0.03,11.8),Vector3.new(7+i,7.85,-19),cream,Enum.Material.Fabric).CanCollide=false end
	Expansion.ensureLanding(root)
	Expansion.ensureReadingWall(root)
	root.Parent=room
	Expansion.applyLayout(room, root)
	return root
end
return Expansion
