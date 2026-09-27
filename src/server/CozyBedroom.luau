-- Room 101: individually editable, anchored models. No external assets required.
local Bedroom = {}
local function clearThermostatView(room)
	if room:GetAttribute("ThermostatPlantsMoved") then return end
	local tall=room:FindFirstChild("TallFloorPlant")
	local expansion=room:FindFirstChild("CottageExpansion")
	local extras=expansion and expansion:FindFirstChild("CozyAccessories")
	if not tall or not extras then return end
	-- Right along the wall when facing the thermostat; keep both pots indoors.
	local shift=Vector3.new(0,0,-4.5)
	tall:PivotTo(tall:GetPivot()+shift)
	for _,p in extras:GetChildren() do
		if p:IsA("BasePart") and (p.Name=="CeramicPlanter" or p.Name=="Stem" or p.Name=="Leaf")
			and (p.Position-Vector3.new(-105,13.48,-151)).Magnitude<4.5 then
			p.CFrame+=shift
		end
	end
	room:SetAttribute("ThermostatPlantsMoved",true)
end
local function softenPillows(room)
	for i=1,3 do
		local pillow=room:FindFirstChild("Pillow"..i)
		local cushion=pillow and pillow:FindFirstChild("Cushion")
		if cushion and cushion:IsA("Part") then
			-- Keep the named placement part; replace its oval silhouette with a
			-- softly crowned rectangular pillow made from rounded fabric layers.
			local old=pillow:FindFirstChild("SoftPillowShape")
			if old then old:Destroy() end
			local shape=Instance.new("Model"); shape.Name="SoftPillowShape"; shape.Parent=pillow
			cushion.Transparency=1
			cushion.CanCollide=false; cushion.CanTouch=false
			local width,depth=cushion.Size.X,cushion.Size.Z
			local height=math.min(width,depth)*0.36
			local function piece(name,size,offset,rounded)
				local p=Instance.new("Part"); p.Name=name; p.Size=size
				p.CFrame=cushion.CFrame*offset; p.Color=cushion.Color; p.Material=Enum.Material.Fabric
				p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
				p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
				if rounded then p.Shape=Enum.PartType.Cylinder end
				p.Parent=shape
			end
			for layer=-3,3 do
				local inset=math.abs(layer)/3
				local w,d=width*(1-0.13*inset^2),depth*(1-0.16*inset^2)
				local thickness=height/7+0.01
				local y=layer*height/7
				local radius=math.min(w,d)*0.18
				piece("FabricCenter",Vector3.new(w-2*radius,thickness,d),CFrame.new(0,y,0))
				piece("FabricSides",Vector3.new(w,thickness,d-2*radius),CFrame.new(0,y,0))
				for _,x in {-1,1} do for _,z in {-1,1} do
					piece("RoundedCorner",Vector3.new(thickness,2*radius,2*radius),
						CFrame.new(x*(w/2-radius),y,z*(d/2-radius))*CFrame.Angles(0,0,math.pi/2),true)
				end end
			end
		end
	end
