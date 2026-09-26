local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mood = require(Shared:WaitForChild("EveningMood"))
local Dream = require(Shared:WaitForChild("Dream"))

-- Demo mode runs Bedtime Rush: a 60-second arcade round where the three key
-- habits are played, not clicked. Set false for the full routine (all
-- activities and five minutes of evening before bed).
local DEMO_MODE = true
-- Backend connection lives in src/server/BackendConfig.luau, which git ignores
-- (copy BackendConfig.example.luau). Without it, the game uses scripted text only.
local config = {}
local configModule = script.Parent:FindFirstChild("BackendConfig")
if configModule then
	local ok, loaded = pcall(require, configModule)
	if ok and type(loaded) == "table" then config = loaded else warn("BackendConfig could not be loaded:", loaded) end
end
-- Public base URL of backend/backend/main.py, e.g. "https://abc123.ngrok-free.app" (no trailing slash).
local BACKEND_URL = string.gsub(if type(config.url) == "string" then config.url else "", "/+$", "")
local BACKEND_TIMEOUT = 4
-- Must match GAME_API_KEY in the backend's .env (protects POST /nights).
local GAME_KEY = if type(config.gameKey) == "string" then config.gameKey else ""
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
local RUSH_SECONDS = 60
-- In Bedtime Rush, healthy habits take effort: anything left undone falls back to these.
local rushDefaults = {Phone = 2, Lighting = 2, Food = 1}
local grades = {
	{95, "S", "Sleep Sensei"},
	{80, "A", "Well-Rested Legend"},
	{60, "B", "Decent Napper"},
	{40, "C", "Chronically Online"},
	{0, "D", "Raccoon Energy"},
}

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
		"Your phone stayed on the desk, so nothing chased you tonight.",
		"You kept scrolling, so the Algorithm followed you into your dream. Rude.",
	},
	Lighting = {
		"Soft lamps meant a soft, starry dream.",
		"The big light stayed on, so your dream went full interrogation room.",
	},
	Food = {
		"Dinner was done early, so the path held still.",
		"That late heavy meal had the whole dream moving like a waterbed.",
	},
}
local suggestions = {
	Phone = "Next night, try leaving your phone on the desk before you get into bed.",
	Lighting = "Next night, try switching to the warm lamps a little before bed.",
	Food = "Next night, try finishing your last big meal a bit earlier in the evening.",
	Notifications = "Next night, try turning on Do Not Disturb so late messages can wait.",
}
local function scriptedReflection(answers, sheep, sheepTotal)
	local lines, suggestion = {"Baaa-rb here."}, nil
	for _, key in Dream.essentials do
		local option = answers[key] or 1
		table.insert(lines, reflections[key][option])
		if option == 2 and not suggestion then suggestion = suggestions[key] end
	end
	table.insert(lines, string.format("You counted %d of %d sheep%s", sheep, sheepTotal, if sheep == sheepTotal then ". Personal best, probably." else ". The rest were busy."))
	if not suggestion and answers.Notifications == 2 then suggestion = suggestions.Notifications end
	suggestion = suggestion or "Next night, keep the same routine. A consistent bedtime helps too."
	return table.concat(lines, " "), suggestion
end

-- Start a POST to the backend now; the returned function waits for the reply
-- (at most BACKEND_TIMEOUT seconds from the start), so requests can overlap.
local function postAsync(path, payload)
	if BACKEND_URL == "" then return function() return nil end end
	local reply
	local deadline = os.clock() + BACKEND_TIMEOUT
	task.spawn(function()
		local ok, response = pcall(function()
			return HttpService:RequestAsync({
				Url = BACKEND_URL .. path,
				Method = "POST",
				Headers = {["Content-Type"] = "application/json", ["X-Game-Key"] = GAME_KEY},
				Body = HttpService:JSONEncode(payload),
			})
		end)
		if ok and response.Success then
			local decoded, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
			if decoded and type(data) == "table" then reply = data; return end
		end
		warn("Backend request failed:", path, if ok then response.StatusCode else response)
		reply = false
	end)
	return function()
		while reply == nil and os.clock() < deadline do task.wait(0.1) end
		return reply or nil
	end
end

local function postBackend(path, payload)
	return postAsync(path, payload)()
end

-- AI text is shown in the game, so run it through Roblox's text filter first.
local function filtered(player, text, maxLength)
	if type(text) ~= "string" then return nil end
	text = string.sub(string.gsub(text, "[\r\n]+", " "), 1, maxLength)
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if ok and result ~= "" then return result end
	return nil
end

local function chosenTexts(answers)
	local chosen = {}
	for key, option in answers do
		if choices[key] then table.insert(chosen, choices[key][option]) end
	end
	return chosen
end

-- Gemini writes the notifications that swarm a scrolling player's dream.
local function geminiNotifications(player, answers)
	local data = postBackend("/notifications", {choices = chosenTexts(answers)})
	if not data or type(data.notifications) ~= "table" then return nil end
	local list = {}
	for _, text in data.notifications do
		local clean = filtered(player, text, 48)
		if clean then table.insert(list, clean) end
		if #list >= 6 then break end
	end
	return if #list >= 3 then list else nil
