local Input=game:GetService("UserInputService")
local Thermostat={}
function Thermostat.open(player,initial,save)
	local gui=Instance.new("ScreenGui"); gui.Name="TemperatureInteraction"; gui.DisplayOrder=9; gui.ResetOnSpawn=false; gui.Parent=player.PlayerGui
	local connections={}; local stopped,busy=false,false
	local value=initial or 72
	local function connect(signal,fn) table.insert(connections,signal:Connect(fn)) end
	local function round(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
	local device=Instance.new("Frame"); device.AnchorPoint=Vector2.new(0.5,0.5); device.Position=UDim2.fromScale(0.5,0.55)
	device.Size=UDim2.new(0.86,0,0,300); device.BackgroundColor3=Color3.fromRGB(240,236,224); device.BorderSizePixel=0; device.Parent=gui; round(device,24)
	local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(350,300); limit.Parent=device
	local border=Instance.new("UIStroke"); border.Color=Color3.fromRGB(190,183,164); border.Thickness=2; border.Parent=device
	local function label(text,y,h)
		local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Text=text; t.TextColor3=Color3.fromRGB(48,43,58)
		t.Font=Enum.Font.Gotham; t.TextSize=14; t.TextWrapped=true; t.Position=UDim2.new(0,18,0,y); t.Size=UDim2.new(1,-36,0,h); t.Parent=device; return t
	end
	local heading=label("ROOM",10,26); heading.Font=Enum.Font.GothamBold; heading.TextSize=17
	local reading=label("",43,62); reading.BackgroundColor3=Color3.fromRGB(160,174,155); reading.BackgroundTransparency=0; reading.Font=Enum.Font.Code; reading.TextSize=42; round(reading,12)
	label("A cooler room, around 65–68°F, is an ideal temperature to sleep in.",109,43)
	local function button(text,x,y,w)
		local b=Instance.new("TextButton"); b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=17; b.TextColor3=Color3.fromRGB(48,43,58)
		b.Position=UDim2.new(x,0,0,y); b.Size=UDim2.new(w,0,0,36); b.BackgroundColor3=Color3.fromRGB(230,174,137); b.BorderSizePixel=0; b.Parent=device; round(b,10); return b
	end
	local down=button("▼",0.06,155,0.13); local up=button("▲",0.81,155,0.13)
	for _,b in {down,up} do b.BackgroundColor3=Color3.fromRGB(229,225,213); local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(177,168,148); s.Parent=b end
	local slider=Instance.new("TextButton"); slider.Text=""; slider.AutoButtonColor=false; slider.BackgroundTransparency=1
	slider.Position=UDim2.new(0.24,0,0,155); slider.Size=UDim2.new(0.52,0,0,36); slider.Parent=device
	local track=Instance.new("Frame"); track.Position=UDim2.fromScale(0,0.38); track.Size=UDim2.fromScale(1,0.24); track.BackgroundColor3=Color3.fromRGB(203,199,191); track.BorderSizePixel=0; track.Parent=slider; round(track,5)
	local range=Instance.new("Frame"); range.Position=UDim2.fromScale(0.1,0); range.Size=UDim2.fromScale(0.3,1); range.BackgroundColor3=Color3.fromRGB(155,184,157); range.BorderSizePixel=0; range.Parent=track; round(range,5)
	local knob=Instance.new("Frame"); knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Size=UDim2.fromOffset(18,26); knob.BackgroundColor3=Color3.fromRGB(255,250,239); knob.BorderSizePixel=0; knob.Parent=slider; round(knob,8)
	local bounds=label("64°F                         74°F",190,18); bounds.TextSize=11
	local feedback=label("",210,20); feedback.TextColor3=Color3.fromRGB(83,101,93)
	local done=button("Set temperature",0.06,241,0.58); local cancel=button("Back",0.68,241,0.26)
	local controller={}
	function controller.stop()
		if stopped then return end; stopped=true
		for _,c in connections do c:Disconnect() end
		gui:Destroy()
	end
	local function update(n)
		if busy or stopped then return end
		value=math.clamp(math.floor(n+0.5),64,74); reading.Text=value.."°F"; knob.Position=UDim2.fromScale((value-64)/10,0.5)
		feedback.Text=if value>=65 and value<=68 then "Perfect!" else "Choose what feels comfortable."
	end
	update(value)
	connect(down.Activated,function() update(value-1) end); connect(up.Activated,function() update(value+1) end)
	local drag
	local function slide(input) update(64+10*(input.Position.X-slider.AbsolutePosition.X)/slider.AbsoluteSize.X) end
	connect(slider.InputBegan,function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then drag=input; slide(input) end
	end)
	connect(Input.InputChanged,function(input) if drag and (input==drag or input.UserInputType==Enum.UserInputType.MouseMovement and drag.UserInputType==Enum.UserInputType.MouseButton1) then slide(input) end end)
	connect(Input.InputEnded,function(input) if input==drag then drag=nil end end)
	connect(done.Activated,function()
		if busy or stopped then return end; busy=true; done.Text="Saving…"
		local ok,accepted=pcall(save,value)
		if stopped then return end
		if ok and accepted then controller.stop() else busy=false; done.Text="Try again" end
	end)
	connect(cancel.Activated,function() if not busy then controller.stop() end end)
	connect(player.CharacterRemoving,controller.stop); connect(gui.Destroying,controller.stop)
	return controller
end
return Thermostat
