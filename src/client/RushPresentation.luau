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
 for i,item in ipairs({{"Phone","CATCH THE PHONE"},{"Lighting","BIG LIGHT OFF"},{"Food","DODGE THE PIZZA"},{"Bed","GET TO BED"}}) do
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
  status.Text=if left>45 then "CATCH PHONE • LIGHTS OFF • BED" elseif left>30 then "THE SNACKS HAVE FOUND YOU" elseif left>15 then "PHONE BATTERY: 3%. LAST CHANCE." elseif left>5 then "BED. NOW. PLEASE." else "LAST CALL FOR SLEEP"
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
  if option==2 then
   Lighting.Brightness=1.25
   Lighting.Ambient=Color3.fromRGB(115,105,125)
  end
 end
 function api.peace()
  if beacon then beacon.Enabled=false bedBoard.Enabled=false end
  TweenService:Create(Lighting,TweenInfo.new(.5),{Brightness=.65,ClockTime=23,Ambient=Color3.fromRGB(95,80,101)}):Play()
 end
 function api.stop()
  alive=false popId+=1 gui:Destroy()
  Lighting.ExposureCompensation=previousExposure
 end
 Lighting.ClockTime=22.9833
 return api
end
return Presentation
