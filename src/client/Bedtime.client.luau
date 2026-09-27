local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dream = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dream"))
local DreamCourse = require(script.Parent:WaitForChild("DreamCourse"))
local ShowerInteraction = require(script.Parent:WaitForChild("ShowerInteraction"))
local ReadingInteraction = require(script.Parent:WaitForChild("ReadingInteraction"))
local BedtimeRush = require(script.Parent:WaitForChild("BedtimeRush"))
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
local progress = label(hud,"Activities completed: 0 • All optional",UDim2.fromScale(0.04,0.34),UDim2.fromScale(0.92,0.3))
progress.TextScaled=true
do local c=Instance.new("UITextSizeConstraint"); c.MaxTextSize=18; c.Parent=progress end
clock.TextScaled=true
do local c=Instance.new("UITextSizeConstraint"); c.MaxTextSize=18; c.Parent=clock end
local bedCue=label(hud,"Go to Bed • upstairs • anytime",UDim2.fromScale(0.04,0.65),UDim2.fromScale(0.92,0.25))
bedCue.TextScaled=true; bedCue.TextColor3=Color3.fromRGB(212,225,183)
local objective=panel(UDim2.fromScale(0.2,0.31),UDim2.fromScale(0.6,0.16))
objective.Name="EveningObjective"; objective.Visible=false
local objectiveText=label(objective,"You have until 11 PM to get ready for bed. Try activities around the room, or go to bed early. Your choices will affect your dream.",UDim2.fromScale(0.05,0.1),UDim2.fromScale(0.9,0.8))
objectiveText.TextScaled=true
local objectiveVersion=0
local function showObjective()
	objectiveVersion+=1; local version=objectiveVersion
	objective.Visible=true
	task.delay(10,function() if objectiveVersion==version then objective.Visible=false end end)
