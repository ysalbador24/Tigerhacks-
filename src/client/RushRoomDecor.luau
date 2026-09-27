-- Additive, client-only storytelling. Existing furniture and collision stay untouched.
local Decor = {}
function Decor.build()
 local existing=workspace:FindFirstChild("RushRoomDetails")
 if existing then return existing end
 local room=workspace:FindFirstChild("CozyBedroom101")
 if not room then return nil end
 local folder=Instance.new("Folder") folder.Name="RushRoomDetails" folder.Parent=workspace
 local cream=Color3.fromRGB(247,233,212)
 local wood=Color3.fromRGB(146,99,64)
 local ink=Color3.fromRGB(48,43,58)
 local function part(name,size,cf,color,material)
  local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=cf p.Color=color
  p.Material=material or Enum.Material.SmoothPlastic p.Anchored=true
  p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=folder return p
 end
 local function note(p,face,content,color)
  local gui=Instance.new("SurfaceGui") gui.Face=face gui.CanvasSize=Vector2.new(420,280) gui.Parent=p
  local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(.88,.84) text.Position=UDim2.fromScale(.06,.08)
  text.BackgroundTransparency=1 text.Text=content text.TextColor3=color or ink text.Font=Enum.Font.FredokaOne
  text.TextScaled=true text.TextWrapped=true text.Parent=gui return text
 end
 local desk=room:FindFirstChild("WritingDesk")
 local desktop=desk and desk:FindFirstChild("Desktop")
 if desktop then
  local top=desktop.CFrame*CFrame.new(0,desktop.Size.Y/2,0)
  for i=1,3 do
   local book=part("DeadlineNotebook",Vector3.new(2.3,.16,1.6),top*CFrame.new(3,.12+i*.16,1.3)*CFrame.Angles(0,.12*i,0),({cream,Color3.fromRGB(155,165,132),Color3.fromRGB(196,186,230)})[i])
   if i==3 then note(book,Enum.NormalId.Top,"DUE\nYESTERDAY") end
  end
  local bottle=part("WaterBottle",Vector3.new(.7,1.5,.7),top*CFrame.new(-3,.8,1.7),Color3.fromRGB(130,176,184))
  bottle.Shape=Enum.PartType.Cylinder bottle.CFrame*=CFrame.Angles(0,0,math.pi/2)
  part("BottleCap",Vector3.new(.35,.16,.35),top*CFrame.new(-3,1.6,1.7),cream)
  local cablePoints={Vector3.new(1,.12,2.6),Vector3.new(2,.12,2.1),Vector3.new(2.6,.12,2.6),Vector3.new(3.5,.12,2.1)}
  for i=2,#cablePoints do
   local a,b=top:PointToWorldSpace(cablePoints[i-1]),top:PointToWorldSpace(cablePoints[i])
   part("ChargingCable",Vector3.new(.07,.07,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),ink)
  end
  local monitor=room:FindFirstChild("Computer")
  local screen=monitor and monitor:FindFirstChild("Screen")
  if screen then
   local panel=part("TooManyTabs",screen.Size+Vector3.new(0,0,.03),screen.CFrame,Color3.fromRGB(39,64,73))
   note(panel,Enum.NormalId.Back,"47 TABS OPEN\n\njust one more...",cream)
  end
  -- Backpack hangs at the edge of the desk, away from the walking route.
  local bag=part("Backpack",Vector3.new(1.8,2.4,.9),top*CFrame.new(-4,-1.4,2.3),Color3.fromRGB(83,108,97),Enum.Material.Fabric)
  part("BagPocket",Vector3.new(1.25,.9,.16),bag.CFrame*CFrame.new(0,-.4,.5),Color3.fromRGB(113,137,118),Enum.Material.Fabric)
 end
 local poster=part("SleepPoster",Vector3.new(.06,4.8,3.7),CFrame.new(-109.1,24,-161),Color3.fromRGB(196,186,230))
 note(poster,Enum.NormalId.Right,"SLEEP\nIS A\nSIDE QUEST")
 local calendar=part("Calendar",Vector3.new(.06,2.8,2.5),CFrame.new(-109.05,23,-153),cream)
 note(calendar,Enum.NormalId.Right,"MONDAY\n8 AM\nwhy.")
 -- Shelf clutter uses the existing bed footprint; no new floor obstacles.
 local bed=room:FindFirstChild("RaisedBed")
 local mattress=bed and bed:FindFirstChild("Mattress")
 if mattress then
  local cf=mattress.CFrame
  for i=1,3 do
   part("LaundryOnBed",Vector3.new(1.7,.2,1.4),cf*CFrame.new(6+i*.8,mattress.Size.Y/2+.35,-3)*CFrame.Angles(0,i*.6,0),({Color3.fromRGB(155,165,132),cream,Color3.fromRGB(196,186,230)})[i],Enum.Material.Fabric)
  end
  local clock=part("BedsideAlarm",Vector3.new(2,1.2,.6),cf*CFrame.new(-8,2,4.4),Color3.fromRGB(230,174,137))
  note(clock,Enum.NormalId.Back,"10:59 PM")
  local card=part("BedsideReminder",Vector3.new(2,.04,1.3),cf*CFrame.new(-7,mattress.Size.Y/2+.4,2.8),cream)
  note(card,Enum.NormalId.Top,"tomorrow me\nwill handle it")
 end
 local sideboard=room:FindFirstChild("Sideboard")
 local cabinet=sideboard and sideboard:FindFirstChild("Cabinet")
 if cabinet then
  local carton=part("PizzaBox",Vector3.new(3,.18,2.8),cabinet.CFrame*CFrame.new(0,cabinet.Size.Y/2+.2,2.5),Color3.fromRGB(207,172,122))
  note(carton,Enum.NormalId.Top,"MIDNIGHT\nDELIVERY",Color3.fromRGB(163,74,57))
  for i=1,2 do part("SnackWrapper",Vector3.new(.8,.06,1.1),carton.CFrame*CFrame.new(-.8*i,.2,-2)*CFrame.Angles(0,i*.8,0),Color3.fromRGB(219,132,118)) end
 end
 return folder
end
return Decor
