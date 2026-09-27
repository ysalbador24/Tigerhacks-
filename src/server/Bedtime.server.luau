local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Mood = require(Shared:WaitForChild("EveningMood"))
local Dream = require(Shared:WaitForChild("Dream"))

-- Demo mode keeps the existing short activity sequences and morning report.
-- RUSH_MODE separately enables the legacy arcade round.
local DEMO_MODE = true
-- Bedtime Rush (60-second arcade evening). Off = the original room: walk to
-- objects and choose during a five-minute evening; bed is always available.
local RUSH_MODE = false
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
ReplicatedStorage:SetAttribute("BedtimeRush", DEMO_MODE and RUSH_MODE)

local remote = Instance.new("RemoteFunction")
remote.Name = "BedtimeChoice"
remote.Parent = ReplicatedStorage
local choices = {
	Curtains = {"Close the curtains", "Leave them open"},
	Lighting = {"Use warm, dim lighting", "Keep the bright light"},
	Food = {"Finish eating for tonight", "Have a late heavy meal"},
	Notifications = {"Turn on Do Not Disturb", "Keep notifications on"},
	Temperature = {"Make the room comfortably cool", "Keep the room warm"},
	Shower = {"Take a warm shower", "Skip showering"},
	BrushTeeth = {"Brush my teeth", "Skip brushing"},
	WindDown = {"Read a book", "Scroll on phone"},
}
local bedroomStart = CFrame.lookAt(Vector3.new(-101, 15.5, -139), Vector3.new(-101, 15.5, -161))
local checkpoints = Dream.checkpoints()
local RUSH_SECONDS = 60
local EVENING_SECONDS = 300
-- In Bedtime Rush, healthy habits take effort: anything left undone falls back to these.
local rushDefaults = {Phone = 2, Lighting = 2, Food = 1}
local grades = {
	{95, "S", "Sleep Sensei"},
	{80, "A", "Well-Rested Legend"},
	{60, "B", "Decent Napper"},
	{40, "C", "Chronically Online"},
	{0, "D", "Raccoon Energy"},
}

-- phase: "room" -> "preparing" -> "ready" -> "dream" -> "morning"
local sessions = {}
local function begin(player)
	sessions[player] = {answers = {}, started = os.clock(), eveningStarted = workspace:GetServerTimeNow(), phase = "room"}
	player:SetAttribute("DreamStumbles", 0)
	player:SetAttribute("DreamSeverity", nil)
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
	answers = Dream.effectAnswers(answers)
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
				-- ngrok-skip-browser-warning: free ngrok tunnels otherwise answer with an HTML warning page.
				Headers = {["Content-Type"] = "application/json", ["X-Game-Key"] = GAME_KEY, ["ngrok-skip-browser-warning"] = "true"},
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
	-- Every evening activity for the stats page (missing = skipped). Activities keeps it a JSON object.
	local routine = {Activities = 0}
	for _, key in {"WindDown", "Lighting", "Food", "Notifications", "Curtains", "Temperature", "Shower", "BrushTeeth"} do
		if session.answers[key] then
			routine[key] = session.answers[key]
			routine.Activities += 1
		end
	end
	if session.shower then routine.ShowerComfortable = if session.shower.comfortable then 1 else 0 end
	local waitNight = postAsync("/nights", {
		player_id = tostring(player.UserId),
		display_name = string.sub(player.DisplayName, 1, 40),
		phone = session.answers.WindDown or 1,
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
		routine = routine,
	})
	local reflectionData = waitReflection()
	local ai = reflectionData and filtered(player, reflectionData.reflection, 500)
	local community = communityStats(waitNight())
	session.phase = "morning"
	player:SetAttribute("DreamSeverity", nil)
	session.result = {
		rush = DEMO_MODE and RUSH_MODE,
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
		shower = session.shower,
		wellbeing = wellbeing,
	}
	local character = player.Character
	if character then character:PivotTo(bedroomStart) end
	return session.result
end

local function restoreWindDown(session)
	local action = session.action
	if not action then return end
	if action.root.Parent then
		action.root.CFrame = action.home
		action.root.Anchored = action.anchored
		action.root.AssemblyLinearVelocity = Vector3.zero
	end
	if action.humanoid.Parent then
		action.humanoid.WalkSpeed = action.speed
		action.humanoid.JumpPower = action.jumpPower
		action.humanoid.JumpHeight = action.jumpHeight
		action.humanoid.AutoRotate = action.autoRotate
	end
	session.action = nil
end
local function finishWindDown(session)
	if session.phase ~= "winddown" then return end
	session.answers.WindDown = session.action.option
	restoreWindDown(session)
	session.phase = "room"
end

-- Reserve the transition before any backend request yields. Both the bed and
-- deadline use this path, so answers freeze and only one dream is configured.
local function prepareDream(player, session)
	if session.phase ~= "room" then return end
	session.phase = "preparing"
	session.bedtime = 22 + math.clamp((workspace:GetServerTimeNow() - session.eveningStarted) / EVENING_SECONDS, 0, 1)
	if DEMO_MODE and RUSH_MODE then
		for _, key in missingEssentials(session.answers) do session.answers[key] = rushDefaults[key] end
		session.secondsLeft = if session.rushStarted then math.clamp(math.floor(RUSH_SECONDS - (os.clock() - session.rushStarted)), 0, RUSH_SECONDS) else 0
	end
	session.dream = Dream.configure(session.answers)
	if session.dream.flags.Notifications then
		session.dream.notifications = geminiNotifications(player, session.answers)
	end
	session.phase = "ready"
end