end
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
	moodText.Text="Mood: "..wellbeing.moodLabel.." • "..wellbeing.mood.." / 100"
	restText.Text="Sleep readiness: "..wellbeing.rest.." / 100"
	sleepText.Text=string.format("Simulated sleep: %dh %02dm",math.floor(wellbeing.sleepMinutes/60),wellbeing.sleepMinutes%60)
	TweenService:Create(moodFill,TweenInfo.new(0.4),{Size=UDim2.fromScale(wellbeing.mood/100,1),BackgroundColor3=if wellbeing.mood>=60 then Color3.fromRGB(190,205,153) else Color3.fromRGB(222,184,136)}):Play()
	TweenService:Create(restFill,TweenInfo.new(0.4),{Size=UDim2.fromScale(wellbeing.rest/100,1)}):Play()
	if feedback then feedbackText.Text=feedback end
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
local fadeGui=Instance.new("ScreenGui"); fadeGui.Name="DreamFade"; fadeGui.IgnoreGuiInset=true; fadeGui.DisplayOrder=20; fadeGui.ResetOnSpawn=false; fadeGui.Parent=gui.Parent
local overlay=Instance.new("TextLabel"); overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(12,12,28); overlay.BackgroundTransparency=1
overlay.TextTransparency=1; overlay.Text="Falling asleep..."; overlay.TextColor3=cream; overlay.Font=Enum.Font.GothamBold; overlay.TextSize=32; overlay.ZIndex=10; overlay.Parent=fadeGui
local demo=false
local rushMode=false -- Bedtime Rush arcade evening (server's BedtimeRush attribute)
local function isEssential(key) return table.find(Dream.essentials,key)~=nil end
-- Keep the original interactions aligned with the relocated library and bed.
local bedroom=workspace:WaitForChild("CozyBedroom101")
local layoutAnchors=bedroom:WaitForChild("LayoutAnchors")
local bedSleepTarget=layoutAnchors:WaitForChild("BedSleepTarget")
local phoneDeskAnchor=layoutAnchors:WaitForChild("PhoneDeskAnchor")
local phoneBedAnchor=layoutAnchors:WaitForChild("PhoneBedAnchor")
local libraryAnchor=layoutAnchors:WaitForChild("LibraryInteractionAnchor")
local activities = {
	{"Curtains","The world outside can wait.","Close the curtains","Leave them open",Vector3.new(-99,22.4,-185)},
	{"Lighting","A softer glow makes this room feel like a place to rest.","Turn off the main light","Turn on the main light",Vector3.new(-95,17.4,-134.5)},
	{"Food","Dinner is over. What feels right for the end of your evening?","Finish eating for tonight","Have a late heavy meal",Vector3.new(-62,19,-157)},
	{"Phone","Where would you like your phone tonight? Putting it away uses the desk downstairs.","Put away for the night","Keep by the bed",phoneBedAnchor.Position},
	{"Notifications","The group chat is still buzzing. You can catch up tomorrow.","Turn on Do Not Disturb","Keep notifications on",phoneDeskAnchor.Position+Vector3.new(2,1,0)},
	{"Temperature","Settle into a room that feels comfortably cool to you.","Make the room comfortably cool","Keep the room warm",Vector3.new(-109,21,-149)},
	{"Shower","Warm water, a soft towel, and a quiet moment to reset.","Take a warm shower","Skip showering",Vector3.new(-128,17,-145)},
	{"BrushTeeth","Set your toothbrush ready and take a moment for your evening routine.","Brush my teeth","Skip brushing",Vector3.new(-120.5,18,-147.5)},
	{"Reading","A quiet chapter in your cozy downstairs library.","Read a quiet chapter","Skip reading",libraryAnchor.Position},
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
local phone=part("BedtimePhone",Vector3.new(1.2,0.18,2),phoneBedAnchor.Position,ink)
phone.CFrame=phoneBedAnchor.CFrame
local phoneScreen=Instance.new("SurfaceGui"); phoneScreen.Name="PhoneScreen"; phoneScreen.Face=Enum.NormalId.Top
phoneScreen.CanvasSize=Vector2.new(180,300); phoneScreen.Parent=phone
local phoneDisplay=Instance.new("TextLabel"); phoneDisplay.Size=UDim2.fromScale(0.86,0.88); phoneDisplay.Position=UDim2.fromScale(0.07,0.06)
phoneDisplay.BackgroundColor3=Color3.fromRGB(71,88,108); phoneDisplay.Text="Phone\n• • •"; phoneDisplay.TextColor3=cream
phoneDisplay.Font=Enum.Font.Gotham; phoneDisplay.TextScaled=true; phoneDisplay.Parent=phoneScreen
Instance.new("UICorner",phoneDisplay).CornerRadius=UDim.new(0,16)
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
local eveningStarted=nil
local eveningSeconds=300
local eveningClosed=false
local eveningGeneration=0
local function eveningTime()
	local elapsed=if eveningStarted then workspace:GetServerTimeNow()-eveningStarted else 0
	local minutes=math.floor(math.clamp(elapsed/eveningSeconds,0,1)*60)
	return string.format("%d:%02d PM",10+math.floor(minutes/60),minutes%60), elapsed
end
local remote -- assigned below after intro
local runDream
local choose
local morningReport
local rush -- the active Bedtime Rush round, if any
local shower
local reading
local function stopReading()
	if reading then reading.stop(); reading=nil end
end
local function stopShower()
	if shower then shower.stop(true); shower=nil end
end
local sleepNow, startRush
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
	local count=0; for _ in answers do count+=1 end
	progress.Text="Activities completed: "..count.." • All optional"
end
-- Demo mode shortens activity sequences so the whole loop fits in two minutes.
local function pace(seconds) return if demo then math.max(3,math.floor(seconds*0.25+0.5)) else seconds end
local function show(key)
	if busy or completed or eveningClosed then return end
	objective.Visible=false
	stopShower()
	if key=="Shower" then
		if answers.Shower then return end
		busy=true
		local result=request("ShowerStart")
		busy=false
		if completed or eveningClosed then return end
		if not result or not result.started then
			feedbackText.Text=if result and result.message then result.message else "Could not start the shower. Try again inside the shower tray."
			return
		end
		dialog.Visible=false
		local bathroom=bedroom:FindFirstChild("EnsuiteBathroom")
		if not bathroom then return end
		shower=ShowerInteraction.start(player,bathroom,function(temperature)
			local response=request("ShowerFinish",{temperature=temperature,wiped=true})
			if completed or eveningClosed then return false end
			if not response or not response.accepted then return false end
			answers.Shower=1; refresh(); updateMood(response.wellbeing,response.feedback)
			for _,p in prompts do if p.ObjectText=="Shower" then p.Enabled=false end end
			return true
		end)
		return
	end
	-- Bedtime Rush plays the key habits as objectives, not dialogs.
	if rushMode and isEssential(key) then return end
	-- In Bedtime Rush the bed ends the round immediately.
	if key=="Sleep" and rushMode then
		if rush then rush.goToBed() else sleepNow() end
		return
	end
	current=key; dialog.Visible=true; first.Visible=true; second.Visible=true; close.Visible=key~="Sleep"
	if key=="Sleep" then
		title.Text="Go to sleep at "..eveningTime().."?"; story.Text="Confirm to begin your dream, or return to your evening."; first.Text="Confirm"; second.Text="Cancel"
	else
		for _,a in activities do if a[1]==key then title.Text=key; story.Text=a[2]; first.Text=a[3]; second.Text=a[4] end end
	end
end
local function prompt(key,pos,object)
	local anchor=object or part(key.."Interaction",Vector3.new(1,1,1),pos,cream)
	if not object then anchor.Transparency=1 end
	local p=Instance.new("ProximityPrompt"); p.Name="BedtimePrompt"
	p.ActionText=if key=="Sleep" then "Go to Bed" elseif key=="Shower" then "Start Shower" else "Interact"
	p.ObjectText=if key=="Sleep" then "Upstairs bed" else key
	p.MaxActivationDistance=8; p.RequiresLineOfSight=false; p.HoldDuration=0; p.Enabled=false; p.Parent=anchor
	local marker=Instance.new("BillboardGui"); marker.Name="ActivityMarker"; marker.Size=UDim2.fromOffset(140,30)
	marker.StudsOffset=Vector3.new(0,2,0); marker.MaxDistance=18; marker.AlwaysOnTop=false; marker.Enabled=false; marker.Parent=anchor
	local markerText=label(marker,"• "..p.ObjectText,UDim2.fromScale(0,0),UDim2.fromScale(1,1))
	markerText.TextSize=14; markerText.TextStrokeTransparency=0.5; markerText.TextColor3=Color3.fromRGB(244,218,168)
	p:GetPropertyChangedSignal("Enabled"):Connect(function() marker.Enabled=p.Enabled end)
	p.Triggered:Connect(function() show(key) end); table.insert(prompts,p)
end
for _,a in activities do
	if a[1]=="Phone" then
		-- Reuse the existing physical phone: one choice prompt, following its location.
		prompt(a[1],a[5],phone)
	elseif a[1]=="Notifications" then
		local attachment=Instance.new("Attachment"); attachment.Name="NotificationInteraction"; attachment.Position=Vector3.new(2,0,0); attachment.Parent=phone
		prompt(a[1],a[5],attachment)
	else prompt(a[1],a[5]) end
end
prompt("Sleep",bedSleepTarget.Position)
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
	if key=="Phone" then phone.CFrame=if good then phoneDeskAnchor.CFrame else phoneBedAnchor.CFrame end
	if key=="Notifications" then phone.Color=if good then ink else Color3.fromRGB(120,196,232); phoneDisplay.Text=if good then "Phone\nQuiet mode" else "Phone\n• • •" end
	if key=="Temperature" then temperatureText.Text=if good then "67°F • Cool" else "72°F • Warm"; thermostat.Color=if good then Color3.fromRGB(160,200,220) else cream end
	if key=="Food" then snack.Transparency=if good then 1 else 0 end
end
-- Live stats from every night played, stored in Tiger Data by the backend.
local function communityLine(c)
	if type(c)~="table" or not c.nights then return "" end
	local parts={"\n\nAll players so far ("..c.nights.." nights)"}
	if c.scrolledRate then table.insert(parts,math.floor(c.scrolledRate*100+0.5).."% doomscrolled") end
	if c.phoneDocked and c.phoneScrolled then table.insert(parts,string.format("phone docked: %d stability vs %d scrolling",math.floor(c.phoneDocked+0.5),math.floor(c.phoneScrolled+0.5))) end
	if c.rankToday then table.insert(parts,"you're #"..c.rankToday.." today") end
	return table.concat(parts," • ")
end
local function showMorning(result)
	TweenService:Create(Lighting,TweenInfo.new(3),{ClockTime=7.2,Brightness=2,Ambient=Color3.fromRGB(150,140,130)}):Play()
	updateMood(result.wellbeing)
	if demo then
		dialog.Visible=false; hud.Visible=false; moodPanel.Visible=false; feedbackPanel.Visible=false
		if morningReport then morningReport.stop() end
		morningReport=require(script.Parent.RushResults).show(player,result,function()
			current="Replay"; choose(1)
		end)
		return
	end
	layout(true)
	dialog.Visible=true; hud.Visible=true; feedbackPanel.Visible=true
	moodPanel.Visible=true
	title.Text="Morning • Grade "..result.grade..": "..result.gradeTitle.." • Dream Stability "..result.stability.." / 100"
	local lines={}
	for _,line in result.dreamLines do table.insert(lines,"• "..line) end
	story.Text=result.feeling.." • Mood: "..result.wellbeing.moodLabel
		..string.format(" • Simulated sleep: %dh %02dm",math.floor(result.wellbeing.sleepMinutes/60),result.wellbeing.sleepMinutes%60)
		.." • Stumbles: "..result.stumbles
		.." • Sheep counted: "..result.sheep.." / "..result.sheepTotal
		..(if demo then " • In bed with "..result.secondsLeft.."s to spare" else "")
		.."\n\nYour choices shaped the dream:\n"..table.concat(lines,"\n")
		.."\n\n"..result.reflectionSource.." says: "..result.reflection
		.."\n\n"..result.suggestion
		..communityLine(result.community)
		.."\n\nBased on CDC sleep tips: turn off screens before bed, keep your room dark, quiet, and cool, and avoid large meals late at night. Dream Stability is a game outcome, not a measure of your health."
	current="Replay"; first.Text="Play another evening"; first.Visible=true; second.Visible=false; close.Visible=false
end
local function fade(visible,text)
	overlay.Text=text or overlay.Text
	local tween=TweenService:Create(overlay,TweenInfo.new(1),{BackgroundTransparency=if visible then 0 else 1,TextTransparency=if visible then 0 else 1})
	tween:Play(); tween.Completed:Wait()
end
function runDream(config)
	if completed then return end
	objective.Visible=false
	stopShower()
	stopReading()
	eveningClosed=true
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
choose = function(option)
	if busy or (eveningClosed and current~="Replay") then return end
	if current=="Sleep" and option==2 then dialog.Visible=false; current=nil; return end
	busy=true
	local generation=eveningGeneration
	local key=current
	local result=request(key,option)
	if completed and key~="Replay" then busy=false; return end
	if not result then story.Text="Could not save that choice. Please try again."; busy=false; return end
	if key=="Replay" and result.replay then
		stopShower()
		stopReading()
		if morningReport then morningReport.stop(); morningReport=nil end
		layout(false)
		lastWellbeing=nil; updateMood(result.wellbeing,"A fresh evening begins.")
		answers={}; completed=false; eveningClosed=false; eveningGeneration+=1
		local status=request("Status")
		eveningStarted=if status then status.eveningStarted else nil
		Lighting.ClockTime=22
		Lighting.Brightness=2; Lighting.Ambient=Color3.fromRGB(110,100,120)
		setCurtains(false); setCandle(true); setTV(false)
		apply("Phone",2); apply("Notifications",2); apply("Temperature",2); apply("Food",2); apply("Lighting",2)
		for _,p in prompts do p.Enabled=true end
		refresh(); dialog.Visible=false; showObjective()
		if rushMode then startRush() else hud.Visible=true; moodPanel.Visible=true; feedbackPanel.Visible=true end
	elseif key=="Sleep" then
		if result.message then story.Text=result.message
		elseif result.dream then runDream(result.dream) end
	elseif result.accepted then
		answers[key]=option; apply(key,option); refresh(); updateMood(result.wellbeing,result.feedback)
		if option==1 and key=="BrushTeeth" then
			first.Visible=false; second.Visible=false; close.Visible=false
			local bathroom=workspace.CozyBedroom101:FindFirstChild("EnsuiteBathroom")
			local duration=pace(20)
			local brush=if bathroom then bathroom:FindFirstChild("Toothbrush") else nil
			local brushHome=if brush then brush.CFrame else nil
			for remaining=duration,1,-1 do
				if completed or eveningClosed or generation~=eveningGeneration then break end
				story.Text="Freshening up for the night.".."\n\n"..remaining.." seconds • game activity"
				if key=="BrushTeeth" and brush and player.Character and player.Character:FindFirstChild("Head") then
					brush.CanCollide=false
					brush.CFrame=player.Character.Head.CFrame*CFrame.new(0.35*(if remaining%2==0 then 1 else -1),-0.25,-0.8)*CFrame.Angles(0,0,math.pi/2)
				end
				task.wait(1)
			end
			if brush and brushHome then brush.CFrame=brushHome end
		end
		if key=="Reading" and option==1 then
			first.Visible=false; second.Visible=false; close.Visible=false
			dialog.Visible=false
			reading=ReadingInteraction.start(player)
			local readingSession=reading
			while readingSession and readingSession.isActive() do
				if completed or eveningClosed or generation~=eveningGeneration or not readingSession or not readingSession.isActive() then break end
				task.wait(0.1)
			end
			stopReading()
		end
		if key=="WindDown" and option==1 then
			first.Visible=false; second.Visible=false; close.Visible=false
			for remaining=pace(60),1,-1 do if completed or eveningClosed or generation~=eveningGeneration then break end; story.Text="Rest your shoulders. Breathe gently.\nNothing to rush.\n"..remaining.." seconds"; task.wait(1) end
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
if not remote then gui:Destroy(); fadeGui:Destroy(); root:Destroy(); return end
demo=ReplicatedStorage:GetAttribute("DemoMode")==true
rushMode=ReplicatedStorage:GetAttribute("BedtimeRush")==true
if rushMode then
	-- Bedtime Rush plays the key habits as arcade objectives, so drop their dialog prompts.
	local kept={}
	for _,p in prompts do if isEssential(p.ObjectText) then p.Parent=nil else table.insert(kept,p) end end
	prompts=kept
end
function sleepNow()
	if busy or completed then return end
	if rush then rush.stop(); rush=nil end
	current="Sleep"
	choose(1)
end
function startRush()
	if rush then rush.stop() end
	hud.Visible=false; moodPanel.Visible=false; feedbackPanel.Visible=false
	rush=BedtimeRush.start({
		request=request,
		apply=apply,
		onFinished=function()
			-- Let an optional activity (like a shower) finish first.
			task.spawn(function()
				while busy do task.wait(0.2) end
				dialog.Visible=false
				sleepNow()
			end)
		end,
	})
end
for _,object in workspace:GetDescendants() do
	if object:IsA("PointLight") and object.Parent:IsA("BasePart") and object.Parent.Name~="Flame" and (object.Parent.Position-Vector3.new(-84,25,-161)).Magnitude<40 then roomLights[object]=object.Brightness end
end
bedroom=workspace:WaitForChild("CozyBedroom101",15)
if bedroom then
	expansion=bedroom:WaitForChild("CottageExpansion",15)
	if expansion then
		for _,fold in expansion.LinenCurtains:GetChildren() do
			if fold:GetAttribute("ClosedPosition") then table.insert(curtains,fold) end
		end
		for _,object in expansion:GetDescendants() do
			if object:IsA("ProximityPrompt") then
				object.Triggered:Connect(function()
					if busy or completed or eveningClosed then return end
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
if status then updateMood(status.wellbeing); eveningStarted=status.eveningStarted; eveningSeconds=status.eveningSeconds end
refresh()
gui.Enabled=true; Lighting.ClockTime=22
showObjective()
Lighting.Ambient=Color3.fromRGB(110,100,120)
for _,p in prompts do p.Enabled=true end
if rushMode then startRush() end
-- Polling also recovers a ready dream if a sleep reply was lost. runDream's
-- guard prevents a simultaneous Confirm reply from building a second course.
while gui.Parent do
	if not completed and not rushMode then
		local state=request("Status")
		if state then
			eveningStarted=state.eveningStarted
			eveningSeconds=state.eveningSeconds
			eveningClosed=state.phase~="room"
			if eveningClosed then
				objective.Visible=false
				stopShower()
				stopReading()
				for _,p in prompts do p.Enabled=false end
				dialog.Visible=false
			end
			if state.dream and not completed then task.spawn(runDream,state.dream) end
		end
		if not completed then
			local timeText,elapsed=eveningTime()
			clock.Text=timeText.." • Your evening"
			Lighting.ClockTime=22+math.clamp(elapsed/eveningSeconds,0,1)
			if current=="Sleep" and dialog.Visible then title.Text="Go to sleep at "..timeText.."?" end
		end
	end
	task.wait(0.25)
end
