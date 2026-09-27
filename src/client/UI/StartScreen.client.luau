-- Menu presentation only. Gameplay, remotes, and world lighting remain team-owned.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("StartScreen")
if previous then previous:Destroy() end

local palette = {
 night = Color3.fromRGB(28,30,49), cream = Color3.fromRGB(247,233,212),
 lavender = Color3.fromRGB(196,186,230), peach = Color3.fromRGB(230,174,137),
 wood = Color3.fromRGB(146,99,64), wool = Color3.fromRGB(250,248,240),
 sheep = Color3.fromRGB(60,56,62), muted = Color3.fromRGB(185,181,197),
 gold = Color3.fromRGB(255,206,112), blue = Color3.fromRGB(96,170,235),
}
local connections = {}
local activeTweens = {}
local alive, started = true, false
local function create(class, parent, properties)
 local item = Instance.new(class)
 for key, value in pairs(properties) do item[key] = value end
 item.Parent = parent
 return item
end
local function connect(signal, callback)
 local connection = signal:Connect(callback)
 table.insert(connections, connection)
 return connection
end
local function animate(item, duration, properties)
 -- New interactions replace any in-flight animation on the same object.
 if activeTweens[item] then activeTweens[item]:Cancel() end
 local tween = TweenService:Create(item, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
 activeTweens[item] = tween
 tween:Play()
 return tween
end
local function rounded(item, radius)
 create("UICorner", item, {CornerRadius = UDim.new(0, radius)})
end
local function label(parent, name, content, position, size, color, maxSize, font)
 local result = create("TextLabel", parent, {
  Name = name, Text = content, Position = position, Size = size,
  BackgroundTransparency = 1, TextColor3 = color, TextScaled = true,
  Font = font or Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left,
 })
 create("UITextSizeConstraint", result, {MinTextSize = 8, MaxTextSize = maxSize})
 return result
end
local gui = create("ScreenGui", playerGui, {
 Name = "StartScreen", IgnoreGuiInset = true, ResetOnSpawn = false,
 DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
local background = create("Frame", gui, {
 Name = "Background", Size = UDim2.fromScale(1,1), BackgroundColor3 = palette.night,
 BorderSizePixel = 0, ClipsDescendants = true,
})
local safe = create("Frame", background, {
 Name = "Composition", Position = UDim2.fromScale(.055,.075),
 Size = UDim2.fromScale(.89,.85), BackgroundTransparency = 1,
})
local title = create("Frame", safe, {Name = "Title", BackgroundTransparency = 1})
local snooze = label(title, "Snooze", "SNOOZE", UDim2.fromScale(0,0), UDim2.fromScale(1,.34), palette.cream, 105)
local you = label(title, "You", "YOU", UDim2.fromScale(.14,.31), UDim2.fromScale(.55,.26), palette.peach, 76)
local choose = label(title, "Choose", "CHOOSE", UDim2.fromScale(.03,.57), UDim2.fromScale(.97,.34), palette.lavender, 100)
snooze.Rotation = -4
choose.Rotation = 3
local subtitle = label(safe, "Subtitle", "Tonight's choices shape tomorrow.", UDim2.new(), UDim2.new(), palette.cream, 21, Enum.Font.Gotham)
subtitle.TextWrapped = true

local menu = create("Frame", safe, {Name = "Menu", BackgroundTransparency = 1})
create("UISizeConstraint", menu, {MinSize = Vector2.new(0,100)})
local buttonShadow = create("Frame", menu, {
 Name = "ButtonShadow", Position = UDim2.fromScale(0,.065), Size = UDim2.fromScale(1,.5),
 BackgroundColor3 = Color3.fromRGB(149,102,79), BorderSizePixel = 0,
})
rounded(buttonShadow,12)
local play = create("TextButton", menu, {
 Name = "StartButton", Size = UDim2.fromScale(1,.5), BackgroundColor3 = palette.peach,
 BorderSizePixel = 0, Text = "LET'S PLAY", TextColor3 = palette.night,
 TextScaled = true, Font = Enum.Font.FredokaOne, AutoButtonColor = false, Selectable = true,
})
rounded(play,12)
create("UITextSizeConstraint", play, {MinTextSize = 15, MaxTextSize = 32})
local buttonScale = create("UIScale", play, {Scale = 1})
local how = create("TextButton", menu, {
 Name = "HowToPlay", AnchorPoint = Vector2.new(0,1), Position = UDim2.fromScale(0,1), Size = UDim2.new(1,0,0,44),
 BackgroundTransparency = 1, Text = "HOW TO PLAY", TextColor3 = palette.cream,
 Font = Enum.Font.GothamBold, TextScaled = true, Selectable = true,
})
create("UITextSizeConstraint", how, {MinTextSize = 12, MaxTextSize = 17})

-- A self-contained diorama: no assets, workspace changes, or live camera takeover.
local scene = create("ViewportFrame", safe, {
 Name = "BedsideScene", BackgroundTransparency = 1, Ambient = Color3.fromRGB(137,122,152),
 LightColor = Color3.fromRGB(255,222,172), LightDirection = Vector3.new(-1,-.7,-.8),
})
create("UIAspectRatioConstraint", scene, {AspectRatio = 1.12, DominantAxis = Enum.DominantAxis.Width})
local world = create("WorldModel", scene, {Name = "MenuDiorama"})
local camera = create("Camera", scene, {FieldOfView = 38})
scene.CurrentCamera = camera
camera.CFrame = CFrame.lookAt(Vector3.new(10,9,20), Vector3.new(0,3,0))
local function part(parent, name, size, position, color, shape)
 return create("Part", parent, {
  Name = name, Size = size, CFrame = CFrame.new(position), Color = color,
  Shape = shape or Enum.PartType.Block, Material = Enum.Material.SmoothPlastic,
  Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
 })
end
local function model(name) return create("Model", world, {Name = name}) end
local function block(name, size, pos, color) return part(world,name,size,pos,color) end
block("Rug",Vector3.new(13,.12,10),Vector3.new(0,-.2,0),Color3.fromRGB(68,65,90))
-- A partial bed makes this a bedroom rather than an isolated product display.
block("BedFrame",Vector3.new(4.6,.65,7),Vector3.new(-4,.7,-1.5),palette.wood)
block("Mattress",Vector3.new(4.4,.6,6.8),Vector3.new(-4,1.3,-1.5),palette.cream)
block("Blanket",Vector3.new(4.5,.25,4.7),Vector3.new(-4,1.72,-.5),Color3.fromRGB(73,112,137))
block("Pillow",Vector3.new(3.5,.6,1.45),Vector3.new(-4,1.8,-3.9),palette.wool)
block("Headboard",Vector3.new(4.8,3,.3),Vector3.new(-4,2,-5),palette.wood)
block("Nightstand",Vector3.new(5,.35,3.2),Vector3.new(1,2.7,0),palette.wood)
block("Drawer",Vector3.new(4.7,1.2,2.9),Vector3.new(1,1.9,0),Color3.fromRGB(119,79,56))
block("DrawerFront",Vector3.new(4.3,.75,.12),Vector3.new(1,2,1.51),palette.wood)
block("Handle",Vector3.new(1,.12,.15),Vector3.new(1,2,1.64),palette.gold)
for _, x in {-.9,2.9} do
 for _, z in {-1.1,1.1} do block("TableLeg",Vector3.new(.25,1.4,.25),Vector3.new(x,.6,z),palette.wood) end
end
local lamp = model("BedsideLamp")
part(lamp,"Base",Vector3.new(1.35,.18,1.35),Vector3.new(2.1,2.98,-.55),palette.gold,Enum.PartType.Ball)
part(lamp,"Stem",Vector3.new(.14,2.35,.14),Vector3.new(2.1,4.05,-.55),palette.gold)
local shade = part(lamp,"WarmShade",Vector3.new(1.25,2.25,2.25),Vector3.new(2.1,5.3,-.55),palette.cream,Enum.PartType.Cylinder)
shade.CFrame *= CFrame.Angles(0,0,math.pi/2)
part(lamp,"Bulb",Vector3.new(.6,.6,.6),Vector3.new(2.1,4.85,-.55),palette.gold,Enum.PartType.Ball)

local clock = model("AlarmClock")
part(clock,"Body",Vector3.new(2.7,1.65,.7),Vector3.new(-.65,3.8,.65),palette.peach)
part(clock,"Face",Vector3.new(2.38,1.2,.08),Vector3.new(-.65,3.85,1.04),palette.night)
for _, x in {-1.5,.2} do
 part(clock,"Bell",Vector3.new(.85,.48,.65),Vector3.new(x,4.75,.65),palette.lavender,Enum.PartType.Ball)
 part(clock,"Foot",Vector3.new(.2,.3,.3),Vector3.new(x,2.98,.65),palette.sheep)
end
-- Seven-segment 10:47 display is actual geometry; SurfaceGuis don't render in ViewportFrames.
local segments = {
 {0,.35,.26,.055},{.15,.18,.055,.28},{.15,-.18,.055,.28},
 {0,-.35,.26,.055},{-.15,-.18,.055,.28},{-.15,.18,.055,.28},{0,0,.26,.055},
}
local digits = { [1]={2,3}, [0]={1,2,3,4,5,6}, [4]={2,3,6,7}, [7]={1,2,3} }
for index, number in {1,0,4,7} do
 local x = -1.51 + (index-1)*.52 + (if index>2 then .14 else 0)
 for _, segmentIndex in digits[number] do
  local s = segments[segmentIndex]
  part(clock,"Digit",Vector3.new(s[3],s[4],.03),Vector3.new(x+s[1],3.92+s[2],1.10),palette.gold)
 end
end
local colon = {}
for _, y in {3.8,4.08} do table.insert(colon,part(clock,"Colon",Vector3.new(.065,.065,.035),Vector3.new(-.7,y,1.1),palette.gold)) end
-- Small PM mark, geometric rather than another UI overlay.
part(clock,"PM",Vector3.new(.12,.06,.03),Vector3.new(.28,3.4,1.1),palette.gold)
local clockHome = clock:GetPivot()

local phone = model("Phone")
part(phone,"Case",Vector3.new(.78,1.4,.16),Vector3.new(2.5,3.6,1.15),palette.sheep)
local phoneScreen = part(phone,"Screen",Vector3.new(.65,1.13,.03),Vector3.new(2.5,3.62,1.25),Color3.fromRGB(54,82,111))
local notification = part(phone,"Notification",Vector3.new(.47,.17,.035),Vector3.new(2.5,3.94,1.28),palette.blue)
notification.Transparency = 1
local eyes = {}
for _, x in {2.34,2.66} do
 local eye = part(phone,"Eye",Vector3.new(.27,.3,.15),Vector3.new(x,3.68,1.32),palette.wool,Enum.PartType.Ball)
 local pupil = part(phone,"Pupil",Vector3.new(.11,.14,.08),Vector3.new(x+.025,3.68,1.42),palette.night,Enum.PartType.Ball)
 eye.Transparency = 1 pupil.Transparency = 1
 table.insert(eyes,eye) table.insert(eyes,pupil)
end
local phoneHome = phone:GetPivot()
local plate = part(world,"SnackPlate",Vector3.new(1.3,.12,1.3),Vector3.new(.45,2.96,-.6),palette.cream,Enum.PartType.Ball)
part(world,"LastCookie",Vector3.new(.65,.12,.65),Vector3.new(.45,3.08,-.6),palette.wood,Enum.PartType.Ball)

local sheep = model("SleepSheep")
local wool = part(sheep,"Wool",Vector3.new(2.2,1.65,2.55),Vector3.new(3.9,1.15,2.7),palette.wool,Enum.PartType.Ball)
wool.Material = Enum.Material.Fabric
part(sheep,"Head",Vector3.new(.95,1,1),Vector3.new(3.9,1.45,4),palette.sheep)
for _, x in {3.28,4.52} do
 for _, z in {2.05,3.3} do part(sheep,"Leg",Vector3.new(.25,.7,.25),Vector3.new(x,.35,z),palette.sheep) end
 part(sheep,"Ear",Vector3.new(.44,.22,.2),Vector3.new(x,1.8,3.9),palette.sheep)
end
for _, x in {3.67,4.13} do
 part(sheep,"Eye",Vector3.new(.19,.22,.1),Vector3.new(x,1.59,4.53),palette.wool,Enum.PartType.Ball)
 part(sheep,"Pupil",Vector3.new(.08,.12,.06),Vector3.new(x,1.57,4.6),palette.night,Enum.PartType.Ball)
end
local sheepHome = sheep:GetPivot()
local zzz = label(safe,"FloatingZ","z  Z",UDim2.new(),UDim2.fromScale(.12,.06),palette.muted,27)
zzz.Rotation = -12

-- Instructions are a small paper note, with the same three-part game loop.
local scrim = create("TextButton",background,{
 Name="HelpScrim",Size=UDim2.fromScale(1,1),BackgroundColor3=palette.night,
 BackgroundTransparency=.18,Text="",Visible=false,AutoButtonColor=false,ZIndex=20,
})
local help = create("Frame",scrim,{
 Name="Instructions",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
 BackgroundColor3=palette.cream,BorderSizePixel=0,Rotation=-1,
})
rounded(help,6)
local heading=label(help,"Heading","A LITTLE BEDTIME PLAN",UDim2.fromScale(.08,.06),UDim2.fromScale(.84,.14),palette.night,30)
local steps={"1. Make your bedtime choices","2. Survive your dream","3. See how rested you wake up"}
for i, content in ipairs(steps) do
 label(help,"Step"..i,content,UDim2.fromScale(.08,.24+(i-1)*.15),UDim2.fromScale(.84,.105),palette.night,22,Enum.Font.GothamBold)
end
local luck=label(help,"SheepAside","a sheep, quietly: good luck.",UDim2.fromScale(.25,.67),UDim2.fromScale(.68,.08),Color3.fromRGB(103,91,117),15,Enum.Font.Gotham)
luck.Rotation=-3
local helpSheep=create("ViewportFrame",help,{
 Name="HelpfulSheep",Position=UDim2.fromScale(.07,.61),Size=UDim2.fromScale(.18,.18),
 BackgroundTransparency=1,Ambient=Color3.fromRGB(170,160,180),LightColor=palette.cream,
})
local sheepCopy=sheep:Clone()
sheepCopy:PivotTo(CFrame.new()) sheepCopy.Parent=helpSheep
local helpCamera=create("Camera",helpSheep,{FieldOfView=35})
helpCamera.CFrame=CFrame.lookAt(Vector3.new(1,1,6),Vector3.zero)
helpSheep.CurrentCamera=helpCamera
local close=create("TextButton",help,{
 Name="CloseHelp",Position=UDim2.fromScale(.26,.81),Size=UDim2.fromScale(.48,.12),
 Text="GOT IT",TextScaled=true,Font=Enum.Font.FredokaOne,TextColor3=palette.night,
 BackgroundColor3=palette.lavender,BorderSizePixel=0,Selectable=true,
})
rounded(close,7)
create("UITextSizeConstraint",close,{MinTextSize=12,MaxTextSize=23})

local function layout()
 local size=background.AbsoluteSize
 local portrait=size.X/ math.max(size.Y,1)<1.05
 if portrait then
  title.Position=UDim2.fromScale(.04,0) title.Size=UDim2.fromScale(.85,.34)
  subtitle.Position=UDim2.fromScale(.05,.33) subtitle.Size=UDim2.fromScale(.9,.055)
  scene.Position=UDim2.fromScale(-.03,.37) scene.Size=UDim2.fromScale(1,.4)
  menu.AnchorPoint=Vector2.new(0,1) menu.Position=UDim2.fromScale(.12,.99) menu.Size=UDim2.fromScale(.76,.18)
  zzz.Position=UDim2.fromScale(.18,.41)
  help.Size=UDim2.fromScale(.88,.56)
 else
  title.Position=UDim2.fromScale(.01,.035) title.Size=UDim2.fromScale(.46,.55)
  subtitle.Position=UDim2.fromScale(.025,.61) subtitle.Size=UDim2.fromScale(.44,.065)
  scene.Position=UDim2.fromScale(.43,.06) scene.Size=UDim2.fromScale(.61,.81)
  menu.AnchorPoint=Vector2.new(0,1) menu.Position=UDim2.fromScale(.025,.96) menu.Size=UDim2.fromScale(.32,.23)
  zzz.Position=UDim2.fromScale(.51,.24)
  help.Size=UDim2.fromScale(.57,.67)
 end
end
connect(background:GetPropertyChangedSignal("AbsoluteSize"),layout)
layout()
connect(how.Activated,function()
 if started then return end
 scrim.Visible=true
 if GuiService.SelectedObject then GuiService.SelectedObject=close end
end)
local function closeHelp()
 scrim.Visible=false
 if GuiService.SelectedObject then GuiService.SelectedObject=how end
end
connect(close.Activated,closeHelp)
connect(scrim.Activated,closeHelp)
local function hover(on)
 if started then return end
 animate(buttonScale,.14,{Scale=on and 1.035 or 1})
 animate(play,.14,{Position=UDim2.fromScale(0,on and -.018 or 0)})
end
connect(play.MouseEnter,function() hover(true) end)
connect(play.MouseLeave,function() hover(false) end)
connect(play.SelectionGained,function() hover(true) end)
connect(play.SelectionLost,function() hover(false) end)

-- One clock drives restrained, spaced-out details. Every connection is cleaned up.
local elapsed=0
local settling=0
connect(RunService.RenderStepped,function(dt)
 elapsed+=dt
 if started then return end
 settling=math.min(settling+dt*2,1)
 you.Rotation=2+(1-settling)*7
 local blink=math.floor(elapsed)%2==0
 for _, dot in ipairs(colon) do dot.Transparency=if blink then 0 else .85 end
 local phase=elapsed%13
 local shake=if phase>10 and phase<10.45 then math.sin(phase*65)*.045 else 0
 clock:PivotTo(clockHome*CFrame.Angles(0,0,shake))
 local buzz=phase>6 and phase<6.8
 notification.Transparency=if buzz then 0 else 1
 phone:PivotTo(phoneHome*CFrame.Angles(0,0,if buzz then math.sin(phase*50)*.025 else 0))
 local eyeTime=elapsed%29
 for _, eye in ipairs(eyes) do eye.Transparency=if eyeTime>23 and eyeTime<24.2 then 0 else 1 end
 local sheepPhase=elapsed%19
 local peek=if sheepPhase>12 and sheepPhase<16 then math.sin((sheepPhase-12)/4*math.pi)*.65 else 0
 sheep:PivotTo(sheepHome*CFrame.new(-peek,math.abs(math.sin(peek*5))*.08,0))
 local warmth=math.sin(elapsed*.4)*3
 scene.LightColor=Color3.fromRGB(255,222+warmth,172+warmth)
end)
connect(gui.Destroying,function()
 alive=false
 for _, connection in ipairs(connections) do connection:Disconnect() end
 for _, tween in pairs(activeTweens) do tween:Cancel() end
end)

-- Fast cinematic, then the team's bounded room-loading handshake and camera setup.
connect(play.Activated,function()
 if started then return end
 started=true play.Active=false scrim.Visible=false
 animate(buttonScale,.1,{Scale=.97})
 animate(play,.1,{Position=UDim2.fromScale(0,.055)}).Completed:Wait()
 local transitionStart=os.clock()
 while alive and os.clock()-transitionStart<.55 do
  local t=os.clock()-transitionStart
  clock:PivotTo(clockHome*CFrame.Angles(0,0,math.sin(t*55)*.09))
  task.wait()
 end
 clock:PivotTo(clockHome)
 notification.Transparency=0
 animate(scene,.65,{LightColor=Color3.fromRGB(116,107,146),Ambient=Color3.fromRGB(73,68,99)})
 animate(title,.3,{Rotation=-2})
 transitionStart=os.clock()
 while alive and os.clock()-transitionStart<.75 do
  local t=(os.clock()-transitionStart)/.75
  sheep:PivotTo(sheepHome*CFrame.new(-t*3,math.abs(math.sin(t*math.pi*4))*.3,0))
  task.wait()
 end
 local fade=create("Frame",gui,{
  Name="Fade",Size=UDim2.fromScale(1,1),BackgroundColor3=palette.night,
  BackgroundTransparency=1,BorderSizePixel=0,ZIndex=100,
 })
 animate(fade,.45,{BackgroundTransparency=0}).Completed:Wait()
 local startCFrame, character, startupError
 local finished, cancelled=false,false
 task.spawn(function()
  local ok,err=pcall(function()
   local startGame=game:GetService("ReplicatedStorage"):WaitForChild("StartGame",10)
   assert(startGame,"StartGame is unavailable")
   repeat
    if cancelled then return end
    character=player.Character
    if character and character:GetAttribute("BedroomReady") then startCFrame=startGame:InvokeServer() end
    if not startCFrame then task.wait(.1) end
   until startCFrame
  end)
  if not ok then startupError=err end
  finished=true
 end)
 local deadline=os.clock()+12
 repeat task.wait() until finished or os.clock()>=deadline or not alive
 if not alive then cancelled=true return end
 if not finished or startupError or not startCFrame then
  cancelled=true
  warn("Unable to start game: "..tostring(startupError or "startup timed out"))
  fade:Destroy()
  subtitle.Text="Room could not load. Please try again."
  play.Text="RETRY" play.Active=true started=false
  buttonScale.Scale=1 play.Position=UDim2.fromScale(0,0)
  title.Rotation=0 sheep:PivotTo(sheepHome)
  scene.Ambient=Color3.fromRGB(137,122,152)
  return
 end
 local gameCamera=workspace.CurrentCamera
 local humanoid=character:WaitForChild("Humanoid")
 player.CameraMinZoomDistance=.5 player.CameraMaxZoomDistance=12
 gameCamera.CameraSubject=humanoid gameCamera.CameraType=Enum.CameraType.Custom
 local focus=startCFrame.Position+Vector3.new(0,2,0)
 gameCamera.CFrame=CFrame.lookAt(focus-startCFrame.LookVector*8+Vector3.new(0,2,0),focus+startCFrame.LookVector*8)
 background.Visible=false
 animate(fade,.6,{BackgroundTransparency=1}).Completed:Wait()
 gui:Destroy()
end)
