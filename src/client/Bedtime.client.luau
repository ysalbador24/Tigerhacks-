local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dream = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dream"))
local DreamCourse = require(script.Parent:WaitForChild("DreamCourse"))
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "BedtimeRoutine"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
local cream = Color3.fromRGB(247, 233, 212)
local ink = Color3.fromRGB(48, 43, 58)
local function label(parent, text, pos, size)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Text = text; t.TextColor3 = cream
	t.Font = Enum.Font.Gotham; t.TextSize = 18; t.TextWrapped = true
	t.Position = pos; t.Size = size; t.Parent = parent
	return t
end
local function panel(pos, size)
	local f = Instance.new("Frame")
	f.Position = pos; f.Size = size; f.BackgroundColor3 = ink; f.BackgroundTransparency = 0.08; f.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,16); corner.Parent = f
	return f
end
local hud = panel(UDim2.fromScale(0.025,0.035), UDim2.fromScale(0.4,0.18))
local clock = label(hud,"10:00 PM • Your evening",UDim2.fromScale(0.04,0.04),UDim2.fromScale(0.92,0.28))
local progress = label(hud,"0 / 11 choices • Explore your room",UDim2.fromScale(0.04,0.34),UDim2.fromScale(0.92,0.3))
label(hud,"Walk to an object and use its prompt.",UDim2.fromScale(0.04,0.65),UDim2.fromScale(0.92,0.25))
local moodPanel=panel(UDim2.fromScale(0.615,0.035),UDim2.fromScale(0.36,0.27))
moodPanel.Name="MoodMeter"
local moodText=label(moodPanel,"Mood: Okay • 50 / 100",UDim2.fromScale(0.04,0.01),UDim2.fromScale(0.92,0.2))
local function meter(y,color)
	local track=Instance.new("Frame");track.Position=UDim2.fromScale(0.06,y);track.Size=UDim2.fromScale(0.88,0.065);track.BackgroundColor3=Color3.fromRGB(80,72,85);track.BorderSizePixel=0;track.Parent=moodPanel
	local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(0.5,1);fill.BackgroundColor3=color;fill.BorderSizePixel=0;fill.Parent=track
	return fill
end
local moodFill=meter(0.23,Color3.fromRGB(190,205,153))
local restText=label(moodPanel,"Sleep readiness: 50 / 100",UDim2.fromScale(0.04,0.32),UDim2.fromScale(0.92,0.2))
local restFill=meter(0.55,Color3.fromRGB(160,191,220))
local sleepText=label(moodPanel,"Simulated sleep: 7h 00m",UDim2.fromScale(0.04,0.65),UDim2.fromScale(0.92,0.2))
local note=label(moodPanel,"Character simulation",UDim2.fromScale(0.04,0.87),UDim2.fromScale(0.92,0.1));note.TextSize=11
local feedbackPanel=panel(UDim2.fromScale(0.2,0.905),UDim2.fromScale(0.6,0.08))
feedbackPanel.Name="MoodFeedback"
local feedbackText=label(feedbackPanel,"Your choices shape your character's evening.",UDim2.fromScale(0.03,0.05),UDim2.fromScale(0.94,0.9))
feedbackText.TextSize=15
local lastWellbeing
local function updateMood(wellbeing,feedback)
	if not wellbeing then return end
	local difference=if lastWellbeing then wellbeing.mood-lastWellbeing.mood else 0
	local restDifference=if lastWellbeing then wellbeing.rest-lastWellbeing.rest else 0
	moodText.Text="Mood: "..wellbeing.moodLabel.." • "..wellbeing.mood.." / 100"
	restText.Text="Sleep readiness: "..wellbeing.rest.." / 100"
	sleepText.Text=string.format("Simulated sleep: %dh %02dm",math.floor(wellbeing.sleepMinutes/60),wellbeing.sleepMinutes%60)
	TweenService:Create(moodFill,TweenInfo.new(0.4),{Size=UDim2.fromScale(wellbeing.mood/100,1),BackgroundColor3=if wellbeing.mood>=60 then Color3.fromRGB(190,205,153) else Color3.fromRGB(222,184,136)}):Play()
	TweenService:Create(restFill,TweenInfo.new(0.4),{Size=UDim2.fromScale(wellbeing.rest/100,1)}):Play()
	if feedback then feedbackText.Text=feedback..string.format("  Mood %+d • Readiness %+d",difference,restDifference) end
	lastWellbeing=wellbeing
