-- Keep the whole kitchenette together beside the windows.
local Kitchenette = {}
local function placeByWindows(model)
	if model:GetAttribute("WindowLayoutVersion")==2 then return end
	local origin=model:FindFirstChild("CounterOrigin")
	if not origin then return end
	-- Absolute scale prevents repeated builds from enlarging it again. Re-align
	-- the floor anchor after scaling so every appliance stays on the floor.
	model:ScaleTo(1.3)
	local target=CFrame.new(-62.4,12.52,-184.8)*CFrame.Angles(0,math.pi,0)
	model:PivotTo(target*origin.CFrame:Inverse()*model:GetPivot())
	model:SetAttribute("WindowLayoutVersion",2)
end
function Kitchenette.build(room)
	local existing=room:FindFirstChild("Kitchenette")
	if existing then placeByWindows(existing); return end
	local model=Instance.new("Model"); model.Name="Kitchenette"
	local cream=Color3.fromRGB(241,232,214)
	local sage=Color3.fromRGB(155,165,132)
	local oak=Color3.fromRGB(164,135,98)
	local origin=Vector3.new(-86,12.52,-135.5)
	local function part(name,size,offset,color,material)
		local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=origin+offset
		p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=model
		return p
	end
	part("LowerCabinet",Vector3.new(7,3.6,3),Vector3.new(0,1.8,0),sage,Enum.Material.Wood)
	part("Countertop",Vector3.new(7.4,0.3,3.3),Vector3.new(0,3.75,0),cream)
	for _,x in {-1.75,1.75} do
		part("CabinetDoor",Vector3.new(3.2,3.1,0.12),Vector3.new(x,1.85,-1.56),cream,Enum.Material.Wood)
		part("BrassHandle",Vector3.new(0.8,0.12,0.16),Vector3.new(x,2.75,-1.7),oak,Enum.Material.Metal)
	end
	part("TileBacksplash",Vector3.new(7.4,2.2,0.12),Vector3.new(0,5,1.53),cream)
	part("SinkBasin",Vector3.new(2.5,0.08,1.8),Vector3.new(1.6,3.94,0),Color3.fromRGB(130,150,145),Enum.Material.Metal)
	part("FaucetStem",Vector3.new(0.18,1,0.18),Vector3.new(1.6,4.4,0.8),oak,Enum.Material.Metal)
	part("FaucetSpout",Vector3.new(0.18,0.18,0.8),Vector3.new(1.6,4.85,0.5),oak,Enum.Material.Metal)
	part("OpenShelf",Vector3.new(7.4,0.2,1),Vector3.new(0,6.6,1.05),oak,Enum.Material.Wood)
	for _,x in {-2.5,-1.4} do
		local jar=part("TeaJar",Vector3.new(0.65,0.85,0.65),Vector3.new(x,7.12,1.05),sage)
		jar.CanCollide=false
		part("JarLid",Vector3.new(0.7,0.12,0.7),Vector3.new(x,7.6,1.05),oak).CanCollide=false
	end
	part("FridgeBody",Vector3.new(3.6,6.8,3.2),Vector3.new(5.55,3.4,0),cream)
	local door=part("FridgeDoor",Vector3.new(3.5,6.65,0.2),Vector3.new(5.55,3.4,-1.7),Color3.fromRGB(247,239,223))
	part("FridgeHandle",Vector3.new(0.18,1.7,0.22),Vector3.new(4.2,3.8,-1.9),oak,Enum.Material.Metal)
	part("FreezerSeam",Vector3.new(3.45,0.06,0.03),Vector3.new(5.55,5,-1.82),oak)
	local anchor=Instance.new("Attachment"); anchor.Name="FoodInteractionAnchor"; anchor.Parent=door
	local plateAnchor=Instance.new("Attachment"); plateAnchor.Name="FoodPlateAnchor"
	plateAnchor.Position=Vector3.new(-2,3.98,-0.1); plateAnchor.Parent=part("CounterOrigin",Vector3.one*0.1,Vector3.zero,cream)
	plateAnchor.Parent.Transparency=1; plateAnchor.Parent.CanCollide=false; plateAnchor.Parent.CanQuery=false
	placeByWindows(model)
	model.Parent=room
end
return Kitchenette
