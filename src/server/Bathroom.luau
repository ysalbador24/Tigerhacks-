local Bathroom={}
function Bathroom.build(room)
	local existing=room:FindFirstChild("EnsuiteBathroom")
	if existing then return existing end
	local m=Instance.new("Model");m.Name="EnsuiteBathroom"
	local origin=Vector3.new(-84,12.4,-161)
	local cream=Color3.fromRGB(239,230,214)
	local sage=Color3.fromRGB(158,175,153)
	local brass=Color3.fromRGB(182,151,92)
	local function p(name,size,pos,color,material)
		local a=Instance.new("Part");a.Name=name;a.Size=size;a.Position=origin+pos;a.Color=color;a.Material=material or Enum.Material.SmoothPlastic;a.Anchored=true;a.TopSurface=Enum.SurfaceType.Smooth;a.BottomSurface=Enum.SurfaceType.Smooth;a.Parent=m;return a
	end
	p("BathroomFloor",Vector3.new(22,0.3,22),Vector3.new(-37,0,19),cream,Enum.Material.Marble)
	for x=0,10 do for z=0,10 do p("FloorTile",Vector3.new(1.94,0.04,1.94),Vector3.new(-47+x*2,0.17,9+z*2),if (x+z)%2==0 then cream else Color3.fromRGB(215,211,193),Enum.Material.Marble) end end
	p("WestWall",Vector3.new(0.5,18,22),Vector3.new(-48,9,19),cream)
	p("NorthWall",Vector3.new(20,18,0.5),Vector3.new(-38,9,8),cream)
	p("SouthWall",Vector3.new(20,18,0.5),Vector3.new(-38,9,30),cream)
	p("DoorWallBack",Vector3.new(0.4,18,9),Vector3.new(-28,9,12.5),cream)
	p("DoorWallFront",Vector3.new(0.4,18,7),Vector3.new(-28,9,26.5),cream)
	p("DoorHeader",Vector3.new(0.4,8,6),Vector3.new(-28,14,20),cream)
	p("Ceiling",Vector3.new(20,0.4,22),Vector3.new(-38,18,19),cream)
	for _,z in {17,23} do p("DoorTrim",Vector3.new(0.7,10,0.3),Vector3.new(-26,5,z),brass) end
	p("DoorTopTrim",Vector3.new(0.7,0.3,6.3),Vector3.new(-26,10,20),brass)
	local light=p("BathroomLight",Vector3.new(4,0.2,4),Vector3.new(-37,17.5,20),cream,Enum.Material.Neon)
	local point=Instance.new("PointLight");point.Color=Color3.fromRGB(255,232,196);point.Range=30;point.Brightness=1.2;point.Parent=light
	for i=0,12 do p("SageWallTile",Vector3.new(1.4,6,0.1),Vector3.new(-47+i*1.5,3.2,8.3),sage) end
	-- Walk-in shower with a clear opening on the room-facing side.
	p("ShowerTray",Vector3.new(7,0.35,8),Vector3.new(-43.5,0.4,12.5),cream,Enum.Material.Marble)
	local glass=p("ShowerGlass",Vector3.new(0.18,10,6),Vector3.new(-39.8,5.5,11.5),Color3.fromRGB(192,214,206),Enum.Material.Glass);glass.Transparency=0.7
	p("ShowerPipe",Vector3.new(0.2,9,0.2),Vector3.new(-46.5,5.5,10),brass,Enum.Material.Metal)
	p("ShowerArm",Vector3.new(3,0.2,0.2),Vector3.new(-45,10,10),brass,Enum.Material.Metal)
	p("ShowerHead",Vector3.new(2.5,0.2,2.5),Vector3.new(-43.6,10,10),brass,Enum.Material.Metal)
	for i=1,9 do
		local water=p("ShowerWater",Vector3.new(0.06,8,0.06),Vector3.new(-44.5+(i%3)*0.65,5.7,9.3+math.floor((i-1)/3)*0.65),Color3.fromRGB(166,210,225),Enum.Material.Glass)
		water.CanCollide=false;water.Transparency=1
	end
	p("ShowerControl",Vector3.new(0.3,0.8,0.8),Vector3.new(-47.5,4.5,14),brass,Enum.Material.Metal)
	p("Shampoo",Vector3.new(0.6,1.5,0.6),Vector3.new(-46,1.3,14),sage)
	p("Conditioner",Vector3.new(0.6,1.3,0.6),Vector3.new(-45,1.2,14),cream)
	-- Vanity, bowl sink, mirror, and small toiletries.
	p("Vanity",Vector3.new(8,4,4),Vector3.new(-33.5,2.2,10.6),sage,Enum.Material.Wood)
	p("MarbleCounter",Vector3.new(8.5,0.5,4.5),Vector3.new(-33.5,4.4,10.6),cream,Enum.Material.Marble)
	local bowl=p("Basin",Vector3.new(3,0.8,2.5),Vector3.new(-33.5,5,10.6),Color3.fromRGB(251,249,237));bowl.Shape=Enum.PartType.Ball
	p("BasinInset",Vector3.new(2.2,0.08,1.7),Vector3.new(-33.5,5.39,10.6),Color3.fromRGB(187,210,206))
	p("Faucet",Vector3.new(0.2,1.7,0.2),Vector3.new(-33.5,5.4,9),brass,Enum.Material.Metal)
	p("FaucetSpout",Vector3.new(0.2,0.2,1.3),Vector3.new(-33.5,6.2,9.55),brass,Enum.Material.Metal)
	p("MirrorFrame",Vector3.new(7,7,0.3),Vector3.new(-33.5,9.5,8.4),brass,Enum.Material.Metal)
	local mirror=p("Mirror",Vector3.new(6.5,6.5,0.1),Vector3.new(-33.5,9.5,8.6),Color3.fromRGB(199,215,207),Enum.Material.Glass);mirror.Reflectance=0.35
	p("ToothbrushCup",Vector3.new(0.8,1,0.8),Vector3.new(-36.5,5.15,11),cream)
	p("Toothbrush",Vector3.new(0.15,1.8,0.15),Vector3.new(-36.5,6,11),sage)
	p("Bristles",Vector3.new(0.3,0.5,0.3),Vector3.new(-36.5,6.8,11),cream)
	for i=1,3 do p("SkincareBottle",Vector3.new(0.65,0.8+i*0.25,0.65),Vector3.new(-30.3,5+i*0.125,9+i*0.85),if i==2 then sage else cream) end
	p("VanityMat",Vector3.new(7,0.12,3),Vector3.new(-33.5,0.3,14.5),cream,Enum.Material.Fabric)
	p("ShowerMat",Vector3.new(6,0.12,3),Vector3.new(-43,0.3,18.5),sage,Enum.Material.Fabric)
	-- Towel shelving and a small toilet complete the ensuite.
	p("TowelShelf",Vector3.new(4,0.3,2),Vector3.new(-43,7,29),brass,Enum.Material.Wood)
	for i=1,3 do p("FoldedTowel",Vector3.new(3,0.4,1.6),Vector3.new(-43,7.2+i*0.4,29),if i==2 then sage else cream,Enum.Material.Fabric) end
	p("TowelRail",Vector3.new(4,0.15,0.15),Vector3.new(-34,6,29),brass,Enum.Material.Metal)
	p("HandTowel",Vector3.new(2.8,3.5,0.15),Vector3.new(-34,4.3,28.8),cream,Enum.Material.Fabric)
	p("ToiletTank",Vector3.new(3,4,1.6),Vector3.new(-45,2.3,28.4),cream)
	local toilet=p("ToiletBowl",Vector3.new(3,2,4),Vector3.new(-45,1.8,25.8),cream);toilet.Shape=Enum.PartType.Ball
	p("ToiletLid",Vector3.new(3,0.25,3.5),Vector3.new(-45,2.85,25.8),cream)
	p("Planter",Vector3.new(1.8,2,1.8),Vector3.new(-30,1,26),cream)
	for i=1,7 do local leaf=p("PlantLeaf",Vector3.new(0.65,3,0.5),Vector3.new(-30+math.sin(i)*0.8,3,26+math.cos(i)*0.8),sage);leaf.Shape=Enum.PartType.Ball;leaf.CFrame*=CFrame.Angles(math.sin(i)*0.4,0,math.cos(i)*0.4);leaf.CanCollide=false end
	m.Parent=room;return m
end
return Bathroom
