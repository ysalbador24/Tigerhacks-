-- Presentation for the existing Rush loop: HUD, feedback, and temporary bed beacon.
local TweenService=game:GetService("TweenService")
local Lighting=game:GetService("Lighting")
local Debris=game:GetService("Debris")
local Presentation={}
local C={cream=Color3.fromRGB(247,233,212),ink=Color3.fromRGB(38,34,52),peach=Color3.fromRGB(230,174,137),mint=Color3.fromRGB(170,210,180),red=Color3.fromRGB(238,132,118)}
function Presentation.new(player)
 require(script.Parent.RushRoomDecor).build()
 local gui=Instance.new("ScreenGui") gui.Name="BedtimeRushHUD" gui.ResetOnSpawn=false gui.DisplayOrder=5 gui.Parent=player.PlayerGui
 local alive=true
 local previousExposure=Lighting.ExposureCompensation
 Lighting.ExposureCompensation=-.2
 -- Room mood: harsh and cold under the big light, warm and soft once it's off.
 local mood=Instance.new("ColorCorrectionEffect") mood.Name="RushMood" mood.Parent=Lighting
 local function round(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=p end
 local function text(parent,content,pos,size,max,font)
  local t=Instance.new("TextLabel") t.BackgroundTransparency=1 t.Text=content t.TextColor3=C.cream t.Font=font or Enum.Font.GothamBold
  t.Position=pos t.Size=size t.TextScaled=true t.TextWrapped=true t.Parent=parent
  local cap=Instance.new("UITextSizeConstraint") cap.MaxTextSize=max cap.MinTextSize=9 cap.Parent=t return t
 end
 local bar=Instance.new("Frame") bar.AnchorPoint=Vector2.new(.5,0) bar.Position=UDim2.new(.5,0,0,8) bar.Size=UDim2.new(.52,0,0,66)
 bar.BackgroundColor3=C.ink bar.BorderSizePixel=0 bar.Parent=gui round(bar,10)
 local size=Instance.new("UISizeConstraint") size.MaxSize=Vector2.new(490,66) size.MinSize=Vector2.new(245,66) size.Parent=bar
 local clock=text(bar,"BEDTIME: 11:00 PM",UDim2.fromScale(.04,.05),UDim2.fromScale(.66,.3),15)
 local remaining=text(bar,"60",UDim2.fromScale(.76,.04),UDim2.fromScale(.2,.65),32,Enum.Font.FredokaOne)
 local status=text(bar,"GET YOUR LIFE TOGETHER",UDim2.fromScale(.04,.38),UDim2.fromScale(.69,.25),11)
 status.TextColor3=C.peach
 local track=Instance.new("Frame") track.Position=UDim2.fromScale(.04,.8) track.Size=UDim2.fromScale(.92,.1) track.BackgroundColor3=Color3.fromRGB(78,72,91) track.BorderSizePixel=0 track.Parent=bar round(track,3)
 local fill=track:Clone() fill.Position=UDim2.new() fill.Size=UDim2.fromScale(1,1) fill.BackgroundColor3=C.mint fill.Parent=track
 local goals=Instance.new("Frame") goals.Position=UDim2.new(0,12,0,84) goals.Size=UDim2.new(.27,0,0,120) goals.BackgroundColor3=C.ink goals.BackgroundTransparency=.08 goals.BorderSizePixel=0 goals.Parent=gui round(goals,9)
 local bounds=Instance.new("UISizeConstraint") bounds.MinSize=Vector2.new(170,120) bounds.MaxSize=Vector2.new(260,120) bounds.Parent=goals
 local objectives={}
 for i,item in ipairs({{"Phone","CATCH THE PHONE"},{"Lighting","BIG LIGHT OFF"},{"Food","SHUT THE FRIDGE"},{"Bed","GET TO BED"}}) do
  local t=text(goals,"○  "..item[2],UDim2.new(.06,0,0,5+(i-1)*28),UDim2.new(.88,0,0,25),13)
  t.TextXAlignment=Enum.TextXAlignment.Left
  objectives[item[1]]={line=t,label=item[2]}
 end
 local big=text(gui,"",UDim2.fromScale(.1,.31),UDim2.fromScale(.8,.15),52,Enum.Font.FredokaOne)
 big.TextStrokeTransparency=.3 big.TextStrokeColor3=C.ink
 local bigScale=Instance.new("UIScale") bigScale.Parent=big
 local aside=text(gui,"",UDim2.fromScale(.17,.47),UDim2.fromScale(.66,.06),18)
 aside.TextStrokeColor3=C.ink aside.TextStrokeTransparency=.2
 local flash=Instance.new("Frame") flash.Size=UDim2.fromScale(1,1) flash.BackgroundColor3=C.cream flash.BackgroundTransparency=1 flash.BorderSizePixel=0 flash.ZIndex=0 flash.Parent=gui
 local popId=0
 local beacon,bedBoard
 local mattress
 local room=workspace:FindFirstChild("CozyBedroom101")
 local raised=room and room:FindFirstChild("RaisedBed")
 mattress=raised and raised:FindFirstChild("Mattress")
 if mattress then
  beacon=Instance.new("Highlight") beacon.Name="RushBedBeacon" beacon.Adornee=raised beacon.FillColor=C.mint beacon.FillTransparency=.87 beacon.OutlineTransparency=.3 beacon.OutlineColor=C.mint beacon.Enabled=false beacon.Parent=gui
  bedBoard=Instance.new("BillboardGui") bedBoard.Name="RushBedSign" bedBoard.Adornee=mattress bedBoard.Size=UDim2.fromOffset(190,46) bedBoard.StudsOffset=Vector3.new(0,5,0) bedBoard.AlwaysOnTop=true bedBoard.MaxDistance=75 bedBoard.Enabled=false bedBoard.Parent=gui
  local sign=text(bedBoard,"GO TO BED!",UDim2.new(),UDim2.fromScale(1,1),25,Enum.Font.FredokaOne) sign.TextColor3=C.mint sign.TextStrokeColor3=C.ink sign.TextStrokeTransparency=.2
 end
 local api={gui=gui}
 function api.pop(message,color,hold,detail)
  if not alive then return end
  popId+=1 local id=popId
  big.Text=message big.TextColor3=color or C.cream big.TextTransparency=0 big.TextStrokeTransparency=.3
  aside.Text=detail or "" aside.TextTransparency=0 aside.TextStrokeTransparency=.2
  bigScale.Scale=.8
  TweenService:Create(bigScale,TweenInfo.new(.18,Enum.EasingStyle.Back),{Scale=1}):Play()
  task.delay(hold or 1.15,function()
   if alive and popId==id then
    TweenService:Create(big,TweenInfo.new(.2),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    TweenService:Create(aside,TweenInfo.new(.2),{TextTransparency=1,TextStrokeTransparency=1}):Play()
   end
  end)
 end
 function api.mark(key,state,suffix)
  local o=objectives[key] if not alive or not o then return end
  o.line.Text=(if state=="done" then "✓  " elseif state=="failed" then "×  " else "○  ")..o.label..(suffix or "")
  o.line.TextColor3=if state=="done" then C.mint elseif state=="failed" then C.red else C.cream
  if state=="done" then
   o.line.Rotation=-3 TweenService:Create(o.line,TweenInfo.new(.22),{Rotation=0}):Play()
  end
 end
 function api.update(left,elapsed)
  if not alive then return end
  remaining.Text=tostring(math.ceil(left))
  fill.Size=UDim2.fromScale(left/60,1)
  fill.BackgroundColor3=if left>30 then C.mint elseif left>15 then C.peach else C.red
  remaining.TextColor3=if left>15 then C.cream else C.red
  bar.Rotation=if left<=15 then math.sin(elapsed*9)*.65 else 0
  status.Text=if left>45 then "CATCH PHONE • LIGHTS OFF • BED" elseif left>30 then "THE FRIDGE IS PLOTTING" elseif left>15 then "PHONE BATTERY: 3%. LAST CHANCE." elseif left>5 then "BED. NOW. PLEASE." else "LAST CALL FOR SLEEP"
 end
 function api.flash(color)
  if not alive then return end
  flash.BackgroundColor3=color or C.cream flash.BackgroundTransparency=.72
  TweenService:Create(flash,TweenInfo.new(.22),{BackgroundTransparency=1}):Play()
 end
 function api.burst(position,color)
  if not alive then return end
  -- Six transient crumbs; no unbounded emitters or texture dependencies.
  for i=1,6 do
   local p=Instance.new("Part") p.Size=Vector3.new(.16,.16,.16) p.Position=position p.Color=color or C.peach p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Parent=workspace
   TweenService:Create(p,TweenInfo.new(.45),{Position=position+Vector3.new(math.cos(i)*1.5,.6+i*.12,math.sin(i)*1.5),Transparency=1}):Play()
   Debris:AddItem(p,.5)
  end
 end
 function api.bedReady(ready)
  if beacon then beacon.Enabled=ready bedBoard.Enabled=ready end
 end
 function api.lightState(option)
  if not alive then return end
  local info=TweenInfo.new(if option==2 then .15 else .9,Enum.EasingStyle.Quad)
  if option==2 then
   -- Overstimulating: bright, flat, slightly blue.
   TweenService:Create(Lighting,info,{Brightness=2.4,Ambient=Color3.fromRGB(170,168,182),ExposureCompensation=.15}):Play()
   TweenService:Create(mood,info,{TintColor=Color3.fromRGB(232,238,255),Saturation=-.18,Contrast=.12}):Play()
  else
   -- Bedtime-ready: dim, warm, cozy.
   TweenService:Create(Lighting,info,{Brightness=.55,Ambient=Color3.fromRGB(105,82,98),ExposureCompensation=-.35}):Play()
   TweenService:Create(mood,info,{TintColor=Color3.fromRGB(255,222,196),Saturation=.12,Contrast=.04}):Play()
  end
 end
 -- The roommate barges in at the door, flips the light, and leaves.
 function api.roommate()
  if not alive then return end
  local model=Instance.new("Model") model.Name="Roommate"
  local door=CFrame.lookAt(Vector3.new(-101,15.4,-134.5),Vector3.new(-101,15.4,-150))
  local parts={}
  local function piece(size,offset,color,shape)
   local p=Instance.new("Part") p.Size=size p.Color=color p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false
   if shape then p.Shape=shape end p.CFrame=door*CFrame.new(offset) p.Parent=model table.insert(parts,{p,offset}) return p
  end
  piece(Vector3.new(2.2,2.6,1.1),Vector3.new(0,.9,0),Color3.fromRGB(214,120,98))
  piece(Vector3.new(1.7,1.7,1.7),Vector3.new(0,3,0),Color3.fromRGB(233,196,160),Enum.PartType.Ball)
  for _,x in {-.55,.55} do piece(Vector3.new(.8,2.4,.8),Vector3.new(x,-1.6,0),Color3.fromRGB(70,76,104)) end
  local arm=piece(Vector3.new(.6,2.2,.6),Vector3.new(1.45,1.6,-.4),Color3.fromRGB(214,120,98))
  arm.CFrame*=CFrame.Angles(math.rad(-60),0,0)
  local board=Instance.new("BillboardGui") board.Size=UDim2.fromOffset(230,48) board.StudsOffset=Vector3.new(0,5.4,0) board.AlwaysOnTop=true board.Parent=parts[2][1]
  local lines={"oh you're sleeping? I just need ONE thing","sorry!! have you seen my charger","don't mind me. big light is a vibe."}
  local say=text(board,lines[math.random(1,#lines)],UDim2.new(),UDim2.fromScale(1,1),20) say.BackgroundTransparency=0 say.BackgroundColor3=C.cream say.TextColor3=C.ink round(say,8)
  model.Parent=workspace
  -- Slide in from the hallway, hold for the joke, slide back out.
  for _,entry in parts do entry[1].CFrame=door*CFrame.new(0,0,4)*CFrame.new(entry[2]) end
  for _,entry in parts do TweenService:Create(entry[1],TweenInfo.new(.35,Enum.EasingStyle.Back),{CFrame=door*CFrame.new(entry[2])}):Play() end
  task.delay(3,function()
   for _,entry in parts do if entry[1].Parent then TweenService:Create(entry[1],TweenInfo.new(.4),{CFrame=door*CFrame.new(0,0,5)*CFrame.new(entry[2]),Transparency=1}):Play() end end
   Debris:AddItem(model,.5)
  end)
 end
 function api.peace()
  if beacon then beacon.Enabled=false bedBoard.Enabled=false end
  TweenService:Create(mood,TweenInfo.new(.8),{TintColor=Color3.fromRGB(210,200,255),Saturation=-.05,Contrast=0}):Play()
  TweenService:Create(Lighting,TweenInfo.new(.5),{Brightness=.65,ClockTime=23,Ambient=Color3.fromRGB(95,80,101)}):Play()
 end
 function api.stop()
  alive=false popId+=1 gui:Destroy() mood:Destroy()
  Lighting.ExposureCompensation=previousExposure
 end
 Lighting.ClockTime=22.9833
 return api
end
return Presentation
