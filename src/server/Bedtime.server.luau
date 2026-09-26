local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mood = require(Shared:WaitForChild("EveningMood"))
local Dream = require(Shared:WaitForChild("Dream"))

-- Demo mode: three key choices, then sleep immediately. Set false for the full
-- routine (all activities and five minutes of evening before bed).
local DEMO_MODE = true
-- Public URL of backend/backend/main.py (e.g. an ngrok tunnel ending in /reflection).
-- Leave empty to always use the scripted reflection. Requires HttpService.HttpEnabled.
local REFLECTION_URL = ""
local REFLECTION_TIMEOUT = 4
ReplicatedStorage:SetAttribute("DemoMode", DEMO_MODE)

local remote = Instance.new("RemoteFunction")
remote.Name = "BedtimeChoice"
remote.Parent = ReplicatedStorage
local choices = {
	Curtains = {"Close the curtains", "Leave them open"},
	Lighting = {"Use warm, dim lighting", "Keep the bright light"},
	Food = {"Finish eating for tonight", "Have a late heavy meal"},
	Phone = {"Put the phone on the desk", "Keep scrolling in bed"},
	Notifications = {"Turn on Do Not Disturb", "Keep notifications on"},
	Temperature = {"Make the room comfortably cool", "Keep the room warm"},
	Shower = {"Take a warm shower", "Skip showering"},
	BrushTeeth = {"Brush my teeth", "Skip brushing"},
	Skincare = {"Do my skincare routine", "Skip skincare"},
	Reading = {"Read a quiet chapter", "Skip reading"},
	WindDown = {"Take a quiet breathing break", "Skip winding down"},
}
local totalChoices = 0
for _ in choices do totalChoices += 1 end
local bedroomStart = CFrame.lookAt(Vector3.new(-101, 15.5, -139), Vector3.new(-101, 15.5, -161))
local checkpoints = Dream.checkpoints()

-- phase: "room" -> "ready" (sleep accepted) -> "dream" -> "morning"
local sessions = {}
local function begin(player)
	sessions[player] = {answers = {}, started = os.clock(), phase = "room"}
	player:SetAttribute("DreamStumbles", 0)
end
local function setup(player)
	player:GetAttributeChangedSignal("StartedGame"):Connect(function()
		if player:GetAttribute("StartedGame") and not sessions[player] then begin(player) end
	end)
	if player:GetAttribute("StartedGame") then begin(player) end
end
Players.PlayerAdded:Connect(setup)
for _, player in Players:GetPlayers() do setup(player) end
Players.PlayerRemoving:Connect(function(player) sessions[player] = nil end)