end
local dialog = panel(UDim2.fromScale(0.2,0.32),UDim2.fromScale(0.6,0.57))
dialog.Visible = false
local title = label(dialog,"",UDim2.fromScale(0.05,0.04),UDim2.fromScale(0.9,0.13))
title.Font = Enum.Font.GothamBold; title.TextSize = 24
local story = label(dialog,"",UDim2.fromScale(0.05,0.18),UDim2.fromScale(0.9,0.36))
local function button(text, y)
	local b=Instance.new("TextButton"); b.Text=text; b.Position=UDim2.fromScale(0.07,y); b.Size=UDim2.fromScale(0.86,0.14)
	b.BackgroundColor3=Color3.fromRGB(183,203,190); b.TextColor3=ink; b.Font=Enum.Font.Gotham; b.TextSize=17; b.TextWrapped=true; b.Parent=dialog
	local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
	return b
end
local first, second, close = button("",0.56),button("",0.73),button("Back to the room",0.9)
close.Size=UDim2.fromScale(0.86,0.08)
story.TextYAlignment=Enum.TextYAlignment.Top
local function capText(object,max) local c=Instance.new("UITextSizeConstraint"); c.MaxTextSize=max; c.MinTextSize=9; c.Parent=object end
capText(story,17)
-- The morning screen needs more room than a single choice.
local function layout(morning)
	dialog.Position=if morning then UDim2.fromScale(0.15,0.06) else UDim2.fromScale(0.2,0.32)
	dialog.Size=if morning then UDim2.fromScale(0.7,0.86) else UDim2.fromScale(0.6,0.57)
	title.Size=if morning then UDim2.fromScale(0.9,0.08) else UDim2.fromScale(0.9,0.13)
	story.Position=if morning then UDim2.fromScale(0.05,0.11) else UDim2.fromScale(0.05,0.18)
	story.Size=if morning then UDim2.fromScale(0.9,0.72) else UDim2.fromScale(0.9,0.36)
	story.TextSize=18
	story.TextScaled=morning -- long morning reports shrink to fit (capped below)
	first.Position=if morning then UDim2.fromScale(0.07,0.85) else UDim2.fromScale(0.07,0.56)
	first.Size=if morning then UDim2.fromScale(0.86,0.1) else UDim2.fromScale(0.86,0.14)