end
function Bedroom.build()
	local existing = workspace:FindFirstChild("CozyBedroom101")
	if existing then
		local pouf=existing:FindFirstChild("PeachReadingPouf")
		if pouf then pouf:Destroy() end
		require(script.Parent:WaitForChild("BedroomExpansion")).build(existing)
		softenPillows(existing)
		clearThermostatView(existing)
		require(script.Parent.BedroomKitchenette).build(existing)
		return existing -- Preserve furniture baked and edited in Studio.
	end
	local root = Instance.new("Model")
	root.Name = "CozyBedroom101"
	local origin = Vector3.new(-84, 12.4, -161)
	local C = {
		wood = Color3.fromRGB(146, 99, 64), cream = Color3.fromRGB(239, 222, 192),
		pink = Color3.fromRGB(210, 168, 143), dark = Color3.fromRGB(38, 40, 39),
		green = Color3.fromRGB(72, 112, 61), gold = Color3.fromRGB(255, 206, 112),
	}
	local function model(name)
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = root
		return m
	end
	local function p(m, name, size, pos, color, material, shape)
		local a = Instance.new("Part")
		a.Name, a.Size = name, size
		a.Position = origin + pos
		a.Color, a.Material = color, material or Enum.Material.SmoothPlastic
		a.Anchored = true
		a.TopSurface, a.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		if shape then a.Shape = shape end
		a.Parent = m
		return a
	end
	local function box(m, name, sx, sy, sz, x, y, z, color, material)
		return p(m, name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, material)
	end
	local function rod(m, a, b, width, color)
		local r = p(m, "StemOrCord", Vector3.new(width, width, (b-a).Magnitude), (a+b)/2, color)
		r.CFrame = CFrame.lookAt(origin+(a+b)/2, origin+b)
		return r
	end
	local function plant(name, x, y, z, scale)
		local m = model(name)
		p(m, "CeramicPot", Vector3.new(2.1, 2.2, 2.1)*scale, Vector3.new(x,y+1.1*scale,z), C.cream, nil, Enum.PartType.Ball)
		for i = 1, 7 do
			local angle = i*2.4
			local base = Vector3.new(x,y+1.6*scale,z)
			local tip = base+Vector3.new(math.cos(angle)*1.5,2+i*0.32,math.sin(angle)*1.5)*scale
			rod(m,base,tip,0.12*scale,C.green)
			local leaf = p(m,"Leaf",Vector3.new(1.1,2,0.35)*scale,tip,C.green,nil,Enum.PartType.Ball)
			leaf.CFrame *= CFrame.Angles(0,angle,0.5)
			leaf.CanCollide = false
		end
		return m
	end
	local floor = model("WoodFloor")
	for i = 0, 25 do
		box(floor,"Floorboard",1.98,0.12,53,-25+i*2,0.06,0,Color3.fromRGB(116+i%4*8,79+i%4*6,53+i%4*4),Enum.Material.Wood)
	end
	local bed = model("RaisedBed")
	box(bed,"Platform",25,0.8,13,6,5.5,-19,C.wood,Enum.Material.Wood)
	for _, x in ipairs({-6,18}) do
		box(bed,"BedEnd",0.7,5,13,x,2.5,-19,C.wood,Enum.Material.Wood)
	end
	box(bed,"Mattress",24,1.3,12,6,6.5,-19,C.cream,Enum.Material.Fabric)
	box(bed,"PeachDuvet",19,0.65,12,8,7.35,-19,C.pink,Enum.Material.Fabric)
	for i=1,3 do
		local pillow = model("Pillow"..i)
		local cushion = p(pillow,"Cushion",Vector3.new(4.5,1.7,3.3),Vector3.new(-3,7.8,-24+i*3),C.cream,Enum.Material.Fabric,Enum.PartType.Ball)
		cushion.CFrame *= CFrame.Angles(0,0.15*i,0)
	end
	for i=0,3 do
		local bin = model("UnderBedBasket"..i+1)
		box(bin,"LinenBin",5.2,3.8,10,-3+i*6,2.1,-19,C.cream,Enum.Material.Fabric)
		box(bin,"Handle",1.5,0.3,0.15,-3+i*6,3,-13.9,C.wood)
	end
	local desk = model("WritingDesk")
	box(desk,"Desktop",12,0.6,7,-18,5.4,-4,C.wood,Enum.Material.Wood)
	for _, x in ipairs({-23,-13}) do
		for _, z in ipairs({-6.5,-1.5}) do box(desk,"Leg",0.5,5,0.5,x,2.5,z,C.cream) end
	end
	local pc = model("Computer")
	box(pc,"MonitorFrame",5.5,3.6,0.4,-18,8,-6,C.cream)
	box(pc,"Screen",5,3.1,0.1,-18,8,-5.75,Color3.fromRGB(29,53,57))
	box(pc,"Stand",0.4,1,0.4,-18,6,-6,C.cream)
	box(pc,"StandBase",3,0.2,1.6,-18,5.8,-6,C.cream)
	local keyboard = model("Keyboard")
	box(keyboard,"Base",4.5,0.2,1.6,-18,5.85,-2.8,C.cream)
	for row=0,2 do for key=0,9 do
		box(keyboard,"Key",0.32,0.08,0.32,-20+key*0.43,6,-3.3+row*0.45,C.pink)
	end end
	local chair = model("BlackDeskChair")
	box(chair,"Seat",5,0.9,5,-17,3.3,3,C.dark,Enum.Material.Fabric)
	box(chair,"Backrest",5,6,0.9,-17,6,5,C.dark,Enum.Material.Fabric)
	box(chair,"Stem",0.7,3,0.7,-17,1.5,3,C.dark,Enum.Material.Metal)
	for i=1,5 do
		local a=i*math.pi*2/5
		rod(chair,Vector3.new(-17,0.5,3),Vector3.new(-17+math.cos(a)*3,0.5,3+math.sin(a)*3),0.4,C.dark)
	end
	local rug = model("RoundWovenRug")
	local disk=p(rug,"Rug",Vector3.new(0.15,17,17),Vector3.new(-10,0.23,5),C.cream,Enum.Material.Fabric,Enum.PartType.Cylinder)
	disk.CFrame *= CFrame.Angles(0,0,math.pi/2)
	for i=1,16 do
		local a=i*math.pi/8
		local detail=box(rug,"WovenPattern",0.7,0.03,1.6,-10+math.cos(a)*7,0.32,5+math.sin(a)*7,C.pink,Enum.Material.Fabric)
		detail.CFrame *= CFrame.Angles(0,-a,0)
	end
	local shelf=model("FloatingBookshelves")
	for level=1,3 do
		box(shelf,"Shelf",1.8,0.4,12,-25,11+level*3,-18,C.wood,Enum.Material.Wood)
		for i=1,5 do
			local book=model("ShelfBook"..level.."_"..i)
			box(book,"Book",1.25,1.5+i%2*0.5,0.65,-25,12+level*3,-22+i*0.9,({C.pink,C.cream,C.green})[i%3+1],Enum.Material.Fabric)
		end
	end
	for i=1,3 do
		local record=model("VinylRecord"..i)
		p(record,"Vinyl",Vector3.new(0.15,3.4,3.4),Vector3.new(-26.1,12+i*4,-7),C.dark,nil,Enum.PartType.Cylinder)
		p(record,"Label",Vector3.new(0.18,1.1,1.1),Vector3.new(-26,12+i*4,-7),C.pink,nil,Enum.PartType.Cylinder)
	end
	local cabinet=model("Sideboard")
	box(cabinet,"Cabinet",5,5,16,22,2.6,3,C.wood,Enum.Material.Wood)
	for i=1,3 do box(cabinet,"Drawer",0.15,3.8,4.5,19.4,2.8,-5+i*4,C.cream) end
	plant("TallFloorPlant",-23,0.2,12,1.6)
	plant("SideboardPlant",22,5.2,0,0.8)
	plant("WindowPlant",11,7,-25,0.65)
	plant("ShelfPlant",-25,20.3,-14,0.55)
	local hanging=plant("HangingPlant",20,17,-23,0.8)
	for _, dx in ipairs({-0.7,0.7}) do rod(hanging,Vector3.new(20+dx,18,-23),Vector3.new(20,25,-23),0.08,C.wood) end
	local lights=model("WarmStringLights")
	for i=0,24 do
		local x=-25+i*2.08
		local y=24-math.sin(i/24*math.pi)*2
		if i>0 then
			local previous=Vector3.new(-25+(i-1)*2.08,24-math.sin((i-1)/24*math.pi)*2,-25)
			rod(lights,previous,Vector3.new(x,y,-25),0.07,C.dark)
		end
		p(lights,"Bulb",Vector3.new(0.38,0.65,0.38),Vector3.new(x,y-0.4,-25),C.gold,Enum.Material.Neon,Enum.PartType.Ball)
	end
	for _, x in ipairs({-16,3,20}) do
		local bulb=box(lights,"WarmGlow",0.2,0.2,0.2,x,20,-22,C.gold,Enum.Material.Neon)
		local light=Instance.new("PointLight")
		light.Color,light.Brightness,light.Range=C.gold,0.8,32
		light.Parent=bulb
	end
	local flags=model("FabricBunting")
	rod(flags,Vector3.new(5,23,-26),Vector3.new(24,23,-26),0.08,C.wood)
	for i=0,7 do box(flags,"Flag",1.7,2.1,0.12,6+i*2.4,21.9,-26,({C.pink,C.green,C.cream,C.gold})[i%4+1],Enum.Material.Fabric) end
	local board=model("WirePhotoBoard")
	for i=0,5 do box(board,"Grid",0.1,8,0.08,-26,14,2+i*1.4,C.dark) end
	for i=0,5 do box(board,"Grid",0.1,0.08,7,-26,10+i*1.6,5.5,C.dark) end
	for i=1,4 do box(board,"Note",0.12,1.8,1.4,-25.9,11+i%2*3,1.5+i*1.4,C.cream) end
	local lamp=model("DeskLamp")
	box(lamp,"Base",2,0.3,2,-22,5.9,-4,C.dark)
	rod(lamp,Vector3.new(-22,6,-4),Vector3.new(-22,9,-5),0.2,C.dark)
	local shade=p(lamp,"Shade",Vector3.new(1.8,1.2,1.8),Vector3.new(-22,9,-5),C.dark,nil,Enum.PartType.Ball)
	local light=Instance.new("PointLight")
	light.Color,light.Range,light.Brightness=C.gold,12,0.7
	light.Parent=shade
	for i=1,3 do
		local candle=model("WindowCandle"..i)
		box(candle,"Wax",0.9,1+i*0.2,0.9,-5+i*3,7.7,-25,C.cream)
		box(candle,"Flame",0.12,0.3,0.12,-5+i*3,8.35+i*0.1,-25,C.gold,Enum.Material.Neon)
	end
	root.Parent=workspace
	require(script.Parent:WaitForChild("BedroomExpansion")).build(root)
	softenPillows(root)
	clearThermostatView(root)
	require(script.Parent.BedroomKitchenette).build(root)
	return root
end
return Bedroom