local function expireEvening(player, session)
	if not RUSH_MODE and session.phase == "room"
		and workspace:GetServerTimeNow() >= session.eveningStarted + EVENING_SECONDS then
		prepareDream(player, session)
	end
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
	-- Gemini-written phone taunts for Bedtime Rush (once per night; nil = use scripted lines).
	if key == "PhoneTaunts" then
		if session.phase ~= "room" or session.tauntsRequested then return nil end
		session.tauntsRequested = true
		local taunts = geminiNotifications(player, {Phone = 2})
		return if taunts then {taunts = taunts} else nil
	end
	if key == "RushStart" then
		if session.phase == "room" and not session.rushStarted then session.rushStarted = os.clock() end
		return {started = true}
	end
	expireEvening(player, session)
	if key == "WindDownFinish" then
		if session.phase == "winddown" then finishWindDown(session) end
		expireEvening(player, session)
		if session.answers.WindDown then
			return {accepted = true, option = session.answers.WindDown, wellbeing = Mood.summarize(session.answers), feedback = Mood.feedback("WindDown", session.answers.WindDown)}
		end
		return nil
	end
	if key == "Status" then
		return {
			wellbeing = Mood.summarize(session.answers), demo = DEMO_MODE,
			eveningStarted = session.eveningStarted, eveningSeconds = EVENING_SECONDS,
			windDown = session.answers.WindDown,
			phase = session.phase, dream = if session.phase == "ready" then session.dream else nil,
		}
	end
	if key == "Sleep" then
		if session.phase == "ready" then return {dream = session.dream} end -- retry after a failed EnterDream
		if session.phase ~= "room" then return nil end
		prepareDream(player, session)
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
		-- Drives the client's sleep-deprivation effects for this dream.
		local flags = {}
		for flag in session.dream.flags do table.insert(flags, flag) end
		player:SetAttribute("DreamFlags", table.concat(flags, ","))
		player:SetAttribute("DreamSeverity", session.dream.severity or 0)
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
	if key == "ShowerStart" or key == "ShowerFinish" then
		if session.phase ~= "room" or session.answers.Shower then return nil end
		local room = workspace:FindFirstChild("CozyBedroom101")
		local bathroom = room and room:FindFirstChild("EnsuiteBathroom")
		local tray = bathroom and bathroom:FindFirstChild("ShowerTray")
		local root = rootOf(player)
		if not tray or not root then return nil end
		local offset = tray.CFrame:PointToObjectSpace(root.Position)
		if key == "ShowerStart" then
			if math.abs(offset.X) > tray.Size.X/2 or math.abs(offset.Z) > tray.Size.Z/2 or math.abs(offset.Y) > 8 then
				return {message = "Step inside the shower tray to turn on the water."}
			end
			session.showerStarted = true
			return {started = true}
		end
		if not session.showerStarted or (root.Position-tray.Position).Magnitude > 16 then return nil end
		local temperature = type(option) == "table" and option.temperature
		if type(temperature) ~= "number" or temperature ~= temperature or temperature < 0 or temperature > 1 or option.wiped ~= true then return nil end
		session.shower = {temperature = temperature, comfortable = temperature >= 0.4 and temperature <= 0.65}
		session.answers.Shower = 1
		session.showerStarted = nil
		return {accepted = true, wellbeing = Mood.summarize(session.answers), shower = session.shower,
			feedback = Mood.feedback("Shower", 1) .. (if session.shower.comfortable then " The water felt comfortable." else " The water was outside the comfortable range.")}
	end
	if key == "WindDown" then
		if session.phase ~= "room" or (option ~= 1 and option ~= 2) then return nil end
		local room = workspace:FindFirstChild("CozyBedroom101")
		local anchors = room and room:FindFirstChild("LayoutAnchors")
		local target = anchors and anchors:FindFirstChild("LibraryInteractionAnchor")
		local seat = room and room:FindFirstChild("WindowReadingSeat", true)
		local root = rootOf(player)
		local human = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not target or not root or not human or human.Health <= 0 or (root.Position-target.Position).Magnitude > 14 then return nil end
		session.action = {option = option,
			root = root, humanoid = human, home = root.CFrame, anchored = root.Anchored,
			speed = human.WalkSpeed, jumpPower = human.JumpPower, jumpHeight = human.JumpHeight, autoRotate = human.AutoRotate}
		session.phase = "winddown"
		root.Anchored = true; human.WalkSpeed = 0; human.JumpPower = 0; human.JumpHeight = 0; human.AutoRotate = false
		if seat and seat:IsA("BasePart") then root.CFrame = seat.CFrame * CFrame.new(0,seat.Size.Y/2+2,0) end
		return {action = true}
	end
	-- Shower completion must come through its interaction, never the old choice dialog.
	if key == "Shower" or key == "Phone" or key == "Reading" then return nil end
	if session.phase ~= "room" or not choices[key] or (option ~= 1 and option ~= 2) then return nil end
	session.answers[key] = option
	local feedback = Mood.feedback(key, option)
	return {accepted = true, wellbeing = Mood.summarize(session.answers), feedback = feedback}
end

-- Server-owned dream progress: advance checkpoints and catch falls.
task.spawn(function()
	while true do
		for player, session in sessions do
			-- Release interrupted activities without imposing a reading or scrolling timer.
			if session.phase == "winddown" and (not session.action.root.Parent
				or session.action.humanoid.Health <= 0 or rootOf(player) ~= session.action.root) then
				finishWindDown(session)
			end
			if not RUSH_MODE and session.phase == "room" and workspace:GetServerTimeNow() >= session.eveningStarted + EVENING_SECONDS then
				task.spawn(expireEvening, player, session)
			end
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