end
-- Dream HUD: what tonight's choices changed, plus stumbles and a safety wake button.
local dreamPanel=panel(UDim2.fromScale(0.02,0.03),UDim2.fromScale(0.36,0.3))
dreamPanel.Name="DreamPanel"; dreamPanel.Visible=false
local dreamTitle=label(dreamPanel,"The Dream • Reach the morning light",UDim2.fromScale(0.05,0.03),UDim2.fromScale(0.9,0.14))
dreamTitle.Font=Enum.Font.GothamBold
local dreamLines=label(dreamPanel,"",UDim2.fromScale(0.05,0.18),UDim2.fromScale(0.9,0.52)); dreamLines.TextSize=15
dreamLines.TextXAlignment=Enum.TextXAlignment.Left; dreamLines.TextYAlignment=Enum.TextYAlignment.Top
dreamLines.TextScaled=true; capText(dreamLines,15)
local dreamStatus=label(dreamPanel,"Stumbles: 0",UDim2.fromScale(0.05,0.72),UDim2.fromScale(0.55,0.22)); dreamStatus.TextSize=15
dreamStatus.TextXAlignment=Enum.TextXAlignment.Left
local wakeButton=Instance.new("TextButton"); wakeButton.Text="Wake up now"; wakeButton.Position=UDim2.fromScale(0.62,0.74); wakeButton.Size=UDim2.fromScale(0.33,0.2)
wakeButton.BackgroundColor3=Color3.fromRGB(183,203,190); wakeButton.TextColor3=ink; wakeButton.Font=Enum.Font.Gotham; wakeButton.TextSize=14; wakeButton.Visible=false; wakeButton.Parent=dreamPanel
local wakeCorner=Instance.new("UICorner"); wakeCorner.CornerRadius=UDim.new(0,8); wakeCorner.Parent=wakeButton
local overlay=Instance.new("TextLabel"); overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(12,12,28); overlay.BackgroundTransparency=1
overlay.TextTransparency=1; overlay.Text="Falling asleep..."; overlay.TextColor3=cream; overlay.Font=Enum.Font.GothamBold; overlay.TextSize=32; overlay.ZIndex=10; overlay.Parent=gui
gui.IgnoreGuiInset=true
local demo=false
local function isEssential(key) return table.find(Dream.essentials,key)~=nil end
local activities = {
	{"Curtains","The world outside can wait.","Close the curtains","Leave them open",Vector3.new(-99,22.4,-185)},
	{"Lighting","A softer glow makes this room feel like a place to rest.","Turn off the main light","Turn on the main light",Vector3.new(-95,17.4,-134.5)},
	{"Food","Dinner is over. What feels right for the end of your evening?","Finish eating for tonight","Have a late heavy meal",Vector3.new(-62,19,-157)},
	{"Phone","One more video could become many. Where will your phone spend the night?","Put the phone on the desk","Keep scrolling in bed",Vector3.new(-102,19,-164)},
	{"Notifications","The group chat is still buzzing. You can catch up tomorrow.","Turn on Do Not Disturb","Keep notifications on",Vector3.new(-98,19,-165)},
	{"Temperature","Settle into a room that feels comfortably cool to you.","Make the room comfortably cool","Keep the room warm",Vector3.new(-109,21,-149)},
	{"Shower","Warm water, a soft towel, and a quiet moment to reset.","Take a warm shower","Skip showering",Vector3.new(-128,17,-145)},
	{"BrushTeeth","Set your toothbrush ready and take a moment for your evening routine.","Brush my teeth","Skip brushing",Vector3.new(-120.5,18,-147.5)},
	{"Skincare","Cleanse, moisturize, and settle into your evening.","Do my skincare routine","Skip skincare",Vector3.new(-114.5,18,-147.5)},
	{"Reading","A quiet chapter in your cozy upstairs nook.","Read a quiet chapter","Skip reading",Vector3.new(-62.5,34,-148)},
	{"WindDown","Let your shoulders relax. Breathe gently at your own pace for a quiet minute.","Take a quiet breathing break","Skip winding down",Vector3.new(-71,17,-149)},
}
local root=Instance.new("Folder"); root.Name="BedtimeInteractions"; root.Parent=workspace
local function part(name,size,pos,color)
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Anchored=true; p.CanCollide=false; p.Parent=root; return p
end
local curtains={}
local expansion
local candleOn=true
local tvOn=false
local phone=part("BedtimePhone",Vector3.new(1,0.15,1.8),Vector3.new(-102,18.6,-163),ink)
local plate=part("EveningPlate",Vector3.new(2.5,0.15,2.5),Vector3.new(-62,17.8,-157),cream)
local snack=part("LateSnack",Vector3.new(1.6,0.5,1.6),Vector3.new(-62,18.1,-157),Color3.fromRGB(190,126,72))
local thermostat=part("Thermostat",Vector3.new(0.3,2,2.5),Vector3.new(-109.5,19,-149),cream)
local temperatureGui=Instance.new("BillboardGui"); temperatureGui.Size=UDim2.fromOffset(140,40); temperatureGui.StudsOffset=Vector3.new(0,2,0); temperatureGui.MaxDistance=20; temperatureGui.Parent=thermostat
local temperatureText=label(temperatureGui,"72°F • Warm",UDim2.fromScale(0,0),UDim2.fromScale(1,1))
local prompts={}
local answers={}
local current=nil
local busy=false
local completed=false
local startedAt=0
local remote -- assigned below after intro
local runDream
local function request(key,option)
	local done,result=false,nil
	task.spawn(function()
		local ok,value=pcall(function() return remote:InvokeServer(key,option) end)
		if ok then result=value end
		done=true
	end)
	local deadline=os.clock()+15 -- server may wait on Gemini and the text filter
	repeat task.wait() until done or os.clock()>deadline
	return result