local function rootOf(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function missingEssentials(answers)
	local missing = {}
	for _, key in Dream.essentials do
		if not answers[key] then table.insert(missing, key) end
	end
	return missing
end

-- Scripted reflection: always available, tied to the exact choices made.
local reflections = {
	Phone = {
		"You put your phone away, so your dream path stayed quiet.",
		"Scrolling was fun in the moment, but notifications chased you through the dream.",
	},
	Lighting = {
		"Dimming the lights kept the dream calm and steady.",
		"The bright light kept things alert, so the dream glared and flickered.",
	},
	Food = {
		"Finishing dinner earlier kept the dream path still.",
		"The late heavy meal made the dream feel sluggish and restless.",
	},
}
local suggestions = {
	Phone = "Next night, try leaving your phone on the desk before you get into bed.",
	Lighting = "Next night, try switching to the warm lamps a little before bed.",
	Food = "Next night, try finishing your last big meal a bit earlier in the evening.",
	Notifications = "Next night, try turning on Do Not Disturb so late messages can wait.",
}
local function scriptedReflection(answers)
	local lines, suggestion = {}, nil
	for _, key in Dream.essentials do
		local option = answers[key] or 1
		table.insert(lines, reflections[key][option])
		if option == 2 and not suggestion then suggestion = suggestions[key] end
	end
	if not suggestion and answers.Notifications == 2 then suggestion = suggestions.Notifications end
	suggestion = suggestion or "Next night, keep the same routine. A consistent bedtime helps too."
	return table.concat(lines, " "), suggestion
end

-- Ask the Gemini backend for a reflection; fall back if it is slow or fails.
local function geminiReflection(answers, config, stumbles, suggestion)
	if REFLECTION_URL == "" then return nil end
	local chosen = {}
	for key, option in answers do
		if choices[key] then table.insert(chosen, choices[key][option]) end
	end
	local reply
	task.spawn(function()
		local ok, response = pcall(function()
			return HttpService:RequestAsync({
				Url = REFLECTION_URL,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json"},
				Body = HttpService:JSONEncode({choices = chosen, dream = config.lines, stumbles = stumbles, suggestion = suggestion}),
			})
		end)
		if ok and response.Success then
			local decoded, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
			if decoded and type(data) == "table" and type(data.reflection) == "string" and data.reflection ~= "" then
				reply = string.sub(data.reflection, 1, 500)
				return
			end
		end
		reply = false
		if not ok then warn("Reflection request failed:", response) end
	end)
	local deadline = os.clock() + REFLECTION_TIMEOUT
	while reply == nil and os.clock() < deadline do task.wait(0.1) end
	return reply or nil
end

local function finishNight(player, session)
	local wellbeing = Mood.summarize(session.answers)
	local stability = wellbeing.rest
	local text, suggestion = scriptedReflection(session.answers)
	local ai = geminiReflection(session.answers, session.dream, session.stumbles, suggestion)
	session.phase = "morning"
	session.result = {
		score = stability,
		stability = stability,
		feeling = if stability >= 75 then "A calm dream" elseif stability >= 50 then "A restless dream" else "A stormy dream",
		stumbles = session.stumbles,
		dreamLines = session.dream.lines,
		reflection = ai or text,
		reflectionSource = if ai then "Reflection by Gemini" else "Scripted reflection",
		suggestion = suggestion,
		answers = session.answers,
		wellbeing = wellbeing,
	}
	local character = player.Character
	if character then character:PivotTo(bedroomStart) end
	return session.result
end

remote.OnServerInvoke = function(player, key, option)
	if not player:GetAttribute("StartedGame") then return nil end
	local session = sessions[player]
	if not session then begin(player); session = sessions[player] end
	if key == "Replay" then
		if session.phase ~= "morning" then return nil end
		begin(player)
		return {replay = true, wellbeing = Mood.summarize({})}
	end
	if key == "Status" then return {wellbeing = Mood.summarize(session.answers), demo = DEMO_MODE} end
	if key == "Sleep" then
		if session.phase == "ready" then return {dream = session.dream} end -- retry after a failed EnterDream
		if session.phase ~= "room" then return nil end
		local count = 0
		for _ in session.answers do count += 1 end
		if DEMO_MODE then
			local missing = missingEssentials(session.answers)
			if #missing > 0 then return {message = "Before bed, make tonight's key choices: " .. table.concat(missing, ", ") .. "."} end
		else
			if count < totalChoices then return {message = "Try all " .. totalChoices .. " room and bathroom activities before going to sleep."} end
			local remaining = math.ceil(300 - (os.clock() - session.started))
			if remaining > 0 then return {message = "Enjoy a little quiet time. Bedtime is in " .. remaining .. " seconds. You can revisit your choices."} end
		end
		session.phase = "ready"
		session.dream = Dream.configure(session.answers)
		return {dream = session.dream}
	end
	-- The client builds its local course first, then asks to be moved into it.
	if key == "EnterDream" then
		if session.phase ~= "ready" then return nil end
		local root = rootOf(player)
		if not root then return nil end
		session.phase = "dream"
		session.checkpoint = 1
		session.stumbles = 0
		session.dreamStarted = os.clock()
		player:SetAttribute("DreamStumbles", 0)
		player.Character:PivotTo(Dream.spawnCFrame(checkpoints[1]))
		return {entered = true}
	end
	if key == "Wake" then
		if session.phase ~= "dream" then return nil end
		local root = rootOf(player)
		local reachedGoal = root and (root.Position - Dream.world(Dream.goal)).Magnitude <= Dream.goalRadius + 6
		local allowedEarly = option == "early" and os.clock() - session.dreamStarted >= Dream.earlyWakeSeconds
		if not reachedGoal and not allowedEarly then return nil end
		session.wokeEarly = not reachedGoal
		return finishNight(player, session)
	end
	if session.phase ~= "room" or not choices[key] or (option ~= 1 and option ~= 2) then return nil end
	session.answers[key] = option
	local feedback = Mood.feedback(key, option)
	local hint = Dream.hint(key, option)
	return {accepted = true, wellbeing = Mood.summarize(session.answers), feedback = if hint then feedback .. " " .. hint else feedback}
end

-- Server-owned dream progress: advance checkpoints and catch falls.
task.spawn(function()
	while true do
		for player, session in sessions do
			if session.phase == "dream" then
				local root = rootOf(player)
				if root then
					local offset = root.Position - Dream.origin
					for index = session.checkpoint + 1, #checkpoints do
						local point = checkpoints[index]
						if offset.Z <= point.Z + 8 and math.abs(offset.Y - point.Y) < 12 then session.checkpoint = index end
					end
					if offset.Y < -Dream.fallDepth then
						session.stumbles += 1
						player:SetAttribute("DreamStumbles", session.stumbles)
						root.AssemblyLinearVelocity = Vector3.zero
						player.Character:PivotTo(Dream.spawnCFrame(checkpoints[session.checkpoint]))
					end
				end
			end
		end
		task.wait(0.25)
	end
end)