end

-- Barb the Sleep Sheep's morning report, written by Gemini. Returns a waiter.
local function geminiReflection(answers, config, stumbles, sheep, suggestion)
	return postAsync("/reflection", {
		choices = chosenTexts(answers), dream = config.lines, stumbles = stumbles,
		sheep = sheep, sheep_total = #config.sheep, suggestion = suggestion,
	})
end

-- Only plain numbers from the stats reach the client.
local function communityStats(data)
	if type(data) ~= "table" or type(data.stats) ~= "table" then return nil end
	local stats = data.stats
	local function number(value) return if type(value) == "number" then value else nil end
	return {
		nights = number(stats.nights),
		scrolledRate = number(stats.scrolled_rate),
		phoneDocked = number(stats.stability_phone_docked),
		phoneScrolled = number(stats.stability_scrolled),
		rankToday = number(data.rank_today),
	}
end

local function finishNight(player, session)
	local wellbeing = Mood.summarize(session.answers)
	local stability = wellbeing.rest
	local text, suggestion = scriptedReflection(session.answers, session.sheep, #session.dream.sheep)
	-- Grade: dream stability, plus counted sheep, plus getting to bed early.
	local points = stability + session.sheep * 2 + math.min(15, math.floor((session.secondsLeft or 0) / 2))
	local grade = grades[#grades]
	for _, entry in grades do
		if points >= entry[1] then grade = entry; break end
	end
	-- Ask Gemini for Barb's report and save the night to Tiger Data at the same time.
	local waitReflection = geminiReflection(session.answers, session.dream, session.stumbles, session.sheep, suggestion)
	local waitNight = postAsync("/nights", {
		player_id = tostring(player.UserId),
		display_name = string.sub(player.DisplayName, 1, 40),
		phone = session.answers.Phone or 1,
		lighting = session.answers.Lighting or 1,
		food = session.answers.Food or 1,
		notifications = session.answers.Notifications,
		stability = stability,
		grade = grade[2],
		points = points,
		sheep = session.sheep,
		sheep_total = #session.dream.sheep,
		stumbles = session.stumbles,
		seconds_left = session.secondsLeft or 0,
		woke_early = session.wokeEarly == true,
		gemini_used = BACKEND_URL ~= "",
	})
	local reflectionData = waitReflection()
	local ai = reflectionData and filtered(player, reflectionData.reflection, 500)
	local community = communityStats(waitNight())
	session.phase = "morning"
	session.result = {
		grade = grade[2],
		gradeTitle = grade[3],
		points = points,
		secondsLeft = session.secondsLeft or 0,
		score = stability,
		stability = stability,
		feeling = if stability >= 75 then "A calm dream" elseif stability >= 50 then "A restless dream" else "A stormy dream",
		stumbles = session.stumbles,
		sheep = session.sheep,
		sheepTotal = #session.dream.sheep,
		sheepCountable = session.dream.sheepCountable,
		dreamLines = session.dream.lines,
		reflection = ai or text,
		reflectionSource = if ai then "Barb the Sleep Sheep (Gemini)" else "Barb the Sleep Sheep",
		suggestion = suggestion,
		community = community,
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
	if key == "RushStart" then
		if session.phase == "room" and not session.rushStarted then session.rushStarted = os.clock() end
		return {started = true}
	end
	if key == "Status" then return {wellbeing = Mood.summarize(session.answers), demo = DEMO_MODE} end
	if key == "Sleep" then
		if session.phase == "ready" then return {dream = session.dream} end -- retry after a failed EnterDream
		if session.phase ~= "room" then return nil end
		local count = 0
		for _ in session.answers do count += 1 end
		if DEMO_MODE then
			for _, key in missingEssentials(session.answers) do session.answers[key] = rushDefaults[key] end
			session.secondsLeft = if session.rushStarted then math.clamp(math.floor(RUSH_SECONDS - (os.clock() - session.rushStarted)), 0, RUSH_SECONDS) else 0
		else
			if count < totalChoices then return {message = "Try all " .. totalChoices .. " room and bathroom activities before going to sleep."} end
			local remaining = math.ceil(300 - (os.clock() - session.started))
			if remaining > 0 then return {message = "Enjoy a little quiet time. Bedtime is in " .. remaining .. " seconds. You can revisit your choices."} end
		end
		session.phase = "ready"
		session.dream = Dream.configure(session.answers)
		if session.dream.flags.Notifications then
			session.dream.notifications = geminiNotifications(player, session.answers)
		end
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
		local info = if type(option) == "table" then option else {}
		local allowedEarly = info.early == true and os.clock() - session.dreamStarted >= Dream.earlyWakeSeconds
		if not reachedGoal and not allowedEarly then return nil end
		session.wokeEarly = not reachedGoal
		-- Sheep are counted on the client; clamp to what tonight's dream allowed.
		local sheep = if type(info.sheep) == "number" and info.sheep == info.sheep then math.floor(info.sheep) else 0
		session.sheep = math.clamp(sheep, 0, session.dream.sheepCountable)
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