end
local function refresh()
	if demo then
		local parts, done={},0
		for _,key in Dream.essentials do
			if answers[key] then done+=1 end
			table.insert(parts,key..(if answers[key] then " ✓" else " ·"))
		end
		progress.Text="Key choices "..done.." / "..#Dream.essentials.." • "..table.concat(parts,"  ")..(if done==#Dream.essentials then "\nYour bed is ready. Other activities are optional." else "")
		return
	end
	local count=0; for _ in answers do count+=1 end
	progress.Text=count.." / "..#activities.." choices • "..(if count==#activities then "Your bed is ready" else "Explore your room")
end
-- Demo mode shortens activity sequences so the whole loop fits in two minutes.
local function pace(seconds) return if demo then math.max(3,math.floor(seconds*0.25+0.5)) else seconds end
local function show(key)
	if busy or completed then return end
	current=key; dialog.Visible=true; first.Visible=true; second.Visible=key~="Sleep"; close.Visible=true
	if key=="Sleep" then
		title.Text="Call it a night"; story.Text="Your choices are yours. Ready to see how this evening adds up?"; first.Text="Go to sleep"
	else
		for _,a in activities do if a[1]==key then title.Text=key; story.Text=a[2]; first.Text=a[3]; second.Text=a[4] end end
	end
end
local function prompt(key,pos)
	local anchor=part(key.."Interaction",Vector3.new(1,1,1),pos,cream); anchor.Transparency=1
	local p=Instance.new("ProximityPrompt"); p.ActionText="Choose"; p.ObjectText=key; p.MaxActivationDistance=10; p.RequiresLineOfSight=false; p.Enabled=false; p.Parent=anchor
	p.Triggered:Connect(function() show(key) end); table.insert(prompts,p)
end
for _,a in activities do prompt(a[1],a[5]) end
prompt("Sleep",Vector3.new(-78,21,-180))
local roomLights={}
local function setCurtains(closed)
	for _,p in curtains do
		TweenService:Create(p,TweenInfo.new(0.7),{
			Position=p:GetAttribute(if closed then "ClosedPosition" else "OpenPosition"),
			Size=Vector3.new(if closed then 1.2 else 0.28,16,0.35),
		}):Play()
	end
end
local function setCandle(on)
	candleOn=on
	local room=workspace:FindFirstChild("CozyBedroom101")
	if not room then return end
	for _,p in room:GetDescendants() do
		if p:IsA("BasePart") and p.Name=="Flame" then
			p.Transparency=if on then 0 else 1
			for _,light in p:GetChildren() do if light:IsA("PointLight") then light.Enabled=on end end
		end
	end
	if expansion then expansion.InteractiveCandle.CandleJar.RoomControlPrompt.ActionText=if on then "Extinguish" else "Light" end
end
local function setTV(on)
	tvOn=on
	if not expansion then return end
	local tv=expansion.TelevisionConsole
	tv.TVScreen.TVDisplay.Enabled=on
	tv.TVScreen.Material=if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	tv.TVScreen.Color=if on then Color3.fromRGB(89,115,102) else Color3.fromRGB(22,28,27)
	tv.TVRemote.RoomControlPrompt.ActionText=if on then "Turn off" else "Turn on"
end
local function apply(key,option)
	local good=option==1
	if key=="Curtains" then setCurtains(good) end
	if key=="Lighting" then
		Lighting.Brightness=if good then 0.7 else 2
		Lighting.Ambient=if good then Color3.fromRGB(95,80,101) else Color3.fromRGB(150,150,150)
		for light,brightness in roomLights do if light.Parent then light.Brightness=brightness*(if good then (if light.Parent.Name=="RoomLight" then 0 else 0.35) else 1) end end
		if expansion then
			local rocker=expansion.WallLightSwitch.Switch
			rocker.Orientation=Vector3.new(if good then -15 else 15,0,0)
			local shelf=expansion.ReadingLoft:FindFirstChild("BuiltInBookshelf")
			if shelf then shelf.UpstairsSwitch.Orientation=Vector3.new(0,0,if good then -15 else 15) end
		end
	end
	if key=="Phone" then phone.Position=if good then Vector3.new(-102,18.6,-163) else Vector3.new(-78,20.7,-180) end
	if key=="Notifications" then phone.Color=if good then ink else Color3.fromRGB(120,196,232) end
	if key=="Temperature" then temperatureText.Text=if good then "67°F • Cool" else "72°F • Warm"; thermostat.Color=if good then Color3.fromRGB(160,200,220) else cream end
	if key=="Food" then snack.Transparency=if good then 1 else 0 end
end
local function showMorning(result)
	TweenService:Create(Lighting,TweenInfo.new(3),{ClockTime=7.2,Brightness=2,Ambient=Color3.fromRGB(150,140,130)}):Play()
	updateMood(result.wellbeing)
	layout(true)
	dialog.Visible=true; hud.Visible=true; feedbackPanel.Visible=true
	title.Text="Morning • Dream Stability "..result.stability.." / 100"
	local lines={}
	for _,line in result.dreamLines do table.insert(lines,"• "..line) end
	story.Text=result.feeling.." • Mood: "..result.wellbeing.moodLabel
		..string.format(" • Simulated sleep: %dh %02dm",math.floor(result.wellbeing.sleepMinutes/60),result.wellbeing.sleepMinutes%60)
		.." • Stumbles: "..result.stumbles
		.." • Sheep counted: "..result.sheep.." / "..result.sheepTotal
		.."\n\nYour choices shaped the dream:\n"..table.concat(lines,"\n")
		.."\n\n"..result.reflectionSource.." says: "..result.reflection
		.."\n\n"..result.suggestion
		.."\n\nBased on CDC sleep tips: turn off screens before bed, keep your room dark, quiet, and cool, and avoid large meals late at night. Dream Stability is a game outcome, not a measure of your health."
	current="Replay"; first.Text="Play another evening"; first.Visible=true; second.Visible=false; close.Visible=false
end
local function fade(visible,text)
	overlay.Text=text or overlay.Text
	local tween=TweenService:Create(overlay,TweenInfo.new(1),{BackgroundTransparency=if visible then 0 else 1,TextTransparency=if visible then 0 else 1})
	tween:Play(); tween.Completed:Wait()
end
function runDream(config)
	completed=true; for _,p in prompts do p.Enabled=false end
	dialog.Visible=false; hud.Visible=false; feedbackPanel.Visible=false
	fade(true,"Falling asleep...")
	local wakeRequest=nil
	local stumbles, sheepCount=0,0
	local function status(extra)
		dreamStatus.Text="Sheep: "..sheepCount.." / "..(config.sheepCountable or 0).." • Stumbles: "..stumbles..(if extra then "\n"..extra else "")
	end
	local course=DreamCourse.build(config,{
		onGoal=function() wakeRequest="goal" end,
		onBuzz=function(text) status(text) end,
		onSheep=function(count,name) sheepCount=count; status(name.." counted!") end,
	})
	if not request("EnterDream") then
		course.destroy(); fade(false)
		completed=false; for _,p in prompts do p.Enabled=true end
		hud.Visible=true; feedbackPanel.Visible=true
		return
	end
	local lines={}
	for _,line in config.lines do table.insert(lines,"• "..line) end
	dreamLines.Text=table.concat(lines,"\n")
	dreamLines.Text=dreamLines.Text.."\n• Count the sheep. Walk up to one to count it."
	status(); wakeButton.Visible=false; dreamPanel.Visible=true
	local stumbleConnection=player:GetAttributeChangedSignal("DreamStumbles"):Connect(function()
		stumbles=player:GetAttribute("DreamStumbles") or 0; status("Whoops. Back to the checkpoint.")
	end)
	local wakeConnection=wakeButton.Activated:Connect(function() wakeRequest="early" end)
	fade(false)
	local dreamStart=os.clock()
	local result
	while not result do
		if not wakeButton.Visible and os.clock()-dreamStart>=Dream.earlyWakeSeconds then wakeButton.Visible=true end
		if wakeRequest then
			fade(true,"Waking up...")
			result=request("Wake",{early=wakeRequest=="early",sheep=course.sheepCounted()})
			if not result then fade(false); wakeRequest=nil; course.resetGoal() end
		end
		task.wait(0.1)
	end
	stumbleConnection:Disconnect(); wakeConnection:Disconnect()
	course.destroy(); dreamPanel.Visible=false
	showMorning(result)
	fade(false)
end
local function choose(option)
	if busy then return end
	busy=true
	local key=current
	local result=request(key,option)
	if not result then story.Text="Could not save that choice. Please try again."; busy=false; return end
	if key=="Replay" and result.replay then
		layout(false)
		lastWellbeing=nil; updateMood(result.wellbeing,"A fresh evening begins.")
		answers={}; completed=false; startedAt=os.clock(); Lighting.ClockTime=18.5
		Lighting.Brightness=2; Lighting.Ambient=Color3.fromRGB(110,100,120)
		setCurtains(false); setCandle(true); setTV(false)
		apply("Phone",1); apply("Notifications",2); apply("Temperature",2); apply("Food",2); apply("Lighting",2)
		for _,p in prompts do p.Enabled=true end
		refresh(); dialog.Visible=false
	elseif key=="Sleep" then
		if result.message then story.Text=result.message
		elseif result.dream then runDream(result.dream) end
	elseif result.accepted then
		answers[key]=option; apply(key,option); refresh(); updateMood(result.wellbeing,result.feedback)
		if option==1 and (key=="Shower" or key=="BrushTeeth" or key=="Skincare") then
			first.Visible=false; second.Visible=false; close.Visible=false
			local bathroom=workspace.CozyBedroom101:FindFirstChild("EnsuiteBathroom")
			local duration=pace(if key=="Shower" then 15 elseif key=="BrushTeeth" then 20 else 12)
			local brush=if bathroom then bathroom:FindFirstChild("Toothbrush") else nil
			local brushHome=if brush then brush.CFrame else nil
			if bathroom and key=="Shower" then
				for _,p in bathroom:GetChildren() do if p.Name=="ShowerWater" then p.Transparency=0.45 end end
			end
			for remaining=duration,1,-1 do
				story.Text=(if key=="Shower" then "The shower is running. Enjoy a quiet moment." elseif key=="BrushTeeth" then "Freshening up for the night." else "A little care at the end of the day.").."\n\n"..remaining.." seconds • game activity"
				if key=="BrushTeeth" and brush and player.Character and player.Character:FindFirstChild("Head") then
					brush.CanCollide=false
					brush.CFrame=player.Character.Head.CFrame*CFrame.new(0.35*(if remaining%2==0 then 1 else -1),-0.25,-0.8)*CFrame.Angles(0,0,math.pi/2)
				end
				task.wait(1)
			end
			if brush and brushHome then brush.CFrame=brushHome end
			if bathroom then for _,p in bathroom:GetChildren() do if p.Name=="ShowerWater" then p.Transparency=1 end end end
		end
		if key=="Reading" and option==1 then
			first.Visible=false; second.Visible=false; close.Visible=false
			for remaining=pace(15),1,-1 do story.Text="The garden grew quiet as the sun slipped away. Tomorrow could wait another chapter.\n\nReading • "..remaining.." seconds"; task.wait(1) end
		end
		if key=="WindDown" and option==1 then
			first.Visible=false; second.Visible=false; close.Visible=false
			for remaining=pace(60),1,-1 do story.Text="Rest your shoulders. Breathe gently.\nNothing to rush.\n"..remaining.." seconds"; task.wait(1) end
		end
		dialog.Visible=false
	end
	busy=false
end
first.Activated:Connect(function() choose(1) end)
second.Activated:Connect(function() choose(2) end)
close.Activated:Connect(function() if not busy then dialog.Visible=false end end)
setCurtains(false); setCandle(true); setTV(false)
repeat task.wait(0.2) until player:GetAttribute("StartedGame") and not player.PlayerGui:FindFirstChild("StartScreen")
remote=game:GetService("ReplicatedStorage"):WaitForChild("BedtimeChoice",15)
if not remote then gui:Destroy(); root:Destroy(); return end
demo=ReplicatedStorage:GetAttribute("DemoMode")==true
if demo then
	for _,p in prompts do if isEssential(p.ObjectText) then p.ObjectText=p.ObjectText.." • key choice" end end
end
for _,object in workspace:GetDescendants() do
	if object:IsA("PointLight") and object.Parent:IsA("BasePart") and object.Parent.Name~="Flame" and (object.Parent.Position-Vector3.new(-84,25,-161)).Magnitude<40 then roomLights[object]=object.Brightness end
end
local bedroom=workspace:WaitForChild("CozyBedroom101",15)
if bedroom then
	expansion=bedroom:WaitForChild("CottageExpansion",15)
	if expansion then
		for _,fold in expansion.LinenCurtains:GetChildren() do
			if fold:GetAttribute("ClosedPosition") then table.insert(curtains,fold) end
		end
		for _,object in expansion:GetDescendants() do
			if object:IsA("ProximityPrompt") then
				object.Triggered:Connect(function()
					if busy or completed then return end
					local key=object.Parent:GetAttribute("RoomControl")
					if key=="TV" then setTV(not tvOn) elseif key=="Candle" then setCandle(not candleOn) elseif key=="Lighting" then show("Lighting") end
				end)
				table.insert(prompts,object)
			end
		end
		setCurtains(false); setCandle(true); setTV(false)
	end
end
local status=request("Status")
if status then updateMood(status.wellbeing) end
refresh()
gui.Enabled=true; startedAt=os.clock(); Lighting.ClockTime=18.5
Lighting.Ambient=Color3.fromRGB(110,100,120)
for _,p in prompts do p.Enabled=true end
while gui.Parent do
	if not completed then
		local elapsed=os.clock()-startedAt
		local minutes=math.min(60,math.floor(elapsed/5))
		clock.Text=string.format("%d:%02d PM • %s",10+math.floor(minutes/60),minutes%60,if demo then "Demo: make 3 key choices, then sleep" elseif elapsed<300 then "Bedtime in "..math.ceil((300-elapsed)/60).." min" else "Ready for bed")
		Lighting.ClockTime=18.5+3.5*math.min(elapsed/45,1)
	end
	task.wait(1)
end
